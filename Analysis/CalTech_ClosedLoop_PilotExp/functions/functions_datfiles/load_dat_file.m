%%%
%%%This is a function for loading in one or more channels from a .dat file
%%%that was created by ProducerConsumer
%%%
%%%I believe the data is aranged in the .dat file such that you get the
%%%first value for each of the analog channels, then you get the 2nd value for
%%%each of the analog channels, then the third and so on (I could be wrong
%%%about this though).
%%%
%%%It looks like having two matrices of 10 x 1,000,000 takes the same
%%%amount of memory as one matrix os size 20 x 1,000,000
%%%
%%%The outputted matrix (output) is made of singles, so as to reduce memory
%%%requirements (.dat file data is only 24 bit precision anyway, so the 32
%%%bit single is perfectly adaquate).
%%%
%%%[output filetell] = load_dat_file(filename, Nchannels, mode, channelsubset, blocklength, fileoffset);
%%%
%%%filename => name of the .dat file to be loaded
%%%
%%%Nchannels => number of analog channels that were recorded in the .dat file
%%%
%%%mode => (optional, default is zero) if mode zero, the full amount of
%%%data will be loaded for each channel, if mode = 1, then only the
%%%specified amount of data will be loaded for each channel.  If the mode
%%%is one, this amount of data is specified in blocklength and must be
%%%small enough so that it can be loaded all in one go.  You can also
%%%specify how far from the beginning of the file this data is loaded using
%%%the fileoffset input to specify (the ending location of the  read is
%%%then specified in filetell).
%%%
%%%channelsubset => optional, default is that all channels are loaded,
%%%otherwise if fewer than all the channels are to be loaded that can be
%%%specified in a vector here
%%%
%%%blocklength => for memory purposes, when loading chunks of the .dat file
%%%you can specify how much data is loaded in each chunk, if
%%%not specified (or specified as -1) this function will automatically
%%%selected using the largest block length that the RAM will accommodate (up to
%%%half a gigabyte).
%%%
%%%For the 64 channel .dat files it looks the data is stored as follows:
% X(1,:) is the trigger channel
% X(2,:) is a virtual channel that increases by 1 from sample to sample are reset at the end of he buffer (you can ignore this)
% X(3:66,:)  is actual analog EEG data
% X(67:73,:) the recording of eight external BioSemi analog channels
%%%
%%%Last modified Jan 2009, EAP

function [output filetell] = load_dat_file(filename, Nchannels, mode, channelsubset, blocklength, fileoffset)

filetell = 0;

load_memory_limit = 0.5*(1000000000);%half a gig as matrix limiting size

if nargin < 2
    disp('Must at least specify .dat file name, and the number of recorded channels in the file');
    return;
end
if nargin < 6; fileoffset = 0; end;
if  nargin < 5; blocklength = -1; end;
if  nargin < 4; channelsubset = 1:Nchannels; end;
if  nargin < 3; mode = 0; end;

if isempty(fileoffset); fileoffset = 0; end;
if  isempty(blocklength); blocklength = -1; end;
if  isempty(channelsubset); channelsubset = 1:Nchannels; end;
if  isempty(mode); mode = 0; end;

%%%How many channels will get loaded
Nsubchannels = size(channelsubset,2);

%%%
%%%Determine how many data points there are in the .dat file
[qty_of_numbers] = getdatfilelength(filename,Nchannels);

switch mode
    case 1%similar to dat2core, just loading a chunk of data
        %%%
        %%%If not specified, try to load the whole file
        if blocklength == -1
            blocklength = qty_of_numbers;
        end
         %%%Open the file
         fid = fopen(filename,'r');
         %%%Go to the requested position
         if fileoffset ~=0 
             fseek(fid,fileoffset,'bof');
         end
         %%%Read in the requested chunk of data
         X   = fread(fid,[Nchannels blocklength],'double');
        %%%Now only save data from this block for the requested channels
        output = single(X(channelsubset,:));
        clear X         
        %%%Store the end location of this chunk of data
        filetell = ftell(fid);
        %%%Close the file
        fclose(fid);
         
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 0%loading all data for specified channels
        %%%
        %%%Pre-allocate the outputspace data matrix
        output = zeros(Nsubchannels,qty_of_numbers,'single');

        %%%Maybe we could assume a maximum RAM availability of 1 gigabyte,
        %%%pre-allocate the output matrix, check to see how much memory is left and
        %%%then assign the loading matrix size based on about 80% of the available
        %%%memory.
        if blocklength == -1
            allocatedRAM     = load_memory_limit;
            currentvariables = whos;
            [recomendedmatrixentries] = recommendedMatrixsize(allocatedRAM,currentvariables);
            blocklength      = floor(recomendedmatrixentries/Nchannels);
        end

        %%%Don't use a loading block that is longer than the file length.
        if qty_of_numbers <= blocklength
            blocklength = qty_of_numbers;
        end

        %%%Open the file
        fid = fopen(filename,'r');
        %fid = fopen(filename,'r','b');
        %%%
        %%%Now, go through the file and load in blocks of data, only keeping the
        %%%requested channels in the outputted data block
        %%%
        %%%The quickest way to do this may be to minimize the calls to fread, and
        %%%thus to load in the largest block that the computers memory will
        %%%tolerate during each call to fread (after having allocated space for the
        %%%final outputted data matrix).
        %%%
        numfullblocks = floor(qty_of_numbers/blocklength);
        %%%
        %%%Pre-allocate space for the loading block
        %X = zeros(Nchannels,blocklength,'double');
        %%%It looks like pre-allocated space doesn't do much good when using fread,
        %%%it is best just to have the fread assign the variable, and then clear it
        %%%at the end of its use
        for k=1:numfullblocks
            %%%The data is stored in the file as doubles, and must be loaded as
            %%%such.  However, it was only recorded with 24 bit precision, so once
            %%%loaded into matlab you can convert it to single (32-bit) precision
            %%%with no loss of accuracy (and for a savings in memory).
            %%%
            %%%Read in a block of data of length 'blocklength' for all 'D' channels
            X   = fread(fid,[Nchannels blocklength],'double');
            %%%
            %%%Now only save data from this block for the requested channels
            output(:,((blocklength*(k-1))+1):(blocklength*k)) = single(X(channelsubset,:));
            clear X
        end

        %%%Load in any remaining data
        if rem(qty_of_numbers,blocklength)>0
            X = zeros(Nchannels,rem(qty_of_numbers,blocklength),'double'); 
            X = fread(fid,[Nchannels rem(qty_of_numbers,blocklength)],'double');
            output(:,(numfullblocks*blocklength + 1):end) = single(X(channelsubset,:));
            clear X
        end

        %%%Close the file
        fclose(fid);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    otherwise
        disp('Unknown mode');
        output = 0;
        return;
end


%%%
%%%This is some code for comparing the output to the original dat2core m
%%%file method.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%For comparison
% filename = 'RSVP_test_SAR.dat';
% NS = 100000;
% mode = 2;
% fileseek = 0;
% [X fileseek] = dat2core(filename, NS, mode, fileseek);

%%%This will simply load several chunks from the file to determine how
%%%much data is actually there.
%%%
% LoadLength   = 50000;
% A            = zeros(73,LoadLength); 
% chunkcounter = 0;
% keeploading  = true;
% fileseek     = 0;
% remainder    = 0;
% while keeploading   
%     [A fileseek] = dat2core(filename,LoadLength,2,fileseek); % read next block of samples;
%     %%%See if the chunk of data is fullsized
%     if size(A,2) ~= LoadLength
%         %%%If not, you've hit the end of the file
%         remainder   = size(A,2);
%         keeploading = false;
%     else
%         %%%If so, count the chunk
%         chunkcounter = chunkcounter + 1; 
%     end
% end
