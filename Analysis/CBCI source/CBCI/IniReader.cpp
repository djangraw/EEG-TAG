// IniReader.cpp
//
// Original Author: Christoforos Christoforou
// Update/refactor: Matthew Jaswa, DCS Corporation, 12/2012

#include "IniReader.h"
#include <Windows.h>
#include <string>

IniReader::IniReader(std::string const & fileName)
: m_fileName(fileName) 
{}

int IniReader::ReadInteger(std::string const & section, std::string const & key, 
							int const defaultValue) const
{
	return GetPrivateProfileInt(section.c_str(), key.c_str(), defaultValue, m_fileName.c_str());
}

std::string IniReader::ReadString(std::string const & section, std::string const & key, 
								   std::string const & defaultValue /* = "" */, 
								   unsigned int bufferSize /* = 256 */) const
{
	// Ensure that the buffer is large enough to hold the default value.
	// Add 1 to account for the null terminator.
	if (defaultValue.length() + 1 > bufferSize)
	{
		bufferSize = defaultValue.length() + 1;
	}
	char * temp_result = new char[bufferSize];

	GetPrivateProfileString(section.c_str(),  key.c_str(), defaultValue.c_str(),
		temp_result, bufferSize, m_fileName.c_str());

	std::string result(temp_result);
	delete temp_result;
	return result;
}
