# Slurm Update for general farm users 

(Modified from RILAB Farm Guide)

![enjoy-slurm](http://i.imgur.com/9MG5aig.png)

Farm2 is runs on a different cluster workload management system than
Farm1 called Slurm. 

Most of
[our existing documentation](https://github.com/BaskettLab/farm-guide/blob/master/Beginners_guide_to_farm.md)
is still relevant for Farm2, up until
[how we submit jobs](https://github.com/BaskettLab/farm-guide/blob/master/Beginners_guide_to_farm.md#submitting-jobs-to-farm). This documentation has been updated for Farm 2 [for Windows users only](https://github.com/mfisher5/farm-guide/blob/master/Beginners_guide_to_farm_Windows.md).

See also the Farm Intro at [https://mcmaurer.github.io/farm-cluster-intro/](https://www.michaelc-m.com/farm-cluster-intro/)

## Connecting to Farm2

The address is `username@agri.cse.ucdavis.edu`. `username` here will
be your UCD kerberos ID. You will have to have generated a SSH key
(see
[this section in the past documentation](https://github.com/BaskettLab/farm-guide/blob/master/Beginners_guide_to_farm.md#setting-up-your-account))
and given the **public** key part (do not share the private key!) to
CSE Help.

### SSH Config

Make your life a little easier by adding the following to `~/.ssh/config`:

    Host farm
        HostName agri.cse.ucdavis.edu
        User username

    Host farm-cp
     	User youruser
     	HostName farm.cse.ucdavis.edu
     	Port 2022

Replace `username` with your username. The first group of lines will allow you to ssh to
farm with just `ssh farm` in the future.
The second group is for copying files to and from farm using the recommended port (so as not to burden the head node with network IO).
Use `scp <file on my computer> farm-cp:<location on farm>` to copy files (or use `rsync` as described [in Jeff's lab wiki](https://github.com/RILAB/lab-docs/wiki/Using-Farm)

## Getting to Know Slurm

Slurm is a lot like SGE: you submit jobs via batch scripts. These
batch scripts have common headers; we will see one below. For more information on Slurm, check the [CSEwiki](http://wiki.cse.ucdavis.edu/support:hpc:software:slurm) or the [conversion guide](http://slurm.schedmd.com/rosetta.pdf) comparing commands in Slurm with other schedulers like SGE.

First, we can get a sense of our lovely cluster with `sinfo`, which is
pronounced *sin-fay* (entomology unknown, but we think French origin):

    $ sinfo
    PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
    low          up   infinite     17    mix c9-[35-41,44-52,55]
	low          up   infinite      6   idle c8-[22-25],c9-[53-54]
	med*         up   infinite     17    mix c9-[35-41,44-52,55]
	med*         up   infinite      6   idle c8-[22-25],c9-[53-54]
	hi           up   infinite     17    mix c9-[35-41,44-52,55]
	hi           up   infinite      6   idle c8-[22-25],c9-[53-54]
	bigmem       up   infinite      1    mix bigmem3
	bigmem       up   infinite      1   idle bigmem4

Here we see our bigmems (more on those later), and all of their
inferior but still useful friends.

Note that there is a column of `STATE`, which indicates the state of
the machine. A better way of looking at what's going on on each
machine is with `squeue`, which is the job queue.

    $ squeue
    JOBID PARTITION     NAME     USER  ST       TIME  NODES NODELIST(REASON)
    5054_2  bigmem    stuff  vince251  R 1-22:25:27      1 bigmem3
    5370    bigmem      eva  vince251  R      56:10      1 bigmem3
    5066        hi LHS-Samp   dude     R 1-23:25:25      1 c9-35
    1911       low clump_al somedude   R 7-23:34:41      1 c9-52
    5350       med sewx_dri otherdude  R    3:33:01      1 c9-55
    5355       med cyclone_ otherdude  R    2:45:20     14 c9-[36-41,44-51]

This shows each job ID (very important), partition the job is running
on, name of person running the job. Also note `TIME` which is how long
a job has been running.

This queue is very important: it can tell us who is running what
where, and how long it's been running. Also, if we realize that we're
accidentally doing something silly like mapping maize reads to the
human genome, we can use `squeue` to find the job ID, allowing us to
cancel a job with `scancel`. Let's kill `vince251`'s job `eva`:

    $ scancel 5370

It's that easy! Slurm is pretty boring so far; all we can do is look
at the cluster and try to kill jobs. Let's see how to submit jobs.

## An Example Slurm Batch Script Header

We wrap our jobs in little batch scripts, which is nice because these
also help make steps reproducible. We'll see how to write batch
scripts for Slurm in the next section, but suppose we had one written
called `steve.sh`. To keep your directory organized, I usually
keep a `scripts/` directory (or even `slrum-scripts/` if you have lots
of other little scripts). 

I like to organize each of my projects in their own directory in a
general `~/projects/` directory. In each project directory, I make a
directory called `slurm-log` for Slurm's logs. Tip: use these logs, as
these are **very** helpful in debugging. I separate them from my
project because they fill up directories rather quickly.

Let's look at an example batch script header for a job called `steve`
(which is run with script `steve.sh`) that's in a project directory
named `your-cool-project` (you're going to change these parts).

	#!/bin/bash
	#SBATCH -D /home/vince251/projects/your-cool-project/
	#SBATCH -o /home/vince251/projects/your-cool-project/slurm-log/steve-stdout-%j.txt
	#SBATCH -e /home/vince251/projects/your-cool-project/slurm-log/steve-stderr-%j.txt
	#SBATCH -J steve
	set -e
	set -u

    # insert your script here

 - `-D` sets your project directory.
 - `-o` sets where standard output (of your batch script) goes.
 - `-e` sets were standard error (of your batch script) goes.
 - `-J` sets the job name.

Note that the programs in your batch script can redirect their output
however they like — something you will like want to do. This is the
standard output and standard error of the batch script itself.

Also note that these directories must already be made — Slurm will not
create them if they don't exist. If they don't exist, `sbatch` will
not work and die silently (since there's no place to write standard
error). If you keep trying something and it doesn't log the error,
make sure all these directories exist.

As mentioned, the jobname is how you distinguish your jobs in
`squeue`. If we ran this, we'd see "steve" in the JOBS column.

## Submitting Jobs

We submit our batch scripts with `sbatch`. For example, we can submit
the `steve.sh` job (assuming it's in a `scripts/` directory):

    $ sbatch scripts/steve.sh

It's that easy! After submitting jobs, check with `squeue` that it's
still running (and didn't immediately fail, do to syntax error or a
program not being in your `$PATH` or a
[module not loaded](https://github.com/BaskettLab/farm-guide/blob/master/Beginners_guide_to_farm.md#modules)). If
you don't see a `steve` job in `squeue`, then it's time to debug. Use
these `slurm-log/` directory to standard output and standard error to
figure out what happened. I use `ls -lrt` (`ls` with reverse time
sort) to see the most recent Slurm log, i.e.:

    $ ls -lrt slurm-log/
	-rw-rw-r-- 1 vince251 vince251            0 Sep 25 11:07 dwgeval-stderr-5370.txt
	drwxrwxr-x 2 vince251 vince251        12288 Sep 25 11:07 .
	-rw-rw-r-- 1 vince251 vince251           47 Sep 25 11:34 dwgeval-stderr-5368.txt

Hey cool, that's the name of the last Slurm job (but double check
against the job ID that `sbatch` gives you when you run it. Then look
at this in less or something.


## Specifying a Partition like bigmem

This is not an option unless the fearless leader of one's lab 
contributed a machine to the bigmem pool. See [the RILAB Wiki for details if that's the case](https://github.com/RILAB/farm-guide/blob/master/slurm-update.md#specifying-a-partition-like-bigmem).


## Allocating Resources

If you're using a process that requires more than one
CPU/thread/process, you'll need to allocate more tasks. It's very
important you do this, or else the cluster manager won't know how much
CPU your program is running, and allocate resources thinking it has
more available than it does. This really gums up the works, so don't
do this. To specify the number of tasks (roughly, number of
processes), use `sbatch --ntasks=x` where `x` is the number.

Farm2 plans for around 8GB of memory per CPU/task. So if your tasks
needs 16Gb of memory but only one CPU, use `--ntasks=2`. This makes
sure that machines don't get overtaxes.

## Monitoring Stuff

You can monitor jobs a few ways:

 - [Agri Ganglia](http://stats.cse.ucdavis.edu/ganglia/?r=hour&s=descending&c=Agri)

 - `squeue`: see if they are still running.

 - Watching your files grow.

 - Advanced: `ssh` to a node and use `top`, but **do not run anything
   on the nodes this way**. Every time you do this, Bill, Jeff, or I
   will have to ruthlessly strangle a young kitten. So if you not sure
   what this section means, save the kittens and don't `ssh` to the
   nodes.


## Interactive jobs (R, xterm) using Slurm

Often, we need to work interactively on a server. 
Keep in mind that using an interactive job on the server is fragile. 
Any interactive jobs may be randomly killed by the smallest network or system problem anywhere on your desktop/laptop, the network connection to the head
node, the network connection to the compute node, etc.

So avoid any long running jobs, they might be killed by a very short network issue!

## Using R with Slurm

For an interactive job, use `srun` with the following options:


    $ srun -p your-partition --pty R

This will drop you into an interactive R session on the partition
specified by `-p`. `--pty` launches srun in terminal in pseudoterminal
mode, which makes R behave as it would on your local machine.


## Using X fowarding with Slrum

For an interactive job using X windows, make sure to use the appropriate options to ssh in, 

    $ ssh -X <user>@<cluster

Then, use `srunx`:
      
      $ srunx <queuename>

The command `srunx` is an alias: 

    $ salloc -p [queue] xterm -e 'ssh -X `srun hostname`'  

So, to pass additional options (e.g. a specific amount of memory) try modifying this command directly. For example: 
   
   $ salloc -p [queue] xterm -e 'ssh -X `srun hostname`'   --mem=<MB>


## Warnings

**Do not run anything on the headnode** except cluster management
tools (`squeue`, `sbatch`, etc), compilation tasks (but usually ask
CSE help for big apps), or downloading files. If you run anything on
the headnode, you will disgrace your lab. How embarrassing is this?
Imagine if you had to give your QE dressed up like Richard
Simmons. It's that embarrassing.

!["oh my! look at how terrible he is for running crap on the headnode!"](http://i.imgur.com/7VqJ9oY.jpg)

**Back up your stuff**, as Farm2 does not back up your stuff. Using
git is a good option.

**Monitor your disk space**, as it can fill up quickly.

## To Add

 - Array jobs
