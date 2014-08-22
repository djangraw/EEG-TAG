// InputDevice.h
//
// Author: Matthew Jaswa, DCS Corporation, 12/2012

#ifndef INPUTDEVICEFACTORY_H
#define INPUTDEVICEFACTORY_H

#include "structures.h"
#include <string>

class InputDevice;

/**
 * \class InputDeviceFactory
 * \brief Create objects derived from InputDevice.
 * 
 * This class provides a static method, CreateDevice(), that returns a pointer to
 * an object that implements the InputDevice interface.
 */

class InputDeviceFactory
{

public:

	/**
	 * \brief Create an InputDevice object.
	 *
	 * Create an InputDevice derived object that matches the device parameter.
	 *
	 * \param device Kind of object to create.
	 * \param filename Name of data file for ActiveFile objects.
	 *
	 * \returns A pointer to new InputDevice derived object.
	 */

	static InputDevice* CreateDevice(DeviceType const device, std::string const filename = "default_session1_mode2.dat");
};

#endif // INPUTDEVICEFACTORY_H