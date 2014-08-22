set PATH=C:\Python25;%PATH%
@echo off

cd C:\DARPA_PHASEII\pythonScriptRSVP_Ver1pt7

copy C:\DARPA_PHASEII\pythonScriptRSVP_Ver1pt7\BatchFiles\configuration_test_ClosedLoop.ini C:\DARPA_PHASEII\pythonScriptRSVP_Ver1pt7\configuration.ini

python RSVPtest.py



Rem Find the appropriate filename for this series of experiments
set /p expextension="What is the experiment series [A,B,C... etc.]? "
set targetdirectory=C:\DARPA_PHASEII\data_TAG_ClosedLoop
set basefilename=ClosedLoopTAG
set /a counter=0

:numbers
set /a counter=%counter%+1
set fullname=%basefilename%_%expextension%_%counter%.xml
set outfilename=%targetdirectory%\%fullname%

IF NOT EXIST %outfilename% (goto :namefinished) ELSE (echo Pre-existing file.) 
goto :numbers

:namefinished
echo Success! A novel filename has been found.

Rem Move XML output file to data directory and rename it
move C:\DARPA_PHASEII\pythonScriptRSVP_Ver1pt7\xml_RSVPoutput_RENAME_ME.xml %outfilename%

Rem Copy the XML output file to the matlab directory
rem update the following line with the path to the matlab directory
rem copy %outfilename% W:\%fullname%

Rem Copy and rename the dat file output to the data directory
copy "C:\Program Files\Neuromatters\CBCI\RSVP.dat" %targetdirectory%\%basefilename%_%expextension%_%counter%.dat


ENDLOCAL

pause
