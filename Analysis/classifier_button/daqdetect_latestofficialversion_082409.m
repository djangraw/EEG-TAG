function res = daqdetect(obj,data)
% 
% Author: Christoforos Christoforou
% 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Pragma  allows to compile function called by feval when that function is
% not referenced any other place.
%
% Here we will list all classifiers available to the core module
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% pragma definition.

%#function multiwindowFDA_init,multiwindowFDA_preprocess,multiwindowFDA_train,multiwindowFDA_run

global t;
global fig;
global traintriagefig testtriagefig
global htraintriage htesttriage

global TCPIPstruct;
global eventBuffer epochParams Cparams Classifier trainingDatabase resultsDatabase;

global trigger Pfilt Pdetect eegdatafilt;





%**************************************************************************
%
% This is the first time this method is excecuded, add all initialization
% code here. The varuable first must be initialized to true in the main
% program.
%
%**************************************************************************
buffersize = 20;                            % This indicates the maximum active events in the circular buffer, more details the documentation (ROFL)

tic;
if (obj.triggersExecuted == 0)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % set up the parameters 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    D=73; % total number of channels: data + control
    fs=2048; % original (biosemi) sampling rate
    fsref=2048; % the downsampled rata which easies memory
    eegchan = [3:66]; % indices of data channels

   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Define epoch parameters, How the epoching will be define,
    % TODO: Make this option as an input from ini file.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    Classifier.initfnc = 'multiwindowFDA_init';
    Classifier.preprocfnc = 'multiwindowFDA_preprocess';
    Classifier.classtrainfnc = 'multiwindowFDA_train';
    Classifier.classifyfnc = 'multiwindowFDA_run';
    
        
    
    

    windowStartSec=[0.1:0.1:1.1];  % 
    windowEndSec = windowStartSec+0.1;% 
    Classifier.UserParams.numofwindows = length(windowStartSec);
    
    Classifier.UserParams.windowStart =  round(windowStartSec*fsref)+1 
    Classifier.UserParams.windowEnd   = round(windowEndSec*fsref);
    Classifier.UserParams.eegChannels = eegchan;
 
    
    trainingDatabase.Xtargets = [];
    trainingDatabase.Xnontargets = [];
    trainingDatabase.targetCounter = 0;
    trainingDatabase.nontargetCounter = 0;
    
    
    resultsDatabase.data{1} = [];
    resultsDatabase.sessionId = 0;
    resultsDatabase.currentBlock = 0;
    resultsDatabase.imagesInCurrentBlock = 0;
    resultsDatabase.blockcount = [];
    resultsDatabase.blockStatus = 0;  
    
    
    
    % initialize the classifier
    [Cparams] = feval(Classifier.initfnc,Classifier.UserParams);
       
    duration_sec = 1.2; % epoch by taking duration_sec seconds of data for each trial
    epochParams.duration = round(duration_sec*fsref);   % number of samples in each epoch
    %epochParams.duration = round(600.*(fs./1000));   % number of seconds
    epochParams.channels_subset = [eegchan];   % Channels to be used in the analysis.
    
    
    % initialize Pfilt
    Pfilt = preprocessinit(D,fs,fsref,eegchan);
   
    % for debug
    trigger.counter = 0;
    trigger.channel = [];
    
    % initialize event buffer
    eventBuffer = [];
end  % end of initialization code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


blklen = obj.samplesPerTrigger;
X = data;                          % get current block of data
X=X(:,find(~isnan(X(1,:))));       % Remove NaN's which normally separate triggers

%trigger.channel = [trigger.channel X(2,:)];
%save('chrisdebug.mat','trigger');


X(2,:) = bitand(X(1,:),4096) > 0;               % Extract bit 12 bits of the trigger channels for the button keypad
X(1,:) = bitand(X(1,:),255);                    % Extract event time markers


%
% Pre-processing the row data
%
tic;
[Xfilter,Pfilt] = preprocess(X,Pfilt);
tmp=toc;
% obtain a list of events to be processed
[eventsQueue eventBuffer]= extractEvents(Xfilter,eventBuffer,epochParams);

% process events loop

if (~isempty(eventsQueue))
    for lcv=1:length(eventsQueue.type),
        switch eventsQueue.type(lcv)
            case 20,
                % Indicate starting a stimulus block
                fprintf('Start new block...\n');
                resultsDatabase.currentBlock = resultsDatabase.currentBlock + 1;
                resultsDatabase.data{resultsDatabase.currentBlock} =[];
                resultsDatabase.imagesInCurrentBlock = 0;
                resultsDatabase.blockStatus = 1;               

            case 25,
                fprintf('End block \n');
                % Indicate end of stimulus block
                resultsDatabase.blockStatus = 0;               
                resultsDatabase.blockcount(resultsDatabase.currentBlock) = resultsDatabase.imagesInCurrentBlock;   
                
                % If requested plot summary of the current results status.
                operatorFeedback(resultsDatabase,obj.feedback);
                drawnow;
            case 80,
                % Labeled stimulus as non target
                [Xproc, Cparams] = feval(Classifier.preprocfnc,eventsQueue.data(:,:,lcv),[],Cparams);
                Ey = feval(Classifier.classifyfnc, Xproc,Cparams);
                [resultsDatabase] = add2resultset(Ey,resultsDatabase,80);
                
                class = 0;
                [Xproc, Cparams] = feval(Classifier.preprocfnc,eventsQueue.data(:,:,lcv),class,Cparams);
                [trainingDatabase] = add2trainingset(Xproc,class,trainingDatabase);
%                Ey = feval(Classifier.classifyfnc, Xproc,Cparams);
%                [resultsDatabase] = add2resultset(Ey,resultsDatabase,80);
          
            case 160,
                % Labeled stimulus as target
                % Test before use it to update the classifier.
                [Xproc, Cparams] = feval(Classifier.preprocfnc,eventsQueue.data(:,:,lcv),[],Cparams);
                Ey =   feval(Classifier.classifyfnc, Xproc,Cparams);
                [resultsDatabase] = add2resultset(Ey,resultsDatabase,160);
                % now update the classifier.
                class = 1;
                [Xproc, Cparams] = feval(Classifier.preprocfnc,eventsQueue.data(:,:,lcv),class,Cparams);
                [trainingDatabase] = add2trainingset(Xproc,class,trainingDatabase);
               % Ey =   feval(Classifier.classifyfnc, Xproc,Cparams);
               % [resultsDatabase] = add2resultset(Ey,resultsDatabase,160);
            case 200,
                class = [];
                [Xproc, Cparams] = feval(Classifier.preprocfnc,eventsQueue.data(:,:,lcv),class,Cparams);
                Ey =   feval(Classifier.classifyfnc, Xproc,Cparams);
                [resultsDatabase] = add2resultset(Ey,resultsDatabase,200);
                % Unlabeled stimulus
            case 210,
                % labeled target for testing, simplu indicate it on the results
                class = [];
                [Xproc, Cparams] = feval(Classifier.preprocfnc,eventsQueue.data(:,:,lcv),class,Cparams);
                Ey =   feval(Classifier.classifyfnc, Xproc,Cparams);
                [resultsDatabase] = add2resultset(Ey,resultsDatabase,210);
            case 220,
                % labeled non-target for testing, simply indicate on the
                % results
                class = [];
                [Xproc, Cparams] = feval(Classifier.preprocfnc,eventsQueue.data(:,:,lcv),class,Cparams);
                Ey =   feval(Classifier.classifyfnc, Xproc,Cparams);
                [resultsDatabase] = add2resultset(Ey,resultsDatabase,220);
                % Unlabeled stimulus
            case 240,
                % unlabeled stimulus classify and send result asap
                class = [];
                [Xproc, Cparams] = feval(Classifier.preprocfnc,eventsQueue.data(:,:,lcv),class,Cparams);
                Ey =   feval(Classifier.classifyfnc, Xproc,Cparams);
                [resultsDatabase] = add2resultset(Ey,resultsDatabase,240);
            case 30,
               fprintf('Requested Last block results\n');
                 block_id = length(resultsDatabase.blockcount);
                blocksize = resultsDatabase.blockcount(block_id);
                msg = resultsDatabase.data{block_id}(1:blocksize,:);
                [dummy idx] = sort(msg(:,3),'descend');
                [dummy2 idx2] = sort(idx);
                msg(:,4) = idx2;
                msgtxt = mat2str(msg(:,1:4),5);
                strlength = length(msgtxt);

                if (obj.simmulation)
                    dirname = ['simmulationResults/'];
                    if (~exist(dirname)),
                       mkdir(dirname); 
                    end;
                    fid = fopen([dirname 'block_' num2str(block_id) '.res'],'wt');
                    fprintf(fid,'%3.2f  %3.2f %3.5f %3.5f %3.5f\n',msg');
                    fclose(fid);
                  else
                    try
                        TCPIPstruct.os.write(msgtxt, 0,strlength-1);
                        TCPIPstruct.os.flush();
                    catch
                        break;
                    end
                
                end;
            case 8,
                fprintf('Entering training mode\n');
                % Indicates begining of a training session, train mode
            case 10,
                 %indicate the begining of a testing mode
                 if (obj.simmulation)
                    % take care in case we are in simmulation mode
                    session_id = obj.simClassifier;
                    fprintf(['Simmulated classifier session: ' session_id ' loaded\n']);
                 else
                 
                     fprintf('Waiting for session_id input...');
                     session_id = TCPIPstruct.is.readLine();
                     session_id = char(session_id);
                     fprintf('session obtained\n');
                  end;  % end of else                    
                 
                  try
                    load(['./' session_id '/classifier.mat']);
                    resultsDatabase = add2resultset(); % initialize the resutls Database      
                    msgtxt='OK\n';                
                  catch 
                    msgtxt= ['Incorrect Session id \n'];
                  end
                  
                  if (~obj.simmulation)
                      try
                         TCPIPstruct.os.write(msgtxt,0,length(msgtxt));
                         TCPIPstruct.os.flush();
                      catch
                         break;
                      end;
                  end;
            case 12,
                % debug 
                fprintf('training classifier...\n');
                % Train classifier on collected data
               
                Cparams = feval(Classifier.classtrainfnc ,trainingDatabase, Cparams);
                session_id = ['_cbci_' num2str(now)];
                mkdir(session_id);   % MKDIR(PARENTDIR,NEWDIR) replace with this
                % save the database
                save([session_id '/trainDatabase.mat'],'trainingDatabase');
                save([session_id '/classifier.mat'],'Cparams','Classifier','epochParams');
                save([session_id '/resultsDatabase.mat'],'resultsDatabase'); 
                strlength = length(session_id);
                if (~obj.simmulation),
                    try
                       TCPIPstruct.os.write(session_id, 0,strlength);
                       TCPIPstruct.os.flush()
                    catch
                        break
                    end
                end;  % if not in simmulation mode
                fprintf('Classifier Trainied...\n');
            case 15,
                fprintf('Session Termination request\n');
                % Terminate the session,
                obj.stopSession = 1; % causes CBCI system to stop session execution and wait for new TCP/IP session
            case 17,
                fprintf('Waiting for TCP/IP input...');
                % Request from the server to pay attention to its TCP/IP  input for commands
        end;      % switch statement
    end; % for loop
end;  % if ~isempty


%{
if (~isempty(eventsQueue)),
   eventsQueue;
   save(['debug_t' num2str(trigger.counter) '.mat'],'eventsQueue');
end;


 trigger.counter =  trigger.counter + 1;
%}
%
% Do not edit the lines below, they are needed for communication with
% the C++ aquizition.
%

t = t + 1;
obj.triggersExecuted  = t;
res = obj;


return;

