This work is protected by US patent applications US20150099962A1,
 UC-2016-158-2-PCT, US provisional #62429461

 Written by Shennan Aibel Weiss MD, PhD. in Matlab at Thomas Jefferson University
 Philadelphia, PA USA. 2017


Usage as follows:

 For first use please see and set the paths in getPaths() local function in this file.
 then run in shell: 

 matlab_binary -r  "main(edf_dataset_path, start_time, stop_time, ...
                         cycle_time, chan_swap, swap_array_file)"

(You can call it with all optional args except from the requiered edf_dataset_path so 
 If you don't specify, defaults are given) 
 
 Input semantic:
    - edf_dataset_path: The directory path to the file with the data to analize.

    - start_time: a number in seconds indicating from when, relative to the file
      duration, do you want to analize the eeg.
    
    - stop_time: a number in seconds indicating up to when, relative to the file
      duration, do you want to analize the eeg.
      
      For example if you want to process the last 5 minutes of an eeg of 20 minutes
      you would use as input start_time = 15*60 = 900 and stop_time = 20*60 = 1200.
    
    - cycle_time: a number in seconds indicating the size of the blocks to cut the data
      in blocks.This improves time performance since it can be parallelized. 
      Example: 300 (5 minutes)
    
    -Swapping data: a struct containing the channel swapping flag (1:yes, 0:no) (in case that 
     channels were incorrectly assigned in the original EDF file as can be the case for intraop 
     recordings) and the swap_array that can be used to correct the channel assignments.
 
 Output: DSP monopolar/bipolar outputs as matfiles get saved in the corresponding working directory
 indicated in the argument 'paths'.

Presetting:

 1)If it it's the first run in this computer please check misc_code/setGlobalPaths.m

Conventions for the code:

  Formats:
      Filename && Function name: Dash separated names. Example: ez_detect_batch
      Local Function name: If you define local functions within a files, use CamelCase. Example: processBatch
      Local Variables: Descriptive names. Dash separated names. Example: start_time
      Global Variables: Dash separated UPPERCASE. Example: PROJECT_PATH

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






