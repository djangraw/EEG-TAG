// Activedev.cpp
//
// Original Author: Christoforos Christoforou
// Update/refactor: Matthew Jaswa, DCS Corporation, 12/2012

#include "activedev.h"

#include <Windows.h> // must come before labview_dll.h and bsif.h
#include "labview_dll.h"
#include "bsif.h"

#include <algorithm>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

#include <cstring>

ActiveDev::ActiveDev()
: bufferPointer(0), currentIndex(0), dev_handle(0),
acquisitionStarted(false), samplesAvailable(0)
{ }

ActiveDev::~ActiveDev()
{
	stop();
}

void ActiveDev::start()
{
	if (!acquisitionStarted)
	{
		std::string const message("\nIs the BioSemi connected and powered on?");

		// initialize the ring buffer (set it all to zero)
		memset(piBuffer, 0, sizeof(piBuffer));
		
		// OPEN_DRIVER() will fail (return null) if the BioSemi is not 
		// connected via USB.
		dev_handle = OPEN_DRIVER();

		if (dev_handle == NULL)
		{
			throw(std::string("OPEN_DRIVER() failed") + message);
		}

		// Connect the driver to the ring buffer.
		// READ_MULTIPLE_SWEEPS() will fail if the BioSemi is not connected via
		// USB, though that condition should be detected above.
		BOOL success = READ_MULTIPLE_SWEEPS(dev_handle, (PCHAR)piBuffer, sizeof(piBuffer));
		if (!success)
		{
			throw(std::string("READ_MULTIPLE_SWEEPS() failed") + message);
		}

		// enable synchronized READ_POINTER() calls
		BSIF_SET_SYNC(true);

		// Create the initialization string that enables acquisition.
		CHAR initStr[64];
		memset(initStr, 0, sizeof(initStr));
		initStr[0] = (CHAR)0xFF;

		// Start acquisition by writing the initialization string to the 
		// BioSemi driver.
		// USB_WRITE() will fail if the BioSemi is not connected via USB,
		// though that condition should be detected above.
		success = USB_WRITE(dev_handle, initStr);
		if (!success)
		{
			throw(std::string("USB_WRITE() failed") + message);
		}

		acquisitionStarted = true;

		// READ_POINTER() will fail if the BioSemi is connected via USB but not
		// powered on.
		success = READ_POINTER(dev_handle, (PINT_PTR)&bufferPointer);

		if (!success)
		{
			throw(std::string("READ_POINTER() failed") + message);
		}
	
		// Wait until 1 sample is available so that we can grab the status 
		// channel information below.
		while (samplesAvailable < 1)
		{
			updateSamplesAvailable();
		}
		
		// Test for the ActiveTwo MK2
		if (piBuffer[1] >> 31 == 1)
		{
			std::cout << "BioSemi ActiveTwo MK2 detected." << std::endl;
		}
		else
		{
			throw (std::string("BioSemi ActiveTwo MK2 not detected. MK1 is not supported."));
		}

		// Test for speed mode.
		unsigned short speedmode = ((piBuffer[1] >> 26) & 0x8) + ((piBuffer[1] >> 25) & 0x7);
		if (speedmode != 4)
		{
			std::ostringstream errorMessage;
			errorMessage << "BioSemi speedmode is set to " << speedmode << ". Only 4 is supported.";
			throw (errorMessage.str());
		}
		std::cout << "Speed mode: " << speedmode << std::endl;
		
		// Wait until 512 samples are available so that we have an accurate stride 
		// number in the driver info below.
		while (samplesAvailable < 512)
		{
			updateSamplesAvailable();
		}

		CHAR infoBuffer[256];
		GET_DRIVER_INFO(infoBuffer, sizeof(infoBuffer));
		std::cout << "BioSemi Driver Info: " << infoBuffer << std::endl;
	}
}

void ActiveDev::stop() 
{
	if (acquisitionStarted)
	{
		CHAR initStr[64];
		memset(initStr, 0, sizeof(initStr));

		// stop acquisition
		USB_WRITE(dev_handle, initStr);

		acquisitionStarted = false;
		
		CLOSE_DRIVER(dev_handle);

		bufferPointer = 0;
		currentIndex = 0;
		dev_handle = 0;
		samplesAvailable = 0;
	}
}

void ActiveDev::updateSamplesAvailable()
{
	// Update the buffer pointer.
	BOOL success = READ_POINTER(dev_handle, (PINT_PTR)&bufferPointer);
	if (!success)
	{
		throw (std::string("READ_POINTER() failed"));
	}

	// Calculate how many samples are in the buffer.
	unsigned long bytesAvailable = 0;
	if (bufferPointer >= currentIndex)
	{
		bytesAvailable = bufferPointer - (currentIndex * sizeof(unsigned long));
	}
	else
	{
		// We've looped past the end of the ring buffer.
		bytesAvailable = (BUFFER_SIZE - currentIndex) * sizeof(unsigned long) + bufferPointer;
	}
	samplesAvailable = bytesAvailable / (SAMPLE_LENGTH * sizeof(unsigned long));
}

std::vector<double> ActiveDev::getSamples(unsigned long requestedSamples)
{
	// Update samplesAvailable, unless we already know that there's
	// enough there to fulfill the request.
	if (requestedSamples > samplesAvailable)
	{
		updateSamplesAvailable();
	}

	// Calculate how many samples we should read from the buffer.
	unsigned long samples = (std::min)(requestedSamples, samplesAvailable);
	samplesAvailable -= samples;
	
	std::vector<double> data;

	for (unsigned long samplesRead = 0; samplesRead < samples; ++samplesRead)
	{
		for (int i=0; i < nchannels; i++)
		{
			if (channelList[i] == 0)
			{ 
				// Debug channel. It does not appear to be used for anything,
				// however the compiled MATLAB code may expect it to exist.
				data.push_back((double)(currentIndex / SAMPLE_LENGTH));
			} 
			else if (channelList[i] == 1)
			{ 
				// Trigger channel
				data.push_back(ultoucTrigger(piBuffer[currentIndex + channelList[i]]));
			} 
			else
			{
				// EEG channel
				data.push_back(ultouc(piBuffer[currentIndex + channelList[i]]));
			}
		}
		// Jump to the start of the next sample.
		currentIndex = (currentIndex + SAMPLE_LENGTH) % BUFFER_SIZE;
	}

	return data;
}

// From http://www.biosemi.com/faq/make_own_acquisition_software.htm
// "The receiver converts every 24-bit word from the AD-box into a 32-bit 
// Signed Integer, by adding an extra zero Least Significant Byte to the ADC 
// data. The 24-bit ADC output has an LSB value of 1/32th uV. The 32-bit 
// Integer received for the USB interface has an LSB value of 
// 1/32*1/256 = 1/8192th uV"

double ActiveDev::ultouc(long const lin)
{
	return lin / 8192.0;
}

// Extract the 16-bit trigger value from the 24-bit status channel and convert
// that value to double.
// The receiver adds a byte to the 24-bit value (see ultouc() note above) and 
// we're only interested in the 16 least significant bits of the 24-bit status
// channel. In the resulting 32-bit value, these are the "middle" bits.

double ActiveDev::ultoucTrigger(long const lin)
{
	return (double)(((lin) & 0x00FFFF00) >> 8);
}
