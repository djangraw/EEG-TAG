%%%
%%%This function takes an XML file and converts it into an XML structure
%%%that matlab can easily analyze.
%%%
%%%Need to have access to the @xmltree files.
%%%
%%%XMLstruct = convertXML2XMLstruct(xmlfilename);
%%%
%%%Last modified Feb 2009, EAP

function XMLstruct = convertXML2XMLstruct(xmlfilename)


%%%First load the existing XML file
%%%Convert the XML file to a structure that Matlab can analyze
s1        = xmltree(xmlfilename);
XMLstruct = convert(s1);