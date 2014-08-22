I. System Setup
These instructions assume that everything will be installed on a single system.

1. Install Python
Install Python 2.5.2 (ThirdParty/Python/python-2.5.2.msi)
copy easygui83/easygui.py to C:\Python25\Lib\site-packages
copy the parallel directory to C:\Python25\Lib\site-packages
Install python packages listed below:
VisionEgg (visionegg-1.1.dev1389.win32-py2.5.exe)
pygame (pygame-1.8.0.win32-py2.5.msi)
Numeric (Numeric-24.2.win32-py2.5.exe)
OpenGL (PyOpenGL-2.0.2.01.py2.5-numpy24.exe)
PIL (PIL-1.1.6.win32-py2.5.exe)

Other packages that were included with the initial drop from Columbia are in ThirdParty/Python/extra.
These packages don't seem to be required.
Outdated packages are in ThirdParty/Python/old. Currently, this is just the old parallel port stuff.

2. Install ProducerConsumer
Create C:\Program Files\Neuromatters\
Copy Analysis\CBCI to C:\Program Files\Neuromatters\
Update EEGTAGPREFIX in go.bat to point to the location of the checkout from svn.

3. Install RSVP images and python scripts
Create C:\DARPA_PHASEII
Create C:\DARPA_PHASEII\data_TAG_ClosedLoop
Copy Display\pythonScriptRSVP_Ver1pt7 and Display\TAG_test_Images to C:\DARPA_PHASEII
Open C:\DARPA_PHASEII\pythonScriptRSVP_Ver1pt7\BatchFiles\RSVP_test_ClosedLoop.bat and change the 
"W:\" in the following line to point to where the MATLAB script (step 4, below) is installed. Also remove the "rem".
rem copy %outfilename% W:\%fullname%

4. Install MATLAB Script (optional)
If desired, the MATLAB closed loop analysis script can be copied elsewhere and modified.
Copy Analysis\CalTech_ClosedLoop_PilotExp to the directory of your choice.
ClosedLoop_CalTech_StopPilot_v4.m has a few parameters that can be tweaked by the experimenter.
See documentation in that file for more information.

II. Running the System

1. Train the classifier
Instruct the subject to look for baseball gloves.
Run C:\Program Files\Neuromatters\CBCI\StartBioSemi.bat or StartABM.bat
Run C:\DARPA_PHASEII\pythonScriptRSVP_Ver1pt7\BatchFiles\RunGui.bat
Click Load Session -> BatchFiles/Session_ClosedLoop_Train.ini
Click Run.
Click OK to accept the TCP/IP defaults.
Run 20-30 blocks of training. From Dave Jangraw, "We usually run training for 20-30 blocks, and will 
stop if the training Az value seems to level off (I think Az>0.7 indicates a pretty good subject)."
Hit "t" to train the classifier.
Exit the python gui and ProducerConsumer (by pressing "q" in the ProducerConsumer window).

2. Test the classifier.
Instruct the target to look for something other than baseball gloves, e.g. brains.
Run C:\Program Files\Neuromatters\CBCI\StartBioSemi.bat or StartABM.bat
Run C:\DARPA_PHASEII\pythonScriptRSVP_Ver1pt7\BatchFiles\RSVP_test_ClosedLoop.bat
RSVP will run for 5 blocks, then shutdown.
Exit ProducerConsumer (by pressing "q" in the ProducerConsumer window).

3. Check the results.
Open MATLAB and run ClosedLoop_CalTech_StopPilot_v4.m (it might be neccessary to run addpath(genpath('path\to\CClosedLoop_CalTech_StopPilot_v4.m')) first)
The script will attempt to predict the category the subject was looking for in the test.
If more data are needed, it will generate a new ClosedLoopTAG.xml file to be used with another test as in step 2 above.
