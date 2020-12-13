# Script for dimer interactions
# Requires anaconda
# See ./readme_conda 

#!/bin/bash
# Stop if you encounter error
set -e

export spack_root=/home/ajay/software/spack
. $spack_root/share/spack/setup-env.sh

export GMX_MAXBACKUP=-1     # Overwrites
export PLUMED_MAXBACKUP=-1  # Unlimited backups
###############################

#source gmx_plumed/bin/activate 
# Edit inputs below

#Ion1 
Ion1=NA
Ion1_q=1

#Ion2
Ion2=CL
Ion2_q=-1


#Tot_q=$(($Ion_q+$Solv_q))

#Solute_central_Atom
CA=NA

#Solvent_binding_Atom 
SA=CL

#Number of ion pairs
n=${1:-4}

#Inner shell radius (nm)
R0=1

#FUNCTIONAL and BASIS SET
#FUNCTIONAL=MP2
#BASIS_SET=aug-cc-pvdz

#Trajectory sampling time (ps) - do not change
nsteps=250000     #dt is set to 0.5 fs in mdp file

###############################
# Take care of situation where Ion=Solv
#[[ "$Ion" == "$Solv" ]] && Solv2="empty" || Solv2="$Solv"

cat << EOF > ion.top
[ defaults ]
; nbfunc        comb-rule       gen-pairs       fudgeLJ fudgeQQ
1               3               yes             0.5     0.5

#include "itp/atomtypes.itp"
#include "itp/HOH.itp"
#include "itp/$Ion1.itp"
#include "itp/$Ion2.itp"

[ system ]
; name
$Ion1-$Ion2-GP 

[ molecules ]
;name number
EOF

for i in `seq 1 $n`
do
cat << EOF >> ion.top
$Ion1      1
$Ion2      1
EOF
done

#cat << EOF > processed.top
#[ defaults ]
#; nbfunc        comb-rule       gen-pairs       fudgeLJ fudgeQQ
#1               3               yes             0.5     0.5
#
##include "itp/atomtypes.itp"
##include "itp/${Ion1}_.itp"
##include "itp/${Ion2}_.itp"
#
#[ system ]
#; name
#$Ion1-$Ion2-GP 
#
#[ molecules ]
#;name number
#EOF
#
#for i in `seq 1 $n`
#do
#cat << EOF >> processed.top
#$Ion1      1
#$Ion2      1
#EOF
#done

###############################

###############################

cat << EOF > mdp/min.mdp
integrator  = steep         ; Algorithm (steep = steepest descent minimization)
emtol       = 1.0          ; Stop minimization when the maximum force < 1000.0 kJ/mol/nm
emstep      = 0.01          ; Minimization step size
nsteps      = 50000         ; Maximum number of (minimization) steps to perform

; Parameters describing how to find the neighbors of each atom and how to calculate the interactions
cutoff-scheme            = group    ; Buffered neighbor searching
rlist                    = 0   ;gas ph min (0 means no cutoff)
rcoulomb                 = 0   ;gas ph min (0 means no cutoff)
rvdw                     = 0   ;gas ph min (0 means no cutoff)
pbc                      = no
nstenergy                = 10
nstxout                  = 10
nstlist                  = 0
ns-type                  = simple
continuation             = no  ; does the same thing as unconstrained_start
;unconstrained_start     = yes ; depricated

;       Vacuum simulations are a special case, in which neighbor lists and cutoffs are basically thrown out.
;       All interactions are considered (rlist = rcoulomb = rvdw = 0) and the neighbor list is fixed (nstlist = 0).
EOF

###############################

# Start from Ion.gro and insert waters and generate force-field
cp ion.top system.top
gmx insert-molecules -f struct/"$Ion1".gro -ci struct/"$Ion2".gro -o Ions.gro -box 1 1 1 -nmol 1 -try 1000 -scale 0.1 &> /dev/null

for i in `seq 1 $(($n-1))`
do
gmx insert-molecules -f Ions.gro -ci struct/"$Ion1".gro -o Ions.gro -box 1 1 1 -nmol 1 -try 1000 -scale 0.1 &> /dev/null
gmx insert-molecules -f Ions.gro -ci struct/"$Ion2".gro -o Ions.gro -box 1 1 1 -nmol 1 -try 1000 -scale 0.1 &> /dev/null
done

gmx editconf -f Ions.gro -bt cubic -d 0.5 -o IonW.gro &> /dev/null
#cat << EOF >> system.top
#$Solv   $n
#EOF


###############################

# Make index and plumed.dat ( to enforce QCT criterion )
# Make index file
echo 'q' | gmx make_ndx -f IonW.gro &> /dev/null

# Create matrix.dat - plumed creates a contact matrix for the cluster
cat > plumed.dat << EOF
Ion: GROUP NDX_FILE=index.ndx NDX_GROUP=Ion
WHOLEMOLECULES ENTITY0=Ion
mat: CONTACT_MATRIX ATOMS=Ion SWITCH={RATIONAL R_0=0.35 NN=10000} NOPBC
dfs: DFSCLUSTERING MATRIX=mat
nat: CLUSTER_NATOMS CLUSTERS=dfs CLUSTER=1
PRINT ARG=nat FILE=NAT
DUMPGRAPH MATRIX=mat FILE=contact.dot
EOF

#gmx select -f IonW.gro -s IonW.gro -on CA.ndx -select "atomname $CA" &> /dev/null
#gmx select -f IonW.gro -s IonW.gro -on SA.ndx -select "atomname $SA" &> /dev/null

###############################

# Minimize
echo -e "\n Run Minimization $Ion - $n $Solv \n"
gmx grompp -f mdp/min.mdp -c IonW.gro -p system.top -o min.tpr&> /dev/null
gmx mdrun -deffnm min -nsteps 1000000 &> /dev/null

# Make box bigger (does not really matter - but do it anyway to be safe)
gmx editconf -f min.gro -bt cubic -d 1.5 -o min2.gro &> /dev/null
gmx solvate -cp min2.gro -cs struct/solvent.gro -p system.top -o solv.gro &> /dev/null

gmx grompp -f mdp/md.mdp -c solv.gro -p system.top -o test.tpr -pp processed.top &> /dev/null
sed -i 's/ Na1 / Na1_/g' processed.top
sed -i 's/ Cl1 / Cl1_/g' processed.top
###############################

echo "$(cat << EOF
        Ion: GROUP NDX_FILE=index.ndx NDX_GROUP=Ion
        WHOLEMOLECULES ENTITY0=Ion
        mat: CONTACT_MATRIX ATOMS=Ion SWITCH={RATIONAL R_0=0.35 NN=10000} NOPBC
        dfs: DFSCLUSTERING MATRIX=mat
        nat: CLUSTER_NATOMS CLUSTERS=dfs CLUSTER=1
        PRINT ARG=nat FILE=NAT
        DUMPGRAPH MATRIX=mat FILE=contact.dot
EOF
)" | plumed driver --igro min2.gro --plumed /dev/stdin &> /dev/null;
###############################

bash run_hrex.sh 
