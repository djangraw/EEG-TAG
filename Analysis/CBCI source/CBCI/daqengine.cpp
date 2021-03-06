// daqengine.cpp
//
// Original Author: Christoforos Christoforou
// ABM Updates: Dave Jangraw, 08/2009
// Update/refactor: Matthew Jaswa, DCS Corporation, 12/2012

/**
 * \file daqengine.cpp
 * \brief EEG Acquisition and TAG Classifier Builder
 *
 * This program captures EEG data from an EEG system. This data is passed to a 
 * library translated from MATLAB code. This library builds an image classifier
 * for the TAG system. See InputDevice for information about supported EEG
 * systems.
 */

#include "IniReader.h"
#include "InputDevice.h"
#include "InputDeviceFactory.h"
#include "libmatrix.h" // generated by mcc (MATLAB compiler)
#include "structures.h"

#include <fstream>
#include <iostream>
#include <sstream>

#include <cstdio>
#include <cstdlib>

#include <conio.h>
#include <io.h>

int establishTCPIPconnection();
void init_variablesfromINIfile(AcquisitionParameters& aqParams, std::string const & iniFile);
int producer(AcquisitionParameters const & parameters);

void main (int argc, char* argv[])
{
	std::string iniFile("./CBCI.ini");

	// It would be nice to be able to specify the initialization file as
	// an argument. This requires changing the compiled MATLAB code, as
	// it is hardcoded with "CBCI.ini".
	/*if (argc == 2)
	{
		iniFile = argv[1];
	}*/

	if (_access_s(iniFile.c_str(), 0) != 0)
	{
		std::cout << iniFile << " does not exist." << std::endl;
		exit(1);
	}

	// The IniReader class needs to have a path to the file, and not just the file name.
	if (iniFile.find("/") == std::string::npos && iniFile.find("\\") == std::string::npos)
	{
		iniFile = "./" + iniFile;
	}

	std::cout << "Initialization parameters will be read from " << iniFile << std::endl;

	// Call the mclInitializeApplication routine. Make sure that the application
	// was initialized properly by checking the return status. This initialization
	// has to be done before calling any MATLAB APIs or MATLAB Compiler generated
	// shared library functions.
	
	std::cout << "Initializing MATLAB library... ";
	if( !mclInitializeApplication(NULL,0) )
	{
		std::cout << "mclInitializeApplication() failed." << std::endl;
		exit(1);
	}

	// Call the library intialization routine and make sure that the
	// library was initialized properly.
	
	if (!libmatrixInitialize())
	{
		std::cout << "libmatrixInitialize() failed." << std::endl;
		exit(1);
	}
	std::cout << "done." << std::endl;

	MessageBox(
		NULL,
		"Press the ok button to start recording.\nNote: Make sure that the EEG device is connected and powered on.",
		"CBCI Rapid Serial Visual Presentation EEG Analysis",
		MB_OK
		);

	AcquisitionParameters aqParams;
	init_variablesfromINIfile(aqParams, iniFile);

	while(true)
	{
		int connected = 0;
		if (aqParams.recordFrom != 0) 
		{
			// if this is not a simulated recording
			connected = establishTCPIPconnection();
		} 
		else 
		{ 
			// if it is simulated recording, proceed 
			connected = 1;
		}

		if (connected) 
		{
			int status = producer(aqParams);
			if (status < 3)
			{
				if (aqParams.recordFrom != 0) 
				{
					closeTCPIPconnection();
				}
			}
			else
			{
				std::cout << "Exiting application!!!!\n" << std::endl;
				exit(0);
			}
		}
		else 
		{
			std::cout << "Exiting application!!!!\n" << std::endl;
			exit(0);
		}
	}

	// Terminate MCR and library function and free resources.
	libmatrixTerminate();
	mclTerminateApplication();
}

int producer(AcquisitionParameters const & parameters)
{
	bool halt = false;

	InputDevice* mydevice = InputDeviceFactory::CreateDevice(parameters.recordFrom, parameters.inputFile);
	mydevice->setChannelList(parameters.channelList, parameters.numberOfChannels);

	int retVal = 0;

	try
	{
		mydevice->start();
	}
	catch (std::string s)
	{
		std::ostringstream errorMessage;
		errorMessage << "Error starting acquisition: " << s << std::endl;
		errorMessage << "The program will now exit." << std::endl;

		std::cout << errorMessage.str() << std::endl;

		MessageBox(NULL, errorMessage.str().c_str(), "Error", MB_OK|MB_ICONERROR);
		exit(1);
	}
	
	// initialize MATLAB data structures
	double info[10];
	info[0] = parameters.recordFrom;
	info[1] = parameters.operatorsFeedback;
	mwArray inp(1, 2, mxDOUBLE_CLASS);
	inp.SetData(info, 2);
	mwArray mystr(parameters.simClassifierSessionId.c_str());
	mwArray out; 
	initialize(1, out, inp, mystr);
	mwArray matlabData(parameters.numberOfChannels, parameters.SamplesPerTrigger, mxDOUBLE_CLASS, mxREAL);

	unsigned long samples = parameters.SamplesPerTrigger;
	std::vector<double> block;
	int sessionStatus = 0;
	std::ofstream outfile(parameters.outputFile.c_str(), 
		std::ofstream::trunc | std::ofstream::binary | std::ofstream::out);
	
	while (retVal == 0) 
	{
		std::vector<double> data;
		try 
		{
			data = mydevice->getSamples(samples);
		}
		catch (std::string s)
		{
			std::ostringstream errorMessage;
			errorMessage << "Error during acquisition: " << s << std::endl;
			errorMessage << "The program will now exit." << std::endl;

			std::cout << errorMessage.str() << std::endl;

			MessageBox(NULL, errorMessage.str().c_str(), "Error", MB_OK|MB_ICONERROR);
			exit(1);
		}

		block.insert(block.end(), data.begin(), data.end());
		samples -= data.size() / parameters.numberOfChannels;

		if (samples == 0)
		{
			try
			{
				matlabData.SetData(&block[0], block.size());

				// 1   indicates 1 output parameter
				// out is the output parameter
				// out is passed as an input parameter as well
				// matlabdata is the actual buffer read.
				
				daqdetect(1, out, out, matlabData); //RUN THE CLASSIFIER CODE
				out.Get(1, 1).GetData(&sessionStatus, 1); //IF IT DIDN'T GO SMOOTHLY, SET THE STOP FLAG.

				if (sessionStatus == 1) 
				{
					halt = true;				   
				}
			}
			catch (const mwException& e)
			{
				std::cout << e.what() << std::endl;
			}
			catch (...)
			{
				std::cout << "Unexpected error thrown" << std::endl;
			}

			if ((parameters.logMode == MEMORYFILE) || (parameters.logMode == FILEONLY))
			{ 
				outfile.write((char*)(&block[0]), block.size() * sizeof(double));
			}
			block.clear();
			samples = parameters.SamplesPerTrigger;
		}
		
		if (halt) 
		{
			retVal = 2;
		}
		else if (_kbhit() > 0)
		{
			char ch = _getch();
			if (ch == 's') 
			{
				retVal = 1; 
			} 
			else if (ch == 't') 
			{
				retVal = 3; 
			}
		}
	}
	
	mydevice->stop();
	delete mydevice;

	return retVal;
}

void init_variablesfromINIfile(AcquisitionParameters& aqParams, std::string const & iniFile)
{

	std::ostringstream warningMessage;

	IniReader iniReader(iniFile);
	std::string szName = iniReader.ReadString("Setting", "Name", "");

	// numofchannels should be eliminated, as it is redundant. However,
	// the compiled MATLAB code also parses the ini file and looks for numofchannels.
	// TODO: modify the compiled MATLAB code to receive configuration information as 
	// arguments to a function that we call from the C++ side, instead of parsing
	// the ini file directly.
	aqParams.numberOfChannels = iniReader.ReadInteger("engine", "numofchannels", 73); 
	aqParams.SamplesPerTrigger = iniReader.ReadInteger("engine","SamplesPerTrigger",1024);

	int feedbackMode = iniReader.ReadInteger("feedback","feedbackmode", 0);
	if (feedbackMode != NONE && feedbackMode != TEXT_MODE && feedbackMode != GUI_MODE)
	{
		warningMessage << "Warning: unknown value \"" << feedbackMode 
			<< "\" found for feedbackmode in section feedback." << std::endl;
		feedbackMode = NONE;
		warningMessage << "Using default value \"" << feedbackMode << "\"." << std::endl;
	}
	aqParams.operatorsFeedback = (FeedbackMode)feedbackMode;

	int logMode = iniReader.ReadInteger("engine","recordingMode",0);
	if (logMode != MEMORYFILE && logMode != MEMORYONLY && logMode != FILEONLY)
	{
		warningMessage << "Warning: unknown value \"" << logMode 
			<< "\" found for recordingMode in section engine." << std::endl;
		logMode = MEMORYFILE;
		warningMessage << "Using default value \"" << logMode << "\"." << std::endl;
	}
	aqParams.logMode = (LogMode)logMode;

	int deviceType = iniReader.ReadInteger("engine","recordFrom",0);
	if (deviceType != EEGFILE && deviceType != ACTIVE2 && deviceType != ABM)
	{
		warningMessage << "Warning: unknown value \"" << deviceType 
			<< "\" found for recordFrom in section engine." << std::endl;
		deviceType = ACTIVE2;
		warningMessage << "Using default value \"" << deviceType << "\"." << std::endl;
	}
	aqParams.recordFrom = (DeviceType)deviceType;

	std::string chanliststr = iniReader.ReadString("engine","channelList","");

	std::istringstream parser(chanliststr);
	while (!parser.eof())
	{
		int temp;
		parser >> temp;
		aqParams.channelList.push_back(temp);
	}

	if (aqParams.numberOfChannels != aqParams.channelList.size())
	{
		warningMessage << "Warning: numofchannels (" << aqParams.numberOfChannels 
			<< ") does not equal the number of elements in channelList (" 
			<< aqParams.channelList.size() << ")" << std::endl;
	}

	aqParams.inputFile = iniReader.ReadString("VirtualDevice", "inputFile", "");
	aqParams.outputFile = iniReader.ReadString("Session", "outfile", "");
	aqParams.simClassifierSessionId = iniReader.ReadString("VirtualDevice", "sim_classifier_sessionidTesting", "");

	if (warningMessage.str().size() > 0)
	{
		MessageBox(NULL, warningMessage.str().c_str(), "Warning", MB_OK|MB_ICONWARNING);
	}
}

int establishTCPIPconnection()
{
	mwArray out;
	bool connected = 0;
	while(true) 
	{
		waitTCPIPconnection(1, out);
		if (out.NumberOfFields() > 1)
		{
			connected = 1; 
			break;
		}
		else 
		{
			if (_kbhit() >= 1)
			{
				if (_getch() == 'q')
				{
					connected = 0; 
					break;
				}
			}
		}
	}
	return connected; 
}
