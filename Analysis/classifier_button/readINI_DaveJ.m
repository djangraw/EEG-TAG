function [D fs fsref eegchan] = readINI_DaveJ(filename)

% [D fs fsref eegchan] = readINI_DaveJ(filename)
% Reads in the following values from a .ini configuration file:
%    D: total number of channels: data + control
%    fs: original (biosemi) sampling rate
%    fsref: the downsampled rata which easies memory
%    eegchan: indices of data channels
% Created 8/24/09 by DJ for use with ProducerConsumer.
% Last updated 8/24/09 by DJ.

% set up
if nargin==0
    filename='CBCI.ini';
end
fprintf('Reading from .ini file %s... \n',which(filename))
fid = fopen(filename);

fieldstofind = {'numofchannels','channelList','recordFrom'};
results = struct;
while ~feof(fid) % Until we reach the end of the file
    thisLine = fgetl(fid);
    if ~isempty(thisLine) && thisLine(1)~=';' % not a comment
        for i=1:numel(fieldstofind)            
            if ~isempty(strfind(thisLine,fieldstofind{i}))
                thisLine = thisLine(thisLine~='"'); % get rid of quotes (on channelList)
                iStart = strfind(thisLine,'=')+1; % to the right of the equals sign
                iEnd = numel(thisLine); % until the end of the line
                results = setfield(results,fieldstofind{i},str2num(thisLine(iStart:iEnd))); % capture value as a number
            end
        end
    end
end
 
D = results.numofchannels;
if results.recordFrom==1 || D>12 % Recording from Biosemi
    fprintf('   Biosemi system detected...\n')
%     D=73; % total number of channels: data + control
    fs=2048; % original (biosemi) sampling rate
    fsref=2048; % the downsampled rata which easies memory    
%     eegchan = [3:66]; % indices of data channels
    eegchan = find(results.channelList>1 & results.channelList < 66); % find possible channels
else % recording from ABM
    fprintf('   ABM system detected...\n')
    %     D=10;
    fs=256;
    fsref=256;
%     eegchan=[3:11];
    eegchan = find(results.channelList>1 & results.channelList < 11); % find possible channels
end

fprintf('Success! \n')