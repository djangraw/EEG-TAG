// InputDevice.cpp
//
// Author: Matthew Jaswa, DCS Corporation, 12/2012

#include "InputDeviceFactory.h"
#include "structures.h"
#include "Activedev.h"
#include "Activedev_ABM.h"
#include "Activefile.h"

#include <string>

InputDevice* InputDeviceFactory::CreateDevice(DeviceType const device, std::string const filename)
{
	switch(device)
	{
	case(ABM):
		return new ActiveDev_ABM();
		break;
	case(ACTIVE2):
		return new ActiveDev();
		break;
	case(EEGFILE):
		return new ActiveFile(filename);
		break;
	default:
		return new ActiveDev();
		break;
	}
}