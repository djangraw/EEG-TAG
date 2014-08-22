%%%
%%%This takes a typical XML structure that Matlab can analyze and converts
%%%it back to and saves it as an XML file.
%%%
%%%You need to have access to the functions in the @xml and xmltree
%%%directories.
%%%
%%%[tree] = XMLstruct2file(XMLstruct,xmlfilename);
%%%
%%%Last modifed Feb 2009 EAP

function [tree] = XMLstruct2file(XMLstruct,xmlfilename)

%%%
%%%Convert the XMLstruct to an actual XML file (root tag hard coded)
tree = struct2xml(XMLstruct,'object_detection_result');
%%%
%uid = root(tree);
%[get(tree,uid,'name')]
%%%
%%%another option for finding the root tag
% fid = fopen('posChips_CV_SAM_top.xml','rt')
% root_tag=fgetl(fid);
% tree = struct2xml(XMLstruct,[root_tag(1,2:(end-1))]);
%%%
%%%Save the results as a new XML file.
save(tree,xmlfilename);
%save(tree,[xmlfilename(1,1:(end-4)),'_new.xml']);