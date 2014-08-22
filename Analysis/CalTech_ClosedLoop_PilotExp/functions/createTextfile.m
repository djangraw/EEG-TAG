
%%%This function creates a text file that you can write data to.
%%%
%%%[fid] = createTextfile(filename);
%%%
%%%Last modified Dec 2008 EAP

function [fid] = createTextfile(filename)

[fid] = fopen(filename, 'wt+');