// InputDevice.h
//
// Original Author: Christoforos Christoforou
// Update/refactor: Matthew Jaswa, DCS Corporation, 12/2012


#ifndef __INPUTDEVICE_H__
#define __INPUTDEVICE_H__

#include <vector>

/**
 * \class InputDevice
 * \brief Interface to an EEG system.
 * 
 * This class describes a generic interface to read data from an EEG system. To
 * create an object that can interface with a particular EEG system, use
 * InputDeviceFactory.
 */

class InputDevice 
{

public:

	/**
	 * \brief Constructor
	 */

	InputDevice();
	
	/**
	 * \brief Destructor
	 */

	virtual ~InputDevice();

	/**
	 * \brief Start acquisition.
	 *
	 * Start EEG acquisiton. 
	 */

	virtual void start() = 0;

	/**
	 * \brief Stop acquisiton.
	 *
	 * Stop EEG acquisition. This method does nothing if acqisition has
	 * already stopped.
	 */

	virtual void stop() = 0;
	
	/**
	 * \brief Get EEG samples.
	 *
	 * Retrieve available EEG data samples, up to the amount specified by 
	 * requestedSamples, that have not been returned by a previous call to  
	 * getSamples().
	 *
	 * A single EEG sample is one measurement from each channel.
	 *
	 * \param requestedSamples Maximum number of samples to return.
	 *
	 * \return A vector containing EEG samples in chronological order (index 0 is oldest).
	 */

	virtual std::vector<double> getSamples(unsigned long requestedSamples) = 0;

	/**
	 * \brief Specify which EEG channels to use.
	 *
	 * Specify from which channels EEG data should be retrieved.
	 *
	 * \param channels list of channels to use
	 * \param numchannels number of channels in the list
	 */

	virtual void setChannelList(std::vector<int> const & channels, int numchannels);
	
	// numchannels is redundant and should be eliminated. It has been left in
	// for the moment to maintain consistency with the options in the 
	// initialization file. See comments in daqengine.cpp.

	
protected:
	std::vector<int> channelList; // only retrieve data from channels in this list
	int nchannels;                // number of channels channelList - redundant and should be eliminated
};

#endif // __INPUTDEVICE_H__