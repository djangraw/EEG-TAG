from xml.sax.handler import ContentHandler 


class RSVPinputHandler(ContentHandler):

 def __init__ (self, fieldList):

   self.fieldList= fieldList;
   self.list = []
   self.object_info = 0
   self.filename = 0
   self.pathname = 0
   self.id = 0
   self.status = 0
   self.position_x = 0
   self.position_y = 0
   self.confidence = 0
   self.eegconfidence = 0
   self.groundTruth = 0
   self.dispOrder = 0
   self.rootpath = ''
   self.node = myNode()
   return





   
 def startElement(self, name, attrs):
     
   if name == 'object_info':
     self.object_info = 1
     self.node = myNode()
     self.object_idx = attrs.get('idx',"")
   elif ((self.object_info == 1) and (name == 'file_name')):  
     self.filename = 1
   elif ((self.object_info == 0) and (name == 'file_name')):  
     self.pathname = 1
   elif ((self.object_info == 0) and (name == 'path_name')):
     self.pathname = 1
   elif (name == 'id'):
     self.id = 1
   elif (name == 'status'):
     self.status = 1
   elif (name == 'position_x'):
     self.position_x = 1
   elif (name == 'position_y'):
     self.position_y = 1
   elif (name == 'confidence'):
     self.confidence = 1
   elif (name == 'eegconfidence'):
     self.eegconfidence = 1
   elif (name == 'groundTruth'):
     self.groundTruth = 1
   elif (name == 'dispOrder'):
     self.dispOrder = 1
   return

 def characters (self, ch):
   if (self.pathname==1):
        self.rootpath = ch
   elif (self.filename == 1):
       self.node.filename = self.node.filename + ch
   if (self.id== 1):
       self.node.id = self.node.id + ch
   if (self.status==1):
       self.node.status = self.node.status + ch
   if (self.position_x == 1):
       self.node.position_x = self.node.position_x + ch
   if (self.position_y == 1):
       self.node.position_y = self.node.position_y + ch
   if (self.confidence == 1):
       self.node.confidence = self.node.confidence + ch
   if (self.eegconfidence == 1):
       self.node.eegconfidence = self.node.eegconfidence + ch
   if (self.groundTruth == 1):
       self.node.groundTruth = self.node.groundTruth + ch
   if (self.dispOrder == 1):
       self.node.dispOrder = self.node.dispOrder + ch
       
 def endElement(self, name):
   if name == 'object_info':
     self.object_info = 0
     self.list.append(self.node)
   elif ((self.object_info == 1) and (name == 'file_name')):  
     self.filename = 0
   elif ((self.object_info == 0) and (name == 'file_name')):  
     self.pathname = 0
   elif ((self.object_info == 0) and (name == 'path_name')):  
     self.pathname = 0
   elif (name == 'id'):
     self.node.id = int(self.node.id)
     self.id = 0
   elif (name == 'status'):
     self.node.status = int(self.node.status)
     self.status = 0
   elif (name == 'position_x'):
     self.position_x = 0
     self.node.position_x = int(self.node.position_x)
   elif (name == 'position_y'):
       self.node.position_y = int(self.node.position_y)
       self.position_y = 0
   elif (name == 'confidence'):
     self.confidence = 0
   elif (name == 'eegconfidence'):
     self.eegconfidence = 0
   elif (name == 'groundTruth'):
     self.node.groundTruth = int(self.node.groundTruth)
     self.groundTruth = 0
   elif (name=='dispOrder'):
     self.node.dispOrder = int(self.node.dispOrder)
     self.dispOrder = 0    
   return

 def getParsedList(self):
    return self.list

 def getRootPath(self):
    return self.rootpath


class myNode():

    
 def __init__ (self):
    self.id = ""
    self.filename = ""
    self.status = ""
    self.confidence = ""
    self.eegconfidence = ""
    self.groundTruth = ""
    self.position_x = ""
    self.position_y = ""
    self.groundTruth = ""
    self.dispOrder = ""     

 def __getitem__(self, key):
    if (key=='dispOrder'):
       return self.dispOrder
    return self.dispOrder
