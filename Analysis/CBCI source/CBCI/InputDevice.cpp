// InputDevice.cpp
//
// Original Author: Christoforos Christoforou
// Update/refactor: Matthew Jaswa, DCS Corporation, 12/2012

#include "InputDevice.h"

#include <vector>

InputDevice::InputDevice()
: nchannels(0)
{}

InputDevice::~InputDevice()
{}

void InputDevice::setChannelList(std::vector<int> const & channels, int numchannels)
{
	channelList = channels;
	nchannels = numchannels;
}
