// ActiveFile.h
//
// Original Author: Christoforos Christoforou
// Updates: Matthew Jaswa, DCS Corporation, 12/2012

// This class is incomplete/untested. It should either be eliminated or 
// updated.

#ifndef __ACTIVEFILE_H__
#define __ACTIVEFILE_H__

#include "InputDevice.h"
#include "windows.h"
#include <time.h>

/**
 * \class ActiveFile
 * \brief Simulate an EEG system.
 * 
 * This class simulates an EEG system using a previously recorded data file, 
 * via the interface provided by InputDevice.
 */

class ActiveFile : public InputDevice 
{

public:

	ActiveFile(std::string const & filename = "default_session1_mode2.dat");
	virtual void start();
	virtual void stop();
	virtual bool isAvailable(unsigned long samplesavailable);
	virtual std::vector<double> getSamples(unsigned long requestedSamples);

private:

	FILE* infile;
};

#endif  // __ACTIVEFILE_H__