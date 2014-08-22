
%%%This function recommends a size for creating a block of data (double
%%%precision) based on the current memory usage of matlab and the specified
%%%amount of memory that Matlab can make use of.
%%%
%%%allocatedRAM should be in bytes.
%%%
%%%Last modified Jan 2009, EAP

function [recomendedmatrixentries] = recommendedMatrixsize(allocatedRAM, currentvariables)

%%%This assumes you are looking for a matrix that uses 64 bit precision
%%%(such as the default matlab doubles).

%allocatedRAM = 0.5*(1000000000);%half a gig

%currentvariables = whos;
currentmemory    = 0;
for k=1:length(currentvariables)
    currentmemory = currentmemory + currentvariables(k).bytes;
end

availableRAM = allocatedRAM - currentmemory;

%%%Use this if you only want to use available RAM up to the base 2 cutoff
%%%of memory
availableRAM = 2^floor(log2(availableRAM));

%%%A matrix of this many entries will take up the available RAM.
recomendedmatrixentries = availableRAM * (1/64) * (8);%%%64 bit encoding and 8 bits to the byte

recomendedmatrixentries = floor(recomendedmatrixentries);