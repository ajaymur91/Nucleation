#!/bin/bash

for i in `seq 1 20`
do
	cp -r sample_n sample_$i
	cd sample_$i
	bash run_n.sh $i
		mkdir -p config_$i
         	cd config_$i
		b=$(gmx check -f topol0/topol.xtc &> /dev/stdout | grep Step| awk '{print $2*$3/2}')
		echo 0 | gmx trjconv -f topol0/topol.xtc -s topol0/topol.tpr -o config/.gro -b $b -sep
		cd ..
	cd ..
done

