#!/bin/bash
###
cat << EOF > md.mdp
define                  = -DFLEXIBLE
integrator              = sd        ; leap-frog integrator
nsteps                  = 1000000     ; 2 * 50000 = 100 ps
dt                      = 0.0005     ; 0.5 fs

; Output control
nstxout                 = 1000     ; save coordinates every 1.0 ps
nstvout                 = 1000     ; save velocities every 1.0 ps
nstenergy               = 1     ; save energies every 1.0 ps
nstcalcenergy           = 1
nstlog                  = 100       ; update log file every 1.0 ps


; Parameters describing how to find the neighbors of each atom and how to calculate the interactions
cutoff-scheme            = group    ; Buffered neighbor searching
rlist                    = 0   ;gas ph min (0 means no cutoff)
rcoulomb                 = 0   ;gas ph min (0 means no cutoff)
rvdw                     = 0   ;gas ph min (0 means no cutoff)
pbc                      = no
nstlist                  = 0
ns-type                  = simple
constraints              = none      ; bonds involving H are constrained
continuation             = no  ; does the same thing as unconstrained_start

;       Vacuum simulations are a special case, in which neighbor lists and cutoffs are basically thrown out.
;       All interactions are considered (rlist = rcoulomb = rvdw = 0) and the neighbor list is fixed (nstlist = 0).

; Run parameters

; Temperature coupling is on
;tcoupl                  = nose-hoover           ; modified Berendsen thermostat
tc-grps                 = system                ; two coupling groups - more accurate
tau_t                   = 2                   ; time constant, in ps
ref_t                   = 300                   ; reference temperature, one for each group, in K

EOF

###
cat << EOF > min.mdp
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
nstenergy                = 1
nstxout                  = 1
nstlist                  = 0
ns-type                  = simple
continuation             = no  ; does the same thing as unconstrained_start
;unconstrained_start     = yes ; depricated

;       Vacuum simulations are a special case, in which neighbor lists and cutoffs are basically thrown out.
;       All interactions are considered (rlist = rcoulomb = rvdw = 0) and the neighbor list is fixed (nstlist = 0).
EOF

