
    
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
from ConfigParser import *
from socket import *
import operator
from random import *
import time
import ResultsDatabaseXML
from ctypes import windll


user32      = windll.user32
ShowWindow  = user32.ShowWindow
IsZoomed    = user32.IsZoomed


DEFAULT_STAND_ALONE = 1      # Default do not run as standalone.
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



VisionEgg.config.VISIONEGG_GUI_INIT = 1

if (len(sys.argv)> 1):
  configFile = sys.argv[1]
else:
  configFile = 'configuration.ini'


#########################################################
## User specified parameters
#########################################################

# The classic way:
cp = SafeConfigParser()
#cp.read('configuration.ini')
cp.read(configFile)

trainPath = cp.get('RSVPtrainUserSpecifiedParams','trainPath')
inputXMLfile = cp.get('RSVPtrainUserSpecifiedParams','trainXMLfile')
outputPath = cp.get('RSVPtrainUserSpecifiedParams','outputPath')
try:
 outputXMLfile = cp.get('RSVPtrainUserSpecifiedParams','outputXMLfile')
except (NoOptionError):
 outputXMLfile = 'xml_RSVPoutput_RENAME_ME.xml'
try:
  stOption = int(cp.get('RSVPtrainUserSpecifiedParams','run_as_standalone'))
except NoOptionError:
  stOption = DEFAULT_STAND_ALONE 

numTargets = int(cp.get('RSVPtrainUserSpecifiedParams','numTargets'))
numNontargets =  int(cp.get('RSVPtrainUserSpecifiedParams','numNontargets'))
alreadySampled = []  # Reserved for future use
presentationFreq = int(cp.get('RSVPtrainUserSpecifiedParams','presentationFreq'))
simulationMode = int(cp.get('RSVPtrainUserSpecifiedParams','simulationMode'))
monitorFrequency = int(cp.get('RSVPtrainUserSpecifiedParams','monitorFrequency'))
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
  





###############################################
# Set to one to avoid the need to communicate with any other server. Overrides TCPIP called / or control.
###############################################

run_as_standalone = stOption;

if not(monitorFrequency == 0):
  debug_list = []    # create an empty list to hold various values to debug.
  delayParams = (0, 0.0000)   # to be used for delay injections, only valid if monitorFrequency ==  2

##########################################################
# Establish connection with the CBCI engine via TCPIP
##########################################################

HOST = '127.0.0.1'
PORT = 4444
BUFSIZ = 4096
ADDR = (HOST, PORT)
if (run_as_standalone == 0):
    tcpCliSock = connectTCPIP(HOST,PORT,BUFSIZ)


#pygame.font.init()
#myfont = pygame.font.Font('freesansbold.ttf',40)

fname="freesansbold.ttf"
fsize = 20;





####################################################
## DISPLAY ##
####################################################


# Initialize OpenGL graphics screen.
screen = get_default_screen()

# Set the background color to white (RGBA).
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
    if event.key == pygame.locals.K_ESCAPE:
        if not(internalState == 1):
            response = confirmMessage('Are you sure you want to quit the program without training?')
            if (response == 1):
              # Escape valid only if program in not in the RSVP state
              if (simulationMode == 1):
                 tcpCliSock.send("stop\n")
              quit(event)
              sys.exit(1)
            else:
              SDL_Maximize()
    elif event.key == pygame.locals.K_RIGHT:
        right = 1
    elif event.key == pygame.locals.K_LEFT:
        left = 1
        sendCommand(doTrain,0)
    elif event.key == pygame.locals.K_SPACE:
      if not(internalState ==1):
        space = 1
        quit(event)  # disable effect of space when program is running
    elif event.key == pygame.locals.K_t:
        doingTraining = 1
        if (internalState == 0):
           quit(event) # 

        
def keyup(event):
    global left, right, space, textstate
    if event.key == pygame.locals.K_RIGHT:
      if (internalState == 2):
         # Right click active only at the instructions state
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


def quit(event):
    p.parameters.go_duration = (0,'frames')




####################################################################
# what to do each frame (i.e. check whether to change image, send parallel trigger)
####################################################################



# OPEN IO PORTS
#ser = serial.Serial(serAddress, timeout=serTimeout)
if (run_as_standalone == 0):
   par = parallel.Parallel()
   par.setData(0)


def sendCommand(cmd,ref=0):
  if (run_as_standalone == 0):
    par.setData(cmd)
    time.sleep(commandLength)
    par.setData(ref)



def every_frame_func(t=None):
    global imageCounter
    global previous_t    # keeps the value of the previous time shown

    t1 = time.time()    
    temp = int((t-previous_t) * presentationFreq)
    if (run_as_standalone == 0):
       par.setData(0)

    if temp >= 1: # get next image
        if (imageCounter==numImsPerBlock):
           p.parameters.go_duration = (0,'frames')
           return 
        idx = imageCounter
        imageCounter = imageCounter + 1    #imageCounter = temp (original code)
        # trigger to parallel port w/new image ID (target or nontarget)
        time.sleep(0.003)
        if (run_as_standalone == 0):
           par.setData(eventList[curTargList[idx]])
        t2 = time.time()
        texture_object.put_sub_image(curImList[idx] )
        if ((monitorFrequency == 2) and (delayParams[0]==idx)):
            time.sleep(delayParams[1])
            debug_list.append((t-previous_t,idx,delayParams[1]))
        elif not(monitorFrequency == 0):
           debug_list.append((t-previous_t,idx,''))

                    
        previous_t = t + t2 - t1
        
 # first block images


#####################
## RUNTIME CONTROL ##
#####################

count = 0

while (count<3):
    # Create a Viewport instance (initialized just to display instructions)
    viewport = Viewport(screen=screen, stimuli=[introTexts[count]])


    # Create an instance of the Presentation class.  (Runtime control)
    p = Presentation(go_duration=('forever',), viewports=[viewport])


    # Register Event Handlers
    p.parameters.handle_event_callbacks = \
        [(pygame.locals.QUIT, quit), (pygame.locals.KEYDOWN, keydown), (pygame.locals.KEYUP, keyup)]

    p.go()

    count = count+1

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
    
    
#width, height = getImageSize(trainPath)
# image scale factors
scale_x = screen.size[0]/float(width)
scale_y = screen.size[1]/float(height)
scale = min(scale_x,scale_y)
scale = 1

# Define a results object.

if (input_from == 2):
   resDB = ResultsDatabaseXML.ResultsDatabaseXML(inputXMLfile)


# initialize the BCI engine to enter the training mode
sendCommand(trainModeStart,0)

while (1):
   internalState = 0  # here we are the block state
   
   # if doing training requested wait for session
   if (doingTraining==1):
       sendCommand(doTrain,0)
       # please wait (while we get results)
       p.parameters.go_duration = (1,'frames')
       p.controllers = []
       sttext = "Please wait while classifier is being trained."
       trainingText = Text( text = sttext, position = (screen.size[0]/2.0,screen.size[1]/2), font_name=fname,font_size = fsize,
                   anchor = 'center', color = (0.0,0.0,0.0,1.0))

       viewport.parameters.stimuli=[trainingText]
       p.go()
       if (run_as_standalone == 0):
          sessionId = tcpCliSock.recv(4096)
       else:
          sessionId = "SessionId R.K.I test"
       doingTraining = 0
       break




   imageCounter = 0
   internalState = 1  # About to enter the presentation mode.

   previous_t = 0;

   
   # Load training block
   #curList = sampleTrainImages(trainPath,numTargets,numNontargets,alreadySampled,withreplacement)
   if (input_from == 1):
     curList = sampleTrainImages(trainPath,numTargets,numNontargets,alreadySampled,withreplacement)
   elif (input_from == 2):
     curList = sampleTrainImagesXML(inputXMLfile,numTargets,numNontargets)
     curIDList =  map(operator.itemgetter(5),curList)
   else:
     msgbox('The input type specified is invalid, check the value of input_from parameter in configuration.ini file.\n Terminating RSVP session.')  
     my_logger.error('The input type specified is invalid, check the value of input_from parameter in configuration.ini file.')
     break;
   
   curImList = map(operator.itemgetter(0),curList)
   curTargList = map(operator.itemgetter(1),curList)
   curImPath = map(operator.itemgetter(2),curList)
   curImName = map(operator.itemgetter(3),curList)
   numImsPerBlock = len(curImList)


   if (monitorFrequency == 2):
      delayParams = (randint(0,numImsPerBlock-1), random()*2) # delay up to half a second for a sinlge image in a block

   # fixation cross
   p.parameters.go_duration = (1,'seconds')
   viewport.parameters.stimuli=[fixPt]

   # indicate begining of a block
   sendCommand(beginBlock,0)
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
   if (run_as_standalone == 0):
      par.setData(0)
   block_idx = block_idx + 1


   # indigate the results
   sendCommand(endBlock,0)

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

   # request the results from the engine
   time.sleep(0.010)
   sendCommand(getBlockResults,0)


   
   #####################################################
   # write code to communicate via TCP/IP connection
   # (or UDP decide later on.) to the BCI server.
   #####################################################

   if (run_as_standalone == 0):
      if (simulationMode == 1):
          tcpCliSock.send("GetResults\n")
          tcpCliSock.send( str(len(curImName)) + "\n")
      data = tcpCliSock.recv(4096)
   else:
      data = ""   # we don't care about this data, just to test the code. 
   totElements = len(curImName)
   curImNamePrefixed = [('_' + str(eventList[curTargList[i]]) + '_' + curImName[i]) for i in range(totElements)]


   if (run_as_standalone == 0):
      dataStruct = processCBCIoutput(data,curImPath,curImNamePrefixed)
   else:
      dataStruct = simulateCBCIoutput(block_idx,curTargList,curImPath,curImName)

   if (input_from == 1):
      output2file(outputPath,block_idx,dataStruct)


   reslist = getblockStatistics(dataStruct,curTargList)
   #else:
   #   reslist = ((-1,-1),(-1,-1))
      
   # wait for user

   #print reslist
   sttext = "Blocks shown: " + str(block_idx)
   statisticsText = Text( text = sttext, position = (screen.size[0]/2.0,screen.size[1]/2), font_name=fname,font_size = fsize,
                     anchor = 'center', color = (0.0,0.0,0.0,1.0))
  
   # strtext2 = "Pre: " + str(reslist[0][0]) + "  Post: " + str(reslist[0][1])
   # statisticsText2 = Text( text = strtext2, position = (screen.size[0]/2.0,screen.size[1]/2+100), font_name=fname,font_size = fsize,
   #                   anchor = 'center', color = (0.0,0.0,0.0,1.0))
   # strtext3 = "Pre: " + str(reslist[1][0]) + "  Post: " + str(reslist[1][1])
   #
   # statisticsText3 = Text( text = strtext3, position = (screen.size[0]/2.0,screen.size[1]/2+50), font_name=fname,font_size = fsize,
   #                  anchor = 'center', color = (0.0,0.0,0.0,1.0))

      
   if (input_from == 2):
      rlist = [];
      for elem in range(len(dataStruct)):
        res = dataStruct[elem][2].rsplit()
        rlist.append(res[2])
      resDB.addResults(curIDList,rlist)
      resDB.toXML(outputXMLfile)

   if not(monitorFrequency == 0):
       log_monitorFrequency(debug_list)   
       debug_list = []
   # Call to the external feedback screen
   status =  show_feedback(screen,viewport,dataStruct,curTargList)

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
     
     p.parameters.go_duration = ('forever',)
     viewport.parameters.stimuli=[statisticsText, statisticsText2 , statisticsText3]
     p.go()
   
       
       
sendCommand(doEndSession,0)

if (run_as_standalone == 0):
   tcpCliSock.close()

# Terminate Session show session id
p.parameters.go_duration = ('forever',)
sttext = "Session Id: " + str(sessionId)
trainingText = Text( text = sttext, position = (screen.size[0]/2.0,screen.size[1]/2), font_name=fname, font_size=fsize,
                   anchor = 'center', color = (0.0,0.0,0.0,1.0))

viewport.parameters.stimuli=[trainingText]
p.go()

  
#############################################
#
# Request training of data
#
#############################################    
    






