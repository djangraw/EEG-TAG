// Activedev.h
//
// Original Author: Christoforos Christoforou
// Update/refactor: Matthew Jaswa, DCS Corporation, 12/2012

#ifndef __ACTIVEDEV_H__
#define __ACTIVEDEV_H__

#include "InputDevice.h"
#include <Windows.h>
#include <string>

/**
 * \class ActiveDev
 * \brief Interface to BioSemi ActiveTwo EEG system
 * 
 * This class provides access to the BioSemi ActiveTwo EEG hardware via the
 * interface provided by InputDevice. It uses the interface provided by 
 * labview.dll to communicate with the BioSemi driver.
 *
 * \see http://www.biosemi.com/faq/make_own_acquisition_software.htm
 * \see http://www.biosemi.com/faq/trigger_signals.htm
 */

class ActiveDev : public InputDevice 
{

public:
	
	/**
	 * \brief Constructor
	 */

	ActiveDev();

	/**
	 * \brief Destructor
	 */

	virtual ~ActiveDev();

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
	 * getSamples() is non-blocking, however, if there are not enough samples
	 * available, it calls a BioSemi function (READ_POINTER()) that can block 
	 * until new EEG data is available.
	 *
	 * A single EEG sample is one measurement from each channel.
	 *
	 * \param requestedSamples Maximum number of samples to return.
	 *
	 * \return A vector containing EEG samples in chronological order (index 0 is oldest).
	 */

	virtual std::vector<double> getSamples(unsigned long requestedSamples);

private:

	double ultouc(long const lin);        // convert a 24-bit value from the BioSemi into a double
	double ultoucTrigger(long const lin); // convert a 16-bit trigger value from the BioSemi into a double
	void updateSamplesAvailable();        // convenience method to count the number of EEG samples available
	
	static unsigned long const SAMPLE_LENGTH = 282; // number of 32-bit words that the BioSemi generates with each sample
	static unsigned long const TOTAL_SAMPLES = 29747; // Choose TOTAL_SAMPLES so that BUFFER_SIZE below is at least 32MB (2^25 bytes).
	static unsigned long const BUFFER_SIZE = SAMPLE_LENGTH * TOTAL_SAMPLES; // BUFFER_SIZE should be a multiple of SAMPLE_LENGTH.

	unsigned long piBuffer[BUFFER_SIZE]; // ring buffer for BioSemi driver
	HANDLE dev_handle;                   // handle to BioSemi driver
	INT_PTR bufferPointer;               // points to the end of the data written to the ring buffer
	long currentIndex;					 // index of next sample to read from the ring buffer
	bool acquisitionStarted;             // flag indicating whether EEG acquisition has started
	unsigned long samplesAvailable;      // number of samples currently available in the ring buffer
};

#endif  //__ACTIVEDEV_H__