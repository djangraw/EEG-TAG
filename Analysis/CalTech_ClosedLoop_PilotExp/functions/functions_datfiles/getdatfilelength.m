%%%This function determines how many analog data points there are in a .dat
%%%file that was created by ProducerConsumer.
%%%
%%%[qyt_of_numbers] = getdatfilelength(filename,Nchannels);
%%%Nchannels: optional, default is 73
%%%
%%%Last modified Jan 2009, EAP

function [qyt_of_numbers] = getdatfilelength(filename,Nchannels)

if nargin == 1
    Nchannels = 73;%Total number of analog channels in the .dat file.
end

%%%First determine how many data points exist in the .dat file
%%%
fileinfo       = dir(filename);
%%%Chris tells me that the BioSemi quantizes to 24 bits.  Paul says that
%%%sounds about right.  It looks like the numbers are actually stored in
%%%the .dat file as 64 bit doubles though.
encoding       = 64;%64 bit encoding
bitbyte        = 8; %8 bits to the byte
%%%FileSizeInBytes = (#channels * #datapts * bitspernumber)/8bitsperbyte
qyt_of_numbers = (fileinfo.bytes*bitbyte)/(encoding*Nchannels);
