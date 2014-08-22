// Activedev_ABM.h
//
// Original Author: Dave Jangraw, 08/2009
// Update/refactor: Matthew Jaswa, DCS Corporation, 12/2012

#ifndef __ACTIVEDEVABM_H__
#define __ACTIVEDEVABM_H__

#include "InputDevice.h"

#include <Windows.h> // Must come before TypeDef.h
#include "TypeDef.h"

#include <string>
#include <vector>

/**
 * \class ActiveDev_ABM
 * \brief Interface to ABM X10 EEG system.
 * 
 * This class provides access to the ABM X10 EEG hardware via the
 * interface provided by InputDevice. It uses the interface provided by 
 * ABM_Athena.dll to communicate with the ABM driver.
 *
 * \see B-Alert Software Programmer's Manual V2.0
 */

class ActiveDev_ABM : public InputDevice 
{

public:

	/**
	 * \brief Constructor
	 */

	ActiveDev_ABM();

	/**
	 * \brief Destructor
	 */

	virtual ~ActiveDev_ABM();

	/**
	 * \brief Start acquisition.
	 *
	 * Start EEG acquisiton. This method does nothing if acquisition has
	 * already started.
	 */

	virtual void start();

	/**
	 * \brief Stop acquisiton.
	 *
	 * Stop EEG acquisition. This method does nothing if acqisition has
	 * already stopped.
	 */

	virtual void stop();

	/**
	 * \brief Get EEG samples.
	 *
	 * Retrieve available EEG data samples, up to the amount specified by 
	 * requestedSamples, that have not been returned by a previous call to  
	 * getSamples(). This operates as a FIFO queue: if there are more samples
	 * available than specified by requestedSamples, return the oldest samples
	 * first; the rest will be available to future calls of getSamples(). If
	 * there are less samples available than specified, return all available 
	 * samples. If no samples are available, return an empty vector.
	 * 
	 * getSamples() is non-blocking.
	 *
	 * A single EEG sample is one measurement from each channel.
	 *
	 * \param requestedSamples Maximum number of samples to return.
	 *
	 * \return A vector containing EEG samples in chronological order (index 0 is oldest).
	 */

	virtual std::vector<double> getSamples(unsigned long requestedSamples);

private:

	unsigned int convertTimeStamp(unsigned char const * const timeStamp); // Convert big-endian timestamp to little-endian int.

	static int const ABM_SAMPLELENGTH = 4; // Approximates the duration of one sample of ABM data. 1/256 sec = 3.90625 milliseconds per sample

	static int const ABM_TP_PACKAGESIZE = 12;     // number of bytes in one package of third party data
	static int const ABM_TP_TIME_OFFSET = 3;      // offset (in bytes) where the third party timestamp starts
	static int const ABM_TP_DATA_OFFSET = 10;     // offset (in bytes) where the third party data starts
	static int const ABM_TIME_PACKAGESIZE = 4;    // number of bytes in one timestamp package
	static int const ABM_RAW_PACKAGESIZE = 16;    // number of bytes in one raw data package
	static int const ABM_RAW_CHANNEL1_OFFSET = 6; // offset (in bytes) where channel 1 starts
	std::string const DEFAULTPATH;                // specifies where data files written by the ABM SDK/driver are stored

	unsigned long deviceChannels;                   // number of channels supported by the device
	bool acquisitionStarted;                        // flag indicating whether EEG acquisition has started
	std::vector<float> rawData;                     // raw data from EEG channels
	std::vector<unsigned int> rawDataTimeStamps;    // converted raw data timestamps (in ms) (1 timestamp per EEG sample)
	std::vector<unsigned char> thirdPartyEvents;    // converted third party events
	std::vector<unsigned int> thirdPartyTimeStamps; // converted third party timestamps (in ms)
	unsigned char latestEvent;	                    // most recent third party event
};

#endif  // __ACTIVEDEVABM_H__