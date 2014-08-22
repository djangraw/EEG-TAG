// IniReader.h
//
// Original Author: Christoforos Christoforou
// Update/refactor: Matthew Jaswa, DCS Corporation, 12/2012

#ifndef INIREADER_H
#define INIREADER_H

#include <string>

/**
 * \class IniReader
 * \brief Read configuration options from an initialization file.
 *
 * This class provides an interface to read integer and string values from an
 * Windows-style initialization file, using the Windows API.
 *
 * It expects files in the following format:
 *
 * <PRE>
 * [section1]
 * key1 = 1
 * key2 = "string value"
 * ; this is a comment
 * [section2]
 * key3 = 3
 * ...
 * </PRE>
 */

class IniReader
{

public:

	/**
	 * \brief Constructor
	 *
	 * Initialize the reader with the provided filename.
	 *
	 * \param fileName name of the initialization file
	 */

	IniReader(std::string const & fileName);

	/**
	 * \brief Read an integer value.
	 *
	 * Read the integer value from the specified key in the specified section.
	 * If no such key can be found, return the specified default value.
	 *
	 * \param section section to examine for key
	 * \param key key to obtain value from
	 * \param defaultValue value to return if key is not found
	 *
	 * \return the value associated with key, or defaultValue if key is not found
	 */

	int ReadInteger(std::string const & section, std::string const & key,
		int const defaultValue) const;

	/**
	 * \brief Read a string value.
	 *
	 * Read the string value from the specified key in the specified section.
	 * If no such key can be found, return the specified default value. If the
	 * resulting string is longer than the internal buffer used to hold it, the
	 * string is truncated.
	 *
	 * \param section section to examine for key
	 * \param key key to obtain value from
	 * \param defaultValue value to return if key is not found
	 * \param bufferSize size of the internal buffer used to hold the string value
	 *
	 * \return the value associated with key, or defaultValue if key is not found
	 */

	std::string ReadString(std::string const & section, std::string const & key, 
		std::string const & defaultValue = "", unsigned int bufferSize = 256) const;

private:

	std::string m_fileName; // name of the initialization file

};

#endif //INIREADER_H