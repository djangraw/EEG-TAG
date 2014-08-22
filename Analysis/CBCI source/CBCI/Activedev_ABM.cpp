// Activedev_ABM.cpp
//
// Original Author: Dave Jangraw
// Update/refactor: Matthew Jaswa, DCS Corporation, 12/2012

#include "activedev_ABM.h"

#include <Windows.h> 
#include "AbmSdkInclude.h"

#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include <cmath>
#include <cstring>

ActiveDev_ABM::ActiveDev_ABM()
: acquisitionStarted(false), latestEvent(0),
DEFAULTPATH("C:\\\\ABM\\EEG\\SDK\\Output Files\\directoutput.ebs")
{ }

ActiveDev_ABM::~ActiveDev_ABM()
{
	stop();
}

void ActiveDev_ABM::start() 
{
	if (!acquisitionStarted)
	{
		std::string const message("\nIs the ABM connected and powered on?");

		// Open the device.
		// It's not clear what condition will cause GetDeviceInfo() to return a
		// NULL pointer, but the documentation recommends checking for it.
		_DEVICE_INFO* devInfo = GetDeviceInfo();
		if (devInfo == NULL)
		{
			throw(std::string("GetDeviceInfo() failed") + message);
		}

		std::cout << "ABM Device Info:" << std::endl;
		std::cout << "Device Name: " << devInfo->chDeviceName << std::endl;
		std::cout << "Comm Port: " << devInfo->nCommPort << std::endl;
		std::cout << "ECG Channel: " << devInfo->nECGPos << std::endl;
		std::cout << "Number of Channels: " << devInfo->nNumberOfChannel << std::endl;

		deviceChannels = devInfo->nNumberOfChannel;

		// SetDestinationFile() wants a non-const char*
		char * path = new char[DEFAULTPATH.length() + 1];
		strcpy(path, DEFAULTPATH.c_str());

		if (!SetDestinationFile(path))
		{
			delete[] path;
			throw(std::string("SetDestinationFile(" + DEFAULTPATH + ") failed") + message);
		}
		else
		{	
			delete[] path;
		}

		if (InitSession(ABM_DEVICE_X10Standard, ABM_SESSION_RAW, -1, 0) != INIT_SESSION_OK)
		{
			throw(std::string("InitSession() failed") + message);
		}

		// Get information about the device's channels. This is primarily so
		// we can check which device we have.
		_CHANNELMAP_INFO channelMap;
		if (!GetChannelMapInfo(channelMap))
		{
			throw(std::string("GetChannelMapInfo() failed") + message);
		}

		std::cout << "Device Code " << channelMap.nDeviceTypeCode << std::endl;
		if (channelMap.nDeviceTypeCode != 0)
		{
			std::ostringstream message;
			message << "ABM X10 not found. Device code is " << channelMap.nDeviceTypeCode;
			throw(message.str());
		}

		// print out all the channels
		_EEGCHANNELS_INFO & eegChannels = channelMap.stEEGChannels;
		for (int i = 0; i < channelMap.nSize; ++i)
		{
			std::cout << eegChannels.cChName[i] << " " << 
				eegChannels.bChUsed[i] << " " <<
				eegChannels.bChUsedInQualityData[i] << std::endl;
		}
		
		std::cout << "Starting ABM Acquisition..." << std::endl;
		if (StartAcquisition() != ACQ_STARTED_OK){
			throw(std::string("StartAcquisition() failed") + message);
		}
		std::cout << "done." << std::endl;
		acquisitionStarted = true;
	}
}

void ActiveDev_ABM::stop() {

	if (acquisitionStarted)
	{
		StopAcquisition();
		acquisitionStarted = false;

		rawData.clear();
		rawDataTimeStamps.clear();
		thirdPartyEvents.clear();
		thirdPartyTimeStamps.clear();
		latestEvent = 0;
	}
}

std::vector<double> ActiveDev_ABM::getSamples(unsigned long requestedSamples)
{
	// Are there enough samples already?
	// If not, read more data from the device and add it to our vectors.
	if (rawDataTimeStamps.size() < requestedSamples)
	{
		int rawCount, thirdPartySize;
		unsigned char* thirdParty = GetThirdPartyData(thirdPartySize);
		float* raw = GetRawData(rawCount);
		unsigned char* timeStamps = GetTimeStampsStreamData(TIMESTAMP_RAW);

		if (raw != NULL)
		{
			bool duplicateTS = true;
			for (int i = 0; i < rawCount; ++i)
			{
				int offset = ABM_RAW_PACKAGESIZE * i + ABM_RAW_CHANNEL1_OFFSET;
				// Grab only the channel data and add it to the end of our vector.
				rawData.insert(rawData.end(), raw + offset, raw + offset + deviceChannels);

				offset = ABM_TIME_PACKAGESIZE * i;
				int newTimeStamp = convertTimeStamp(timeStamps + offset);
				
				// The X10 always returns EEG samples in pairs, and the 
				// timestamps that correspond to those samples are identical.
				// To approximate the value of the first timestamp, subtract
				// the time between samples.
				// See also: B-Alert Software Programmer's Manual V2.0 pp. 34-35, 52-53
				if (duplicateTS)
				{
					newTimeStamp -= ABM_SAMPLELENGTH;
				}
				duplicateTS = !duplicateTS;
				
				rawDataTimeStamps.push_back(newTimeStamp);
			}
		}

		if (thirdParty != NULL)
		{
			int numEvents = thirdPartySize / ABM_TP_PACKAGESIZE;
			for (int i = 0; i < numEvents; ++i)
			{
				int offset = i * ABM_TP_PACKAGESIZE;
				thirdPartyTimeStamps.push_back(convertTimeStamp(thirdParty + offset + ABM_TP_TIME_OFFSET));
				thirdPartyEvents.push_back(thirdParty[offset + ABM_TP_DATA_OFFSET]);
			}
		}
	}

	// Determine how many samples to read, and move them into the data vector.
	std::vector<double> data;
	unsigned long samples = (std::min)(requestedSamples, (unsigned long)rawDataTimeStamps.size());

	for (unsigned long samplesRead = 0; samplesRead < samples; ++samplesRead)
	{
		if (thirdPartyTimeStamps.size() > 0 && thirdPartyTimeStamps.front() <= rawDataTimeStamps.front())
		{
			latestEvent = thirdPartyEvents.front();
			thirdPartyEvents.erase(thirdPartyEvents.begin());
			thirdPartyTimeStamps.erase(thirdPartyTimeStamps.begin());
		}

		for (std::vector<int>::const_iterator it = channelList.begin(); 
			it != channelList.end(); ++it)
		{
			if (*it == 1)
			{
				// Trigger channel
				data.push_back(latestEvent);	
			}
			else if (*it == 0)
			{
				// Debug channel. It does not appear to be used for anything,
				// however the compiled MATLAB code may expect it to exist.
				data.push_back(rawDataTimeStamps.front());
			}
			else
			{
				// EEG channel
				data.push_back(rawData[(*it) - 1]);
			}
		}

		rawData.erase(rawData.begin(), rawData.begin() + deviceChannels);
		rawDataTimeStamps.erase(rawDataTimeStamps.begin());
	}

	return data;
}

unsigned int ActiveDev_ABM::convertTimeStamp(unsigned char const * const timeStamp)
{
	unsigned int convertedTS;
	unsigned char* temp = (unsigned char*)&convertedTS;
	temp[3] = timeStamp[0];
	temp[2] = timeStamp[1];
	temp[1] = timeStamp[2];
	temp[0] = timeStamp[3];
	return convertedTS;
}
