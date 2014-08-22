from Tkinter import *
from tkFileDialog   import askopenfilename  
from tkFileDialog   import askdirectory
from tkFileDialog   import asksaveasfilename
from configClass    import configClass
import subprocess


class Application(Frame):
    
  def __init__(self, master=None):
    Frame.__init__(self, master) 
    self.grid(sticky=N+S+E+W)
    self.createWidgets()
    self.configParams = configClass('session_default.ini');
    self.updateGUI()
    
  def createWidgets(self):

     self.dialogBodyFrame = Frame(self,borderwidth = 0)
     self.dialogButtonFrame = Frame(self,borderwidth = 0)
     self.createDialogBody(self.dialogBodyFrame)
     self.createDialogButton(self.dialogButtonFrame)
     self.dialogBodyFrame.grid(row=0,rowspan=7,column=0,sticky=W)
     self.dialogButtonFrame.grid(row=7,column=0)
     
     top=self.winfo_toplevel() 
     top.rowconfigure(0, weight=1) 
     top.columnconfigure(0, weight=1) 
     self.rowconfigure(0, weight=1) 
     self.columnconfigure(0, weight=1)

  def createDialogBody(self,container):
     container.topContainer = Frame(container,borderwidth=2)
     container.centerContainer = Frame(container,borderwidth=2)
     container.bottomContainer = Frame(container,borderwidth=2)
     self.createTopWidgets(container.topContainer)
     self.createCenterWidgets(container.centerContainer)
     self.createBottomWidgets(container.bottomContainer)
     container.topContainer.grid(rowspan=3)
     container.centerContainer.grid(rowspan=3)
     container.bottomContainer.grid()
     
     
  def createDialogButton(self,container):
     self.runBtn = Button ( container, text="Run", command=self.handle_runbutton)
     self.quitBtn = Button ( container, text="Quit",command=self.quit)
     self.loadSessionBtn = Button ( container, text="Load Session", command=self.handle_loadbutton )
     self.saveSessionBtn = Button ( container, text="Save Session", command=self.handle_savebutton )
     self.runBtn.grid(row=0,column=4,sticky=E,padx=5)  
     self.quitBtn.grid(row=0,column=3,sticky=E,padx=5)
     self.loadSessionBtn.grid(row=0,column=2,sticky=E,padx=5)
     self.saveSessionBtn.grid(row=0,column=1,sticky=E,padx=5)
     
  def createTopWidgets(self,container):

     # Define the mode selection radiobuttons
     self.runMode = IntVar()
     self.runMode.set(1) # Default Value.
     Label(container, text="Configure/Run in:").grid(row=0,column=0,sticky=W,padx=35)
     Radiobutton(container, text="Train mode", variable=self.runMode, value=1,command=self.handle_selectmode_radio).grid(row=1,column=0,sticky=W,padx=35)
     Radiobutton(container, text="Test mode", variable=self.runMode, value=2,command=self.handle_selectmode_radio).grid(row=2,column=0,sticky=W,padx=35)
     Radiobutton(container, text="Practice mode", variable=self.runMode, value=3,command=self.handle_selectmode_radio).grid(row=3,column=0,sticky=W,padx=35)

     self.inputType = IntVar()
     self.inputType.set(1)  #set to default value
     Label(container, text="Input type:").grid(row=0,column=2,sticky=W,padx=35)
     Radiobutton(container, text="Input from file structure", variable=self.inputType, value=1,command=self.handle_selectmode_radio).grid(row=1,column=2,sticky=W,padx=35)
     Radiobutton(container, text="Input from XML file", variable=self.inputType, value=2,command=self.handle_selectmode_radio).grid(row=2,column=2,sticky=W,padx=35)


  def createCenterWidgets(self,container,typeof=1):
     
     self.trainFileTabFrame = Frame(container,borderwidth=2)
     self.createTrainFromFileWidget(self.trainFileTabFrame)

     self.trainXMLTabFrame = Frame(container,borderwidth=2)
     self.createTrainFromXMLWidget(self.trainXMLTabFrame)

     self.testFileTabFrame = Frame(container,borderwidth=2)
     self.createTestFromFileWidget(self.testFileTabFrame)

     self.testXMLTabFrame = Frame(container,borderwidth=2)
     self.createTestFromXMLWidget(self.testXMLTabFrame)

     self.practiceFileTabFrame = Frame(container,borderwidth=2)
     self.createPracticeFromFileWidget(self.practiceFileTabFrame)

     self.practiceXMLTabFrame = Frame(container,borderwidth=2)
     self.createPracticeFromXMLWidget(self.practiceXMLTabFrame)


     # Defaut show the train from file fie now.
     self.trainFileTabFrame.grid()
     
     #Label(container, text="Center widgets").grid(row=0)

  def showStatus(self):
    runStatus = self.runMode.get()*10 + self.inputType.get();
  
    if (runStatus == 11):
      # train mode - file input
      self.trainFileTabFrame.grid()
      pass
    elif (runStatus == 12):
      # train mode - XML input
      self.trainXMLTabFrame.grid()
      pass
    elif (runStatus == 21):
      # test mode - file input
      self.testFileTabFrame.grid()
      pass
    elif (runStatus == 22):
      # test mode - XML input
      self.testXMLTabFrame.grid()
      pass
    elif (runStatus == 31):
      #  practice mode - file input
      self.practiceFileTabFrame.grid()
      pass
    elif (runStatus == 32):
      #  practice mode - xml input
      self.practiceXMLTabFrame.grid()
      pass
    
    
  def createBottomWidgets(self,container):
     # presentation frequency widget
     self.presentationFreqScale = Scale(container, from_=1, to=30,command=self.handle_presentationFreqScale)
     self.presentationFreqScale.set(10)
     self.presentationFreqScale.grid(row=1,column=0,sticky=W,rowspan=5)
     Label(container, text="Freq.(Hz):").grid(row=0,column=0)

     self.logLevel = IntVar()
     self.logLevel.set(3)
     Label(container, text="logLevel:").grid(row=0,column=2,sticky=W,padx=35)
     Radiobutton(container, text="debug", variable=self.logLevel, value=1,command=self.handle_selectLog_radio).grid(row=1,column=2,sticky=W,padx=35)
     Radiobutton(container, text="info", variable=self.logLevel, value=2,command=self.handle_selectLog_radio).grid(row=2,column=2,sticky=W,padx=35)
     Radiobutton(container, text="warn", variable=self.logLevel, value=3,command=self.handle_selectLog_radio).grid(row=3,column=2,sticky=W,padx=35)
     Radiobutton(container, text="error", variable=self.logLevel, value=4,command=self.handle_selectLog_radio).grid(row=4,column=2,sticky=W,padx=35)
     Radiobutton(container, text="critical", variable=self.logLevel, value=5,command=self.handle_selectLog_radio).grid(row=5,column=2,sticky=W,padx=35)

     # Run As standalong
     self.standAlone = IntVar()
     Checkbutton(container,text="Stand alone",variable=self.standAlone, command=self.handle_standAloneChbox).grid(row=3,column=6)
     # Run As standalong
     self.preDefinedOrder = IntVar()
     Checkbutton(container,text="display Order",variable=self.preDefinedOrder, command=self.handle_standAloneChbox).grid(row=4,column=6)


     # presentation frequency widget
     self.displayBgcolor = Button (container, bg="blue",width=10,height=2)
     self.displayBgcolor.grid(row=1,column=6, rowspan=2)
     self.bgColorScale = Scale(container, from_=0, to=255, resolution=1,command=self.handle_changebgscale)
     self.bgColorScale.set(255)
     self.bgColorScale.grid(row=1,column=7,sticky=W,rowspan=5)
     Label(container, text="Bg color):").grid(row=0,column=7)


  def createTrainFromXMLWidget(self,container):
     space_const = 5
     Label(container, text="Input XML file(training)").grid(row=0,column=1,padx=space_const,sticky=W)
     self.trainXMLfile = Entry(container);
     self.trainXMLfile.grid(row =0 , column = 2, padx=space_const)
     Button(container,command=self.handle_buttonchooseFile,text='...').grid(row=0, column=3,padx=space_const)

     Label(container, text="Output XML file(training)").grid(row=1,column=1,padx=space_const,sticky=W)
     self.trainOutputXML = Entry(container);
     self.trainOutputXML.grid(row =1 , column = 2,padx=space_const)
     Button(container,command=self.handle_button2chooseFile,text='...').grid(row=1, column=3,padx=space_const)

     Label(container, text="Number of Targets per block:").grid(row=2,column=1,padx=space_const,sticky=W)
     self.trainNumTargets = Entry(container,validate='focusout',validatecommand=self.validate_t1);
     self.trainNumTargets.grid(row =2 , column = 2,padx=space_const)

     Label(container, text= "Number of Non-targets per block:").grid(row=3,column=1,padx=space_const,sticky=W)
     self.trainNumNonTargets = Entry(container,validate='focusout',validatecommand=self.validate_nt1);
     self.trainNumNonTargets.grid(row =3 , column = 2,padx=space_const)


  def createTrainFromFileWidget(self,container):
     space_const = 5
     Label(container, text="Input path(training)").grid(row=0,column=1,padx=space_const,sticky=W)
     self.trainPathE = Entry(container);
     self.trainPathE.grid(row =0 , column = 2, padx=space_const)
     Button(container,command=self.handle_buttonchooseFile,text='...').grid(row=0, column=3,padx=space_const)

     Label(container, text="Output Path(training)").grid(row=1,column=1,padx=space_const,sticky=W)
     self.trainOutputPath = Entry(container);
     self.trainOutputPath.grid(row =1 , column = 2,padx=space_const)
     Button(container,command=self.handle_button2chooseFile,text='...').grid(row=1, column=3,padx=space_const)

     Label(container, text="Number of Targets per block:").grid(row=2,column=1,padx=space_const,sticky=W)
     self.trainNumTargetsFile = Entry(container,validate='focusout',validatecommand=self.validate_t1);
     self.trainNumTargetsFile.grid(row =2 , column = 2,padx=space_const)

     Label(container, text= "Number of Non-targets per block:").grid(row=3,column=1,padx=space_const,sticky=W)
     self.trainNumNonTargetsFile = Entry(container,validate='focusout',validatecommand=self.validate_nt1);
     self.trainNumNonTargetsFile.grid(row =3 , column = 2,padx=space_const)


  def createTestFromFileWidget(self,container):
     space_const = 5
     Label(container, text="Input path(testing)").grid(row=0,column=1,padx=space_const,sticky=W)
     self.testPathE = Entry(container);
     self.testPathE.grid(row =0 , column = 2, padx=space_const)
     Button(container,command=self.handle_buttonchooseFile,text='...').grid(row=0, column=3,padx=space_const)

     Label(container, text="Output path(testing)").grid(row=1,column=1,padx=space_const,sticky=W)
     self.testOutputPath = Entry(container);
     self.testOutputPath.grid(row =1 , column = 2,padx=space_const)
     Button(container,command=self.handle_button2chooseFile,text='...').grid(row=1, column=3,padx=space_const)
    
  def createTestFromXMLWidget(self,container):
     space_const = 5
     Label(container, text="Input XML file(testing)").grid(row=0,column=1,padx=space_const,sticky=W)
     self.testXMLfile = Entry(container);
     self.testXMLfile.grid(row =0 , column = 2, padx=space_const)
     Button(container,command=self.handle_buttonchooseFile,text='...').grid(row=0, column=3,padx=space_const)

     Label(container, text="Output XML file(testing)").grid(row=1,column=1,padx=space_const,sticky=W)
     self.testOutputXML = Entry(container);
     self.testOutputXML.grid(row =1 , column = 2,padx=space_const)
     Button(container,command=self.handle_button2chooseFile,text='...').grid(row=1, column=3,padx=space_const)

     Label(container, text="Number of Targets per block:").grid(row=2,column=1,padx=space_const,sticky=W)
     self.testNumTargetsXML = Entry(container,validate='focusout',validatecommand=self.validate_t2);
     self.testNumTargetsXML.grid(row =2 , column = 2,padx=space_const)

     Label(container, text= "Number of Non-targets per block:").grid(row=3,column=1,padx=space_const,sticky=W)
     self.testNumNonTargetsXML = Entry(container,validate='focusout',validatecommand=self.validate_nt2);
     self.testNumNonTargetsXML.grid(row =3 , column = 2,padx=space_const)

     

  
  def createPracticeFromFileWidget(self,container):
     space_const = 5
     Label(container, text="Input path(practice)").grid(row=0,column=1,padx=space_const,sticky=W)
     self.practicePathE = Entry(container);
     self.practicePathE.grid(row =0 , column = 2, padx=space_const)
     Button(container,command=self.handle_buttonchooseFile,text='...').grid(row=0, column=3,padx=space_const)


     Label(container, text="Output path(practice)").grid(row=1,column=1,padx=space_const,sticky=W)
     self.practiceOutputPath = Entry(container);
     self.practiceOutputPath.grid(row =1 , column = 2,padx=space_const)
     Button(container,command=self.handle_button2chooseFile,text='...').grid(row=1, column=3,padx=space_const)

     Label(container, text="Number of Targets per block:").grid(row=2,column=1,padx=space_const,sticky=W)
     self.practiceNumTargetsFile = Entry(container,validate='focusout',validatecommand=self.validate_t3);
     self.practiceNumTargetsFile.grid(row =2 , column = 2,padx=space_const)

     Label(container, text= "Number of Non-targets per block:").grid(row=3,column=1,padx=space_const,sticky=W)
     self.practiceNumNonTargetsFile = Entry(container,validate='focusout',validatecommand=self.validate_nt3);
     self.practiceNumNonTargetsFile.grid(row =3 , column = 2,padx=space_const)
    
  def createPracticeFromXMLWidget(self,container):

     space_const = 5
     Label(container, text="Input XML file(practice)").grid(row=0,column=1,padx=space_const,sticky=W)
     self.practiceXMLfile = Entry(container);
     self.practiceXMLfile.grid(row =0 , column = 2, padx=space_const)
     Button(container,command=self.handle_buttonchooseFile,text='...').grid(row=0, column=3,padx=space_const)

     Label(container, text="Output XML file(practice)").grid(row=1,column=1,padx=space_const,sticky=W)
     self.practiceOutputXML = Entry(container);
     self.practiceOutputXML.grid(row =1 , column = 2,padx=space_const)
     Button(container,command=self.handle_button2chooseFile,text='...').grid(row=1, column=3,padx=space_const)

     Label(container, text="Number of Targets per block:").grid(row=2,column=1,padx=space_const,sticky=W)
     self.practiceNumTargetsXML = Entry(container,validate='focusout',validatecommand=self.validate_t3);
     self.practiceNumTargetsXML.grid(row =2 , column = 2,padx=space_const)

     Label(container, text= "Number of Non-targets per block:").grid(row=3,column=1,padx=space_const,sticky=W)
     self.practiceNumNonTargetsXML = Entry(container,validate='focusout',validatecommand=self.validate_nt3);
     self.practiceNumNonTargetsXML.grid(row =3 , column = 2,padx=space_const)
  



  
  #######################################################################
  # Define event handlers handlers
  #######################################################################

  def update_textEntryFields(self):
     #
     # Update the configStructure again in case the user manually edited to file selection fields. In invalid input the original value remails.
     #  Note: Need to validate each of this methods.

     self.configParams.updatetraininputXML(self.trainXMLfile.get())
     self.configParams.updatetraininputPath(self.trainPathE.get())
     
     self.configParams.updatetestinputPath(self.testPathE.get())
     self.configParams.updatetestinputXML(self.testXMLfile.get())
     self.configParams.updatetrainoutputPath(self.trainOutputPath.get())
     self.configParams.updatetrainoutputXML(self.trainOutputXML.get())
     self.configParams.updatetestoutputPath(self.testOutputPath.get())
     self.configParams.updatetestoutputXML(self.testOutputXML.get())

     self.configParams.trainnumTargets = self.trainNumTargets.get()
     self.configParams.trainnumNontargets = self.trainNumNonTargets.get()
     self.configParams.testnumTargets = self.testNumTargetsXML.get()
     self.configParams.testnumNontargets = self.testNumNonTargetsXML.get()
     self.updateGUI()

     
  def handle_runbutton(self):
     self.update_textEntryFields()
     self.configParams.savetoConfigVersion1('__currentconfig.ini')
     appselect = self.runMode.get()
     if (appselect == 1):
        subprocess.Popen('python RSVPtrain.py __currentconfig.ini')
     elif (appselect == 2):
        subprocess.Popen('python RSVPtest.py __currentconfig.ini')
     elif (appselect == 3):  
        subprocess.Popen('python RSVPpractice.py __currentconfig.ini')

    

  
               
  def handle_loadbutton(self):
      fname = askopenfilename(defaultextension='*.ini')
      if len(fname)>0:
        newconfig = configClass(fname)
        if newconfig.getIsValidConfig():
           # if the configuration file is valid. proceed to load it.
           self.configParams = newconfig
        self.updateGUI()


  def handle_savebutton(self):
      fname = asksaveasfilename(defaultextension='*.ini')
      if len(fname)>0:
        self.configParams.savetoConfig(fname)


  # "Handling the change scale bar event."

  def handle_changebgscale(self,newscaleValue):
    
    rgb_tuple = (int(newscaleValue), int(newscaleValue), int(newscaleValue))
    tk_rgb = "#%02x%02x%02x" % rgb_tuple
    self.displayBgcolor.config(bg=tk_rgb)
    self.configParams.updatebgColor(float(newscaleValue)/255)


  def handle_presentationFreqScale(self,newscaleValue):
    self.configParams.updateFrequency(newscaleValue)
    
  def handle_button2chooseFile(self):

    runStatus = self.runMode.get()*10 + self.inputType.get();    

    if (runStatus == 11):
      # train mode - file input
      dname = askdirectory()
      if len(dname)>0:
         self.configParams.updatetrainoutputPath(dname)
         ##self.trainOutputPath.insert(0,dname)
      
    elif (runStatus == 12):
      # train mode - XML input
      fname = asksaveasfilename()  #askopenfilename()
      if len(fname)>0:
         self.configParams.updatetrainoutputXML(fname)
         ##self.trainOutputXML.insert(0,fname)
    elif (runStatus == 21):
      # test mode - file input
      dname = askdirectory()
      if len(dname)>0:
         self.configParams.updatetestoutputPath(dname)
         ##self.testOutputPath.insert(0,dname)
    elif (runStatus == 22):
      # test mode - XML input
      fname =  fname = asksaveasfilename()  #askopenfilename()
      if len(fname)>0:
         self.configParams.updatetestoutputXML(fname)
         ##self.testOutputXML.insert(0,fname)
      
    elif (runStatus == 31):
      #  practice mode - file input
      dname = askdirectory()
      if len(dname)>0:
         self.configParams.updatetrainoutputPath(dname)  # same as training session
         ##self.practiceOutputPath.insert(0,dname)

    elif (runStatus == 32):
      #  practice mode - xml input
      fname = asksaveasfilename() #askopenfilename()
      if len(fname)>0:
         self.configParams.updatetrainoutputXML(fname)
         ##self.practiceOutputXML.insert(END,fname)

    self.updateGUI()


  #
  # Button to open file chooser window
  #

  def handle_buttonchooseFile(self):
    runStatus = self.runMode.get()*10 + self.inputType.get();    

    if (runStatus == 11):
      # train mode - file input
      dname = askdirectory()
      if len(dname)>0:
         ##self.trainPathE.insert(0,dname)
         self.configParams.updatetraininputPath(dname)
    elif (runStatus == 12):
      # train mode - XML input
      fname = askopenfilename()
      if len(fname)>0:
         ##self.trainXMLfile.insert(0,fname)
         self.configParams.updatetraininputXML(fname)
    elif (runStatus == 21):
      # test mode - file input
      dname = askdirectory()
      if len(dname)>0:
         ##self.testPathE.insert(0,dname)
         self.configParams.updatetestinputPath(dname)
    elif (runStatus == 22):
      # test mode - XML input
      fname = askopenfilename()
      if len(fname)>0:
         ##self.testXMLfile.insert(0,fname)
         self.configParams.updatetestinputXML(fname)
    elif (runStatus == 31):
      #  practice mode - file input
      dname = askdirectory()
      if len(dname)>0:
         ##self.practicePathE.insert(0,dname)
         self.configParams.updatetraininputPath(dname)    # same as train
    elif (runStatus == 32):
      #  practice mode - xml input
      fname = askopenfilename()
      if len(fname)>0:
         ##self.practiceXMLfile.insert(END,fname)
         self.configParams.updatetraininputXML(fname)

    self.updateGUI()


  def handle_standAloneChbox(self):
     self.configParams.updateRunasStandalone(self.standAlone.get())
     self.configParams.updateUsePredefinedOrdering(self.preDefinedOrder.get())


  #
  #
  #

  def handle_selectmode_radio(self):
    # ungrid all.
    self.trainFileTabFrame.grid_remove()
    self.trainXMLTabFrame.grid_remove()

    self.testFileTabFrame.grid_remove()
    self.testXMLTabFrame.grid_remove()

    self.practiceFileTabFrame.grid_remove()
    self.practiceXMLTabFrame.grid_remove()

    self.configParams.input_from = self.inputType.get()
    self.showStatus()


  def handle_selectLog_radio(self):
     lv=self.logLevel.get()
     self.configParams.updateLoglevel(lv)
     self.updateGUI()

     
  def handle_loadSession_button(self):
     fname = askopenfilename()
     if len(fname)>0:
        self.session_name = fname
        loadsession(fname)

  ##########################################################
  #  Update parameters from configuration.
  ##########################################################

  def updateGUI(self):
    # all variables are checked from validity within configParams class

    self.clearEntryWidgetsText()
    
    # Update radio button, load from
    self.inputType.set(self.configParams.input_from)

    # Update training mode params
    self.trainXMLfile.insert(END,self.configParams.traininputXMLfile) 
    self.trainOutputXML.insert(END,self.configParams.trainoutputXMLfile)
    self.trainNumTargets.insert(END,self.configParams.trainnumTargets)
    self.trainNumNonTargets.insert(END,self.configParams.trainnumNontargets)          


    self.trainPathE.insert(END,self.configParams.trainPath) 
    self.trainOutputPath.insert(END,self.configParams.trainoutputPath)
    self.trainNumTargetsFile.insert(END,self.configParams.trainnumTargets) 
    self.trainNumNonTargetsFile.insert(END,self.configParams.trainnumNontargets)

    # update testing mode params.

    self.testXMLfile.insert(END,self.configParams.testinputXMLfile) 
    self.testOutputXML.insert(END,self.configParams.testoutputXMLfile)
    self.testNumTargetsXML.insert(END,self.configParams.testnumTargets)
    self.testNumNonTargetsXML.insert(END,self.configParams.testnumNontargets)

    self.testPathE.insert(END,self.configParams.testPath)
    self.testOutputPath.insert(END,self.configParams.testoutputPath)

    # Update practice mode params.
    self.practicePathE.insert(END,self.configParams.trainPath) 
    self.practiceOutputPath.insert(END,self.configParams.trainoutputPath) 
    self.practiceNumTargetsFile.insert(END,self.configParams.trainnumTargets) 
    self.practiceNumNonTargetsFile.insert(END,self.configParams.trainnumNontargets) 

    
    self.practiceXMLfile.insert(END,self.configParams.traininputXMLfile) 
    self.practiceOutputXML.insert(END,self.configParams.trainoutputXMLfile) 
    self.practiceNumTargetsXML.insert(END,self.configParams.trainnumTargets) 
    self.practiceNumNonTargetsXML.insert(END,self.configParams.trainnumNontargets) 


    # Update the bottom widgets, Freq, loging , stand alone, color

    self.presentationFreqScale.set(self.configParams.presentationFreq)
    if self.configParams.loglevel == 'debug': 
      self.logLevel.set(1)
    elif self.configParams.loglevel == 'info': 
      self.logLevel.set(2)  
    elif self.configParams.loglevel == 'warn': 
      self.logLevel.set(3)  
    elif self.configParams.loglevel == 'error': 
      self.logLevel.set(4)  
    elif self.configParams.loglevel == 'critical': 
      self.logLevel.set(5)  

     
    bg_tmp = self.configParams.background_color_str.split(',')
    bg_values = [float(bg_tmp[0]), float(bg_tmp[1]) , float(bg_tmp[2]) , float(bg_tmp[3])]

    self.bgColorScale.set(round(bg_values[0]*255))
    self.standAlone.set(int(self.configParams.run_as_standalone))
    self.preDefinedOrder.set(int(self.configParams.use_predefined_ordering))
    self.handle_selectmode_radio()  # update display option, to show the current mode.
    
    
  def clearEntryWidgetsText(self):
      # Update training mode params
      self.trainXMLfile.delete(0,END) 
      self.trainOutputXML.delete(0,END)
      self.trainNumTargets.delete(0,END) 
      self.trainNumNonTargets.delete(0,END) 


      self.trainPathE.delete(0,END) 
      self.trainOutputPath.delete(0,END) 
      self.trainNumTargetsFile.delete(0,END) 
      self.trainNumNonTargetsFile.delete(0,END) 

      # update testing mode params.

      self.testXMLfile.delete(0,END) 
      self.testOutputXML.delete(0,END) 
      self.testNumTargetsXML.delete(0,END) 
      self.testNumNonTargetsXML.delete(0,END) 
  
      self.testPathE.delete(0,END) 
      self.testOutputPath.delete(0,END) 

      # Update practice mode params.
      self.practicePathE.delete(0,END) 
      self.practiceOutputPath.delete(0,END) 
      self.practiceNumTargetsFile.delete(0,END) 
      self.practiceNumNonTargetsFile.delete(0,END) 

    
      self.practiceXMLfile.delete(0,END) 
      self.practiceOutputXML.delete(0,END) 
      self.practiceNumTargetsXML.delete(0,END) 
      self.practiceNumNonTargetsXML.delete(0,END) 


  ##################################
  # Validate the target and non-target values.
  # Note: a much better way to handle this would be to implement a validateEntry class to handle the validation internaly. Keep in mind for future mo
  ##################################
  
  def validate_t1(self):
    value = self.validate_int(1)
    if (value >=0):
       self.configParams.trainnumTargets = value
       self.updateGUI()
       return True
    else:
       self.updateGUI()
       return False


  def validate_nt1(self):

     value = self.validate_int(2)
     if (value >=0):
       self.configParams.trainnumNontargets = value
       self.updateGUI()
       return True
     else:
       self.updateGUI()
       return False

  def validate_t2(self):
    value = self.validate_int(3)
    if (value >=0):
       self.configParams.testnumTargets = value
       self.updateGUI()
       return True
    else:
       self.updateGUI()
       return False

  def validate_nt2(self):
    value = self.validate_int(4)
    if (value >=0):
       self.configParams.testnumNontargets = value
       self.updateGUI()
       return True
    else:
       self.updateGUI()
       return False

  def validate_t3(self):
    value = self.validate_int(5)
    if (value >=0):
       self.configParams.trainnumTargets = value
       self.updateGUI()
       return True
    else:
       self.updateGUI()
       return False

  def validate_nt3(self):
    value= self.validate_int(6)
    if (value >=0):
       self.configParams.trainnumNontargets = value
       self.updateGUI()
       return True
    else:
       self.updateGUI()
       return False

    
  
  def validate_int(self,_from):
    ivalue = -1
    if (_from==1):
      # Train - Target 
       if (self.inputType.get()==1):
         # from file
         value = self.trainNumTargetsFile.get()      
       else:
         # from XML
         value = self.trainNumTargets.get()
    elif (_from==2):
        # Train - nontarget
       if (self.inputType.get()==1):
         # from File.
         value = self.trainNumNonTargetsFile.get()        
       else:
         # from XML
         value = self.trainNumNonTargets.get()
    elif (_from==3):
        # Testing - Target
        value = self.testNumTargetsXML.get()
    elif (_from==4):
        # Testing - Non target
        value = self.testNumNonTargetsXML.get()
    elif (_from==5):
       if (self.inputType.get()==1):
         # from file  
         value = self.practiceNumTargetsFile.get()      
       else:
         # from XML
         value = self.practiceNumTargetsXML.get()
    elif (_from==6):
        # Train - nontarget
       if (self.inputType.get()==1):
         # from File.
         value = self.practiceNumNonTargetsFile.get()        
       else:
         # from XML
         value = self.practiceNumNonTargetsXML.get()
         
    try:
       ivalue = int(value)
    except ValueError:
       ivalue = -1

    
    return ivalue
    
app = Application() 
app.master.title("C^3Vision - Rapid Serial Visual Presentation") 
app.mainloop()
