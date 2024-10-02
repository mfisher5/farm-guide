#!/bin/bash -l
#SBATCH -D ~/OneDrive - University of California, Davis/Documents/farm-guide
#SBATCH -o ~/OneDrive - University of California, Davis/Documents/farm-guide/R/test_hello-stdout-%j.txt
#SBATCH -J test_hello

 # module load gcc R # hashed out to run locally
R CMD BATCH test_hello.R