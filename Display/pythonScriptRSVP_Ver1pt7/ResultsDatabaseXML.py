from xml.sax import make_parser
from xml.sax.handler import ContentHandler
from TrainingSetXMLHandler import *


class ResultsDatabaseXML:
   "Keeps track of the EEG confidences per block."

   def __init__(self,xmlFile):
      self.xmlinputFile = xmlFile
      self.dict = {}   # create a dictionary
      self.orderDisplayed = {} # create dictionary for order displayed
      self.currentResultIdx = 1
      

   def addResults(self,idx,value):
      for i in range(len(idx)):
         try:
           self.dict[idx[i]].append(value[i])
           self.orderDisplayed[idx[i]].append(self.currentResultIdx)
           self.currentResultIdx = self.currentResultIdx + 1
         except KeyError:
           self.orderDisplayed[idx[i]] = []
           self.orderDisplayed[idx[i]].append(self.currentResultIdx)
           self.currentResultIdx = self.currentResultIdx + 1
           self.dict[idx[i]] = []
           self.dict[idx[i]].append(value[i])
       
   def toXML(self,XMLoutputFilename= 'xml_RSVPoutput_renameme.xml'):
      parser = make_parser()   
      curHandler = RSVPinputHandler(('file_name','groundTruth'))
      parser.setContentHandler(curHandler)
      parser.parse(open(self.xmlinputFile))
      imList = curHandler.getParsedList()
      rootpath = curHandler.getRootPath()
      
      filename = XMLoutputFilename   #'xml_RSVPoutput_renameme.xml'
      f = open(filename,'w')

     
      f.write(self.private_XMLheaderString(rootpath))
              
      for cur in range(len(imList)):  
        node_str = self.private_XMLgetNodeString(imList[cur])
        f.write(node_str)
              
      f.write(self.private_XMLfooterString())
      f.close()        
              
        


   def private_XMLgetNodeString(self,mynode):
      xmlnode_string = self.private_XMLnodeheaderString(mynode)
      xmlnode_string = xmlnode_string + self.private_XMLeegConfidenceString(mynode)
      xmlnode_string = xmlnode_string + self.private_XMLdispayedOrder(mynode)   
      xmlnode_string = xmlnode_string + self.private_XMLnodefootterString(mynode)
      return xmlnode_string

   
   def private_XMLheaderString(self,rootpath):
      xmlheader_string = '<?xml version="1.0" ?>\n<object_detection_result>\n<file_name>' + rootpath +'</file_name>\n';
      return xmlheader_string


   def private_XMLfooterString(self):
     xmlfooter_string = '</object_detection_result>\n'
     return xmlfooter_string

   
   def private_XMLnodeheaderString(self,mynode):
       xmlnode_string = '<object_info idx="' + str(mynode.id) + '">\n<file_name>' + mynode.filename + '</file_name>	\n<id>' + str(mynode.id) + '</id>\n<status>' + str(mynode.status) + '</status>\n<position_x>' + str(mynode.position_x)+ '</position_x>\n<position_y>' +  str(mynode.position_y) + '</position_y>\n<confidence>' + str(mynode.confidence) +'</confidence>\n'
       return xmlnode_string
 
      
   def private_XMLeegConfidenceString(self,mynode):
      try:
        len(self.dict[str(mynode.id)])
        xmlnode_string =  '<eegconfidence>\n'
        for cur in range(len(self.dict[str(mynode.id)])):
           xmlnode_string = xmlnode_string + '<econf>'+ self.dict[str(mynode.id)][cur] + '</econf>\n'
        xmlnode_string = xmlnode_string + '</eegconfidence>\n'
      except KeyError:
        xmlnode_string = '<eegconfidence>0.0</eegconfidence>\n'
          
      return xmlnode_string       

   def private_XMLdispayedOrder(self,mynode):
      try:
        len(self.orderDisplayed[str(mynode.id)])
        xmlnode_string =  '<displayedOrderLastRun>\n'
        for cur in range(len(self.orderDisplayed[str(mynode.id)])):
           xmlnode_string = xmlnode_string + '<order>'+ str(self.orderDisplayed[str(mynode.id)][cur]) + '</order>\n'
        xmlnode_string = xmlnode_string + '</displayedOrderLastRun>\n'
      except KeyError:
        xmlnode_string = '<displayedOrderLastRun>0.0</displayedOrderLastRun>\n'
          
      return xmlnode_string       


   def private_XMLnodefootterString(self,mynode):
                                          
      xmlnode_string =  '<dispOrder>' +  str(mynode.dispOrder)  + '</dispOrder>\n' + '<groundTruth>' + str(mynode.groundTruth) + '</groundTruth>\n</object_info>\n'
      return xmlnode_string
   
