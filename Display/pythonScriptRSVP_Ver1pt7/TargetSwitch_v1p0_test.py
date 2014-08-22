############################
## Import various modules ##
############################

import os, os.path, sys, time, parallel
import VisionEgg, pygame
from VisionEgg.Core import *
from VisionEgg.Text import *
from VisionEgg.Textures import *
from VisionEgg.FlowControl import Presentation, FunctionController
import RSVPutilities
import types
from   RSVPutilities import *
from ConfigParser import SafeConfigParser
from ConfigParser import *
from socket import *
import operator
from ctypes import windll
from random import *
import ResultsDatabaseXML
from shutil import *

VisionEgg.config.VISIONEGG_GUI_INIT = 0

###########################################
# Quick fix to minimize maximize windows
###########################################
user32      = windll.user32
ShowWindow  = user32.ShowWindow
IsZoomed    = user32.IsZoomed

DEFAULT_STAND_ALONE = 0      # Default do not run as standalone.
DEFAULT_USE_ORDERING = 0     # Default do not use predefined ordering.
DEFAULT_NBLOCKS = 5 # Default is 5 blocks per session. 

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


testPath = cp.get('RSVPtestUserSpecifiedParams','testPath')
numTargets = int(cp.get('RSVPtestUserSpecifiedParams','numTargets'))
numNontargets =  int(cp.get('RSVPtestUserSpecifiedParams','numNontargets'))
trainPath = cp.get('RSVPtrainUserSpecifiedParams','trainPath')
outputPath = cp.get('RSVPtestUserSpecifiedParams','outputPath')
# DJ made this substitution 4/24/12: build up subject/session-specific filename later
#try:
#  outputXMLfile = cp.get('RSVPtestUserSpecifiedParams','outputXMLfile')  
#except NoOptionError:
#  outputXMLfile = 'xml_RSVPoutput_RENAME_ME.xml'
experimentName = cp.get('RSVPtestUserSpecifiedParams','experimentName')
nBlocks = int(cp.get('RSVPtestUserSpecifiedParams','numBlocks'))

# DJ addition 4/24/12: categories in database
categoryString = cp.get('RSVPtestUserSpecifiedParams','categories'); 
categories = categoryString.split(',');
timeBetweenBlocks = int(cp.get('RSVPtestUserSpecifiedParams','timeBetweenBlocks')); 


try:
  stOption = int(cp.get('RSVPtrainUserSpecifiedParams','run_as_standalone'))
except NoOptionError:
  stOption = DEFAULT_STAND_ALONE
  
try:
  poOption = int(cp.get('RSVPtrainUserSpecifiedParams','use_predefined_ordering'))
except NoOptionError:
  poOption = DEFAULT_USE_ORDERING


presentationFreq = int(cp.get('RSVPtrainUserSpecifiedParams','presentationFreq'))
simulationMode = int(cp.get('RSVPtrainUserSpecifiedParams','simulationMode'))
monitorFrequency = int(cp.get('RSVPtrainUserSpecifiedParams','monitorFrequency')) # typically 0: no delays inserted
logfilename = cp.get('LOG','logfile')
loglevel = cp.get('LOG','loglevel')

# Get and process background color values 
background_color_str= cp.get('RSVPglobalParams','background_color')
input_from = int(cp.get('RSVPglobalParams','input_from')) # Typically 2: from an xml file


#sessionStr = cp.get('RSVPtestUserSpecifiedParams','sessionStr')
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
testTargetStimulus = int(cp.get('BCIengineCodes','testTarget'))
testNonTargetStimulus = int(cp.get('BCIengineCodes','testNonTarget'))
getBlockResults = int(cp.get('BCIengineCodes','getBlockResults'))
trainModeStart = int(cp.get('BCIengineCodes','trainModeStart'))
testModeStart = int(cp.get('BCIengineCodes','testModeStart'))
doTrain = int(cp.get('BCIengineCodes','doTrain'))
doEndSession = int(cp.get('BCIengineCodes','doEndSession'))
TCPIPattentionRequest = int(cp.get('BCIengineCodes','attention'))
eventList = [nonTargetcd, targetcd, unlabledStimulus, unlabeledStimulusOnline, testTargetStimulus, testNonTargetStimulus]
# in seconds, indicate the length of a parralel port signal
commandLength = 0.020 
textstate = 0   # Instructions text counter
internalState = 2   # 0 : Block state  1: RSVP state showing images 2: Instruction Instructions state.





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


#########################################
# OPEN IO PORTS
#########################################
#ser = serial.Serial(serAddress, timeout=serTimeout)

if (run_as_standalone == 0):
   par = parallel.Parallel()
   par.setData(0)


##########################################################
# Establish connection with the CBCI engine via TCPIP
##########################################################

HOST = '127.0.0.1'
PORT = 4444
BUFSIZ = 4096
ADDR = (HOST, PORT)
if (run_as_standalone == 0):
   tcpCliSock = connectTCPIP(HOST,PORT,BUFSIZ)

fname="freesansbold.ttf"
fsize = 20;

#################################
## DISPLAY ##
#################################

# Initialize OpenGL graphics screen.
screen = get_default_screen()

# Set the background color to white (RGBA).
screen.parameters.bgcolor = (bg_values[0],bg_values[1],bg_values[2],bg_values[3])

# make Fixation Cross texture
fixPt = FixationCross(position= (screen.size[0]/2,screen.size[1]/2),
                      size=(25,25), texture_size=(30,30))

# Intro instruction screen
introTexts = [Text( text = "In this experiment, you will see " + str(nBlocks) + " blocks of images", position = (screen.size[0]/2.0,screen.size[1]/2 + fsize), font_name=fname,font_size=fsize,
                        anchor = 'center', color = (0.0,0.0,0.0,1.0))]
introTexts_bottomline = [Text( text = "with short breaks in between.", position = (screen.size[0]/2.0,screen.size[1]/2 - fsize), font_name=fname,font_size=fsize,
                        anchor = 'center', color = (0.0,0.0,0.0,1.0))]

introTexts.append(Text( text = "During one of these breaks, there will be a TARGET SWITCH!", position = (screen.size[0]/2.0,screen.size[1]/2 + fsize), font_name=fname,font_size=fsize,
                        anchor = 'center', color = (0.0,0.0,0.0,1.0)))
introTexts_bottomline.append(Text( text = "and you'll be asked to look for a new category.", position = (screen.size[0]/2.0,screen.size[1]/2 - fsize), font_name=fname,font_size=fsize,
                        anchor = 'center', color = (0.0,0.0,0.0,1.0)))

introTexts.append(Text( text = "You don't need to press any buttons.", font_name=fname,font_size=fsize,
                  position = (screen.size[0]/2.0,screen.size[1]/2 + fsize), anchor = 'center', color = (0.0,0.0,0.0,1.0)))
introTexts_bottomline.append(Text( text = "Blocks will load automatically.", font_name=fname,font_size=fsize,
                  position = (screen.size[0]/2.0,screen.size[1]/2 - fsize), anchor = 'center', color = (0.0,0.0,0.0,1.0)))

introTexts.append(Text( text = "The first block is about to start.", font_name=fname,font_size=fsize,
                  position = (screen.size[0]/2.0,screen.size[1]/2 + fsize), anchor = 'center', color = (0.0,0.0,0.0,1.0)))
#introTexts_bottomline.append(Text( text = "On this block, look for TARGET objects.", font_name=fname,font_size=fsize,
#                  position = (screen.size[0]/2.0,screen.size[1]/2 - fsize), anchor = 'center', color = (0.0,0.0,0.0,1.0)))


# Please wait screen
pleaseWait = Text( text = "Please Wait.", position = (screen.size[0]/2.0,screen.size[1]/2), font_name=fname,font_size=fsize,
                   anchor = 'center', color = (0.0,0.0,0.0,1.0))


####################
## EVENT HANDLERS ##
####################

def keydown(event):
    if event.key == pygame.locals.K_ESCAPE:
         if not(internalState == 1):
            response = confirmMessage('Are you sure you want to quit the program without training?')
            if (response == 1):
               if (simulationMode == 1):
                  tcpCliSock.send("stop\n")
               else: # DJ addition, 4/24/12: End the TCPIP session neatly                 
                  sendCommand(doEndSession,0)
                  if (run_as_standalone == 0):
                      tcpCliSock.close()
               quit(event)
               sys.exit(1)
            else:
                SDL_Maximize()
    elif event.key == pygame.locals.K_RIGHT:
        right = 1
    elif event.key == pygame.locals.K_LEFT:
        left = 1
    elif event.key == pygame.locals.K_SPACE:
        if not(internalState == 1):
          space = 1
          quit(event)
        
def keyup(event):
    global left, right, space, textstate
    if event.key == pygame.locals.K_RIGHT:
        if (internalState == 2):
          textstate = textstate + 1
          if textstate < len(introTexts):
              viewport.parameters.stimuli=[introTexts[textstate], introTexts_bottomline[textstate]]
          else:
              p.parameters.go_duration = (0,'frames')
          #viewport.parameters.stimuli=[pleaseWait]
          right = 0
        elif (internalstate == 0): # DJ: added for block switch!
            textstate = textstate + 1
            if textstate < len(statisticsText):
                viewport.parameters.stimuli=[statisticsText[textstate], statisticsText_bottomline[textstate]]
            else:
                p.parameters.go_duration = (0,'frames')
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




def sendCommand(cmd,ref=0):
    if (run_as_standalone == 0):
       par.setData(cmd)
       time.sleep(commandLength)
       par.setData(ref)



def every_frame_func(t=None):
    global imageCounter
    global previous_t    # keeps the value of the previous time shown
    t1 = time.time()
    temp = int((t-previous_t) * presentationFreq) # The number of image periods that have elapsed
    if (run_as_standalone == 0):
       par.setData(0)
    if temp >= 1: # get next image
        if (imageCounter==numImsPerBlock):
           p.parameters.go_duration = (0,'frames')
           return 
        idx = imageCounter
        imageCounter = imageCounter  + 1
        # trigger to parallel port w/new image ID (target or nontarget)
        
        time.sleep(.001)
        if (run_as_standalone == 0):
           par.setData(eventList[curTargList[idx]])

        t2 = time.time()   
#       par.setData(idx+1)
        texture_object.put_sub_image(curImList[idx] )
        if ((monitorFrequency == 2) and (delayParams[0]==idx)):
            time.sleep(delayParams[1])
            debug_list.append((t-previous_t,idx,delayParams[1]))
        elif not(monitorFrequency == 0):
           debug_list.append((t-previous_t,idx,''))

        previous_t = t + t2 - t1
        
 # first block images




#################################################
## load the session/classifier information 
#################################################


if (run_as_standalone == 0):
   sessionId = '_cbci_'  
      
   while (1):
    sessionId = requestSessionId(sessionId)
    sendCommand(testModeStart,0)
    tcpCliSock.send(sessionId + '\n')
    response = tcpCliSock.recv(4096)
    if (len(response) < 8):
       break
    else:
       msgbox(response,title="Error....",ok_button="OK")

# DJ addition 4/24/12: get info for this session
while (1):
   # Get session info from user input
   session_info = requestInfo("Session Info","Enter session info",["Subject:","Session:"],["",""]);
   subject = int(session_info[0]);
   session = int(session_info[1]);
   # Get input and output xml files
   try:
      inputXMLfile = cp.get('RSVPtestUserSpecifiedParams','testXMLfile')
   except NoOptionError:
      inputXMLpath = cp.get('RSVPtestUserSpecifiedParams','testXMLpath')
      inputXMLfile = inputXMLpath + '/' + experimentName + '-' + str(subject) + '-' + str(session) + '.xml'
   outputXMLfile = outputPath + '/' + experimentName + '-' + str(subject) + '-' + str(session) + '.xml'

   # Write/read session parameters to/from subject-specific ini file   
   filename = outputPath + '/' + experimentName + '-' + str(subject) + '.ini'
   if (session==1): # for first session, write a file with a randomly defined category order      
      f = open(filename,'w')
      f.write('; Parameters for Subject ' + str(subject) + '\n')
      f.write('[SessionParameters]\n')
      category_order = range(len(categories))
      shuffle(category_order) # random permutation
      categories_ordered = [categories[i] for i in category_order] # reshuffle categories
      categories_ordered.append(categories_ordered[0]) # circle back around to first category at the end
      for i in range(0,len(categories_ordered)-1):
         infostr = 'session_' + str(i+1) + '_startcategory: ' + categories_ordered[i] + '\n'
         f.write(infostr)
         infostr = 'session_' + str(i+1) + '_switchblock: ' + str(randint(2,nBlocks)) + '\n'
         f.write(infostr)
         infostr = 'session_' + str(i+1) + '_endcategory: ' + categories_ordered[i+1] + '\n'
         f.write(infostr)   
      f.close()      
   # for later sessions, read in start category, end category, and switch block
   info = SafeConfigParser()
   info.read(filename)
   start_category = info.get('SessionParameters','session_' + str(session) + '_startcategory')
   switch_block = int(info.get('SessionParameters','session_' + str(session) + '_switchblock'))
   end_category = info.get('SessionParameters','session_' + str(session) + '_endcategory')
   
      
   if (switch_block>0):
      break
   #category_info = requestInfo("Start category","Enter target categories",["Start Category:","End Category:","Switch before block:"],["car_side","laptop","2"])
   #start_category = category_info[0]
   #end_category = category_info[1]
   #switch_block = int(category_info[2])
   #if (switch_block < 6):
       #break
        
SDL_Maximize()


# DJ moved this here 4/24/12 so start_category is defined.
# Intro instruction screen
introTexts_bottomline.append(Text( text = "On this block, look for " + start_category + " objects.", font_name=fname,font_size=fsize,
                  position = (screen.size[0]/2.0,screen.size[1]/2 - fsize), anchor = 'center', color = (0.0,0.0,0.0,1.0)))


#####################
## RUNTIME CONTROL ##
#####################


count = 0

while (count<len(introTexts)): # DJ CHANGE 4/23/12
    # Create a Viewport instance (initialized just to display instructions)
    viewport = Viewport(screen=screen, stimuli=[introTexts[count], introTexts_bottomline[count]])

    # Create an instance of the Presentation class.  (Runtime control)
    # note that timeBetweenBlocks/2 is used here to match the time of each between-block frame.
    p = Presentation(go_duration=(timeBetweenBlocks/2,'seconds'), viewports=[viewport])

    # Register Event Handlers so we can speed things up or quit early if we need to
    p.parameters.handle_event_callbacks = \
        [(pygame.locals.QUIT, quit), (pygame.locals.KEYDOWN, keydown), (pygame.locals.KEYUP, keyup)]

    p.between_presentations()
    p.go()

    count = count+1

#####################################################################
## Here the intro text is complete, entering the image block loop   ##
#####################################################################






#imageTex = Texture('white.jpg') # To be made generic

try:
   if (input_from == 1):
      imageTex = getTestImageSize(testPath)
   elif (input_from == 2):
      imageTex = getImageSizeXML(inputXMLfile)

   width, height = imageTex.size
except AttributeError:
    msgbox("Error: No images availabe in the input Testing path, \n " + testPath + " \n\n Make sure the configuration.ini file points to a valid Testing Path. \n \n A valid Testing Path should:\n \n 1) Include a sub-folder called '__block_1' \n 2) Include sub-folders called '__block_X, one for each additional test block, where X is the block number (i.e __block_2)'\n 3) Each such sub-folder include ONLY image files.\n\n\n Application will terminate", title='Error: No or invalid image files') 
    sys.exit()

# image scale factors
scale_x = screen.size[0]/float(width)
scale_y = screen.size[1]/float(height)
scale = min(scale_x,scale_y)
scale = 1


# request TCP/IP attention
#sendCommand(TCPIPattentionRequest)
#tcpCliSock.send("classifierSession\n");


# initialize the BCI engine to enter the testing mode




# Define a results object.

if (input_from == 2):
   resDB = ResultsDatabaseXML.ResultsDatabaseXML(inputXMLfile)

###############################
##    MAIN DISPLAY LOOP!     ##
###############################

block_idx = 1

while (block_idx<=nBlocks):   
   internalState = 1
   imageCounter = 0
   previous_t = 0
   # Load test block
   if (input_from == 1):
     curList = loadBlockImages(testPath,block_idx)
   else:
     if (poOption==1):
       curList = sampleByExactSequence(inputXMLfile,numTargets+numNontargets,block_idx)
     else: 
       curList = sampleTestImagesXML(inputXMLfile,numTargets,numNontargets,block_idx)
   
   if type(curList) is types.NoneType:
       print "End of available blocks"
       break
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
   #   par.setData(fixationOnOffTrig)   
#   time.sleep(.001)

   # indicate begining of a block
   sendCommand(beginBlock,0)
   p.go()

   #par.setData(fixationOnOffTrig)
   #time.sleep(.001)

   imageStim = TextureStimulus(texture=imageTex,
                               position = (screen.size[0]/2.0,screen.size[1]/2.0),
                               anchor='center', size=(width*scale,height*scale),
                               mipmaps_enabled = 0, texture_min_filter=gl.GL_LINEAR)

   texture_object = imageStim.parameters.texture.get_texture_object()
              
   texture_object.put_sub_image( curImList[0] )
   p.add_controller(None, None, FunctionController(during_go_func=every_frame_func) )
#   p.parameters.go_duration = ((numImsPerBlock + 1)/float(presentationFreq),'seconds')
   p.parameters.go_duration = (3*(numImsPerBlock + 1)/float(presentationFreq),'seconds') # DJ: Why *3?
   viewport.parameters.stimuli=[imageStim]
   p.go();
   if (run_as_standalone == 0):
      par.setData(0)

   # indicate the results
   sendCommand(endBlock,0)
   internalState = 0

   # fixation cross
   p.parameters.go_duration = (1,'seconds')
   p.controllers = []
   viewport.parameters.stimuli=[fixPt]

   # indicate begining of a block, commented out to avoid double block starts ba
   #   sendCommand(beginBlock,0)
   #  p.go()

   # please wait (while we get results)
   p.parameters.go_duration = (1,'frames')
   p.controllers = []
   viewport.parameters.stimuli=[pleaseWait]
   p.go()

   # DJ: Do we need to process the output at all?
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


   if (run_as_standalone == 0):
      dataStruct = processCBCIoutput(data,curImPath,curImName)
   else:
      dataStruct = simulateCBCIoutput(block_idx,curTargList,curImPath,curImName)

   if (input_from == 1):
      output2file(outputPath,block_idx,dataStruct)



 #     dataStruct = processCBCIoutput(data,curImPath,curImName)
 #     output2file(outputPath,block_idx,dataStruct)


   # wait for user
   statisticsText = []
   statisticsText_bottomline = []
   timeLeft = timeBetweenBlocks
   while (timeLeft>0):
      # Set top line of text (target category info)
      if timeLeft>(timeBetweenBlocks/2):
         sttext = "You have completed " + str(block_idx) + " blocks!"
      elif (block_idx+1 > nBlocks): # Display target cateogory or target switch
         sttext = "You've finished this session. Take a break!"            
      elif (block_idx+1 < switch_block):
         sttext = "Continue looking for " + start_category + " images."
      elif (block_idx+1 == switch_block):
         sttext = "TARGET SWITCH!  Now look for " + end_category + " images."     
      elif (block_idx+1 > switch_block):
         sttext = "Continue looking for " + end_category + " images."
      statisticsText.append(Text( text = sttext, position = (screen.size[0]/2.0,screen.size[1]/2 + fsize), font_name=fname,font_size=fsize,
                   anchor = 'center', color = (0.0,0.0,0.0,1.0)))
      # Set bottom line of text (countdown)
      if (timeLeft==1):
         sttext_bottomline = "You have " + str(timeLeft) + " second until the next block."
      else:
         sttext_bottomline = "You have " + str(timeLeft) + " seconds until the next block."
      statisticsText_bottomline.append(Text( text = sttext_bottomline, position = (screen.size[0]/2.0,screen.size[1]/2 - fsize), font_name=fname,font_size=fsize,
                   anchor = 'center', color = (0.0,0.0,0.0,1.0)))
      # Decrement time left
      timeLeft = timeLeft - 1
      
   
   # Handle the case when we output data to XML file.

   if (input_from == 2):
      rlist = [];
      for elem in range(len(dataStruct)):
        res = dataStruct[elem][2].rsplit()
        rlist.append(res[2])
    
      resDB.addResults(curImName,rlist)
      resDB.toXML(outputXMLfile)



   if not(monitorFrequency == 0):
       log_monitorFrequency(debug_list)   
       debug_list = []
 
   count = 0

   while (count<len(statisticsText)): # DJ CHANGE 4/23/12
      # Create a Viewport instance (initialized just to display instructions)
      viewport.parameters.stimuli=[statisticsText[count], statisticsText_bottomline[count]]

      # Create an instance of the Presentation class.  (Runtime control)
      #p.parameters.go_duration=('forever',)
      p.parameters.go_duration=(1,'seconds')
      
      # Register Event Handlers
      p.parameters.handle_event_callbacks = \
            [(pygame.locals.QUIT, quit), (pygame.locals.KEYDOWN, keydown), (pygame.locals.KEYUP, keyup)]

      p.between_presentations()
      p.go()

      count = count+1   

   # increment block index before starting block loop again
   block_idx = block_idx+1 
       
sendCommand(doEndSession,0)

internalState = 0

if (run_as_standalone == 0):
   tcpCliSock.close()
   
# Terminate Session and copy .dat file
filename = outputPath + '/' + experimentName + '-' + str(subject) + '-' + str(session) + '.dat'
copyfile('Y:/RSVP.dat',filename)

p.parameters.go_duration = ('forever',)
sttext = "The data has been saved! Press SPACE to exit."
trainingText = Text( text = sttext, position = (screen.size[0]/2.0,screen.size[1]/2), font_name=fname,font_size=fsize,
                   anchor = 'center', color = (0.0,0.0,0.0,1.0))
viewport.parameters.stimuli=[trainingText]
p.go()




