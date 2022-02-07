*Installation Instructions for HFO-Engine and EZ-Detect version 1.0.1 (2014-2022)

Software Authors: Shennan Weiss M.D. Ph.D., Tomas Pastore M.S., Zachary Waldman M.S., Inkyung Song Ph.D., Matthias Gatti M.S., Federico Raimondo Ph.D., Diego Slezak Ph.D. 

Document and Corresponding Author: Shennan Weiss M.D. Ph.D. shennanweiss@gmail.com
Assistant Professor Neurology and Physiology/Pharmacology
State University of New York Downstate
Brooklyn, NY

Listserv for users: send email to hfoengine-request@freelists.org with 'subscribe' in the Subject field (no quotes) 

Date: 2/2022	

Purpose of software: To reduce/differentiate artifact and then detect, categorize, and quantify HFOs and epileptiform spikes in intracranial EEG recordings, and annotate these detections in the commercial EEG viewer Brain Quick™ produced by Micromed™ and save the detailed HFO and spike data as a Matlab Mathworks file. 

Support: This work was fully supported by NIH/NINDS K23 NS094633 (SAW), and a Junior Investigator Award from the American Epilepsy Society (SAW).

Licensing: Copyright (c) 2022 Shennan Weiss, Tomas Pastore, Zachary Waldman, Inkyung Song, Matthias Gatti, Federico Raimondo, and Diego Slezak. 

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Notes: Some code may refer to an entity named Fastwave LLC. Fastwave LLC has been dissolved and maintains no ownership over any copyrights or intellectual property. 

Dedication: I would like to thank my daughter Sabine Weiss who missed me while I was working on this software. I would also like to thank the other authors who worked with me in sickness and in health. Special thanks goes to Zac Waldman for his work on EZ-top, Federico Raimondo for his work on CUDAICA and TRC import and export, and Diego Slezak for overseeing the design and execution of HFO-Engine.  

Recommended Literature (please read and cite the papers appended below if you utilize this software in your research):
-----------

1) HFO Detector and independent component analysis:\

CUDAICA: GPU optimization of Infomax-ICA EEG analysis.  Raimondo F, Kamienkowski JE, Sigman M, Fernandez Slezak D. Comput Intell Neurosci. 2012;2012:206972. doi: 10.1155/2012/206972. 

Utilization of independent component analysis for accurate pathological ripple detection in intracranial EEG recordings recorded extra- and intra-operatively. Shimamoto S, Waldman ZJ, Orosz I, Song I, Bragin A, Fried I, Engel J Jr, Staba R, Sharan A, Wu C, Sperling MR, Weiss SA. Clin Neurophysiol. 2018 Jan;129(1):296-307. doi: 10.1016/j.clinph.2017.08.036. 

Visually validated semi-automatic high-frequency oscillation detection aides the delineation of epileptogenic regions during intra-operative electrocorticography.  Weiss SA, Berry B, Chervoneva I, Waldman Z, Guba J, Bower M, Kucewicz M, Brinkmann B, Kremen V, Khadjevand F, Varatharajah Y, Guragain H, Sharan A, Wu C, Staba R, Engel J Jr, Sperling M, Worrell G. Clin Neurophysiol. 2018 Oct;129(10):2089-2098. doi: 10.1016/j.clinph.2018.06.030. 

2) Topographical Method of HFO categorization and quantification:

A method for the topographical identification and quantification of high frequency oscillations in intracranial electroencephalography recordings.  Waldman ZJ, Shimamoto S, Song I, Orosz I, Bragin A, Fried I, Engel J Jr, Staba R, Sperling MR, Weiss SA. Clin Neurophysiol. 2018 Jan;129(1):308-318. doi: 10.1016/j.clinph.2017.10.004. 

3) HFO Phase-amplitude coupling (phasor method):

Ripples on spikes show increased phase-amplitude coupling in mesial temporal lobe epilepsy seizure-onset zones.  Weiss SA, Orosz I, Salamon N, Moy S, Wei L, Van't Klooster MA, Knight RT, Harper RM, Bragin A, Fried I, Engel J Jr, Staba RJ. Epilepsia. 2016 Nov;57(11):1916-1930. doi: 10.1111/epi.13572. 

Bimodal coupling of ripples and slower oscillations during sleep in patients with focal epilepsy. 
Song I, Orosz I, Chervoneva I, Waldman ZJ, Fried I, Wu C, Sharan A, Salamon N, Gorniak R, Dewar S, Bragin A, Engel J Jr, Sperling MR, Staba R, Weiss SA. Epilepsia. 2017 Nov;58(11):1972-1984. doi: 10.1111/epi.13912. Epub 2017 Sep 26.

Ripples Have Distinct Spectral Properties and Phase-Amplitude Coupling With Slow Waves, but Indistinct Unit Firing, in Human Epileptogenic Hippocampus. Weiss SA, Song I, Leng M, Pastore T, Slezak D, Waldman Z, Orosz I, Gorniak R, Donmez M, Sharan A, Wu C, Fried I, Sperling MR, Bragin A, Engel J Jr, Nir Y, Staba R. Front Neurol. 2020 Mar 24;11:174. doi: 10.3389/fneur.2020.00174. eCollection 2020. PMID: 32292384 

---------

System Requirements: A Windows 7 or above system running Brain Quick version 1. This plug-in has not yet been tested with the yet to be released Brain Quick version 2. A second system running Linux (tested on Ubuntu 20), with an NVIDIA GPU, that performs the data processing. On the Linux system, at least 64 GB of RAM is required, although over 100 GB of RAM is recommended. A swapdisk for vistual memory of at least 10GB is recommended. Linux software requirements include Matlab 2017a or later, Python 3.5.2 and Anaconda 3 4.2 or above. Other dependencies are stated below in the instructions or will be installed automatically. Note that it may be possible to use the MCR instead of purchasing Matlab, but MCR has a different architecture for running Matlab within Python and the HFO-Engine/EZ-detect code will need to be modififed. 

** A note about Anaconda ***
Anaconda is needed mainly for virtual environments. Errors were encountered in building the software using the latest version of Conda 4.11 which uses Python 3.9. The software was successfully built using Conda 4.10.3 and Python 3.8.

** A note about Anaconda virtual environments **
A new virtual environment should be initiated for this project and it does not need to import all of Anaconda.(ex. conda create --prefix /home/sweiss/hfoenv python=3.7.12)

Test system: Hardware: Total Intel Xeon Cores/ 2.1GHz Base Frequency 40 Total Cores with Hyperthreading Enabled 1x 6230 CPU, 128GB of High Performance DDR, 2933 MHz ECC Memory, 4x32GB Memory Modules,6 Gbps, 1 x RTX 4000 GPU / 2034 CUDA Cores / 8 GB Memory. Host operating system: Ubuntu 20.04.3 LTS. Guest VM operating system: Windows 10.  Software on host Python 3.8.11, Conda version 4.10.3. Co

Description of software: HFO-Engine consists of the HFO-Engine plug-in client for Micromed Brainquick that operates on Windows 7 or above, and a HFO-Engine webserver that interfaces with the HFO-Engine plug-in client and operates in Linux. The HFO-Engine client in Windows can be executed within Brainquick or as a stand alone. The HFO Engine webserver on the Linux system, that receives commands from HFO-engine client, interfaces with EZ-detect (the HFO detector) which also operates in Linux.  Installation of this package requires a moderate-advanced proficiency in Linux and familiarity with Python and also Matlab.

For further information please see the HFO-Engine User’s manual.

Windows installation instructions:
- In https://github.com/shenweiss/ From the HFO_engine repository on the master branch in the bundles folder download HFO_engine_V_0.0.2.rar
- unrar the files in the BQ_plugin_driver_dlls folder to the Micromed/BrainQuick/Plugins directory
- create a folder hfo_engine in the Plugins directory
- unrar the files in the hfo_engine folder to the ~/Plugins/hfo_engine directory
- copy the CommandLine.dll file in the ~/Plugins/hfo_engine directory to the ~/Plugins directory

* Troubleshooting:
1) make sure all the files in the plugins directory and subdirectory are unblocked in Windows by clicking on file properties. If the files are marked as blocked it will result in a .NET framework error within Brain Quick.
2) make sure your user has access to the windows98 directory on your local drive and all subdirectories including temp.

Linux installation instructions
* make sure all users have privileges to the directories created by the git repositories *

a) install git repositories
- Create a project directory ~/ for the project and in this directory run the following commands
- git clone http://github.com/shenweiss/io_trc.git
- git clone http://github.com/shenweiss/hfo_engine.git
- git clone http://github.com/shenweiss/io_evt.git
- git clone http://github.com/shenweiss/ez-detect.git
- in the ez-detect folder change the branch from origin to develop with the command
1. git checkout develop

b) installing cudaica 
- in your project directory ~/ run git clone https://github.com/fraimondo/cudaica.git
- download and install CUDA from NVIDIA latest version is OK
- download and install the CUDA Toolkit from NVIDIA developer latest version is OK
- install the GNU Compiler Collection (GCC)
- install autotools, autoconf, and M4
- install gfortran
- install BLAS library
- In the cudaica directory run ./reconf.sh
- run: $./configure --with-cuda-arch= this is the compute capability look it up at https://developer.nvidia.com/cuda-gpus for your GPU (i.e. 7.5=75)
- run: $make

c) installing ez-detect
- in the ez-detect directory run: $pip3 install -r requirements.txt
- note any errors in the pip dependency resolver
- in the ez-detect directory run python3 setup.py develop
- copy the compiled cudaica binary executable to the ~/ez-detect/ez_detect/matlabcode/cudaica/ folder overwriting the existing cudaica file there 
- In your matlab directory go to matlab_path/extern/engines/python/ and run: $python3 setup.py install

d) installing io_trc code
- go to io_trc directory
- run: $python3 setup.py develop

e) installing io_evt code
- go to io_evt directory
- run: $python3 setup.py develop

f) installing the hfo_engine webserver
- go to the ~/hfo_engine directory
-pip3 install -r Requirements.txt
- go to the ~/hfo_engine/web_server directory
- run $python3 setup.py develop
- to find the directory of your virtual environment run conda env list 
- edit line 5 of the start_server.sh file to reflect your virtual environment (remember to add bin/activate) [Note in early versions of Conda line 5 is not neccessary]
example
	# conda environments:
	# base                  *  /home/sweiss/anaconda3

	line 5: source /home/sweiss/anaconda3/bin/activate
- try starting the server $./start_server.sh --production --init
- then ctrl-c and run $./start_server.sh --production
- Be careful in the start_server script how the IP address is assigned, also a specific port can be assigned in the waitress command. Port 8080 is the default.

Troubleshooting (ignore if you encountered no errors)
- You may also need to install llvmlite $ conda install --channel=numba llvmlite
- You may also need to downgrade markdown $ pip3 install Markdown==3.3.4

g) You need to manually enter your project paths
-  in ~/hfo_engine/src/ez-detect/ez_detect/config.py line paths['project_root'] = str( Path('/home/sweiss/ez-detect'))
-  hfo_annotate.py lines (107, 181, 190, 211, 217, 227)
-  in ~/ez-detect/ez_detect/matlab_code/cudaica/ez_cudaica.m lines 90-92
-  in ~/ez-detect/ez_detect/matlab_code/dsp/ez_detect_dsp_monopolar lines 432, 447, 451

h) Selecting 60 cycle (default) vs. 50 cycle line noise reduction
- ~/hfo_engine/src/ez-detect/ez_detect/preprocessing.py lines 20 and 21 change 60 range to 50 range
- ~/ez-detect/ez_detect/matlab_code/dsp/dsp_toolbox/EZDetectDspToolbox.m line 65 change 60 to 50

i) connecting the Windows HFO Engine client to the HFO Engine webserver
- Open the HFO Engine Client in Windows
- Click on Advanced Settings
- Enter the hostname (ip address) and port (8080) of the webserver then click on Save then click on Test Server Connection.

* troubleshooting:
1) In case you did not create a new virtual environment specifically for this project, this project has many dependencies and some of the dependencies may need to be upgraded or downgraded depending on the current version to execute the project. Please look carefully at error messages when installing each package or installing the dependencies. Instructions for upgrading and downgrading each dependency can be found online using Google searches.
2) If a connection cannot be established between the HFO_engine.exe client on Windows and the web_server on Linux it may be due to a firewall on either system. Be sure the port (8080) is open to incoming and outgoing traffic on both systems. To check that the webserver is operational on the host try

$ python3
Python 3.5.2 (default, Apr 16 2020, 17:47:17)
[GCC 5.4.0 20160609] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> import requests
>>> response = requests.get('http://')
>>> response
<Response [200]>
>>> response.text
'{"message":"Welcome to FastWaveLLC HFO engine"}\n'

To check that you can connect to the server from the client’s computer open a web browser and go to 
http://server's ip address:8080/ 
you should see the Fastwave welcome message

Note: This package was intended for the server to run in the cloud. Other configuration options are possible including setting up a Windows guest VM on a Linux host. In this case, a bridged network configuration is recommended for the Windows VM. It may also be possible to install HFO-Engine/EZ-Detect on Windows

v1.0.0 can be downloaded from http://gitlab.liaa.dc.uba.ar/tju-uba (currently down)

v1.0.1 Modifications include:
------------------------
- in HFO-Engine requirements updated Werkzeug to 0.15.5
- in EZ-Detect requirements updated mne to 0.23.4
- in engine.py added line 53 to accept lower case EDF
- in io.py in trcio hacked rec_time error in lines 544-550 due to datetime incompatibility and deidentify the data
- in converter.py added lines 139-134 to differentiate EDF files stored in uV vs. Volts 
- added debug comments in analyzer.py and indent after try to allow user to see error messages from the Flask server
- in analyzer.py simplified call to hfo_annotate 
- io_trc/io.py modified line 956 with open(self._filenames[0]) as fid: likely due to MNE version upgrade
- in hfo_annotate altered start_time code to account for time zone conversion. It should work worldwide and adjust to daylight savings time
- in hfo_annotate hardcoded cycletime to 600 seconds.
- in removeEvents_1_5_cycles.m converted RonS and fRonS that did not meet duration criteria to FronS. 
- in ez_detect_dsp_bipolar.m added lines 24-28 for bipolar only detection mode
- in hfo_annotate.py made a number of changes to eliminate threading due to Matlab bug related to saving data on each thread, the original version can be downloaded in v1.0.0
- in hfo_annotate.py and ez_bad_channel_temp.m and preprocessing.py made several changes relating to building correct montages in Matlab related to translation of a Python object structure.
- in eztop_putou_e1.m added metadata to the saved data to correct for error in writing annotations of multiple blocks
- in evtio/io.py added code to allow for correct annotations of multiple blocks of data
- in evtop/io.py added code to permit annotations of channels recorded in bipolar montage except for channels moved to bipolar montage 

Benchmarks
-------------------
- A 10 minute block of data will require between 25-120 minutes, if analyzed in referential mode. The actual time depends on the number of channels and the number of HFOs detected.
- A 10 minute block of data will require between 15-90 minutes, if analyzed in bipolar mode. The actual time depends on the number of channels and the number of HFOs detected.

v1.0.1 Beta Testing
----------------------
- Nihon Kohden amplifier EDF data
- Natus Quantum amplifier EDF data
- Micromed Native TRC data
- New installation from shenweiss github repositories onto Google Cloud instances, tested installation three times. Note for Cloud deployment most services have http tranfer limit of 35 MB, thus to deploy the software to the cloud using a commercial platform you will need to make modifications at the client and server side to overcome the limitation in file size. 

Concluding Remarks
----------------------
I hope you enjoy this software and it benefits your research. Please read the user's manual for further details. If you encounter problems during these laborious steps of installation, or if I failed to denote a step, please do not e-mail me directly but use the listserv for users instead so others can benefit. [send email to hfoengine-request@freelists.org with 'subscribe' in the Subject field (no quotes) to join]



