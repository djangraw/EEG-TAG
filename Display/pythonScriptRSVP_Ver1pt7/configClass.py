from ConfigParser import SafeConfigParser
from ConfigParser import *
from easygui import *

class configClass:
    "Keeps track of all configuration parameters and can validate the input."

    def __init__(self,default_config):
        self.isValidConfig = 1
        self.loadfromFile(default_config)


    
    def getIsValidConfig(self):
        if (self.isValidConfig==1):
            return True
        else:
            return False


    def loadfromFile(self,configFile):
        
        # The classic way:
            cp = SafeConfigParser()
       
        #try:      
            cp.read(configFile)

            # Get and process background color values 
            self.background_color_str= cp.get('RSVPglobalParams','background_color')
            self.input_from = int(cp.get('RSVPglobalParams','input_from'))

            self.presentationFreq = int(cp.get('RSVPglobalParams','presentationFreq'))
            self.simulationMode = int(cp.get('RSVPglobalParams','simulationMode'))
            self.run_as_standalone = int(cp.get('RSVPglobalParams','run_as_standalone'))
            self.use_predefined_ordering = int(cp.get('RSVPglobalParams','use_predefined_ordering'))                            
            self.monitorFrequency = int(cp.get('RSVPglobalParams','monitorFrequency'))
            self.logfilename = cp.get('LOG','logfile')
            self.loglevel = cp.get('LOG','loglevel')

            self.trainPath = cp.get('RSVPtrainUserSpecifiedParams','trainPath')
            self.traininputXMLfile = cp.get('RSVPtrainUserSpecifiedParams','trainXMLfile')
            self.trainoutputXMLfile = cp.get('RSVPtrainUserSpecifiedParams','outputXMLfile') 
            self.trainoutputPath = cp.get('RSVPtrainUserSpecifiedParams','outputPath')
            self.trainnumTargets = int(cp.get('RSVPtrainUserSpecifiedParams','numTargets'))
            self.trainnumNontargets =  int(cp.get('RSVPtrainUserSpecifiedParams','numNontargets'))
  

            self.testPath = cp.get('RSVPtestUserSpecifiedParams','testPath')
            self.testinputXMLfile = cp.get('RSVPtestUserSpecifiedParams','testXMLfile')
            self.testoutputXMLfile = cp.get('RSVPtestUserSpecifiedParams','outputXMLfile')
            self.testoutputPath = cp.get('RSVPtestUserSpecifiedParams','outputPath')
            self.testnumTargets = int(cp.get('RSVPtestUserSpecifiedParams','numTargets'))
            self.testnumNontargets =  int(cp.get('RSVPtestUserSpecifiedParams','numNontargets'))


            self.practicePath = cp.get('RSVPtrainUserSpecifiedParams','trainPath')
            self.practiceinputXMLfile = cp.get('RSVPtrainUserSpecifiedParams','trainXMLfile')
            self.practiceoutputPath = cp.get('RSVPtrainUserSpecifiedParams','outputPath')
            self.practicenumTargets = int(cp.get('RSVPtrainUserSpecifiedParams','numTargets'))
            self.practicenumNontargets =  int(cp.get('RSVPtrainUserSpecifiedParams','numNontargets'))
        #except (NoOptionError, MissingSectionHeaderError):
        #    self.isValidConfig = 0
        #    msgbox ("Bad session file format....")
        
    def savetoConfig(self,fname):
        f = open(fname, 'w')
        f.write(";\n;Automatically generated session_file for RSVP brain, created using RSVPconfig utility.\n; \n")
        f.write("[RSVPglobalParams]\n\n")

        # background color param
        comment = 'Specify the screen background color in a comma separated rgba values'
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nbackground_color = " + self.background_color_str + "\n")

        # input from param 99698997  96393109
        comment = """
; Specify which type on data loading mechanism to use, currently two types are supported. Loading from file strucuture or loading from XML files
; each has its own pros an cons. 
;
; input_from = 1    input from file structure
; input_from = 2    input from an XML file.
;
;"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\ninput_from = " + str(self.input_from) + "\n")

        # simulation mode
        comment = """
;
; Set to one to run script in simulation mode (i.e communicating with the simulated server), set to 0
; to communicate directly with the CBCI server.
;
"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nsimulationMode = " + str(self.simulationMode) + "\n")

        # run as standalone

        comment = """
;
; Set this to run either component to a stand alone mode, does not require CBCI server to be running.
;
"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nrun_as_standalone = " + str(self.run_as_standalone) + "\n")

        # use_predefined_ordering

        comment = """
;
; Set this to use predifined ordering from the XML file.
;
"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nuse_predefined_ordering = " + str(self.use_predefined_ordering) + "\n")

        # Presentation frequency parameter

        comment = """        
;
; Frequency of presentation of the image in Hz, typical values 10 or 5
;
"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\npresentationFreq = " + str(self.presentationFreq) + "\n")

        # Monitor logging
        comment = """ 
;
; Monitors the presentation frequency of consecutive images stimulus in blocks, will generate a log file with the difference between every pair 
; of consecutive images.     
;
; 0 : disable ,    suggested for real experiment
; 1 : Monitor performance, generate a log file with differences in the image presentation
; 2 : Monitor performance as in mode 1, but also injects time delayes randomly during the presentaion, to sumulate context switch, and multi-tasking systems.
"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nmonitorFrequency = " + str(self.monitorFrequency) + "\n")


        comment = """
;
; Specify loging information for the valious levels.
;

[LOG]

;
; Specify the log file to be used, for logging messages
;
"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nlogfile = " + self.logfilename + "\n")

        comment = """
;
; Specify the minimul log-level for the current logger. Siz log levels are supported with the following values:
; 
;  'debug' -  Debug 
;  'info' -  Info
;  'warn' -  Warn
;  'error' -  Error
;  'critical' -  Critical
;
"""

        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nloglevel = " + self.loglevel + "\n")
        
        comment = """
;
; User Specified parameters for the RSVPtrain interface
; User can modify this section as see fit

[RSVPtrainUserSpecifiedParams]

;
; Full path to the directory where the training images are located. The folder must include
; two subfolders called 'targetpool' and 'nontargetpool' containing example images of targets and distractors
;
;
"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\ntrainPath = " + self.trainPath + "\n")

        comment = """
;
;
; Full path to the XML input file. This parameter is used to load the data for a training session if the XML input is enabled.
;

"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\ntrainXMLfile = " + self.traininputXMLfile + "\n")

        comment = """
;
; Number of targets per block in the training script.
;
"""

        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nnumTargets = " + str(self.trainnumTargets) + "\n")

        comment = """
;
; Number of distractors per block during the training phase
;
"""
        
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nnumNontargets = " + str(self.trainnumNontargets) + "\n")

        comment = """
;
; Specifies the directory where the output of the training session will be stored  used only when input_from parameters is set to 2
;
"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\noutputPath = " + self.trainoutputPath + "\n")

        comment = """
;
; Specifies the XML file where the output of the training session will be stored, used only when input_from parameters is set to 2
;
"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\noutputXMLfile = " + self.trainoutputXMLfile + "\n")


        comment = """
;
; User Specified parameters for the RSVPtest interface
; User can modify this section as see fit

[RSVPtestUserSpecifiedParams]

;
; Full path to the directory where the testing images are located. The folder must include
; two subfolders called 'targetpool' and 'nontargetpool' containing example images of targets and distractors
;
"""

        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\ntestPath = " + self.testPath + "\n")

        comment = """
;
;
; Full path to the XML input file. This parameter is used to load the data for a training session if the XML input is enabled.
;
"""

        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\ntestXMLfile = " + self.testinputXMLfile + "\n")

        comment = """
;
; Specifies the directory where the output of the testing session will be stored
;
"""

        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\noutputPath = " + self.testoutputPath + "\n")


        comment = """
;
; Specifies the XML file where the output of the testing session will be stored.
;
"""

        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\noutputXMLfile = " + self.testoutputXMLfile + "\n")
    
        comment = """
;
; Number of targets per block in the testing script, valid if XML input specified
;
"""

        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nnumTargets = " + str(self.testnumTargets) + "\n")
    
        comment = """
;
; Number of distractors per block during the testing phase, valid if XML input specified
;
"""


        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nnumNontargets = " + str(self.testnumNontargets) + "\n")

        f.close()






############################################
        ##
        #################################
                   ##
                   ###################





    def savetoConfigVersion1(self,fname):
        f = open(fname, 'w')
        f.write(";\n;Automatically generated configuration_file for RSVP brain, created using RSVPconfig utility.\n; \n")
        f.write(";\n;configuration for Version 1.3 \n; \n")
        f.write("[RSVPglobalParams]\n\n")

        # background color param
        comment = 'Specify the screen background color in a comma separated rgba values'
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nbackground_color = " + self.background_color_str + "\n")

        # input from param 
        comment = """
; Specify which type on data loading mechanism to use, currently two types are supported. Loading from file strucuture or loading from XML files
; each has its own pros an cons. 
;
; input_from = 1    input from file structure
; input_from = 2    input from an XML file.
;
;"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\ninput_from = " + str(self.input_from) + "\n")


        comment = """
;
; Specify loging information for the valious levels.
;

[LOG]

;
; Specify the log file to be used, for logging messages
;
"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nlogfile = " + self.logfilename + "\n")

        comment = """
;
; Specify the minimul log-level for the current logger. Siz log levels are supported with the following values:
; 
;  'debug' -  Debug 
;  'info' -  Info
;  'warn' -  Warn
;  'error' -  Error
;  'critical' -  Critical
;
"""

        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nloglevel = " + self.loglevel + "\n")
        
        comment = """
;
; User Specified parameters for the RSVPtrain interface
; User can modify this section as see fit

[RSVPtrainUserSpecifiedParams]

;
; Full path to the directory where the training images are located. The folder must include
; two subfolders called 'targetpool' and 'nontargetpool' containing example images of targets and distractors
;
;
"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\ntrainPath = " + self.trainPath + "\n")

        comment = """
;
;
; Full path to the XML input file. This parameter is used to load the data for a training session if the XML input is enabled.
;

"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\ntrainXMLfile = " + self.traininputXMLfile + "\n")



        # simulation mode
        comment = """
;
; Set to one to run script in simulation mode (i.e communicating with the simulated server), set to 0
; to communicate directly with the CBCI server.
;
"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nsimulationMode = " + str(self.simulationMode) + "\n")

        # run as standalone

        comment = """
;
; Set this to run either component to a stand alone mode, does not require CBCI server to be running.
;
"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nrun_as_standalone = " + str(self.run_as_standalone) + "\n")

# use_predefined_ordering

        comment = """
;
; Run test mode using predefined ordering 
;
"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nuse_predefined_ordering = " + str(self.use_predefined_ordering) + "\n")



        # Presentation frequency parameter

        comment = """        
;
; Frequency of presentation of the image in Hz, typical values 10 or 5
;
"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\npresentationFreq = " + str(self.presentationFreq) + "\n")

        # Monitor logging
        comment = """ 
;
; Monitors the presentation frequency of consecutive images stimulus in blocks, will generate a log file with the difference between every pair 
; of consecutive images.     
;
; 0 : disable ,    suggested for real experiment
; 1 : Monitor performance, generate a log file with differences in the image presentation
; 2 : Monitor performance as in mode 1, but also injects time delayes randomly during the presentaion, to sumulate context switch, and multi-tasking systems.
"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nmonitorFrequency = " + str(self.monitorFrequency) + "\n")


        comment = """
;
; Number of targets per block in the training script.
;
"""

        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nnumTargets = " + str(self.trainnumTargets) + "\n")

        comment = """
;
; Number of distractors per block during the training phase
;
"""
        
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nnumNontargets = " + str(self.trainnumNontargets) + "\n")

        comment = """
;
; Specifies the directory where the output of the training session will be stored  used only when input_from parameters is set to 2
;
"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\noutputPath = " + self.trainoutputPath + "\n")

        comment = """
;
; Specifies the XML file where the output of the training session will be stored, used only when input_from parameters is set to 2
;
"""
        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\noutputXMLfile = " + self.trainoutputXMLfile + "\n")


        comment = """
;
; User Specified parameters for the RSVPtest interface
; User can modify this section as see fit

[RSVPtestUserSpecifiedParams]

;
; Full path to the directory where the testing images are located. The folder must include
; two subfolders called 'targetpool' and 'nontargetpool' containing example images of targets and distractors
;
"""

        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\ntestPath = " + self.testPath + "\n")

        comment = """
;
;
; Full path to the XML input file. This parameter is used to load the data for a training session if the XML input is enabled.
;
"""

        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\ntestXMLfile = " + self.testinputXMLfile + "\n")

        comment = """
;
; Specifies the directory where the output of the testing session will be stored
;
"""

        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\noutputPath = " + self.testoutputPath + "\n")


        comment = """
;
; Specifies the XML file where the output of the testing session will be stored.
;
"""

        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\noutputXMLfile = " + self.testoutputXMLfile + "\n")
    
        comment = """
;
; Number of targets per block in the testing script, valid if XML input specified
;
"""

        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nnumTargets = " + str(self.testnumTargets) + "\n")
    
        comment = """
;
; Number of distractors per block during the testing phase, valid if XML input specified
;
"""


        f.write("\n;\n; " + comment + "\n;\n")
        f.write("\nnumNontargets = " + str(self.testnumNontargets) + "\n")



        comment = """



[BCIengineCodes]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This section is tite toe the BCI engine, do not modify
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
; indicate starting an stimulus block
;

beginBlock = 20

;
; indicate end of stimulus block
;

endBlock = 25

;
; Reference value of the stimulus
;

baseRef = 40

;
; labeled non target
;

nonTargetcd = 80


;
; labeled target
;

targetcd = 160

;
; unlabeled stimulus
;

unlabledStimulus = 200

;
; labeled target testing stimulus
;

testTarget = 210

;
; labeled non target test stimulus
;

testNonTarget = 220

;
; unknown stimulus classify imitiatly
;

unlabeledStimulusOnline = 240

;
; Request last blocks results
;

getBlockResults = 30

;
; indicates begining of a training session, train mode
;

trainModeStart = 8

;
; indicate the begining of a testing mode
;

testModeStart = 10

;
; Train classifier on collected data
;

doTrain = 12


;
; Terminate the session
;

doEndSession = 15

;
; Request from the server to pay attention to its TCP/IP  input for commands
;

attention = 17
"""
        f.write("\n;\n; " + comment + "\n;\n")        
        f.close()






    ##############################################
    # update methods    
    ##############################################
    
    def updatetrainoutputPath(self,dname):
        self.trainoutputPath = dname


    def updatetrainoutputXML(self,fname):
        self.trainoutputXMLfile = fname

    def updatetestoutputPath(self,dname):
        self.testoutputPath = dname

    def updatetestoutputXML(self,fname):
        self.testoutputXMLfile = fname
        
    def updatetraininputPath(self,dname):
        self.trainPath = dname

    def updatetraininputXML(self,fname):
        self.traininputXMLfile =fname
        
    def updatetestinputPath(self,dname):
        self.testPath = dname

    def updatetestinputXML(self,fname):
        self.testinputXMLfile = fname

        
    def updatebgColor(self,value):
        self.background_color_str = str(value) + ',' + str(value) + ',' + str(value) + ', 1.0'

    def updateFrequency(self,value):
        self.presentationFreq = value

    def updateLoglevel(self,lv):
      if (lv==1):
        self.loglevel = 'debug'
      elif (lv==2):
        self.loglevel = 'info'
      elif (lv==3):
        self.loglevel = 'warn' 
      elif (lv==4):
        self.loglevel = 'error'
      elif (lv==5):
        self.loglevel = 'critical'


    def updateRunasStandalone(self,val):
      self.run_as_standalone = val

    def updateUsePredefinedOrdering(self,val):
      self.use_predefined_ordering = val
