import os, sys
import Image
import random
from easygui import *
from random import shuffle
from socket import *
from VisionEgg.Textures import *
from xml.sax import make_parser
from xml.sax.handler import ContentHandler
from TrainingSetXMLHandler import *
import time
import operator



def getTestImageSize(testPath):
   my_logger = logging.getLogger('RKI_Logger')
   my_logger.info('Determining the image size for the testing session')
   if os.path.isdir(testPath):
      targetPath = testPath + '/__block_1/'
      if (os.path.isdir(targetPath)):
         imListTarget = os.listdir(targetPath)
         try:
            imListTarget.remove('Thumbs.db')
            my_logger.info('Thumbs.db file found, in folder __block_1, it is ignored')
         except ValueError:
            dummy=1

         try:
            imListTarget.remove('.svn')
            my_logger.info('A .svn  sub-folder found, and in folder __block_1, it is ignored')
         except ValueError:
            dummy=1
      
         if (len(imListTarget)== 0):
            return
         else:
            # time to obtain requested sample
            try:
              imageTex = Texture(targetPath + imListTarget[0]) # To be made generic
            except IOError:
              my_logger.error("Corrupted or non existing image file " + targetPath + imListTarget[0] + " Terminating application.")
              msgbox("Corrupted or non existing image file " + targetPath + imListTarget[0] + " Terminating application.")
              sys.exit(1)
            return imageTex


def getImageSize(trainPath):

    my_logger = logging.getLogger('RKI_Logger')
    my_logger.info('Determining the image size for the training session')

    if os.path.isdir(trainPath):
      targetPath = trainPath + '\\targetpool\\'
      if (os.path.isdir(targetPath)):
         imListTarget = os.listdir(targetPath)
         try:
            imListTarget.remove('Thumbs.db')
            my_logger.info('Thumbs.db file found, in folder targetpool, it is ignored')
         except ValueError:
            dummy=1
         try:
            imListTarget.remove('.svn')
            my_logger.info('.svn sub-folder found, in folder targetpool, it is ignored')
         except ValueError:
            dummy=1
         if (len(imListTarget)== 0):
            my_logger.debug('Train path targetpool folder contains no targets!!!')
            return
         else:
            # time to obtain requested sample
            try:
               imageTex = Texture(targetPath + imListTarget[0]) # To be made generic
            except IOError:
               my_logger.error("Error Corrupted image " + targetPath + imListTarget[0] + " Terminating application")
               msgbox("Error Corrupted image " + targetPath + imListTarget[0] + " Terminating application")
               sys.exit(1)  
            return imageTex


def getImageSizeXML(xmlFile):

    my_logger = logging.getLogger('RKI_Logger')
    my_logger.info('Determining the image size for the testing session')


    parser = make_parser()   
    curHandler = RSVPinputHandler(('file_name','groundTruth'))
    parser.setContentHandler(curHandler)
    parser.parse(open(xmlFile))
    imList = curHandler.getParsedList()
    rootpath = curHandler.getRootPath()
    try:
      imageTex = Texture(rootpath + imList[0].filename) # To be made generic
    except IOError:
      my_logger.error("Error Corrupted image " + rootpath + imList[0].filename + " Terminating application")
      msgbox("Error Corrupted image " + rootpath + imList[0].filename + " Terminating application")
      sys.exit(1)  
    return imageTex

    

def loadBlockImages(rootPath,blocknumber):
   my_logger = logging.getLogger('RKI_Logger')
   my_logger.info('Loading images for the current test block')

   unlabeledstimulus_const = 2
   pretarg = '_210_'
   prenontarg = '_220_'

   currentpath = rootPath + '\\__block_' + str (blocknumber) + '\\'
   if os.path.isdir(currentpath):
      imList = os.listdir(currentpath)
      try:
        imList.remove('Thumbs.db')
        my_logger.info('Thumbs.db file found, in folder __block_1, it is ignored')
      except ValueError:
        dummy=1
      try:
        imList.remove('.svn')
        my_logger.info('.sbv sub-folder found, in the current __block_1, it is ignored')
      except ValueError:
        dummy=1

            
      targlist = [2 * (imList[cur].find(pretarg) + 1) for cur in range(len(imList))]
      nontarglist = [3 * (imList[cur].find(prenontarg) + 1) for cur in range(len(imList))]
      # targetcode 5: target 4: nontarget 2: unlabeled stimulus
      targetcode = [targlist[cur] + nontarglist[cur] + 2 for cur in range(len(imList))]
      # Load set of images
      # curImList = [(Image.open(currentpath + imList[cur]),targetcode[cur],currentpath,imList[cur]) for cur in range(len(imList))]

      curImList = []
      for cur in range(len(imList)):
        try:
           tmpcur = Image.open(currentpath + imList[cur])
           curImList.append((tmpcur,targetcode[cur],currentpath,imList[cur]))
        except IOError:
           my_logger.warning("Corrupted or not available image file" + currentpath + imList[cur] + " Skipping image, one less image than specified will be shown")
      if len(curImList) == 0 :
         my_logger.debug('No images available in the current block')
         return

      shuffle(curImList)
      return curImList
   else:
       return



def confirmMessage(mytext):
    ch = ynbox(mytext, title=' ', choices=('Yes', 'Cancel'), image=None)
    return ch   



#
#
# This script will load a testing set of images for a given block.
#
#

def sampleTestImagesXML(xmlFile,numTargets,numNontargets,block_idx):

    my_logger = logging.getLogger('RKI_Logger')
    my_logger.info('Loading images for the current test block')

    parser = make_parser()   
    curHandler = RSVPinputHandler(('file_name','groundTruth'))
    parser.setContentHandler(curHandler)
    parser.parse(open(xmlFile))
    imList = curHandler.getParsedList()
    rootpath = curHandler.getRootPath()
    imPotentialTargIdx = []
    imPotentialNonTargIdx = []
    
    for cur in range(len(imList)):
       if (int(imList[cur].status) == 1):
          imPotentialTargIdx.append(cur)  
       elif (int(imList[cur].status) == 2):
          imPotentialNonTargIdx.append(cur)
    
    tListlen = len(imPotentialTargIdx)
    ntListlen = len(imPotentialNonTargIdx)

    # check if the number of potential targets discractors available will suffice.
    if ((ntListlen<1 ) and (numNontargets>0)):
       my_logger = logging.getLogger('RKI_Logger')
       my_logger.error('Inconsistency: No fillers/distractors specified in the XML file but requested to display ' + str(numNontargets) + ' per block')
       print "An error occured check log file for details"
       
       sys.exit(1)
    #tsample = [random.randint(0,tListlen-1) for r in range(numTargets)]
    shiftby = (block_idx-1)*numTargets
    if ((tListlen-shiftby) < numTargets):
       # in not enought targers to be shown, show whatever is left.
       numTargets = (tListlen-shiftby)
    if (numTargets <= 0):
       # end of available targers
       return
    tsample = [shiftby + r for r in range(numTargets)]
    ntsample = [random.randint(0,ntListlen-1) for r in range(numNontargets)]
    # curImListTarget = [(Image.open(rootpath + imList[imPotentialTargIdx[tsample[cur]]].filename),imList[imPotentialTargIdx[tsample[cur]]].groundTruth, imList[imPotentialTargIdx[tsample[cur]]].status, str(imList[imPotentialTargIdx[tsample[cur]]].id)) for cur in range(numTargets)]
    # curImListNonTarget = [(Image.open(rootpath + imList[imPotentialNonTargIdx[ntsample[cur]]].filename),imList[imPotentialNonTargIdx[ntsample[cur]]].groundTruth, imList[imPotentialNonTargIdx[ntsample[cur]]].status, str(imList[imPotentialNonTargIdx[ntsample[cur]]].id)) for cur in range(numNontargets)]            

    curImListTarget = []
    skipedSoMany = 0;   # keep track of how many images were skipped due to bad quality or improper format.
    for cur in range(numTargets):
       try:
           tmpImage = Image.open(rootpath + imList[imPotentialTargIdx[tsample[cur]]].filename)
           targetcode = 5 #code of 5 indicates a distracter
           if (int(imList[imPotentialTargIdx[tsample[cur]]].groundTruth) == 1):
              targetcode = 4 #code of 4 indicates it is a target
           curImListTarget.append((tmpImage, targetcode, imList[imPotentialTargIdx[tsample[cur]]].status, str(imList[imPotentialTargIdx[tsample[cur]]].id)))  
       except IOError:
           my_logger.warning("Corrupted or not available image file" + rootpath + imList[imPotentialTargIdx[tsample[cur]]].filename + " Skipping image, one less image than specified will be shown")
           skipedSoMany = skipedSoMany + 1

    curImListNonTarget = []
    skipedSoMany = 0;   # keep track of how many images were skipped due to bad quality or improper format.

    for cur in range(numNontargets):
       try:
          tmpImage  = Image.open(rootpath + imList[imPotentialNonTargIdx[ntsample[cur]]].filename)
          targetcode = 5 #code of 5 indicates a distracter
          if (int(imList[imPotentialNonTargIdx[ntsample[cur]]].groundTruth) == 1):
             targetcode = 4 #code of 4 indicates it is a target
          curImListNonTarget.append((tmpImage, targetcode, imList[imPotentialNonTargIdx[ntsample[cur]]].status, str(imList[imPotentialNonTargIdx[ntsample[cur]]].id)))
       except IOError:
          my_logger.warning("Corrupted or not available image file" + rootpath + imList[imPotentialNonTargIdx[ntsample[cur]]].filename + " Skipping image, one less image than specified will be shown")
          skipedSoMany = skipedSoMany + 1


    curImList = curImListTarget + curImListNonTarget
    shuffle(curImList)
    return curImList

    





#
#
# This script will sort the images according to a specicied fie
# load a set of images  testing set of images for a give block.
#
#

def sampleByExactSequence(xmlFile,blockSize,block_idx):

    my_logger = logging.getLogger('RKI_Logger')
    my_logger.info('Loading images for the current test block')

    parser = make_parser()   
    curHandler = RSVPinputHandler(('file_name','groundTruth'))
    parser.setContentHandler(curHandler)
    parser.parse(open(xmlFile))
    imList = curHandler.getParsedList()
    rootpath = curHandler.getRootPath()
    imPotentialTargIdx = []
    imPotentialNonTargIdx = []
    imList = sorted(imList, key=operator.itemgetter('dispOrder'))    
    listlen = len(imList)

    #tsample = [random.randint(0,tListlen-1) for r in range(numTargets)]
    shiftby = (block_idx-1)*blockSize
    if ((listlen-shiftby) < blockSize):
       # in not enought targers to be shown, show whatever is left.
       blockSize = (listlen-shiftby)
    if (blockSize <= 0):
       # end of available targers
       return
    tsample = [shiftby + r for r in range(blockSize)]

    curImList = []
    skipedSoMany = 0;   # keep track of how many images skiped dur to bad quality on improper formant.
    for cur in range(blockSize):
       try:
           tmpImage = Image.open(rootpath + imList[tsample[cur]].filename)
           targetcode = 5 #code of 5 indicates a distracter
           if (int(imList[tsample[cur]].groundTruth) == 1):
              targetcode = 4 #code of 4 indicates it is a target
           curImList.append((tmpImage, targetcode, imList[tsample[cur]].status, str(imList[tsample[cur]].id)))  
       except IOError:
           my_logger.warning("Corrupted or not available image file" + rootpath + imList[tsample[cur]].filename + " Skipping image, one less image than specified will be shown")
           skipedSoMany = skipedSoMany + 1

    return curImList







def sampleTrainImagesXML(xmlFile,numTargets,numNontargets):
    
    my_logger = logging.getLogger('RKI_Logger')
    my_logger.info('Loading images for the current test block')

    parser = make_parser()   
    curHandler = RSVPinputHandler(('file_name','groundTruth'))
    parser.setContentHandler(curHandler)
    parser.parse(open(xmlFile))
    imList = curHandler.getParsedList()
    rootpath = curHandler.getRootPath()
    imTargIdx = []
    imNonTargIdx = []
    
    for cur in range(len(imList)):
       if (int(imList[cur].groundTruth) == 1):
          imTargIdx.append(cur)  
       elif (int(imList[cur].groundTruth) == 0):
          imNonTargIdx.append(cur)

    tListlen = len(imTargIdx)
    ntListlen = len(imNonTargIdx)
    tsample = [random.randint(0,tListlen-1) for r in range(numTargets)]
    ntsample = [random.randint(0,ntListlen-1) for r in range(numNontargets)]
    #curImListTarget = [(Image.open(rootpath + imList[imTargIdx[tsample[cur]]].filename),imList[imTargIdx[tsample[cur]]].groundTruth, imList[imTargIdx[tsample[cur]]].status, str(imList[imTargIdx[tsample[cur]]].id)) for cur in range(numTargets)]
    #curImListNonTarget = [(Image.open(rootpath + imList[imNonTargIdx[ntsample[cur]]].filename),imList[imNonTargIdx[ntsample[cur]]].groundTruth, imList[imNonTargIdx[ntsample[cur]]].status, str(imList[imNonTargIdx[ntsample[cur]]].id)) for cur in range(numNontargets)]            

    curImListTarget = []
    skipedSoMany = 0;   # keep track of how many images skiped dur to bad quality on improper formant.
    for cur in range(numTargets):
       try:
           # reparate rootpath from filename.
           fnamesplit = os.path.split(os.path.join(rootpath + imList[imTargIdx[tsample[cur]]].filename))
           tmpImage = Image.open(rootpath + imList[imTargIdx[tsample[cur]]].filename)
           curImListTarget.append((tmpImage,imList[imTargIdx[tsample[cur]]].groundTruth, fnamesplit[0]  , fnamesplit[1], imList[imTargIdx[tsample[cur]]].status, str(imList[imTargIdx[tsample[cur]]].id)))  
       except IOError:
           my_logger.warning("Corrupted or not available image file" + rootpath + imList[imTargIdx[tsample[cur]]].filename + " Skipping image, one less image than specified will be shown")
           skipedSoMany = skipedSoMany + 1

    curImListNonTarget = []
    skipedSoMany = 0;   # keep track of how many images skiped dur to bad quality on improper formant.

    for cur in range(numNontargets):
       try:
          fnamesplit = os.path.split(os.path.join(rootpath + imList[imNonTargIdx[ntsample[cur]]].filename))
          tmpImage  = Image.open(rootpath + imList[imNonTargIdx[ntsample[cur]]].filename)
          curImListNonTarget.append((tmpImage,imList[imNonTargIdx[ntsample[cur]]].groundTruth, fnamesplit[0]  , fnamesplit[1] , imList[imNonTargIdx[ntsample[cur]]].status, str(imList[imNonTargIdx[ntsample[cur]]].id)))
       except IOError:
          my_logger.warning("Corrupted or not available image file" + rootpath + imList[imNonTargIdx[ntsample[cur]]].filename + " Skipping image, one less image than specified will be shown")
          skipedSoMany = skipedSoMany + 1

        
    curImList = curImListTarget + curImListNonTarget
        
  #  print imList[0].id
  #  print imList[0].filename
  #  print imList[0].groundTruth
    shuffle(curImList)
    return curImList








#
# Samples and loads a block of images,  can use with or without replacement
# If without replacement, and less images than requested are available then the return
# list will be only the images available. If no targets are available the the list return
# has zero length.
#http://math.carleton.ca/old/help/matlab/MathWorks_R13Doc/techdoc/matlab_external/ch_java.html

def sampleTrainImages(trainPath,numTargets,numNontargets,alreadySampled,withreplacement):

    my_logger = logging.getLogger('RKI_Logger')
    my_logger.info('Sampling training images')

    target_const = 1
    nontarget_const = 0
    if os.path.isdir(trainPath):
      targetPath = trainPath + '\\targetpool\\'
      nontargetPath = trainPath + '\\nontargetpool\\'
      if (os.path.isdir(targetPath) and os.path.isdir(nontargetPath)):
         imListTarget = os.listdir(targetPath)
         imListNonTarget = os.listdir(nontargetPath)
         try:
           imListTarget.remove('Thumbs.db')
           my_logger.info('Thumbs.db found in the targetpool folder, file is ignored')
           imListNonTarget.remove('Thumbs.db')
           my_logger.info('Thumbs.db found in the nontargetpool folder, file is ignored')
         except ValueError:
           dumy=1 
         try:
           imListTarget.remove('.svn')
           my_logger.info('.svn found in the targetpool folder, file is ignored')
           imListNonTarget.remove('.svn')
           my_logger.info('.svn found in the nontargetpool folder, the sub-folder is ignored')
         except ValueError:
           dumy=1 
             
         if (len(imListTarget)== 0 or len(imListNonTarget) == 0):
            my_logger.debug('No images available in either targetpool or nontargetpoll folders')
            msgbox("Error: No images availabe, or invalid input Train path, \n " + trainPath + " \n\n Make sure the configuration.ini file points to a valid Training path \n \n A valid Training Path should:\n \n 1) Include a sub-folder called 'targetpool'\n 2) Include a sub-folder called 'nontargetpool' \n 3) Both sub-folders include ONLY image files.\n\n\n Application will terminate", title='Error: No or invalid image files - RSVPUtilities.py')
            sys.exit()
         else:
            # time to obtain requested sample
            random.seed()
            tListlen = len(imListTarget)
            ntListlen = len(imListNonTarget)
            tsample = [random.randint(0,tListlen-1) for r in range(numTargets)]
            ntsample = [random.randint(0,ntListlen-1) for r in range(numNontargets)]
            #curImListTarget = [(Image.open(targetPath + imListTarget[tsample[cur]]),target_const, targetPath, imListTarget[tsample[cur]]) for cur in range(numTargets)]
            #curImListNonTarget = [(Image.open(nontargetPath + imListNonTarget[ntsample[cur]]),nontarget_const, nontargetPath, imListNonTarget[ntsample[cur]]) for cur in range(numNontargets)]            

            curImListTarget = []
            skipedSoMany = 0;   # keep track of how many images skiped dur to bad quality on improper formant.

            for cur in range(numTargets):
              try:
                 tmpImage = Image.open(targetPath + imListTarget[tsample[cur]])
                 curImListTarget.append((tmpImage,target_const, targetPath, imListTarget[tsample[cur]]))  
              except IOError:
                 my_logger.warning("Corrupted or not available image file" + targetPath + imListTarget[tsample[cur]] + " Skipping image, one less image than specified will be shown")
                 skipedSoMany = skipedSoMany + 1

            curImListNonTarget = []
            skipedSoMany = 0;   # keep track of how many images skiped dur to bad quality on improper formant.

            for cur in range(numNontargets):
              try:
                 tmpImage  = Image.open(nontargetPath + imListNonTarget[ntsample[cur]])
                 curImListNonTarget.append((tmpImage,nontarget_const, nontargetPath, imListNonTarget[ntsample[cur]]))
              except IOError:
                 my_logger.warning("Corrupted or not available image file" + nontargetPath + imListNonTarget[ntsample[cur]] + " Skipping image, one less image than specified will be shown")
                 skipedSoMany = skipedSoMany + 1




            curImList = curImListTarget + curImListNonTarget
           
            shuffle(curImList)
            return curImList
      else:
         my_logger.debug('No images available in either targetpool or nontargetpoll folders')
         msgbox("Error: No images availabe, or invalid input Train path, \n " + trainPath + " \n\n Make sure the configuration.ini file points to a valid Training path \n \n A valid Training Path should:\n \n 1) Include a sub-folder called 'targetpool'\n 2) Include a sub-folder called 'nontargetpool' \n 3) Both sub-folders include ONLY image files.\n\n\n Application will terminate", title='Error: No or invalid image files - RSVPUtilities.py')
         sys.exit()
         


#
# Accepts a path to a folder containing two subfolders, called targetpool and nontargetpool. Each
# folder needs to contain the targets stimulus and distructire strimulus images. 
#


def getListFromFolder(trainPath):

     my_logger = logging.getLogger('RKI_Logger')
     my_logger.info('Get listing from train folder')
    
     target_const = 1
     nontarget_const = 0
     if os.path.isdir(trainPath):
        targetPath = trainPath + '\\targetpool\\'
        nontargetPath = trainPath + '\\nontargetpool\\'
        if (os.path.isdir(targetPath) and os.path.isdir(nontargetPath)):
           imListTarget = os.listdir(targetPath)
           imListNonTarget = os.listdir(nontargetPath)
           print len(imListNonTarget)
           try:
             imListTarget.remove('Thumbs.db')
             imListNonTarget.remove('Thumbs.db')
           except ValueError:
             dumy=1 

           try:
             imListTarget.remove('.svn')
             my_logger.info('.svn found in the targetpool folder, file is ignored')
             imListNonTarget.remove('.svn')
             my_logger.info('.svn found in the nontargetpool folder, the sub-folder is ignored')
           except ValueError:
             dumy=1 
                    
           if (len(imListTarget)== 0 or len(imListNonTarget) == 0):
              return
           else:
               tListlen = len(imListTarget)
               ntListlen = len(imListNonTarget)
               curImListTarget = [(targetPath + imListTarget[cur],target_const, targetPath, imListTarget[cur]) for cur in range(tListlen)]
               curImListNonTarget = [(nontargetPath + imListNonTarget[cur],nontarget_const, nontargetPath, imListNonTarget[cur]) for cur in range(ntListlen)]            
               imageList = curImListTarget + curImListNonTarget
               return imageList
     else:
         return


def getPracticeSessionPath():
    sessionPath = diropenbox(msg=None, title="Select a session input directory", default=None)

    if (sessionPath == None):
       return
    #
    # Make sure this is a valid directory
    #
    if os.path.isdir(sessionPath):
      targetPath = sessionPath + '\\targetpool\\'
      nontargetPath = sessionPath + '\\nontargetpool\\'
      if (os.path.isdir(targetPath) and os.path.isdir(nontargetPath)):
         return sessionPath 
   

def getPracticeSessionParams():
    Dfreq = 10         # Default frequency value
    DTargetNum = 2     # Defaul number of targets
    DBlocksize = 98    # Defaul number of non targets
    Dmode = 1          # Default mode of operation.

    while 1:
       msg = "Please set the session parameters."
       title = "Set session parameters"
       fieldNames = ["Frequency (Hz)"]
       fieldValues = [Dfreq]  # we start with blanks for the values

       fieldValues = multenterbox(msg,title, fieldNames, fieldValues)

       error_flag = 0
       error_msg = ""

       if (fieldValues == None):
          fieldValues = [Dfreq ,DTargetNum ,DBlocksize, Dmode]
          return fieldValues
       
       try:
           int(fieldValues[0])
           
           break
       except ValueError:
           error_flag = 1
           error_msg = "Make sure all values are specified and are correct."
           msgbox(error_msg)
    
    return fieldValues



#################################################
# Prompt for the TCP/IP connections and attempts to connect
# to the CBCI.server. 
#################################################

def connectTCPIP(HOST,PORT,BUFSIZE):
    msg = "Connect to CBCI via TCP/IP"
    title = "Connect to CBCI via TCP/IP"
    fieldNames = ["Host","Port","Buffer Size"]
    fieldValues = [HOST ,PORT ,BUFSIZE]  # we start with blanks for the values

    while 1:
       fieldValues = multenterbox(msg,title, fieldNames, fieldValues)

       # make sure that none of the fields was left blank
       while 1:
           if fieldValues == None: 
               ch = ynbox('Are you sure you want to quit?', title=' ', choices=('Yes', 'Cancel'), image=None)
               if ch==1:
                  sys.exit(1)
               else:
                  fieldValues = [HOST, PORT, BUFSIZE]
                  break
           errmsg = ""
           for i in range(len(fieldNames)):
               if fieldValues[i].strip() == "":
                   errmsg = errmsg + ('"%s" is a required field.' % fieldNames[i])
           if errmsg == "": break # no problems found
           fieldValues = multenterbox(errmsg, title, fieldNames, fieldValues)
    
       
       ADDR = (fieldValues[0], int(fieldValues[1]))

       try:
          tcpCliSock = socket(AF_INET, SOCK_STREAM)
          tcpCliSock.connect(ADDR)
          break
       except error, (value,message):
          msgbox("Connection Failed!!! Make sure CBCI server is running.")

    return tcpCliSock
    
      
    
def processCBCIoutput(mystr,curImPath,curImName):
   mystr = mystr.replace('[',' ')
   mystr = mystr.replace(']',' ')
   mystr = mystr.split(';')
   totElements = len(mystr);
   outlist = [(curImPath[i],curImName[i], mystr[i]) for i in range(totElements)]
   return outlist


#
# Simulates the output of the 'processCBCIoutput'
#
def simulateCBCIoutput(blockIdx,curTargList,curImPath,curImName):
    reindex = range(len(curImPath))
    shuffle(reindex)
    outlist = []                 
    for i in range(len(curImPath)):
        mystr = str(blockIdx) + ' ' + str(i) + ' ' +  str(0.0001) + ' ' + str(reindex[i])
        outlist.append((curImPath[i],curImName[i], mystr))

    return outlist

            
def output2file(outdir,blocknum,reslist):
   filename = outdir + '//block_' + str(blocknum) + '.res'
   f = open(filename,'w')
   f.write('Path \t Imagename \t block index \t image index \t class \t confidence \n')
   for elem in range(len(reslist)):
     resstr = reslist[elem][0] + '\t' + reslist[elem][1] + '\t' + reslist[elem][2] + '\n'
     f.write(resstr)
   f.close()

def getblockStatistics(reslist,curTargList):
 
    rlist = [];
    for elem in range(len(curTargList)):
        if (curTargList[elem] == 1):
            res = reslist[elem][2].rsplit()
            rlist.append((res[1], res[3]))
    return rlist

  #rlist = [];
  #for elem in range(len(curTargList)):
     #if (curTargList[elem] == 1):
   #  if (1):
   #     res = reslist[elem][2].rsplit()
    #    rlist.append((res[1],res[2],res[3]))

  #lst = rlist[1];  
  #print rlist
  #import operator
  #temp = sorted(enumerate(lst), key=operator.itemgetter(1))
  #rlist = temp  
        
  #return rlist
    
def requestSessionId(sessionId):


    msg = "Load Session"
    title = "Load pre-trained classifier"
    fieldNames = ["Session Id:"]
    fieldValues = [sessionId]  # we start with blanks for the values

    fieldValues = multenterbox(msg,title, fieldNames, fieldValues)

       # make sure that none of the fields was left blank
    while 1:
           if fieldValues == None: 
               ch = ynbox('Are you sure you want to quit?', title=' ', choices=('Yes', 'Cancel'), image=None)
               if ch==1:
                  sys.exit(1)
               else:
                  fieldValues = [HOST, PORT, BUFSIZE]
                  break
           errmsg = ""
           for i in range(len(fieldNames)):
               if fieldValues[i].strip() == "":
                   errmsg = errmsg + ('"%s" is a required field.' % fieldNames[i])
           if errmsg == "": break # no problems found
           fieldValues = multenterbox(errmsg, title, fieldNames, fieldValues)
    
       
    sessionId = (fieldValues[0])

    return sessionId


def log_monitorFrequency(debug_list):
   filename = 'monitor_freq.log'
   f = open(filename,'a+')
   f.write('Begining of block\n')
   for elem in range(len(debug_list)):
     resstr = str(debug_list[elem][1]) + '\t' + str(debug_list[elem][0]) +  '\t' + str(debug_list[elem][2]) + '\n'
     f.write(resstr)
   f.write('End of block\n')
   f.close()




#
# obtain the input XML file for the RSVP experiment.
#

def getXMLfile():

    inputfile = fileopenbox(msg="Please select an input XML file", title="XML input selection", default="*.xml")

    if (inputfile == None):
       return

    #
    # Here I need to add some validation code for the XML input
    #
    return inputfile



#
# function to support XML output according the the proper schema
#

def get_xmlRSVPheader(rootpath):
   xmlheader_string = '<?xml version="1.0" ?>\n<object_detection_result>\n<path_name>' + rootpath +'</path_name>\n';
   return xmlheader_string

#
# imagelist a list 
#  (fullname, target or not, pathonly, filename only)
#

def get_xmlRSVPentries(imagelist,idx,dispIdx,rootpath):
    mystatus = 2 - imagelist[1] 
    xmlnode_string = '<object_info idx="' + str(idx) + '">\n<file_name>' + imagelist[0].replace(rootpath,'') + '</file_name>	\n<id>' + str(idx) + '</id>\n<status>'+ str(mystatus) +'</status>\n<position_x>0</position_x>\n<position_y>0</position_y>\n<confidence>0.0</confidence>\n<eegconfidence>0.0</eegconfidence>\n<dispOrder>' + str(dispIdx) + '</dispOrder>\n<groundTruth>' + str(imagelist[1]) + '</groundTruth>\n</object_info>\n'
    return xmlnode_string
    
def get_xmlRSVPfooter():
    xmlfooter_string = '</object_detection_result>\n'
    return xmlfooter_string
  

# DJ Addition 4/24/12: Get generic string input
# Adapted from requestSessionId.
def requestInfo(msg, title, fieldNames, fieldValues):


    #msg = "Load Session"
    #title = "Load pre-trained classifier"
    #fieldNames = ["Session Id:"]
    #fieldValues = [sessionId]  # we start with blanks for the values

    fieldValues = multenterbox(msg,title, fieldNames, fieldValues)

       # make sure that none of the fields was left blank
    while 1:
           if fieldValues == None: 
               ch = ynbox('Are you sure you want to quit?', title=' ', choices=('Yes', 'Cancel'), image=None)
               if ch==1:
                  sys.exit(1)
               else:
                  fieldValues = ["0","0","0"]
                  break
           errmsg = ""
           for i in range(len(fieldNames)):
               if fieldValues[i].strip() == "":
                   errmsg = errmsg + ('"%s" is a required field.' % fieldNames[i])
           if errmsg == "": break # no problems found
           fieldValues = multenterbox(errmsg, title, fieldNames, fieldValues)

    return fieldValues



