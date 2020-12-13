#!/bin/bash
        nrep=12
        tmin=300
        tmax=600

## build geometric progression of temperatures
        list=$(
        awk -v n=$nrep \
        -v tmin=$tmin \
        -v tmax=$tmax \
        'BEGIN{for(i=0;i<n;i++){
        t=tmin*exp(i*log(tmax/tmin)/(n-1));
        printf(t); if(i<n-1)printf(",");
        }
        }'
        )
        echo "intermediate temperatures are $list"

## clean directory (pre-existing folders)
        rm -fr topol*
#Create the replica folders
for((i=0;i<nrep;i++))
do
   mkdir -p topol$i
   lambda=$(echo $list | awk 'BEGIN{FS=",";}{print $1/$'$((i+1))';}')

   #process topology (create the "hamiltonian-scaled" forcefields)
   pmirun -n 1 plumed partial_tempering $lambda < processed.top > topol"$i"/topol.top

   #mpirun -n 1 gmx_mpi grompp -c em.gro -o topol"$i"/em.tpr -f em.mdp -p topol"$i"/topol.top

   # prepare tpr files
   mpirun -n 1 gmx_mpi grompp -c solv.gro -o topol"$i"/topol.tpr -f mdp/md.mdp -p topol"$i"/topol.top
done

