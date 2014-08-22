
@echo off

cd C:\DARPA_PHASEII\pythonScriptRSVP_Ver1pt7

copy C:\DARPA_PHASEII\pythonScriptRSVP_Ver1pt7\BatchFiles\TargetSwitch_v1p0_test_configuration.ini C:\DARPA_PHASEII\pythonScriptRSVP_Ver1pt7\configuration.ini

python TargetSwitch_v1p0_test.py

PAUSE

ENDLOCAL

