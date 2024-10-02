# Beginner's guide to farm for Windows


Farm is a computer cluster that runs a distribution of Linux called CentOS version 5.8. 

Farm has a **head node** , which controls the cluster, and **compute nodes** which is where the action happens. For the most part, you interact with Farm using scripts to launch jobs on the compute nodes; you don't run processes on the head node and you don't log into the compute nodes directly.

This doc was updated 09/2024 based on Michael Culshaw-Maurer's [farm cluster info webpage](https://www.michaelc-m.com/farm-cluster-intro/) and the UCD Data Science Training tutorials.

##### UC Davis Resources

For common issues and questions, visit the link:
https://hpc.ucdavis.edu/faq

To learn about Linux commands and scripts, see this link:
https://hpc.ucdavis.edu/helpdocs

Data Science Training tutorials:
https://ngs-docs.github.io/2021-august-remote-computing/index.html 

## Contents:

- Setting up your account
- Unix shell tips / basics
- Farm defaults
- Installing programs on farm
- Special farm things [scratch usage, tentakel]
- Submit jobs to farm 


## Setting up your account:

### Account Request form

Start by submitting an [Account Request](https://hpc.ucdavis.edu/account-request-forms) on the UC Davis HPC website. Under the "New Accounts" tab, there will be a link to create a request on the new platform [HiPPO](https://hippo.ucdavis.edu/). After you submit this form, wait to get an email from Hippo Notification <hippo@notify.ucdavis.edu>

When requesting an account, you will need to have: your UC Davis CAS ID, email address, Group (baskettgrp), Supervising PI or sponsor (Marissa Baskett), computing cluster (FARM), department information and your **SSH public key.** If your lab isn't listed, you can still use farm - just refer to [this documentation](https://wiki.cse.ucdavis.edu/support:systems:farm).

### The SSH key

> SSH is a widely-used protocol for securely logging into a computer from another computer. Since the FARM is basically another gigantic computer, this is what we’ve gotta do. The way SSH works is that you generate a key pair. You can think of this as a pair of extremely weird and long passwords that recognize each other. One is your public key and the other is the private key. As the names suggest, your public key will get shared with the other computer you want to log into, and the private key stays on your computer and **should never ever ever be shared.**

- [*Farm Cluster Intro*](https://www.michaelc-m.com/farm-cluster-intro/)

Two important notes on SSH keys: Once you lose the passphrase, you *can't get it back.* And you should make sure you can get to your `.ssh` folder from File Explorer.


The process for generating your SSH public key is as follows...


a. Open a Git Bash terminal (not Git GUI) or the Terminal in RStudio. Check your home directory (something like /c/Users/Username/); you can create a folder here to hold the ssh keys, or navigate to a different folder.

```
pwd
mkdir .ssh
```

b. Create the key. After typing in the last line of code below, hit Enter on the next question without typing anything - you want to use the default file name for the keys (id_rsa and id_rsa.pub) to avoid potential problems with logging into your farm account in Git Bash.

```
cd .ssh
ssh-keygen -b 2048 -t rsa
```

c. Key in a passphrase and hit Enter. Nothing will show up on the screen, that's supposed to happen!

d. You should see something very similar to that in Macs shown above, and you'll now have a key pair in /c/Users/Username/.ssh. Go to <https://wiki.cse.ucdavis.edu/cgi-bin/index2.pl>, fill out the short web form (choosing your OS, graduate lab, etc), attach your public key (id_rsa.pub), and submit it. 


## Unix shell tips / basics:

Some terminology: The language *Linux* is run by typing commands and responding to prompts in the *command line*; the *command line* exists in a *terminal* program. The bash *shell* interprets the text commands from the command line for the computer.

The existing FARM documentation may be easier to follow using the **Git Bash** terminal [download instructions here](<https://openhatch.org/missions/windows-setup/install-git-bash>), compared to the Windows command line. IT has approved git bash for use on school computers.

In addition to opening a git bash terminal window, RStudio has a "Terminal" tab - check the Tools >> Terminal >> "Terminal Options" to confirm if its using git bash. 

![img-rstudio-terminal](https://github.com/mfisher5/farm-guide/blob/master/imgs/rstudio-terminal-screenshot.png?raw=true)

Send a command in this document to the terminal by highlighting it and then using the keys Alt+Ctrl+Enter.

Some basic bash commands:
```sh
git -v, , # check git version
bash -version # check bash version
pwd, ,    # what is the working directory
ls -a, ,  # list all the files in the working directory
mkdir test, # create a new folder in the working directory
cd test,    # go into that new folder
cd ../, , # return up to working directory
rmdir test, # delete the test folder
cat, ,    # print the contents of a file to the terminal
```

Helpful tips -- 

- when typing in a directory or file name into the command line, you can auto-complete the name by hitting tab

- you can't use ctrl-c / ctrl-v shortcuts to copy and paste on the command line, you have to right click - copy / paste.

### nano: Editing text files

Both the UCD docs and the Culshaw-Maurer webpage use `nano` to create and modify text files from the command line. This is a command line program standard to most Linux systems; I have it on git bash and therefore my terminal in RStudio.

Check to see if you have nano:

```
nano --version

>>  GNU nano, version 7.2
 (C) 2023 the Free Software Foundation and various contributors
 Compiled options: --enable-utf8
```

This should open a text editor window

```
cd ../ # return to main farm-guide directory, from the R directory
nano README.md
```

Exit by typing CTRL-X. When you do this, nano will ask if you want to save the modified file. If you say “No”, it will not save; if you type ‘y’, it will ask you for the name of the file. Just hit ENTER to overwrite the file you edited here.


There is a list of letter-based commands below the lines of the file that nano prints to the screen.

^G Help,  ^O Write Out, ^W Where Is,  ^K Cut,   ^T Execute, ^C Location,  M-U Undo, M-A Set Mark, M-] To Bracket  M-Q Previous, ^B Back
^X Exit,  ^R Read File, ^\ Replace,   ^U Paste, ^J Justify, ^/ Go To Line, M-E Redo, M-6 Copy, ^Q Where Was, M-W Next, ^F Forward

You can do the full [UCD tutorial here](https://ngs-docs.github.io/2021-august-remote-computing/creating-and-modifying-text-files-on-remote-computers.html)


### Basic files I: Shell script

This is a very small script which just tells farm where you want to store files, which program(s) you'll need, and where to find the scripts for your main task. On a very basic level, the lines below are all that you need in a .sh file to run an R script:

```sh
	#!/bin/bash -l
	#SBATCH -D /home/username/myproject/
	#SBATCH -o /home/username/myproject/name-stdout-%j.txt
	#SBATCH -J name
		
	module load gcc R
	R CMD BATCH myRscript.R
```

A few comments: the first line just establishes what syntax these commands are using (in this case bash)

-D: This sets your working directory. This is where your .sh and .R scripts will be located, and this is also where farm will store a history of the console (for R, it will be a .Rout file, which you can view in a text editor). This file can be very useful to check if anything went wrong within R while running the script (eg, missing libraries or packages).

-o: This just sets up the name+place of a small text file which contains feedback from running the .sh script. It may be helpful to check this file if your job doesn't run - for example, to see if you're calling an invalid or unavailable program.

The last 2 lines load the programs you need (for R, its gcc and R), and which script you'll be running in them.

Let's try out running an R script from a bash shell on your local PC! Create an R script that just prints "Hello world."

```
# mkdir R

cd R

ls
>> test_hello.R

cat test_hello.R
>> message("hello world!")
```

Customize the basic .sh that you need to run an R script, outlined above. Here's what mine looks like:

```
ls
>> test_hello.R  test_hello.sh*

cat test_hello.sh
>> #!/bin/bash -l
   #SBATCH -D ~/OneDrive - University of California, Davis/Documents/farm-guide
   #SBATCH -o ~/OneDrive - University of California, Davis/Documents/farm-guide/R/test_hello-stdout-%j.txt
   #SBATCH -J test_hello

   # module load gcc R # hashed out to run locally
   R CMD BATCH test_hello.R
```

What happens when we run it?

```
bash test_hello.sh

cat test_hello.Rout

>> R version 4.4.0 (2024-04-24 ucrt) -- "Puppy Cup"
Copyright (C) 2024 The R Foundation for Statistical Computing
Platform: x86_64-w64-mingw32/x64

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.

  Natural language support but running in an English locale

R is a collaborative project with many contributors.
Type 'contributors()' for more information and
'citation()' on how to cite R or R packages in publications.

Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.

[Previously saved workspace restored]

> message("hello world!")
hello world!
>
> proc.time()
   user  system elapsed
   0.00, 0.01, 0.12
```



### Basic files II: R script

There are a few commands which you probably don't use very often, but which will be needed to run the R script on farm. Here is the basic structure of a script you might use:

First, we tell R where to install and/or find preinstalled packages. This needs to be a folder which you create beforehand in the home directory of your farm account.

` .libPaths( "/home/username/MyPackages" )`

Now lets install the packages we need. Add/remove any that you need from this list, and be sure to specify the repository (probably just cran).

`install.packages(c('doParallel','foreach','deSolve'), repos='http://cran.us.r-project.org')`

After the first time you run a script with the line above, the packages will be installed in your R library on farm, and in the future you can just comment out/remove the line above, and load them as usual.

`library(doParallel); library(foreach); library(deSolve);`


Below you'll set up the parameters and functions needed for the simulation. You'll most likely want to paralellize your code so you can use >1 core simultaneously. There's extensive documentation on how to do this online, but since most people love for() loops, here's an example of how they can be parallelized using the foreach package; for explanations of what everything is, look through <https://cran.r-project.org/web/packages/foreach/vignettes/foreach.pdf>.
First though we need to set up the parallel environment. There are multiple ways of doing this. Since we're using foreach, to do this we'll need a function from the doParallel packages. Here you specify the number of cores you'll need to use; if you're not sure, use 8 (# of processors on a single node). If you want >8, you'll need to use multiple nodes; read up on how to do that, eg in the CSE wiki.

`registerDoParallel(cores=8)`

Now we can call the foreach function, which will parallelize the simulation code inside it. Note the need to pass foreach() any packages you need, choose the appropriate function to combine the output, etc.

`output = foreach(k = (1:10), .packages="deSolve", .combine=rbind) %dopar% { ... }#simulation code in brackets`


Then do any transformations you want to the output. There are several options on how to save the output - for example, if all you want out is a single object (vector, matrix, array), you can save the object using saveRDS() and then read it into R on your computer after moving it there. Alternatively, you can save the whole working environment and then continue transforming/graphing the results on your own computer. However, in that case, you may run into compatibility issues if you're running a different version of R than farm.
In either case, first specify the location in your home directory on farm where the files will be saved (you can't access files on your PC from the R session on farm).

```r
setwd("/home/username/myproject")
save(list=ls(all=TRUE), file="myworkspace.RData")
saveRDS(output, "myresults.rds")
```


		
## Bare basics of running jobs on farm
Here, well briefly go over the basics of connecting to farm, moving files between your PC and farm, and submitting jobs. A wonderful resource to look/work through to get familiar with the syntax is: <http://cli.learncodethehardway.org/book/>.

### First time in farm

#### a. Tell you computer that Farm is a 'known host.' 

**This didn't work for me, but maybe it'll work for you**

Make a file in the folder with your .ssh keys called 'config', that contains the following text:

```
VerifyHostKeyDNS yes
Host farm
  HostName agri.cse.ucdavis.edu
  User your-user-name
```

Let's do that using nano from the command line.
```
cd
cd keys # navigate to .ssh directory
ls -a   # check what's in there
>> farmkey.txt  farmkey.txt.pub  farmkey_terminal.txt

nano config # use nano to make config file; type in text above on the command line, exit, and save

ls -a      # is the new config file here?
>> ./  ../  config  farmkey.txt  farmkey.txt.pub  farmkey_terminal.txt

cat config # check file contents

>> VerifyHostKeyDNS yes
   Host farm
        HostName agri.cse.ucdavis.edu
        User marfishe
```


#### b. Ok, now we can connect to farm using the ssh command.

If you successfully completed (a) above, you should be able to just type in:

```
ssh farm
```

If (a) didn't work for you, then you'll get a message  `>>> ssh: Could not resolve hostname farm: Name or service not known`
 

Instead, type in: `username@farm.cse.ucdavis.edu` and say 'yes' when it asks if you want to continue connecting. Enter your password.

```
ssh marfishe@farm.cse.ucdavis.edu

>>> The authenticity of host 'farm.cse.ucdavis.edu (128.120.146.1)' can't be established.
>>> This key is not known by any other names.
>>> Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
>>> marfishe@farm.cse.ucdavis.edu's password:
```

If you forget your username, log into your HIPPO account. In Account Details, go to data > groups > home. Whatever is after `/home/` is your username. So for example, mine is `/home/marfishe` because *marfishe* is my username.


b. You should see a series of messages, and after that you'll be in your home directory on farm: /home/username/. You can verify this via print working directory - `pwd`

c. Now lets make 2 folders we referenced earlier in the .sh and .R scripts. You can structure this any way you like; I ran one command for the scripts+outputs folder on my current project (`mkdir myproject`) and one command to make a folder for all my R packages (`mkdir MyPackages`).

d. Enter the command `ls`. You should still be in your home directory, and this will show all the files/folders in there. You should see two items: `myproject` and `MyPackages`.


### Moving files between farm and your computer
a. To do this, you'll need to log out of farm - use the `exit` command. If you were in the home directory on your PC before logging on (`/c/Users/Username/` in Windows, `~` on Mac or unix-like), you should still be there - use `pwd` to check.

b. If you're new to Linux, it may be helpful to make a new folder near your home directory where we could store all our .sh and .R scripts. I created a new folder in the .ssh folder for this using `mkdir .ssh/ClusterScripts`. I will reference this path in future commands, but this could be any folder on your computer.

c. (maybe optional -- **windows**) A common issue on Windows machines is that they tend to save script files in DOS format, whereas farm needs them to be in unix format. To be safe, you can easily fix this via the Git Bash terminal. Simply (1) navigate to the folder with scripts `cd .ssh/ClusterScripts`, and (2) run the commands `dos2unix *.sh` and `dos2unix *.R` (* is a 'wildcard' character - that is, any files ending with .R or .sh, like our scripts, will be converted). You  should see something like `dos2unix: converting file myscript.sh to UNIX format ...`

d. Now move the scripts to your account on farm using: `scp .ssh/ClusterScripts/myscript.R username@farm.cse.ucdavis.edu:~/myproject/myscript.R` and `scp .ssh/ClusterScripts/myscript.sh username@farm.cse.ucdavis.edu:~/myproject/myscript.sh`. Each time, you'll be asked for your passphrase to farm. Alternatively, if you only have the 2 scripts in your folder, you could use `scp .ssh/ClusterScripts/* username@farm.cse.ucdavis.edu:~/myproject/`, which will copy over all files inside ClusterScripts.

e. When your job finishes successfully, the output should be in /home/username/myproject. To move it to your computer, you must first log out of your farm account using `exit` (if you're logged in), and then use the command `scp username@farm.cse.ucdavis.edu:~/myproject/myworkspace.RData .ssh/ClusterScripts/myworkspace.RData`

### Submitting jobs on farm
This is covered in greater detail below, but generally all you need to do is:

a. Log into your farm account and navigate to the folder with your shell script (`cd myproject`)

b. Run your shell script using `sbatch -p serial -N 1 -n 8 myscript.sh`, which will in turn run your R script in the same folder. If you set up your scripts as described above, this command should work. If you want to play around with it, read the section on submitting jobs below.

c. After a few seconds, enter the command `squeue` to see a list of running jobs; if your shell scripts ran fine, you should be able to see your job. If not, refer to the .Rout and .txt output files in /home/username/myproject. 


## Farm Defaults:
Farm comes with a lot of software preinstalled. Here's a list of some of the most commonly used ones:

* gcc
* Git
* libsequence
* Matlab
* Perl
* Python
* R

####Installing programs on farm:

#####C and C++:
When using farm, you're probably going to need to install some software. Since farm is a Linux computer, it follows much the same procedure as other Linux computers. The main difference is that you can't install things into the default directory. This is because it's located in `/bin` and you need root access in order to do that. The solution is to change where the binary file is located:

1. Download software:

		$ wget http://www.best-software-ever.com/thesis-in-a-box.tar.gz

2. Untar it:

		$ tar -xvzf thesis-in-a-box.tar.gz

3. Move to your new directory:

		$ cd thesis-in-a-box

4. Configure the program:

		$ ./configure --prefix=/home/user/[path for binary executable]/

5. Compile the program:
		
		$ make

6. Move it to the path you specified:
	
		$ make install

Note: this only works for software that is packaged to be installed this way. Always make sure to read the README or INSTALL files to ensure you're doing it right.

Then, to run the program just type in the path:

	$ /home/user/programs/thesis

Now, that's a lot to type every time you want to run a program. There are multiple better ways.

#####Alias:

Bash has something called aliases, which let you put your own shorter (usually) command to stand for another command. For example, I could create an alias for my thesis program called `graduate` which runs `/home/user/programs/thesis`. I could also create an alias for `ls -a` (show hidden files) called `la`. To do this, you need to create a file called `.bash_profile`

a. Make sure you're in the home directory

		$ cd

b. Create `.bash_profile`

		$ touch .bash_profile

c. Open it up in your favorite text editor
	
		$ nano .bash_profile

d. Create the aliases by typing this in:
	
		alias graduate="/home/user/programs/thesis"
		alias la="ls -a"

e. Save the file:
In nano this is control+O (WriteOut)

f. Reload bash by logging out or with this command:

		$ source ~/.bash_profile

#####Add to path:
When you type in a command into bash, bash looks for a binary file matching that command. The places it looks by default on farm are: 

	/share/apps/ge-6.2/bin/lx24-amd64
	/usr/kerberos/bin
	/usr/local/bin
	/bin
	/usr/bin

We can shorten the command we have to type by adding the binary file to the path. To do this, we add it to the `.bash_profile`.

a. Make sure you're in the home directory

		$ cd

b. Create `.bash_profile`

		$ touch .bash_profile

c. Open it up in your favorite text editor

		$ nano .bash_profile

d. Add to your path by typing this in:
		
		PATH=$PATH:/home/user/programs/
		export PATH

e. Save the file:
In nano this is control+O (WriteOut)

f. Reload bash by logging out or with this command:

		$ source ~/.bash_profile

This will add all binary files in `/home/user/programs/`including the one we want, `thesis`. To see what is in your path, type this into bash:

	$ echo $PATH

To add more folders to your path, just append it to the line with a colon in the beginning:

	PATH=$PATH:/home/user/programs/:/home/user/who-needs-organization/bin/
	export PATH

#####Case study: msstats:
Msstats is a program that uses libsequence. It's useful to see how this is installed because it requires libraries to be loaded during installation. 

1. Download msstats source code:

		$ wget http://molpopgen.org/software/msstats/msstats-0.3.1.tar.gz

2. Untar:

		$ tar -xvzf msstats-0.3.1.tar.gz

3. cd to new directory:

		$ cd msstats-0.3.1

4. Read the README:

		$ less README

5. Load the required modules:

		$ module load gcc
		$ module load libsequence

6. Provide configure with information about libsequence and run configure (notice the prefix option; that is all one line):

		$ CPPFLAGS=-I$LIBSEQUENCE/include LDFLAGS=-L$LIBSEQUENCE/lib ./configure --prefix=/home/[user]/programs/

7. Make:

		$ make

8. Make install:
		
		$ make install 

#####Java programs:
Using Java programs is easy because Java is inherently cross-platform. Java works by creating a layer between the computer and the program called the Java Virtual Machine (JVM). The JVM is platform specific, but any java executable file (.jar) can be run. This way, software people only have to send out 1 file which can be used on (almost) any platform. This also means that you don't have to compile the Java program (the software provider already did it for you), you just need to run it. A short example involving `BEAGLE` follows:

a. cd to the parent directory:

		$ cd programs

b. Download `BEAGLE` with `wget`:

		$ wget http://faculty.washington.edu/browning/beagle/beagle.jar

c. Run `BEAGLE` according to the instructions provided here: <http://faculty.washington.edu/browning/beagle/beagle_3.3.2_31Oct11.pdf> For example:

		$ java -Xmx800m -jar beagle.jar data=data.bgl trait=T2D out=example

As you can see, Java programs don't really need to be "installed", they just need to exist. If you do need to compile the program, you will need to follow the instructions provided. If the source code contains a file called `build.xml` it probably uses ant (which is similar to make). If this is the case, you can create a .jar file simply by typing:

	$ ant compile jar

Note: I haven't tested these myself. More information about ant is available here: <http://ant.apache.org/manual/tutorial-HelloWorldWithAnt.html>


#####Programs from Github:
Programs, pipelines, and scripts from Github work much the same way as software from other sources. One key difference is in acquiring it. There are two main ways to get software from Github: cloning and downloading a zip. The advantage of cloning is that if the software updates, you just need to pull the changes and reinstall and you are updated. With the zip file, you need to remove the folder and redownload it when there in an update. However, sometimes software isn't updated frequently so you don't need to worry about updates. 

#####Cloning:

a. Go to the parent directory of where you want the software installed

		$ cd programs

b. Visit the Github repository and on the very right there will be a text box that says `HTTPS clone URL` and it will contain a link that looks like this: `https://github.com/[user]/[repository].git`. Copy that link to the clipboard

c. Back in farm, `clone` the repository:

		$ git clone https://github.com/[user]/[repository].git

d. Change to the directory you just created (the name of the repository) and follow the installation instructions that are (hopefully) provided.

#####Downloading a zip:
a. Go to the parent directory of where you want the software installed

		$ cd programs

b. Visit the Github repository and on the very right there is a button that says `Download zip`. Right click this link and click `copy link`. 

c. Back in farm, download the zip with wget:

		$ wget https://github.com/[user]/[repository]/archive/[branch].zip

d. Unzip this folder with unzip:

		$ unzip [repository]

e. Change to the directory you just created (the name of the repository) and follow the installation instructions that are (hopefully) provided.


####Special Farm Things:
Farm has a number of things that make it unique, not dissimilar from a snowflake. These are things you won't see on many Linux distributions and if you try to do it on them, you might get an angry message telling you to do something you're good at (don't listen to it you're beautiful). 

#####Max number of command line arguments:

The maximum number of arguments in any command is 131072. If you are getting errors from bash saying you have too many arguments, try and specify the maximum number of arguments as 131072. For example, in removing a bunch of files:

	$ find -name "[name_of_file].*" | xargs -n131072 rm

This command will remove all files that match the pattern `[name_of_file].*`. `*` is a wildcard character. The `-name` is different from `[name_of_file]` and should not be substituted!
 
#####Modules:

This package allows system administrators to update the system libraries and other core programs without breaking your code or scripts. Modules contain the information that the shell needs to locate programs and libraries without getting confused about different versions and different files. For you, this means that before using something like gcc, you need to load it:

	$ module load gcc
	Module GCC 4.5.0 Loaded.

To see what modules are available, type:

	$ module avail

Any one of these modules can be loaded and should be. The special farm thing here is that if you run python, for example, without loading the module, you'll run version 2.4.3. However, if you load the python module, you will get 2.7.3. This becomes an issue when you run python from a script but forget to load the module because you'll be running an old version of python. So remember, if you're using a preinstalled program, make sure you load the module. 

#####Built-in variables:

When you submit a job on farm, the Sun Grid Engine gives you two variables that change according to some parameters. One is the variable `$SGE_TASK_ID`. When running an array of jobs, this variable corresponds to a particular task. Each job in the array has a different value for `$SGE_TASK_ID`. 

Next, there is `$JOB_ID`. This variable changes every time you submit a job. Therefore, when you submit an array of jobs, each job will have the same `$JOB_ID`, but each one will have a different `$SGE_TASK_ID`. These variables can be used in conjunction to name output files. For example, you can submit a job like this:

	sfs_code 1 1 > out.$JOB_ID.$SGE_TASK_ID

This will save the output in a file named something like this: `out.83917.1`

####Submitting Jobs to farm:
Speaking of submitting jobs, you are probably going to want to do that. The farm cluster uses the Sun Grid Engine (SGE) to distribute jobs across its 39(?) nodes. When you run simulations, you want them to run on these nodes rather than the one you're logged in to (which is called the head). To submit a job simply type:

	$ qsub myjob.sh

The qsub command has a number of options, many of which are necessary: [expand on this from the current wiki] 

`-S`:
This option tells qsub what shell you're using. You will probably want to use bash:
`-S /bin/bash`

`-cwd`:
This tells qsub to run the command from your current working directory. 

`-e`:
This tells qsub where to put the error log files. If you don't want to save them, put them in `/dev/null`:
`-e /dev/null`

`-o`:
This tells qsub where to put the output log files. If you don't want to save them, or if you are creating your own output files, put them in `/dev/null`:
`-o /dev/null`

`-t`:
This tells qsub that you are submitting an array of jobs. It will run the script you send it multiple times. To specify how many times, use a range. The max number of jobs in an array is 50,000:
`-t 1-10`

`-help`:

Prints a listing of all options.

`-j y|n`:

Specifies whether or not the standard error stream of the job is merged into the standard output stream. If both the `-j y` and the `-e` options are present, Grid Engine sets, but ignores the `error-pat`h attribute.

`-m b|e|a|s|n,…`:

Defines or redefines under which circumstances mail is to be sent to the job owner or to the users defined with the `-M` option described below. The option arguments have the following meaning: 'b' Mail is sent at the beginning of the job. 'e' Mail is sent at the end of the job. 'a' Mail is sent when the job is aborted or rescheduled. 's' Mail is sent when the job is suspended. 'n' No mail is sent. Currently no mail is sent when a job is suspended.

`-M user[@host],…`

Defines or redefines the list of users to which the server that executes the job has to send mail, if the server sends mail about the job. Default is the job owner at the originating host. You can use this to add your email address for updates or information about your jobs. For example, `qsub -M johndoe@example.com stupid.sh` will send email about the job status of the stupid.sh script to johndoe@example.com.

`-N name`

The name of the job. The name can be any printable set of characters, starting with an alphabetic character. If the `-N` option is not present Grid Engine assigns the name of the job script to the job after any directory pathname has been removed from the script-name.

#####Output to many files vs one:
When using qsub, you are going to want to save the output of each simulation in a different file. This is because when multiple processors write to the same file, bad and funky things happen. James Brown may be pleased, but you will not be. To achieve this, use the built-in variables (`$SGE_TASK_ID`, `$JOB_ID`) to number your output files.

#####Checking up on jobs:
SGE comes with a command called `qstat` which will tell you the progress of your job:

	$ qstat

You can use the following to check on status of everyone's jobs
$ qstat -u \*

You can also check the status of a particular job:

	$ qstat -j [job-id]

The maxvmem information gives you an idea of the maximum amount of RAM your job has used. This is important for memory considerations (see below).

You can delete a job:

	$ qdel [job-id]

Log into a compute node:

	$ qrsh

#####Ganglia

One of the best ways to check on jobs is to use the ganglia website. It can be opened on a browser at

	$ http://localhost:50070/ganglia/

But only works if you've logged into farm with a special ssh command. It is suggested to write an alias to log into farm always using:

	$ ssh -Y -L 50070:farm:80 user@farm.caes.ucdavis.edu

Where "user" is replaced with your username.

Ganglia lets you check down nodes (email help to get them restarted), network I/O, memory, etc. for individual nodes as well as the head node.

#####Things to watch for:

######NFS Usage

The network filesystem (NFS) is what the system uses to communicate between the head node and compute nodes. Overloading the NFS can cause work to slow down dramatically or even cause nodes to crash. Remember that all your files are stored on the head node, so any jobs that do heavy reading/writing require that the CPU on the compute node is writing over the network (using NFS) to the headnode. Avoid heavy read/write as much as possible, for example, by writing to files on the compute node and moving them to the head node when you're done. NFS usage may spike to >150Mb when transferring big files or starting a run, but if it stays constant at >10Mb your job probably needs to be re-thought, as this will likely cause problems for other users.

######Memory

Each compute node has 24G RAM. If you are using more than 1.5G RAM per job you need to use something like `-pe threaded` to request more CPU so you do not end up using other people's resources. Check the overall memory usage of your runs; using too much memory can cause individual nodes to go down.

######Space on nodes

Each compute node has a 200G hard drive. This is available in /scratch . 
It is advisable to create your own directory there, e.g. /scratch/jri . 
You can use tentakel to do this on all nodes at once. 
It is a good idea for jobs writing to the compute node that you create a new directory for each job, using the `$JOB_ID` variable. 
This prevents overwriting files. 
Make sure to delete all these files when the job is done, so the hard disk on the compute node does not fill up.

To avoid causing problems with the NFS, in general:

* Make bigger tasks (so submit 500-1000 instead of 25-75000 * Throttle your qsubs, if in a loop add a sleep so submitting 25-75k takes say 10 minutes instead of 10 seconds.

To check on a big job:

* Run top. Watch for any of the following:

	- Does the load average spike?

	- Does the %wa (3rd line) spike?

	- Does any process balloon in memory usage? (sort by memory use with M)

	- Does any process saturate at 100% cpu usage? Which?

	- Does swap usage increase?



======

###Unix computer tips:
This section contains tips and information applicable to any Unix-based computer you use. (Hereafter referred to as Unix).

####Bash:
In order to effectively use the farm computer, you need to know how to move around in bash. Use this course to learn how: <http://cli.learncodethehardway.org/book/>

[add specific things that people in the lab need/use]

####R:

####Python: 
Learn from here: <http://learnpythonthehardway.org/book/>

[add specific things that people in the lab need/use]

####Git:
Git is useful because it allows you to share your programs/scripts with minimal effort and it backs up your programs in case you do something dumb and `rm -rf ./` your source code (please don't run that code because it deletes things you don't want deleted). 

Git is already installed on farm. To create a new repository, make a new folder:

	$ mkdir i-am-awesome

cd to that directory and type in:

	$ git init

Now you have a new git repository. Now you need to connect it to your Github account:

	$ git remote add origin https://github.com/[username]/[repository-name].git

Now you can add files to the repository with the git add command:

	$ git add [file1] [file2]

You can add multiple files at once separated with a space or if you're lazy you can wildcard:

	$ git add *

Now to send your files to Github, you need to commit them:

	$ git commit -m "[info]"

And finally, push them to the server:

	$ git push

If a repository exists, you can add it to your computer by cloning it (this is explained in depth in the software installation section):

	$ git clone [url]

If you are working on multiple computers or with other people make sure you pull the changes before you start working or else you risk losing your changes or needing to merge, which can get ugly:

	$ git pull

For a more well written guide, go here: <http://rogerdudler.github.io/git-guide/>


####Special Unix things:

#####What language should I use?
The world of computer languages is confusing because of the seemingly arbitrary distinctions and made up words that make every language seem like the new hot stuff. I'm going to try and clear up some of the confusion.

Two of the major camps of languages are scripting languages and compiled languages (scripting languages are also called interpreted languages). Scripting languages have something called an interpreter which runs while your script is running and translates your instructions on the fly to the computer. Examples of scripting languages include perl, Python, R, Ruby, and Javascript. Compiled languages on the other hand, have something called a compiler which translates your program into machine code (or binary: 00101010010). The compiler is no longer needed at this point and your computer can just run your compiled code (the binary file). Examples of compiled languages are: C, C++, Java, Fortran, COBOL.

There are a few notable results of the difference between compiled and scripting languages:

1. Scripts are usually slower than their compiled counterparts: this is because the interpreter must run while the script is running so it takes up more memory (and probably other reasons).

2. Scripts are easier to write than compiled programs: when you compile a program, you need to tell the computer __everything__, including where to start. This is why C, C++, and Java programs have a "main" method or class. Generally speaking, you need to be more careful and know a lot about the language you're programming in when writing in a compiled language. Scripts on the other hand can figure most things out on their own and run top to bottom (unless told otherwise). 

3. Scripts are cross platform: or more accurately, they are more cross platform than compiled programs. This is because when programs are compiled, they are compiled according to the processor instructions, which change from computer to computer. This is why you can't install iOS on your desktop computer (also because Apple would sue you so hard). 

#####So what do I pick?
Scripts for short things like manipulating files and summarizing data, programs for larger projects that do complex transformations or simulations (if you're really in doubt, pick scripts.)

#####Object orientation?
I refer you to this: <http://learnpythonthehardway.org/book/ex42.html>
Any other questions can be answered with Google and mediation.



#####Screen:
Screen is especially useful for farm because it lets you run things that take a while without qsubbing (Be careful not to run things that take hours and lots of memory though). Screen lets you open another session on the farm which you can detach from. This lets whatever program or script you have running keep running even after you log out. To open a new screen, type:

	$ screen

Now you'll have a new bash session. To detach from that screen, press they keys Control-a, d. To see what screens you have detached, use the -ls option:

	$ screen -ls

This will output a list of existing screens along with a number corresponding to each screen. In order to switch to a particular screen, use the -r option along with that screen's number:

	$ screen -r [number]

To find out more, use the manual page:

	$ man screen

#####/dev/null:
This is a directory in Linux that is akin to a wasteland. If you have output files you don't need you can send them here and it's like deleting them. This is especially useful with the SGE because it has default output and error files. If you don't need to look at these, you can add this to the top of your script and it won't write them to disk:

	#$ -e /dev/null
	#$ -o /dev/null

