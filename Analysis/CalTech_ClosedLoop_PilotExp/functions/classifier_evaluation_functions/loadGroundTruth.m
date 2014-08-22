%%%This loads a text file that contains the x-y coordinates of a Ground
%%%Truth.  The data is loaded into a single, 2-column matrix (col 1 is x,
%%%col 2 is y).
%%%
%%%[coordinates] = loadGroundTruth(filename);
%%%
%%%Last modified Feb 2009 EAP

function [coordinates] = loadGroundTruth(filename)

%%%Load the file into a matrix
coordinates = load(filename);
