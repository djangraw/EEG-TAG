//
// This is the implementation of the active2/ABM device handler simulation . It provides
// methods to initialize the device, start and stop the acquisition process.
// Further it provides the method to process the samples acquired and convert them
// to a Matlab daq engine accesible format.
//
// There are certain configurable parameters in config.h. These parameters will adjust 
// the behaviour of this class as well as the behaviour of the data acquisition engine. 
// These parameters are sufficiently documented in the config.h header file 
//
// Author: Christoforos Christoforou
//       
//
// C++ implementation
//

#include <fstream>
#include <iostream>
#include "activefile.h"
#include "stdlib.h"
#include "string.h"
#include "stdio.h"
#include <time.h>		// Allows us to obtain the current time

#include <vector>

/**
*
* Creates an instace of the activeFile class.
*/

ActiveFile::ActiveFile(std::string const & filename) {

	//
	// Open file.  
	//

	infile = fopen(filename.c_str(),"r+b");

}

void ActiveFile::start()
{

}


/////////////////////////////////////////////////////////
//
// This method stops the data aquisition 
//
/////////////////////////////////////////////////////////

void ActiveFile::stop() {


	fclose(infile);

	//
	// Add some code to represent termination of the aquisition
	//
	//

}



/**
*
* Checks the intermitiate buffer to check if there are 'samplesavailable' sample
* ready to read in the intermidiate buffer starting from bufferindex
*
* This method is intented to be used to check availability with the Analog Input Implementation
* So It makes sure that the specified number of samples are available
*/

bool ActiveFile::isAvailable (unsigned long samplesavailable){


	Sleep(samplesavailable/16);		     // Sleep for some time to simulate processing time
	return true;	

}


/**
*
* This method will read all the data and process them. This is the most impoortant mehtod 
* in this class :) it is called by the engine every n miliseconds (see active2Ain on how the callback is setup)
* and will process the samples available in the buffer (upto requestedSamples). 
*
* The code for the debug mode is kept commented, it can help understanding how the class works throw simulation
* uncoment it as indicated if needed to experament with the code.
*
* Christoforos Christoforou
*
*/

std::vector<double> ActiveFile::getSamples(unsigned long requestedSamples)
{
	double* buffer = new double[nchannels * requestedSamples];
	int count = fread(buffer, sizeof(double), nchannels * requestedSamples, infile);
	std::vector<double> data(buffer, buffer + count);
	delete[] buffer;
	return data;
}

/////////////////////////////////////////////////////////////////////
