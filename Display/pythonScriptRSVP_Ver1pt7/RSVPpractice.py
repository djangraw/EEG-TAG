#
# Practive module for RSVP, Allows the user to familiarize with the RSVP paradygm, the specific targets of interestes.
# The script can be used to identify the prefered presentation rate for the RSVP experiment for the specific subject.
#
# Author: Christoforos Christoforou
# Date: February 2009
#

    
############################
## Import various modules ##
############################

import os, os.path, sys, time, parallel
import VisionEgg, pygame
from VisionEgg.Core import *
from VisionEgg.Text import *
from VisionEgg.Textures import *
from VisionEgg.FlowControl import Presentation, FunctionController
from feedback import show_feedback
import RSVPutilities
from   RSVPutilities import *
from ConfigParser import SafeConfigParser
from socket import *
import operator
from ctypes import windll
import logging
import logging.handlers
import time


VisionEgg.config.VISIONEGG_GUI_INIT = 0


###########################################
# Quick fix to minimize maximize windows
###########################################
user32      = windll.user32
ShowWindow  = user32.ShowWindow
IsZoomed    = user32.IsZoomed

SW_MAXIMIZE =   3
SW_RESTORE  =   9

def getSDLWindow():
    return pygame.display.get_wm_info()['window']

def SDL_Maximize():
    return ShowWindow(getSDLWindow(), SW_MAXIMIZE)

def SDL_Restore():
    return ShowWindow(getSDLWindow(), SW_RESTORE)

def SDL_IsMaximized():
    return IsZoomed(getSDLWindow())


#########################################################
## User specified parameters
#########################################################


if (len(sys.argv)> 1):
  configFile = sys.argv[1]
else:
  configFile = 'configuration.ini'


# The classic way:
cp = SafeConfigParser()
#cp.read('configuration.ini')
cp.read(configFile)


trainPath = cp.get('RSVPtrainUserSpecifiedParams','trainPath')
inputXMLfile = cp.get('RSVPtrainUserSpecifiedParams','trainXMLfile')
outputPath = cp.get('RSVPtrainUserSpecifiedParams','outputPath')
numTargets = int(cp.get('RSVPtrainUserSpecifiedParams','numTargets'))
numNontargets =  int(cp.get('RSVPtrainUserSpecifiedParams','numNontargets'))
alreadySampled = []  # Reserved for future use
presentationFreq = int(cp.get('RSVPtrainUserSpecifiedParams','presentationFreq'))
simulationMode = int(cp.get('RSVPtrainUserSpecifiedParams','simulationMode'))
withreplacement = True  # allow sampling with replacement default true

logfilename = cp.get('LOG','logfile')
loglevel = cp.get('LOG','loglevel')

# Get and process background color values 
background_color_str= cp.get('RSVPglobalParams','background_color')
input_from = int(cp.get('RSVPglobalParams','input_from'))

########################################################
# Load Engine configuration parameters
########################################################

beginBlock = int(cp.get('BCIengineCodes','beginBlock'))
endBlock = int(cp.get('BCIengineCodes','endBlock'))
baseRef = int(cp.get('BCIengineCodes','baseRef'))
nonTargetcd = int(cp.get('BCIengineCodes','nonTargetcd'))
targetcd = int(cp.get('BCIengineCodes','targetcd'))
unlabledStimulus = int(cp.get('BCIengineCodes','unlabledStimulus'))
unlabeledStimulusOnline = int(cp.get('BCIengineCodes','unlabeledStimulusOnline'))
getBlockResults = int(cp.get('BCIengineCodes','getBlockResults'))
trainModeStart = int(cp.get('BCIengineCodes','trainModeStart'))
testModeStart = int(cp.get('BCIengineCodes','testModeStart'))
doTrain = int(cp.get('BCIengineCodes','doTrain'))
doEndSession = int(cp.get('BCIengineCodes','doEndSession'))


eventList = [nonTargetcd, targetcd, unlabledStimulus, unlabeledStimulusOnline]
# in seconds, indicate the length of a parralel port signal
commandLength = 0.020 
textstate = 0   # Instractions text counter
doingTraining = 0
internalState = 2;   # 0 : Block state  1: RSVP state showing images 2: Instruction Instructions state.

fname="freesansbold.ttf"
fsize = 20;


#########################################
# Set up logger information.
#########################################

LEVELS = {'debug': logging.DEBUG,
          'info': logging.INFO,
          'warning': logging.WARNING,
          'error': logging.ERROR,
          'critical': logging.CRITICAL}


LOG_FILENAME = logfilename
# Set up a specific logger with our desired output level
my_logger = logging.getLogger('RKI_Logger')

level = LEVELS.get(loglevel, logging.NOTSET)
my_logger.setLevel(level)


# Add the log message handler to the logger
handler = logging.handlers.RotatingFileHandler(
              LOG_FILENAME, maxBytes=2000000, backupCount=5)

# create formatter
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
# add formatter to ch
handler.setFormatter(formatter)
my_logger.addHandler(handler)


###############################
# Example for generating messages at various levels.
###############################

#my_logger.debug('This message should go to the log file')
#my_logger.info('This is an info message')
#my_logger.warning('This is a warning message')
#my_logger.error('This is an error message')
#my_logger.critical('This is a critical error message')




#################################
# Validate color values or use default if invalid values.
#################################

bg_tmp = background_color_str.split(',')
try:
  bg_values = [float(bg_tmp[0]), float(bg_tmp[1]) , float(bg_tmp[2]) , float(bg_tmp[3])]
except IndexError:
  my_logger.warning('Background color values are invalid, default background is used')
  bg_values = [1.0,1.0,1.0,1.0]
  


###################################################
#
# Load tge XML file.
#
###################################################


#inputXMLfile = getXMLfile()
#if inputXMLfile == None:
#  msgbox("Invalid xml file ,.... application will terminante")
#  sys.exit(1)



####################################################
## DISPLAY ##
####################################################


# Initialize OpenGL graphics screen.
screen = get_default_screen()

# Set the background color to white (RGBA).
#screen.parameters.bgcolor = (1.0,1.0,1.0,1.0)

screen.parameters.bgcolor = (bg_values[0],bg_values[1],bg_values[2],bg_values[3])
# make Fixation Cross texture
fixPt = FixationCross(position= (screen.size[0]/2,screen.size[1]/2),
                      size=(25,25), texture_size=(30,30))

# Intro instruction screen
introTexts = [Text( text = "You will be shown a block of images; look for target objects.", font_name=fname,font_size = fsize,
                  position = (screen.size[0]/2.0,screen.size[1]/2), anchor = 'center', color = (0.0,0.0,0.0,1.0))]

introTexts.append(Text( text = "At the end of each block, press the space bar to continue.", font_name=fname,font_size = fsize,
                  position = (screen.size[0]/2.0,screen.size[1]/2), anchor = 'center', color = (0.0,0.0,0.0,1.0)))


introTexts.append(Text( text = " When instructed, press 't' to finish training.", position = (screen.size[0]/2.0,screen.size[1]/2), font_name=fname,font_size = fsize,
                        anchor = 'center', color = (0.0,0.0,0.0,1.0)))

introTexts.append(Text( text = "Please press the space bar to start.", position = (screen.size[0]/2.0,screen.size[1]/2), font_name=fname,font_size = fsize,
                        anchor = 'center', color = (0.0,0.0,0.0,1.0)))


# Please wait screen
pleaseWait = Text( text = "Please Wait.", position = (screen.size[0]/2.0,screen.size[1]/2), font_name=fname,font_size = fsize,
                   anchor = 'center', color = (0.0,0.0,0.0,1.0))




####################
## EVENT HANDLERS ##
####################

def keydown(event):
    global doingTraining
    global ctrl_key
    if event.key == pygame.locals.K_ESCAPE:
        if not(internalState == 1):
            response = confirmMessage('Are you sure you want to quit the program without training?')
            if (response == 1):
              # Escape valid only if program in not in the RSVP state
              quit(event)
              sys.exit(1)
            else :
              SDL_Maximize()
    elif event.key == pygame.locals.K_RIGHT:
        right = 1
    elif event.key == pygame.locals.K_LEFT:
        left = 1
    elif event.key == pygame.locals.K_SPACE:
        if not(internalState ==1):
          space = 1
          quit(event)
    elif ((event.key == pygame.locals.K_t) and (ctrl_key==1)):
        doingTraining = 1;
        if (internalState == 0):
           p.parameters.go_duration = (0,'frames')
           quit(event)
    elif ((event.key == pygame.locals.K_s) and (ctrl_key==1)):
        doingTraining = 2;
        p.parameters.go_duration = (0,'frames')
        quit(event)
    elif event.key == pygame.locals.K_RCTRL:     
        ctrl_key = 1
    
       
        
def keyup(event):
    global left, right, space, textstate, ctrl_key
    if event.key == pygame.locals.K_RIGHT:
        if (internalState == 2):
          textstate = textstate + 1
          if textstate < len(introTexts):
              viewport.parameters.stimuli=[introTexts[textstate]]
          else:
              p.parameters.go_duration = (0,'frames')
          #viewport.parameters.stimuli=[pleaseWait]
          right = 0
    elif event.key == pygame.locals.K_LEFT:
        left = 0
    elif event.key == pygame.locals.K_SPACE:
        space = 0
        #sys.exit(1)
    elif event.key == pygame.locals.K_RCTRL:     
        ctrl_key = 0
    


def quit(event):
    p.parameters.go_duration = (0,'frames')



def every_frame_func(t=None):
    global imageCounter
    global previous_t    # keeps the value of the previous time shown
    global numImsPerBlock
    
    temp = int((t-previous_t) * presentationFreq)
    
    if temp >= 1: # get next image
        if (imageCounter==numImsPerBlock):
           p.parameters.go_duration = (0,'frames')
           return 
        idx = imageCounter
        imageCounter = imageCounter + 1    #imageCounter = temp (original code)
        # trigger to parallel port w/new image ID (target or nontarget)
        time.sleep(0.003)
    
        texture_object.put_sub_image(curImList[idx] )
        previous_t = t
 # first block images


#####################
## RUNTIME CONTROL ##
#####################

count = 0

while (count<1):
    # Create a Viewport instance (initialized just to display instructions)
    viewport = Viewport(screen=screen, stimuli=[introTexts[count]])


    # Create an instance of the Presentation class.  (Runtime control)
    p = Presentation(go_duration=('forever',), viewports=[viewport])


    # Register Event Handlers
    p.parameters.handle_event_callbacks = \
        [(pygame.locals.QUIT, quit), (pygame.locals.KEYDOWN, keydown), (pygame.locals.KEYUP, keyup)]

    count = count + 1



#
# Script to show only example from targets.
#

def showTargets(viewport):
 global imageCounter
 global previous_t
 global numImsPerBlock
 global texture_object
 global curImList
 global presentationFreq    # use/update the global value for presetnation frequency
 global doingTraining
 global ctrl_key

 ctrl_key = 0
 doingTraining = 0

 Pfreq_default = presentationFreq

 
 SDL_Maximize()
                
 #
 # Show instructures
 #

 sttext = "You will be shown examples of target images... press space bar"
 statisticsText = Text( text = sttext, position = (screen.size[0]/2.0,screen.size[1]/2), font_name=fname,font_size = fsize,
                      anchor = 'center', color = (0.0,0.0,0.0,1.0))
      
   
 p.parameters.go_duration = ('forever',)
 viewport.parameters.stimuli=[statisticsText]
 p.go()

 
 while (1):
   imageCounter = 0
   previous_t = 0;
   block_idx = 0
   numTargets = 20
   numNontargets = 0
   presentationFreq = 5   # show 1 target every second to familiarize the user with the target set.
   
   
   # Load training block
#   curList = sampleTrainImages(trainPath,numTargets,numNontargets,alreadySampled,withreplacement)

   if (input_from == 1):
     curList = sampleTrainImages(trainPath,numTargets,numNontargets,alreadySampled,withreplacement)
   elif (input_from == 2):
     curList = sampleTrainImagesXML(inputXMLfile,numTargets,numNontargets)
   else:
     msgbox('The input type specified is invalid, check the value of input_from parameter in configuration.ini file.\n Terminating RSVP session.')  
     my_logger.error('The input type specified is invalid, check the value of input_from parameter in configuration.ini file.')
     break;

   curImList = map(operator.itemgetter(0),curList)
   curTargList = map(operator.itemgetter(1),curList)
   curImPath = map(operator.itemgetter(2),curList)
   curImName = map(operator.itemgetter(3),curList)
   numImsPerBlock = len(curImList)
   
   # fixation cross
   p.parameters.go_duration = (1,'seconds')
   viewport.parameters.stimuli=[fixPt]

   p.go()

   imageStim = TextureStimulus(texture=imageTex,
                               position = (screen.size[0]/2.0,screen.size[1]/2.0),
                               anchor='center', size=(width*scale,height*scale),
                               mipmaps_enabled = 0, texture_min_filter=gl.GL_LINEAR)

   texture_object = imageStim.parameters.texture.get_texture_object()
   texture_object.put_sub_image( curImList[0] )
   p.add_controller(None, None, FunctionController(during_go_func=every_frame_func) )
   p.parameters.go_duration = (2*(numImsPerBlock+1)/float(presentationFreq),'seconds')
   viewport.parameters.stimuli=[imageStim]
   p.go();
   block_idx = block_idx + 1



   # fixation cross
   p.parameters.go_duration = (2,'seconds')
   p.controllers = []
   viewport.parameters.stimuli=[fixPt]
   p.go()

   #
   # Show instructures
   #
   
   response = ynbox(msg='Would you like to see these targets again?', title=' ', choices=('No', 'Yes'), image=None) # default No
   
   SDL_Maximize()
   
   if (response == 1):
     presentationFreq = Pfreq_default 
     break




#
# Script to show only example from targets.
#

def showRSVP(viewport):
 global imageCounter
 global previous_t
 global numImsPerBlock
 global texture_object
 global curImList
 global numTargets
 global numNontargets
 global presentationFreq
 global doingTraining
 global ctrl_key

 doingTraining = 0

 #
 # Load the parameters for the presentation
 #

 presentationParams = getPracticeSessionParams()

 SDL_Maximize()

 presentationFreq = int(presentationParams[0])


 block_idx = 0
 ctrl_key = 0 
 while (1):
   internalState = 0  # here we are the block state
   
   if (doingTraining==1):
      presentationParams = getPracticeSessionParams()
      presentationFreq = int(presentationParams[0])
      SDL_Maximize()

      doingTraining = 0
   elif (doingTraining==2):
      break     
       

   imageCounter = 0
   internalState = 1  # About to enter the presentation mode.

   previous_t = 0;
      
   # Load training block
   
   if (input_from == 1):
     curList = sampleTrainImages(trainPath,numTargets,numNontargets,alreadySampled,withreplacement)
   elif (input_from == 2):
     print "loading XML"
     curList = sampleTrainImagesXML(inputXMLfile,numTargets,numNontargets)
   else:
     msgbox('The input type specified is invalid, check the value of input_from parameter in configuration.ini file.\n Terminating RSVP session.')  
     my_logger.error('The input type specified is invalid, check the value of input_from parameter in configuration.ini file.')
     break;
   curImList = map(operator.itemgetter(0),curList)
   curTargList = map(operator.itemgetter(1),curList)
   curImPath = map(operator.itemgetter(2),curList)
   curImName = map(operator.itemgetter(3),curList)
   numImsPerBlock = len(curImList)

   # fixation cross
   p.parameters.go_duration = (1,'seconds')
   viewport.parameters.stimuli=[fixPt]

   p.go()

   imageStim = TextureStimulus(texture=imageTex,
                               position = (screen.size[0]/2.0,screen.size[1]/2.0),
                               anchor='center', size=(width*scale,height*scale),
                               mipmaps_enabled = 0, texture_min_filter=gl.GL_LINEAR)

   texture_object = imageStim.parameters.texture.get_texture_object()
   texture_object.put_sub_image( curImList[0] )
   p.add_controller(None, None, FunctionController(during_go_func=every_frame_func) )
   #p.parameters.go_duration = ((numImsPerBlock+1)/float(presentationFreq),'seconds')
   p.parameters.go_duration = (2*(numImsPerBlock+1)/float(presentationFreq),'seconds')
   viewport.parameters.stimuli=[imageStim]
   p.go();
   block_idx = block_idx + 1

   internalState = 0  # here we are the block state


   # fixation cross
   p.parameters.go_duration = (1,'seconds')
   p.controllers = []
   viewport.parameters.stimuli=[fixPt]
   p.go()

   # please wait (while we get results)
   p.parameters.go_duration = (1,'frames')
   p.controllers = []
   viewport.parameters.stimuli=[pleaseWait]
   p.go()

 

   totElements = len(curImName)
   curImNamePrefixed = [('_' + str(eventList[curTargList[i]]) + '_' + curImName[i]) for i in range(totElements)]

   # get the data strucute to be able to show potential feedback during evaluation methodology.

   dataStruct = simulateCBCIoutput(block_idx,curTargList,curImPath,curImName)
   
      
   # Call to the external feedback screen
   status = show_feedback(screen,viewport,dataStruct,curTargList)

   if (status == 1):
     #
     # Show custom feedback screen
     #
     p.parameters.go_duration = ('forever',)
     p.go()
   else:
     
     #
     # Show default feedback.
     #

     #print reslist
     sttext = "Blocks shown: " + str(block_idx)
     statisticsText = Text( text = sttext, position = (screen.size[0]/2.0,screen.size[1]/2), font_name=fname,font_size = fsize,
                        anchor = 'center', color = (0.0,0.0,0.0,1.0))

     p.parameters.go_duration = ('forever',)
     viewport.parameters.stimuli=[statisticsText]
     p.go()
   
   





#####################################################################
## Here the intro text is complete, entering the image block loop   ##
#####################################################################

block_idx = 0

#imageTex = Texture('white.jpg') # To be made generic
try:
  if (input_from == 1):
    imageTex = getImageSize(trainPath)
  elif (input_from == 2):
    imageTex = getImageSizeXML(inputXMLfile)
  width, height = imageTex.size
except AttributeError:
    msgbox("Error: No images availabe, or invalid input Train path, \n " + trainPath + " \n\n Make sure the configuration.ini file points to a valid Training path \n \n A valid Training Path should:\n \n 1) Include a sub-folder called 'targetpool'\n 2) Include a sub-folder called 'nontargetpool' \n 3) Both sub-folders include ONLY image files.\n\n\n Application will terminate", title='Error: No or invalid image files')
    sys.exit()

scale_x = screen.size[0]/float(width)
scale_y = screen.size[1]/float(height)
scale = min(scale_x,scale_y)
scale = 1


#
# Main Event loop
# 

while (1):

   response =  buttonbox(msg='Choose the type of familarization mode to exectute.', title='RSVP Practive Module - Main Menu', choices=('Target Familarization', 'RSVP Familarization', 'Exit'), image=None)
   if (response == 'Target Familarization'):
     #
     # Show only targets
     #
     showTargets(viewport)
   elif (response == 'RSVP Familarization'):

     #
     # Show RSVP presentation.
     #
     showRSVP(viewport)
   else:
     #
     # Break
     #
     break

   


