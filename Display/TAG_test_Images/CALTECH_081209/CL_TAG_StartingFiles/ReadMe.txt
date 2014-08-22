
This folder just contains a bunch of XML files that list 500
random images from the Closed-Loop TAG experiment image database (total of 3798 images).

Each of these XML's can thus be used as a random starting sample of images
when running an experiment where you want to figure out what category the
subject is looking for.

Just move one of the files to the C:\DARPA_PHASEII\TAG_test_Images\CALTECH_081209

folder, and rename it ClosedLoopTAG.xml, and the Python code will then use
it the next time the Python code is run, meaning that the 500 images the
XML lists will be what is shown.  This process of moving and renaming one
of these files is down automatically by the ClosedLoop_CalTech_StopPilot_v4.m
function that is run on the Analysis laptop during the course of the actual
experiments (it is done automatically when the analysis laptop has determined
it is time to exit the closed-loop, thus it moves a new random start file to
the directory to get you reset for the next experiment).



