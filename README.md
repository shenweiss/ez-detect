This work is protected by US patent applications US20150099962A1,
 UC-2016-158-2-PCT, US provisional #62429461

 Written by Shennan Aibel Weiss MD, PhD. in Matlab at Thomas Jefferson University
 Philadelphia, PA USA. 2017

Project directory: 
  -documents: Project documentation
  -hfo_engine_1: output saving directories.
  -src: project code.
  -testing: testing tools, historical issue prompts.
  -tools: useful packages used in src code. Third parties.

Requirements 

  1) Python 3.5 if there is no stand-alone executable file.
  2) Matlab 2017a or later. 
  3) Cudaica binary for the current running device.


Installation and configuration instructions:
 
  1) If you don't have python installed, you can find 3.5 version for your O.S in https://www.python.org/
  2) Get sure you have matlab 2017a installed and working.
  3) Get cudaica binary for the running device: please find instructions in the README of cudaica 
  in folder ez-detect/src/cudaica/README_cudaica.md
  Note: Once you reach the step of configuring cudaica mentioned in the file, consider to use the flag –-with-cuda-arch=CC where CC is your gpu compute capability.
  4) Go to src/main/config.py and manually edit the paths to matlab binary and to the project 
  root directory (example '/home/username/ez-detect') in getPaths() local function. 
  *The other paths are relative to this last one. So as long as they exist, they will work.
  **You can also set defaults for input arguments as you desire here.

Usage:

Warning, during execution, the program will clean previous outputs in hfo_engine_1 directory. So if you
want to save outputs of previous executions, do it before the next run. I THINK THIS SHOULD BE MODIFIED TO CREATE A NEW SAVING ROOT DIR, example hfo_engine_2.

Main function is src/main/hfo_annotate_py. For usage please type: 

 LINUX: 'python3 hfo_annotate.py --help'
 WINDOWS: 'python hfo_annotate.py --help'

Minimum arguments for a run would be for example: python3 hfo_annotate.py --edf_dataset_path=test.edf

In other words, the only requiered argument is --edf_dataset_path, the other ones are optional and
defaults within config.py are given in case you don't specify them.
 
Output: 

DSP monopolar/bipolar outputs as matfiles get saved in the corresponding working directory
indicated in the argument 'paths'. XML file is saved in the directory passed by argument or in default
set in src/main/config.py


Developers:

Conventions for the code:

  Formats:
      Filename && Function name: Dash separated names. Example: ez_detect_batch
      Local Function name: CamelCase. Example: processBatch
      Local Variables: Descriptive names. Dash separated names. Example: start_time
      Global Variables: Dash separated UPPERCASE. Example: PROJECT_PATH


OLD README BELOW


1. Prerequisites for Deployment 

Verify that version 9.3 (R2017b) of the MATLAB Runtime is installed.   

If the MATLAB Runtime is not installed, you can run the MATLAB Runtime installer.
To find its location, enter
  
    >>mcrinstaller
      
at the MATLAB prompt.

Alternatively, download and install the Linux version of the MATLAB Runtime for R2017b 
from the following link on the MathWorks website:

    http://www.mathworks.com/products/compiler/mcr/index.html
   
For more information about the MATLAB Runtime and the MATLAB Runtime installer, see 
Package and Distribute in the MATLAB Compiler documentation  
in the MathWorks Documentation Center.    


2. Files to Deploy and Package

Files to Package for Standalone 
================================
-ezdetect_putou70_e1_batch 
-run_ezdetect_putou70_e1_batch.sh (shell script for temporarily setting environment 
                                   variables and executing the application)
   -to run the shell script, type
   
       ./run_ezdetect_putou70_e1_batch.sh <mcr_directory> <argument_list>
       
    at Linux or Mac command prompt. <mcr_directory> is the directory 
    where version 9.3 of the MATLAB Runtime is installed or the directory where 
    MATLAB is installed on the machine. <argument_list> is all the 
    arguments you want to pass to your application. For example, 

    If you have version 9.3 of the MATLAB Runtime installed in 
    /mathworks/home/application/v93, run the shell script as:
    
       ./run_ezdetect_putou70_e1_batch.sh /mathworks/home/application/v93
       
    If you have MATLAB installed in /mathworks/devel/application/matlab, 
    run the shell script as:
    
       ./run_ezdetect_putou70_e1_batch.sh /mathworks/devel/application/matlab
-MCRInstaller.zip
    Note: if end users are unable to download the MATLAB Runtime using the
    instructions in the previous section, include it when building your 
    component by clicking the "Runtime downloaded from web" link in the
    Deployment Tool.
-This readme file 

3. Definitions

For information on deployment terminology, go to
http://www.mathworks.com/help and select MATLAB Compiler >
Getting Started > About Application Deployment >
Deployment Product Terms in the MathWorks Documentation
Center.

4. Appendix 

A. Linux systems:
In the following directions, replace MR by the directory where MATLAB or the MATLAB 
   Runtime is installed on the target machine.

(1) Set the environment variable XAPPLRESDIR to this value:

MR/v93/X11/app-defaults


(2) If the environment variable LD_LIBRARY_PATH is undefined, set it to the following:

MR/v93/runtime/glnxa64:MR/v93/bin/glnxa64:MR/v93/sys/os/glnxa64:MR/v93/sys/opengl/lib/glnxa64

If it is defined, set it to the following:

${LD_LIBRARY_PATH}:MR/v93/runtime/glnxa64:MR/v93/bin/glnxa64:MR/v93/sys/os/glnxa64:MR/v93/sys/opengl/lib/glnxa64

    For more detailed information about setting the MATLAB Runtime paths, see Package and 
   Distribute in the MATLAB Compiler documentation in the MathWorks Documentation Center.


     
        NOTE: To make these changes persistent after logout on Linux 
              or Mac machines, modify the .cshrc file to include this  
              setenv command.
        NOTE: The environment variable syntax utilizes forward 
              slashes (/), delimited by colons (:).  
        NOTE: When deploying standalone applications, you can
              run the shell script file run_ezdetect_putou70_e1_batch.sh 
              instead of setting environment variables. See 
              section 2 "Files to Deploy and Package".    






