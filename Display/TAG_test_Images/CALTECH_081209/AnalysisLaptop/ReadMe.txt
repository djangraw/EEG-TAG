

It is in this folder in which the matlab code on the analysis laptop (ClosedLoop_Caltech_StopPilot4.m)
automatically places the last input XML file used for a closed loop search.  ie, for the closed-loop
TAG experiments in which we were trying to determine what category of images the sujbect was searching
for, when the analysis computer had decided it was time to exit the loop and guess the category, it
automaticlly copied the most recent XML file that had the images shown in the most recent RSVP
from the directory C:\DARPA_PHASEII\TAG_test_Images\CALTECH_081209 to this folder, renaming the
file from ClosedLoopTAG.xml to ClosedLoopTAG_???_lastone.xml, where ??? was the letter (A,B,C etc)
that corresponded to which search that subject had been doing.

