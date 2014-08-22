############################
## Import various modules ##
############################

import os, os.path, sys, time
from easygui import *
import RSVPutilities
from   RSVPutilities import *
from ConfigParser import SafeConfigParser
from socket import *
import operator
from random import shuffle
from ctypes import windll
import subprocess
from tkFileDialog   import asksaveasfilename




msgbox("This wizard will help you generate an RSVP input XML from a file structure",title='XML Wizard - Create XML from file structure',ok_button='Continue');

msgbox("In the following dialog box select a root directory that specifies two sub-folders with the names 'targetpool' and 'nontargetpool'\n\n\n The directory should contain the target and distructor images respectivly.",title='XML Wizard - Create XML from file structure',ok_button='Next');

mypath = getPracticeSessionPath();

#
# Obtain list of targets and distractors
#

imageList = getListFromFolder(mypath)
print len(imageList)

msgbox("In the following dialog box choose filename for the XML file.",title='XML Wizard - Create XML from file structure',ok_button='Next');
fname = asksaveasfilename(defaultextension='*.xml')
if len(fname)>0:
  filename = fname
else:
  msgbox("No output file specified.... Terminating XML generation process.")
  sys.exit()
# filename = 'xml_output_renameME.xml'
f = open(filename,'w')

  
s1 = get_xmlRSVPheader(mypath)
f.write(s1)
dispOrder = range(len(imageList))
shuffle(dispOrder)
for i in range(len(imageList)):
  s2 = get_xmlRSVPentries(imageList[i],i,dispOrder[i],mypath)
  f.write(s2)
  
s3 =  get_xmlRSVPfooter()
f.write(s3)
f.close()

msgbox("The XML windows has been created!!!!",title='XML Wizard - Create XML from file structure',ok_button='Done');

subprocess.Popen('explorer .') 


