import VisionEgg, pygame
from VisionEgg.Core import *
from VisionEgg.Text import *
from VisionEgg.Textures import *
from VisionEgg.FlowControl import Presentation, FunctionController
from VisionEgg.MoreStimuli import *


#
# This is the entry point for a feedback screen, This method is called by the RSVPtrain module at the end of each block.
# Its responsibility is to obtain any statistics from the data and set a visual feedback screen.
#
# Input:
#       screen - An OpenGL Object, obtained by a call to get_default_screen() constructore, it can be used to obtain information about the screen.
#                most common use of this is a call to screen.size property of the object which gives the resolution of the screen.
#
#       viewport - VisionEgg object which allows to create textures and text to be displayed on the screen,
#
#
#       classifierOutput - The results of the classifier on this block, see implementation of getblockStatistics() method in RSVPutilities.py for example how to use 
#
#          classifierOutput Structure
#               [imagePath imageName DetailsString]
#
#          where
#                imagePath - is a string for the image path
#                imageName - is a string with the image name
#                DetailsString = A SPACE separated string with the as follow
#
#                   classifierOutput = 'cb cs Ey resortidx'
#                    where
#                        cb is the current block's index
#                        cs index of the current image as was shown during presentation
#                        Ey classifier output
#                        resortidx - index of the image after resorting.
#
#
#       curTargList  - List of the current targets, see implementation of getblockStatistics() method in RSVPutilities.py for example how to use
#   
# Output: The output of the screen is a viewport VisionEgg object containing the frames to be displayed.
#
# The example code shows how to create a dummy feedback screen.
#


def show_feedback(screen,viewport,classifierOutput,curTargList):
   fname="freesansbold.ttf"
   fsize = 20;
   
   #
#   sttext = "This is a dummy feedback!!!"
#   statisticsText = Text( text = sttext, position = (screen.size[0]/2.0,screen.size[1]/2), font_name=fname,font_size = fsize,
#                     anchor = 'center', color = (0.0,0.0,0.0,1.0))   
  #viewport.parameters.stimuli=[statisticsText]

   #
   ###Here we use the input data to determine the identities of the target images
   #Also, determine when the images were shown during the RSVP, and where they
   #were re-ranked to after the presentation
   rlist = [];
   spots = [];
   for elem in range(len(curTargList)):
      if (curTargList[elem] == 1):
         res = classifierOutput[elem][2].rsplit()
         rlist.append((res[1], res[3]))
         spots.append((elem))#indices of the targets
         block_idx = res[0]#block number
   #
   ###This gives me the initial and final locations of the targets
   initial_order = [float(rlist[0][0]),float(rlist[1][0])]
   resort_order  = [float(rlist[0][1]),float(rlist[1][1])]
   #
   ###Now I need the names of the image files (including locations) of the target images
   imagename1 = classifierOutput[spots[0]][1]
   imagename2 = classifierOutput[spots[1]][1]
   #if in training mode must remove the _160_ from the filename
   if (imagename1[0] == '_'):
      imagename1 = imagename1[5:]
      imagename2 = imagename2[5:]
   #tie together the filename and filepath
   filename1 = os.path.join(classifierOutput[spots[0]][0],imagename1)
   filename2 = os.path.join(classifierOutput[spots[1]][0],imagename2)   
   #want to put the upper thumbnails (names 1&2) in the order they were shown, and then
   #put the lower thumbnails in the order of their classifier ranking
   if (resort_order[0] < resort_order[1]):
      filename3 = filename1
      filename4 = filename2
   else:
      filename3 = filename2
      filename4 = filename1

   #Make some text that specifically tells the presentation and classifier placements of the target images
   text_offset = .02*screen.size[1]
   sttext = "Blocks shown: " + block_idx
   statisticsText = Text( text = sttext, position = (5.0,screen.size[1]/2), font_name=fname,font_size = fsize,
                     anchor = 'left', color = (0.0,0.0,0.0,1.0))   
   strtext2 = "Presentation Order: " + str(rlist[0][0]) + " " + str(rlist[1][0])
   statisticsText2 = Text( text = strtext2, position = (screen.size[0]/2.0,screen.size[1]/2+text_offset), font_name=fname,font_size = fsize,
                     anchor = 'center', color = (0.0,0.0,0.0,1.0))
   strtext3 = "EEG Classifier Order: " + str(rlist[0][1]) + " " + str(rlist[1][1])
   statisticsText3 = Text( text = strtext3, position = (screen.size[0]/2.0,screen.size[1]/2-text_offset), font_name=fname,font_size = fsize,
                     anchor = 'center', color = (0.0,0.0,0.0,1.0))


   ################################
   ################################
   ################################
   #This section uses instances of the Target2D class to make boxes and lines
   #screen.size[0] is the horizontal dimension
   #the origin for screen coordinates is the lower left corner of the screen
   #
   #these are basic parameters for the boxes
   rectangle_ht = 0.1*screen.size[1]
   rectangle_wd = 0.5*screen.size[0]
   box_thickness = 5.0
   #Location of boxes on the screen
   box_up_y = 0.5*screen.size[1] + 0.5*rectangle_ht + 0.06*screen.size[1]
   box_down_y = 0.5*screen.size[1] - 0.5*rectangle_ht - 0.06*screen.size[1]
   #These are basic parameters for the lines
   display_line_ht = 0.8*rectangle_ht
   display_line_wd = 0.65*0.01*rectangle_wd
   #this is where the lines are located on the screen
   #vertically
#   display_line_ver_displacement_up  = 0.5*screen.size[1] + 0.5*display_line_ht + .05*screen.size[1]
#   display_line_ver_displacement_dwn = 0.5*screen.size[1] + 0.5*display_line_ht - rectangle_ht - .05*screen.size[1]
   display_line_ver_displacement_up  = box_up_y - 0.5*rectangle_ht + 0.5*display_line_ht 
   display_line_ver_displacement_dwn = box_down_y - 0.5*rectangle_ht + 0.5*display_line_ht
   #horizontally in top rectangle
   display_line_hor_displacement_top = 0.5*screen.size[0] + -1.0*0.5*rectangle_wd + initial_order[0]*.01*rectangle_wd
   display_line_hor_displacement_top2 = 0.5*screen.size[0] + -1.0*0.5*rectangle_wd + initial_order[1]*.01*rectangle_wd
   #horizontally in bottom rectangle
   display_line_hor_displacement_bttm1 = 0.5*screen.size[0] + -1.0*0.5*rectangle_wd + resort_order[0]*.01*rectangle_wd
   display_line_hor_displacement_bttm2 = 0.5*screen.size[0] + -1.0*0.5*rectangle_wd + resort_order[1]*.01*rectangle_wd
   #
   ###Size of feedback images
   image_ht = 0.25*screen.size[1];
   image_wd = image_ht
   #
   ###Coordinates of upper and lower feedback images [x,y]
   upper_lt = [0.5*screen.size[0] - 0.2*screen.size[0],
               0.5*screen.size[1] + 2*.05*screen.size[0] + rectangle_ht + 0.5*image_ht];
   upper_rt = [0.5*screen.size[0] + 0.2*screen.size[0],
               0.5*screen.size[1] + 2*.05*screen.size[0] + rectangle_ht + 0.5*image_ht];
   lower_lt = [0.5*screen.size[0] - 0.2*screen.size[0],
               0.5*screen.size[1] - 2*.05*screen.size[0] - rectangle_ht - 0.5*image_ht];
   lower_rt = [0.5*screen.size[0] + 0.2*screen.size[0],
               0.5*screen.size[1] - 2*.05*screen.size[0] - rectangle_ht - 0.5*image_ht];
   ################################
   ################################
   ################################
   #Now we need to start building the feedback images
   #####
   #this makes the upper box
   box_up_out = Target2D(size  = (rectangle_wd+2*box_thickness,rectangle_ht+2*box_thickness),
                     color      = (0.0,0.0,0.0,1.0), # Set the target color (RGBA) black
                     orientation = 0.0,
                            position = (screen.size[0]/2.0,box_up_y))
   box_up_in = Target2D(size  = (rectangle_wd,rectangle_ht),
                     color      = (1.0,1.0,1.0,1.0), # Set the target color (RGBA) white
                     orientation = 0.0,
                            position = (screen.size[0]/2.0,box_up_y))
   #viewport_box_up_out = Viewport(screen=screen, stimuli=[box_up_out])
   #viewport_box_up_in = Viewport(screen=screen, stimuli=[box_up_in])
   #####
   #this makes the lower box
   box_dwn_out = Target2D(size  = (rectangle_wd+2*box_thickness,rectangle_ht+2*box_thickness),
                     color      = (0.0,0.0,0.0,1.0), # Set the target color (RGBA) black
                     orientation = 0.0,
                          position = (screen.size[0]/2.0,box_down_y))
   box_dwn_in = Target2D(size  = (rectangle_wd,rectangle_ht),
                     color      = (1.0,1.0,1.0,1.0), # Set the target color (RGBA) white
                     orientation = 0.0,
                            position = (screen.size[0]/2.0,box_down_y))
   #viewport_box_dwn_out = Viewport(screen=screen, stimuli=[box_dwn_out])
   #viewport_box_dwn_in = Viewport(screen=screen, stimuli=[box_dwn_in])
   #####
   #this makes a pair of vertical lines (rectangles) in the upper box
   #
   vert_line1_up = Target2D(size  = (display_line_wd,display_line_ht),
                     color      = (1.0,0.0,0.0,1.0), # Set the target color (RGBA) black
                     orientation = 0.0,
                     position=(display_line_hor_displacement_top,display_line_ver_displacement_up))
   vert_line2_up = Target2D(size  = (display_line_wd,display_line_ht),
                     color      = (0.0,1.0,0.0,1.0), # Set the target color (RGBA) black
                     orientation = 0.0,
                     position=(display_line_hor_displacement_top2,display_line_ver_displacement_up))
#   viewport_vert_line1_up = Viewport(screen=screen, stimuli=[vert_line1_up])
#   viewport_vert_line2_up = Viewport(screen=screen, stimuli=[vert_line2_up])
   #
   #####
   #this makes a pair of vertical lines (rectangles) in the lower box
   #
   vert_line1_down = Target2D(size  = (display_line_wd,display_line_ht),
                     color      = (1.0,0.0,0.0,1.0), # Set the target color (RGBA) black
                     orientation = 0.0,
                     position=(display_line_hor_displacement_bttm1,display_line_ver_displacement_dwn))
   vert_line2_down = Target2D(size  = (display_line_wd,display_line_ht),
                     color      = (0.0,1.0,0.0,1.0), # Set the target color (RGBA) black
                     orientation = 0.0,
                     position=(display_line_hor_displacement_bttm2,display_line_ver_displacement_dwn))
#   viewport_vert_line1_down = Viewport(screen=screen, stimuli=[vert_line1_down])
#   viewport_vert_line2_down = Viewport(screen=screen, stimuli=[vert_line2_down])
   #
   ####
   #this makes instances of the 4 images (2 before and 2 after)
   #that are shown to the user to offer feedback
   #
   # Make textures from the image names before (1&2) and after (3&4) they were re-sorted

   texture1 = Texture(filename1)
   texture2 = Texture(filename2)
   texture3 = Texture(filename3)
   texture4 = Texture(filename4)
   #make thumbnails of the textures for user feedback
   imagestim1 = TextureStimulus(texture=texture1,
                              position = upper_lt,
                              anchor='center', size=(image_wd,image_ht),
                              mipmaps_enabled = 0, texture_min_filter=gl.GL_LINEAR,
                               shrink_texture_ok=1)
   imagestim2 = TextureStimulus(texture=texture2,
                              position = upper_rt,
                              anchor='center', size=(image_wd,image_ht),
                              mipmaps_enabled = 0, texture_min_filter=gl.GL_LINEAR,
                               shrink_texture_ok=1)
   imagestim3 = TextureStimulus(texture=texture3,
                              position = lower_lt,
                              anchor='center', size=(image_wd,image_ht),
                              mipmaps_enabled = 0, texture_min_filter=gl.GL_LINEAR,
                               shrink_texture_ok=1)
   imagestim4 = TextureStimulus(texture=texture4,
                              position = lower_rt,
                              anchor='center', size=(image_wd,image_ht),
                              mipmaps_enabled = 0, texture_min_filter=gl.GL_LINEAR,
                               shrink_texture_ok=1)
   # Create viewports for the thumbnails
#   imagestim_viewport1 = Viewport(screen=screen, stimuli=[imagestim1])
#   imagestim_viewport2 = Viewport(screen=screen, stimuli=[imagestim2])
#   imagestim_viewport3 = Viewport(screen=screen, stimuli=[imagestim3])
#   imagestim_viewport4 = Viewport(screen=screen, stimuli=[imagestim4])
   #
   #################################
   #################################
   ###Combine all the viewports so they can be show simultaneously
#   allviewports = [viewport_box_up_out,viewport_box_dwn_out,viewport_box_up_in,viewport_box_dwn_in,#boxes
#                   viewport_vert_line1_up,viewport_vert_line2_up,viewport_vert_line1_down,viewport_vert_line2_down,#lines
#                   imagestim_viewport1,imagestim_viewport2,imagestim_viewport3,imagestim_viewport4]#thumbnails


   viewport.parameters.stimuli=[box_up_out,box_up_in,box_dwn_out,box_dwn_in,#boxes
                                vert_line1_up,vert_line2_up,vert_line1_down,vert_line2_down,#lines
                                imagestim1,imagestim2,imagestim3,imagestim4,#thumbnails
                                statisticsText,statisticsText2,statisticsText3]#text

   return 1
   return viewport

