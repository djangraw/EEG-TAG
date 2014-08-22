// Activedev.h
//
// Original Author: Christoforos Christoforou
// ABM Updates: Dave Jangraw, 08/2009
// Update/refactor: Matthew Jaswa, DCS Corporation, 12/2012

/**
 * \file structures.h
 * \brief Global data structures
 *
 * This file contains data structures used throughout the rest of the code. It
 * has been trimmed down considerably; it may be appropriate to eliminate it
 * altogether in the future.
 */

#ifndef __STRUCTURES_H__
#define __STRUCTURES_H__

#include <string>
#include <vector>

/**
 * \brief EEG devices
 */

enum DeviceType
{
	EEGFILE = 0, //!< Previously recorded data file
	ACTIVE2,     //!< BioSemi ActiveTwo Mk2
	ABM			 //!< ABM X10
};

/**
 * \brief EEG data recording behavior
 */

enum LogMode
{
	MEMORYFILE = 0, //!< Process data and write it to a file.
	MEMORYONLY,     //!< Process data only.
	FILEONLY        //!< Write data to a file only.
};

/**
 * \brief Operator feedback
 */

enum FeedbackMode
{
	NONE = 0,  //!< No feedback
	TEXT_MODE, //!< Text-only feedback written to the console
	GUI_MODE   //!< MATLAB generated graph
};

/**
 * \brief Convenience struct that holds EEG acquisition parameters.
 */

struct AcquisitionParameters 
{
	/// EEG channels to read from the acquisition device
	std::vector<int> channelList; 

    // numberOfChannels is redundant and should be eliminated. It has been left in
	// for the moment to maintain consistency with the options in the 
	// initialization file. See comments in daqengine.cpp.

	/// Number of elements in channelList
	int numberOfChannels; 
	
	/// Number of EEG samples per trigger
	int SamplesPerTrigger; 

	/// Specifies what to do with EEG data: process it, write it to a file, or both.
	LogMode logMode; 

	/// EEG device to use
	DeviceType recordFrom;

	/// File to read EEG data from. Only used if recordFrom is set appropriately.
	std::string inputFile;

	/// File to write EEG data to. Only used if logMode is set appropriately.
	std::string outputFile;

    /// Classifier ID. Only used if reading from an EEG data file.
	std::string simClassifierSessionId;

    /// Type of feedback to display.
	FeedbackMode operatorsFeedback;

};

#endif  // __STRUCTURES_H__
