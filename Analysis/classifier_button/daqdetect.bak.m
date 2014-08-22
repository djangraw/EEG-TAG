function res = daqdetect(obj,data)
% Adam Gerson and Chris Christoforos, 4/5/2006
% Adam Gerson, 4/5/2006: Added eegdatafilt to track and display triage
% performance


global t;
global fig;
global traintriagefig testtriagefig
global htraintriage htesttriage
global TCPIPstruct;

global trigger Pfilt Pdetect eegdatafilt;


%**************************************************************************
%
% This is the first time this method is excecuded, add all initialization
% code here. The varuable first must be initialized to true in the main
% program.
%
%**************************************************************************
buffersize = 20;                            % This inicates the maximum active events in the circular buffer, more details the documentation

if (obj.triggersExecuted == 0)
    fs=2048;                                    % This is the sample frequency
    maxTriggers = 6000; 
    fsref=fs;
    buffersize = 20;                            % This inicates the
    %maximum active events in the circular buffer, more details the
    %documentation
    % Every unit adds  memory of about 1Mb, suggested
    % size 10
    % Initialize detection variables
    extchan = 234:241;
    %eegchan = [1+(1:128)]; % eeg channels
    %eegchan = [2+(1:64)]; % eeg channels
    eegchan = [3:16 18:66];

    % TEMPORARY CODE remove
    % eegchan = [3:27 30 33:59 61 62 64 66];
    %eegchan = [3:20];
    %D=137; % EEG and TRIGGER
    D=73; % EEG and TRIGGER

    channels=1:D;

    trigger.eegchan=eegchan; % EEG channels


    trigger.iter=0;                             % Number of iterations
    trigger.N=0;                                % This is the number if triggers(onsets), for each event
    trigger.continue=0;                         % flag indicates event
    %might continue into following acquisition, continue is set to the label
    %of the event, on the last sample
    % Continue might get one of the following values [80 160 120 200 40]
    %


    trigger.eventcounter = 0;                   % used to keep truck of
    %all the events onset, if in training mode it keeps the number of
    %elements in
    % trigger.cuievents if in testing mode it keeps the number of
    %elements in trigger.cuioutevent
    % Note, The varuable is re-initialized to zero for every set of
    %images .
    %



    trigger.switch=0; % indicates new trigger
    %trigger.label= []; % event labels
    trigger.label= zeros(1,maxTriggers); % event labels
    trigger.trainevents=[80 160]; % Training events (1): Distractor (2): Target
    trigger.testevents=[120 200]; % Testing events  (1): Distractor (2): Target

    % To keep track of events in set of training trials
    trigger.cuievents= zeros(2,maxTriggers);
    trigger.cuievents(2,:) = trigger.cuievents(2,:) * NaN;

    % To keep track of events in set of testing trials
    trigger.cuioutevents=zeros(2,maxTriggers);
    trigger.cuioutevents(2,:) = trigger.cuioutevents(2,:) * NaN;


    trigger.train=0; % Flag indicates whether training detector
    trigger.duration=round(600.*(fs./1000)); % Data to acquire for each trigger variable, corresponds to 600 miliseconds
    trigger.chrisStart = round(300 * 2048/1000);
    trigger.chrisEnd = round(350 * 2048/1000);
    trigger.numWindows = 10;        % number of windows to be used by the classifier

    trigger.windowStart =  [100:100:1000]; %[1:100:1600];   %[100:100:1000]; %210 round(200*2048/1000)];   %[1]    % define the 13 windows
    trigger.windowEnd   = trigger.windowStart + 99;
    %
    % Note: event thow only 100 events correspond to the images, total 101
    % events are send, one indicating the begining of the experiment.
    % So for uniformity we treat that start event as another event and
    % store its data (garbage usless data, but still).
    %

    trigger.data = cell(1,buffersize);
    trigger.filtdata = cell(1,buffersize);
    for i=1:buffersize,
        trigger.data{i} = zeros(D,trigger.duration);
        trigger.filtdata{i} = zeros(D,trigger.duration);
    end;

    %% trigger.filtdata = zeros(150,trigger.duration);
    % Allocate Space for the filter data, 100 correponts to the number of events. I'll make it a parameter later.
    trigger.dataaquired = zeros(1,maxTriggers);                 % This serves as a counter for the data samples aquired per event(image)


    %%%% V = eyecalibrate_biosemi([filepath fileeye],false);    %%% not tested yet

    %%%%Pfilt = preprocessinit(D,fs,fsref,channels,V);
    Pfilt = preprocessinit(D,fs,fsref,channels);

    % Initialize detector, seperated in trigger.numWindows windows.
    Pdetect = detectinit(length(eegchan));



    for i=2:(trigger.numWindows)
        Pdetect(i) = detectinit(length(eegchan));
    end;

    % This are variables to be used for the logistic regression level of
    % the classifier.

    trigger.W = 1e-10 * ones(trigger.numWindows + 1,1);  % Inital gess of W, small weight, logistic regression
    trigger.logistData = zeros(trigger.numWindows,2500); % allocate enought space to store all the samples
    % in the training session, if more that this number appear
    % in the program
    % will automatically alllocate the needed space
    %

    if (exist('knowledge.mat')),
       load('knowledge.mat');
       trigger.W = WW;
       fprintf('knowledge file has been loaded....');
    end
    
    trigger.logistLabels = zeros(2500,1);              % stores the true labels of all the samples
    trigger.logistTotal= 0;



    % Triage progress
    trigger.pretriage=[];
    trigger.posttriage=[];
    trigger.pretesttriage=[];
    trigger.posttesttriage=[];




    %
    % This part of the code simply increases the triggers executed to disallow
    % further initialization in following calls to this function
    %
    obj.triggersExecuted = obj.triggersExecuted + 1;
    t=0;
    %fig = figure;
    % set(fig,'Position',[0 0 1024,700]);

    eegdatafilt{8}=[];

end  % end of initialization code



%//////////////////////////////////////////////////////////////
%/


blklen = obj.samplesPerTrigger;
X = data;   %//getdata(obj,blklen)';                         % get current block of data

X=X(:,find(~isnan(X(1,:))));       % Remove NaN's which normally separate triggers
%X(1,:) = (X(1,:)./conversionfactor-1)./512;     % Do any nessecary conversion



baddata_idx = find(X(1,:) < 0);
if (length(baddata_idx>0)),
    Xtm = X(1,:);
    save('dubug.mat','Xtm');
%    X(1,baddata_idx)= 0;
end;

X(2,:) = bitand(X(1,:),4096) > 0;               % Extract bit 12 bits of the trigger channels for the button keypad
X(1,:) = bitand(X(1,:),255);                    % Extract event time markers


[Xfilter,Pfilt] = preprocess(X,Pfilt);

Xfilter(1,:) = X(1,:);
Xfilter(2,:) = X(2,:); 


%
% Uncomment this code if you need to generate the filtered version of the
% data. Uncomment only if run in simulation mode.
%

%fid = fopen('session_james_mode_2filtered.dat','a+');
%count = fwrite(fid,Xfilter,'float');
%fclose(fid);



% Manage triggers
trigger.iter=trigger.iter+1;

% Detect trigger onsets
events=find(diff(Xfilter(1,:),1) > 0)+1;
events=events(find(Xfilter(1,events)>0)); % Remove 0 events
if Xfilter(1,1)>0, events=[1 events]; end

eventonsets=events;

%
% This is the mechanism that will take care the continueation of the evens,
% is the continuation flag is a set on then the first event at the begining
% of the singal is iqnored. this works in combination with the statements
% at the end of this procedure.
%

events=find(Xfilter(1,:)>0); % redefine events for trigger.continue flag below


% Set up trigger variables for each onset in acquisition




%**************************************************************************
%
% This part of the code, extract and separates the data that correspond to
% the onset events.
%
%**************************************************************************

%fprintf('Event length: %d , \r\n', length(eventonsets));

for i=1:length(eventonsets),
    samplesavailable=blklen-eventonsets(i)+1; % Samples available in current block
    if (eventonsets(i)>1)|((eventonsets(i)==1)&(Xfilter(1,1)~=trigger.continue) & (Xfilter(1,1)~= 40)),
        % Do not set up trigger if continuation from previous acquisition
        trigger.N=trigger.N+1;
        % trigger.label(trigger.N)=Xfilter(1,eventonsets(i));

        %
        % CHRIS: This is a quick fix, to the problem of holding on
        % COM3,either because of e-prime implementation or because the way
        % trigger bit are interpreated (to be checked later), at random time  
        % rarely the trigger channel containes the wrong signal trigger 
        % value (i.e in the training phase will send the value 120 instread of 80 - 120 is the 
        % indicator for the test set distractor and 80 the value of the training set distractor)
        % 
        % A quick fix is to use the next to the onset trigger sample to
        % avoid this problem, hence the + 1 value. Note this might
        % potentially create a problem when the ONSET mislabeled sample appears EXACTLY the last 
        % element of the current block, The chance of that occuring is
        % prity low However.
        %
        % So it is important to identify the exact source of the
        % error in passing the trigger value.
        %
        if (eventonsets(i) >= size(Xfilter,2))
            trigger.label(trigger.N) = Xfilter(1,eventonsets(i));
        else
            trigger.label(trigger.N)=Xfilter(1,eventonsets(i) + 1);
        end
        % estimate how many samples we can get from the current dataacuire
        %fprintf('Current events processed: %d, \r\n', i);

        samplesrequired = min(blklen,eventonsets(i)-1 + trigger.duration-trigger.dataaquired(trigger.N));
        %{
        trigger.data{mod(trigger.N, buffersize) + 1}(:,eventonsets(i):samplesrequired)=X(:,eventonsets(i):samplesrequired);
        trigger.filtdata{mod(trigger.N, buffersize) + 1}(:,eventonsets(i):samplesrequired) = Xfilter(:,eventonsets(i):samplesrequired);
        plot(trigger.filtdata{mod(trigger.N, buffersize) + 1}(1,eventonsets(i):samplesrequired));
        drawnow;

        trigger.dataaquired(trigger.N) = trigger.dataaquired(trigger.N) + samplesrequired;
        %}
        samples2read = min(samplesavailable,samplesrequired);
        %fprintf( 'Samples2read: %d  Data aquired:  %d  Samples required: %d ' , samples2read, samplesavailable, samplesrequired);
        trigger.data{mod(trigger.N, buffersize) + 1}(:,(trigger.dataaquired(trigger.N)+1):(trigger.dataaquired(trigger.N) + samples2read))=X(:,eventonsets(i):(eventonsets(i) + samples2read-1));
       
        trigger.filtdata{mod(trigger.N, buffersize) + 1}(:,(trigger.dataaquired(trigger.N) + 1):(trigger.dataaquired(trigger.N) + samples2read)) = Xfilter(:,eventonsets(i):(eventonsets(i) + samples2read-1));
        
%        plot(trigger.filtdata{mod(trigger.N, buffersize) + 1}(2,:));
%        drawnow;

        trigger.dataaquired(trigger.N) = trigger.dataaquired(trigger.N) + samples2read;


        trigger.switch(trigger.N+1)=0;
    end
end % trigger setup



%**************************************************************************
%
% This part of the code goes over the current triggers and sets the
% parameters 'class', trigger.training, trigger.cuievents, and
% trigger.cuioutevents. Dependingon the value of these paramers there is
% going to be a different way to proceed on handling this data.
%
%**************************************************************************

fprintf('Samples acquired: %d , \r', trigger.N);

for i=1:trigger.N,


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    % This part of the code takes care the case where the data of an event
    % continue to more that one block (events at the boundaries).
    % trigger.switch(i) == 0 indicates that this is the first time that the
    % event was processed has already been processed above.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if trigger.switch(i)==1,
        if trigger.dataaquired(i)<trigger.duration,
            samplesrequired=min(blklen,trigger.duration - trigger.dataaquired(i));
            %%%%fprintf('CHRIS %d  %d  %d  %d',(trigger.dataaquired(i) + 1), samplesrequired)
            trigger.data{mod(i,buffersize) + 1}(:,(trigger.dataaquired(i) + 1):(trigger.dataaquired(i) + samplesrequired))= X(:,1:samplesrequired);
            trigger.filtdata{mod(i,buffersize) + 1}(:,(trigger.dataaquired(i) + 1):(trigger.dataaquired(i) + samplesrequired))= Xfilter(:,1:samplesrequired);
            %plot(trigger.filtdata{mod(i,buffersize) + 1}(1,:));
            %  plot(Xfilter(1,1:samplesrequired));
            %  drawnow;
            trigger.dataaquired(i) = trigger.dataaquired(i) + samplesrequired;
        end
    else
        trigger.switch(i)=1;
    end



    %//////////////////////////////////////////////////////////////////////
    %
    % If the current sample has enough data, it can be processed. So if the
    % data aquired is EXACTLY equal to the trigger.duration then the
    % following code will proceed to classify the data. After the sample
    % has been processed one, its corresponding aquired data is increase by
    % 1, thus avoiding reprocessing it next time this function is called.
    %
    %//////////////////////////////////////////////////////////////////////

    if trigger.dataaquired(i)==trigger.duration,

        trigger.dataaquired(i) = trigger.dataaquired(i) + 1;  % This event is going to be processed, so dont process it next time

        %//
        %// Set the proper parameters depending on if we are training or
        %// testing.
        %//

        class=-1; % Unrecognized event
        if ismember(trigger.label(i),[trigger.trainevents(1) trigger.testevents(1)]), class=0; end % Distractor events
        if ismember(trigger.label(i),[trigger.trainevents(2) trigger.testevents(2)]), class=1; end % Target events
        if ismember(trigger.label(i),trigger.trainevents), trigger.train=1; end % Training trials
        if ismember(trigger.label(i),trigger.testevents), trigger.train=0; end % Testing trials

        if (trigger.train==1)&(ismember(class,[0 1])),
            trigger.eventcounter = trigger.eventcounter + 1;       % keeps count of the total number of elements
            trigger.cuievents(:,trigger.eventcounter) = [trigger.label(i); NaN];
        end
        if (trigger.train==0)&(ismember(class,[0 1])),
            trigger.eventcounter = trigger.eventcounter + 1;        % keeps count of the total number of elements
            trigger.cuioutevents(:,trigger.eventcounter) = [trigger.label(i); NaN];
        end


        %
        % A label 20 indicates the begining of a new set of images (100 images). So
        % we need to initialize the counter
        %

        if trigger.label(i)==20,
            trigger.cuievents(2,:) = trigger.cuievents(2,:) * NaN;
            trigger.cuioutevents(2,:) = trigger.cuioutevents(2,:) * NaN;
            trigger.eventcounter=0;
            fprintf('resetting cui\n');
        end

        if (class==-1)&(~ismember(trigger.label(i),[1 20 40])),
            fprintf('Unrecognized event: %d %d\n',trigger.label(i),i); end


        %%
        %%
        %% HERE WE SUPPOSE TO HAVE SOME REAL DATA PROCESSING
        %%
        %%

        if (trigger.train==1)&ismember(class,[0,1]),
            % original code:
            %   [Y, Pdetect] = detect(trigger.filtdata{mod(i,buffersize) + 1}(trigger.eegchan,1:trigger.duration),Pdetect,class);

            % bilinear regression TEMPORARY
            %%trigger.filtdata{mod(trigger.N, buffersize) + 1}(:,eventonsets(i):samplesrequired)
            %plot(trigger.filtdata{mod(i,buffersize) + 1}(1,trigger.windowStart:trigger.windowEnd));
            %drawnow;

            %if ((i>55) && (i<80))
            %figure;
            %plot(trigger.filtdata{mod(i,buffersize) + 1}(1,trigger.windowStart:trigger.windowEnd));
            %drawnow;
            % end

            %[Y, Pdetect] = detect(trigger.filtdata{mod(i,buffersize) + 1}(trigger.eegchan,trigger.windowStart:trigger.windowEnd),Pdetect,class);

            %
            % Run all the classifiers on there corresponding windows, save
            % the result on the vector Yvec.
            %
            Ysum = 0;
            Yvec = zeros(1,trigger.numWindows);
            for j=1:trigger.numWindows,
                [Ytmp, Pdetect(j)] = detect(trigger.filtdata{mod(i,buffersize) + 1}(trigger.eegchan,trigger.windowStart(j):trigger.windowEnd(j)),Pdetect(j),class);
                Yvec(j) = Ytmp;
            end;

            trigger.logistTotal = trigger.logistTotal + 1;

            %
            % update logistic discriminant vector, with all the data
            % obtains so far.
            %
            if ((trigger.logistTotal == 2500) & (mod(trigger.logistTotal,100)==0)) % when do we train the logistic regr.

                numoftargers = size(Pdetect(1).mhistory{1},2);     % obtain the size of the number of targets
                numofdistractors = size(Pdetect(1).mhistory{2},2);     % obtain the size of the number of distractors
                VV = zeros(63,trigger.numWindows);
                for k=1:trigger.numWindows,
                    trigger.logistData(k,1:numoftargers) = Pdetect(k).v' * Pdetect(k).mhistory{1} + Pdetect(k).b;
                    trigger.logistData(k,(numoftargers+1):trigger.logistTotal) = Pdetect(k).v' * Pdetect(k).mhistory{2} + Pdetect(k).b;
                    VV(:,k) = Pdetect(k).v;
                end

                trigger.logistLabel(1:numoftargers) = 1;                            % target labels
                trigger.logistLabel((numoftargers+1):trigger.logistTotal) = 0;      % disctractors labels



                % trigger.logistData(:,trigger.logistTotal) = Yvec';
                % trigger.logistLabel(trigger.logistTotal) = class;


                % fid = fopen('logist_debug','a+');
                % count = fwrite(fid,trigger.logistData(:,1:trigger.logistTotal),'float');
                % fclose(fid);

                % if (trigger.logistTotal == 400)
                % end

                [trigger.W,loglik] = logisticregr(trigger.logistData(:,1:trigger.logistTotal)',trigger.logistLabel(1:trigger.logistTotal),trigger.W);
                if isinf(loglik) | isnan(loglik)
                    [trigger.W,loglik] = logisticregr(trigger.logistData(:,1:trigger.logistTotal)',trigger.logistLabel(1:trigger.logistTotal));
                end

                DATA = trigger.logistData(:,1:trigger.logistTotal);
                LABELS = trigger.logistLabel(1:trigger.logistTotal);
                WW = trigger.W;
                save('knowledge.mat','Pdetect','WW');
                save('logist_debug3.mat','DATA','VV','WW','LABELS');


            end     % of ecexuting logistic regression.
            Y = trigger.W(1) + trigger.W(2:end)' * Yvec';


            trigger.cuievents(2,trigger.eventcounter)= Y;

            eegdatafilt{3}(end+1)=Y(end);
            eegdatafilt{4}(end+1)=class;
            if 1 % This can be used to track button press
                % for biosemi the only issue is teasing out the button
                % events for the Cedrus box
                %if class==1,
                   buttonpress=find(trigger.filtdata{mod(i,buffersize) + 1}(2,:)>0);
                    if ~isempty(buttonpress),
                        eegdatafilt{7}(end+1)=buttonpress(1);
                    else
                        eegdatafilt{7}(end+1)=0;
                    end
               % else
               %     eegdatafilt{7}(end+1)=0;
               % end
            end % if 0
        end

        if (trigger.train==0)&(ismember(class,[0 1]))&(~isempty(trigger.cuioutevents)),

            % Logist Regr. with multiple windows

            Ysum = 0;
            Yvec = zeros(1,trigger.numWindows);
            for j=1:trigger.numWindows,
                [Ytmp] = detect(trigger.filtdata{mod(i,buffersize) + 1}(trigger.eegchan,trigger.windowStart(j):trigger.windowEnd(j)),Pdetect(j));
                Yvec(j) = Ytmp;
                Ysum = Ysum + Ytmp;
            end;

            Ytest = trigger.W(1) + trigger.W(2:end)' * Yvec';
          
            trigger.cuioutevents(2,trigger.eventcounter)=(Ytest);


            eegdatafilt{5}(end+1)=Ytest;
            eegdatafilt{6}(end+1)=class;

            if 1 % This can be used to track button press
                % for biosemi the only issue is teasing out the button
                % events for the Cedrus box
              %%  if class==1,
                    %buttonpress=find(bitand(trigger.filtdata{mod(i,buffersize) + 1}(1,:),3840)/255 >3);
                    buttonpress=find(trigger.filtdata{mod(i,buffersize) + 1}(2,:)>0);
                    %                    buttonpress=find(trigger.filtdata{i}(2,:)>.1);
                    if ~isempty(buttonpress),
                        eegdatafilt{8}(end+1)=buttonpress(1);
                    else
                        eegdatafilt{8}(end+1)=0;
                    end
              %%  else
              %%      eegdatafilt{8}(end+1)=0;
              %%  end
            end % if 0

        end


        %
        %
        % If enough data have been accumulated, set the flag to send results to
        % e-prime
        %
        if ((trigger.eventcounter==100)& (trigger.train == 1))...
                |((trigger.eventcounter==100)& (trigger.train == 0))...
                , class=2;
                fprintf('Debug  - events accumulated. %d   N: %d = \n',i,trigger.N);
        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % Debug, This code might need to change, it is used to make sure that if
        % 100 events are accumulated that the results will be observed. Here i
        % must consider the case where the event started here but not being
        % evaluated until the next call because of lack of data. SOS SOS
        %

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %      if ((trigger.eventcounter==100)&(~isnan(trigger.cuievents(2,end))))...
        %         |((trigger.eventcounter==100)&(~isnan(trigger.cuioutevents(2,end))))...
        %              , class=2;
        %          fprintf('Debug  - events accumulated.
        %d\n',trigger.label(i));
        %      end


        %//
        %//
        %// This part of the code handled the returning results back to the E-Prime
        %// thing
        %//
        %//

         TMP = trigger.cuievents;
         TMPLABEL = trigger.label;
             save('test.mat','TMP','TMPLABEL');

        % Classify train trials
        if (class==2)&(trigger.train==1)&(~isempty(trigger.cuievents))

            fprintf('class %d, i: %d length: %d , train:  %d \n', class,i, length(trigger.cuievents), trigger.train);


            [sourcesort,targettriallist]=sort(trigger.cuievents(2,find(~(isnan(trigger.cuievents(2,:))))),2,'descend');

            %%%%%[sourcesort,targettriallist]=sort(trigger.cuievents(2,:),2,'descend');

            % New addition, find the average threshold. for multiple
            % class classifier.

            %%AverageThresh = 0;
            %%% for count=1:trigger.numWindows
            %%%     AverageThresh = AverageThresh + Pdetect(count).thresh;
            %%%  end

            targettrialclasslist = sourcesort > Pdetect(1).thresh;  % This is always zero anyway.

            %% Multiple windows with average          targettrialclasslist = sourcesort > AverageThresh;
            %   targettrialclasslist = sourcesort > Pdetect(trigger.numWindows + 1).thresh;
            %         targettrialclasslist = sourcesort > Pdetect(1).thresh;


            testtruth = (trigger.cuievents(1,:)==160); % [0|1] -> [distractor|target]
            testclass = trigger.cuievents(2,:) >  Pdetect(1).thresh;    % This is always zero

            %% multiple windows with average           testclass = trigger.cuievents(2,:) >  AverageThresh;
            %        testclass = trigger.cuievents(2,:) >  Pdetect(trigger.numWindows+1).thresh; ;
            %         testclass = trigger.cuievents(2,:) >  Pdetect(1).thresh; ;

            % Keep track of target position before and after triage
            targetposition=find(testtruth);
            triagetargetposition=find(testtruth(targettriallist));
            trigger.pretriage=[trigger.pretriage; targetposition(1:2)];
            trigger.posttriage=[trigger.posttriage; triagetargetposition(1:2)];

            % Update E-Prime display

            heprime=serial('COM1');
            % This buffer should be enough for about 400 comma separated
            % integers (i.e. without decimals)


            % integers (i.e. without decimals)
            set(heprime,'OutputBufferSize',1024);
            fopen(heprime);
            fprintf('events lenfth %d\n\n\n',length(targettriallist));
            %%%%  comouttext=['~' num2str(1) ',' num2str(0)];
            comouttext=['~' num2str(targettriallist(1)) ',' num2str(targettrialclasslist(1))];
           % save('test.mat','targettriallist','targettrialclasslist');
            for triali=2:100,
                comouttext=[comouttext ',' num2str(targettriallist(triali)) ',' num2str(targettrialclasslist(triali))];
                % comouttext=[comouttext ',' num2str(triali) ',' num2str(mod(triali,2))];
            end
            comouttext=[comouttext ',' num2str(targetposition(1)) ',' num2str(targetposition(2)) ...
                ',' num2str(triagetargetposition(1)) ',' num2str(triagetargetposition(2))];
            comouttext=[comouttext ',' num2str(round(mean(trigger.pretriage(:,1)))) ',' num2str(round(mean(trigger.pretriage(:,2)))) ...
                ',' num2str(round(mean(trigger.posttriage(:,1)))) ',' num2str(round(mean(trigger.posttriage(:,2))))];

            % comouttext=[comouttext ',' num2str(1) ',' num2str(2) ...
            %     ',' num2str(1) ',' num2str(2)];
            % comouttext=[comouttext ',' num2str(3) ',' num2str(3) ...
            %     ',' num2str(4) ',' num2str(4)];

            comouttext=[comouttext '%'];
            %            disp(comouttext);
            fprintf(heprime,comouttext); % '%' is the termination character
            %  fprintf(heprime,['~end%']); % '%' is the termination character
            fclose(heprime);

            % THIS IS FOR DEBUGING
            %   trigger.cuievents=[]; trigger.cuioutevents=[];
            trigger.N = 0;
            trigger.eventcounter=0; % This most probably needs to stay, not debug
            trigger.dataaquired =  trigger.dataaquired * 0;
            %  trigger.label=[]; % event labels
            %  trigger.chris = []; % just used to dubag
            %  trigger.chris2 = [];
            %  trigger.chris3 = [];

            % Display triage raster and performance
            Ntarget=sum(eegdatafilt{4}==1);
            Nnontarget=sum(eegdatafilt{4}==0);
            [sorty sortindx]=sort(eegdatafilt{3},'descend');
            traintriagecdf=cumsum(eegdatafilt{4}(sortindx));
            traintriagedistcdf=cumsum(~eegdatafilt{4}(sortindx));
            trainorigcdf=cumsum(eegdatafilt{4});
            trainorigdistcdf=cumsum(~eegdatafilt{4});
            trainorigperf=[trainorigcdf./Ntarget]*[0 diff(trainorigdistcdf)./Nnontarget]';
            trainperf=[traintriagecdf./Ntarget]*[0 diff(traintriagedistcdf)./Nnontarget]';
            fprintf('\nPre-triage Az: %6.2f, Post-triage Az: %6.2f\n',trainorigperf,trainperf);

            traintriage=([traintriagecdf(1) diff(traintriagecdf)]);
            origtriage=[trainorigcdf(1) diff(trainorigcdf)];
            trainmap=zeros(50);                 % Gray
            trainmap(find(traintriage))=-1;     % Black
            trainmap(find(traintriage==0))=1;   % White
            origmap=zeros(50);
            origmap(find(origtriage))=-1;
            origmap(find(origtriage==0))=1;

            if isempty(findobj('Tag','triageraster')),
                traintriagefig=figure;
                set(traintriagefig,'Tag','triageraster');

                % Pre-triage raster
                htraintriage(1)=subplot(1,3,1);
                set(gca,'Tag','trainpretriage');
                htraintriage(2)=imagesc(-1.*ones(50));
                colormap(gray);
                %colormap([repmat([1 0 0],63,1);[.75 .75 .75]]);
                %colormap([repmat([0 1 0],63,1);[1 0 0]]);

                set(gca,'YTick',[1 5:5:50]);
                set(gca,'YTickLabel',[1 201:250:2451]);
                set(gca,'XTick',50); set(gca,'XTickLabel',2500);
                axis square;
                hold on;
                for i=1:50, h(i)=line([1 1].*i-.5,[0 51]); end
                for i=1:50, h(i+50)=line([0 51],[1 1].*i-.5); end
                set(h,'color',[.7 .7 .7],'LineWidth',1);
                titlestr=sprintf('Pre-triage Az: %6.2f',trainorigperf);
                title(titlestr,'FontSize',12);
                set(gca,'FontSize',10);
                set(gcf,'color','w');


                % Post-triage raster
                htraintriage(3)=subplot(1,3,2);
                set(gca,'Tag','trainposttriage');
                htraintriage(4)=imagesc(-1.*ones(50));
                colormap(gray);
                %colormap([repmat([1 0 0],63,1);[.75 .75 .75]]);
                %colormap([repmat([0 1 0],63,1);[1 0 0]]);
                set(gca,'YTick',[1 5:5:50]);
                set(gca,'YTickLabel',[1 201:250:2451]);
                set(gca,'XTick',50); set(gca,'XTickLabel',2500);
                axis square;
                hold on;
                for i=1:50, h(i)=line([1 1].*i-.5,[0 51]); end
                for i=1:50, h(i+50)=line([0 51],[1 1].*i-.5); end
                set(h,'color',[.7 .7 .7],'LineWidth',1);
                titlestr=sprintf('Post-triage Az: %6.2f',trainperf);
                title(titlestr,'FontSize',12);
                set(gca,'FontSize',10);

                % Triage CDF's
                htraintriage(5)=subplot(1,3,3);

                htraintriage(6)=plot(trainorigdistcdf,trainorigcdf,'color',[.7 .7 .7]);
                hold on; axis square; set(gca,'FontSize',10);

                htraintriage(7)=plot(traintriagedistcdf,traintriagecdf,'k-.','LineWidth',2);

                hlegend=legend([htraintriage(6:7)],'Pre-triage','EEG','location','southeast');
                set(hlegend,'FontSize',10);
                title(['Triage Performance'],'FontSize',12,'FontWeight','bold');
                xlabel('Distractors Presented','FontSize',12,'FontWeight','bold');
                ylabel('Targets Presented','FontSize',12,'FontWeight','bold');
                axis([0 2450 0 50]);
                set(gca,'XTick',[0 500 1000 1500 2000 2450]);

            end

            set(htraintriage(2),'CData',origmap');
            titlestr=sprintf('Pre-triage Az: %6.2f',trainorigperf);
            set(get(htraintriage(1),'Title'),'String',titlestr);

            set(htraintriage(4),'CData',trainmap');
            titlestr=sprintf('Post-triage Az: %6.2f',trainperf);
            set(get(htraintriage(3),'Title'),'String',titlestr);


            set(htraintriage(6),'XData',trainorigdistcdf,'YData',trainorigcdf);

            set(htraintriage(7),'XData',traintriagedistcdf,'YData',traintriagecdf);

            drawnow;
            
            %
            % This code will save the current training results to a file.
            % 
            %
            train_results = eegdatafilt{3};
            train_true = eegdatafilt{4};
            train_button_response = eegdatafilt{7};
            save('train_classification.mat','train_results','train_button_response','train_true');    
        end % End if sending data to e-prime (when testing mode)



        %******************************************************************
        %*
        %* This part of the code, will send the classification results for
        %* the testing set
        %*

        %******************************************************************


        if (class==2)&(trigger.train==0)&(~isempty(trigger.cuioutevents))

            fprintf('class %d, i: %d length: %d , train:  %d \n', class,i, length(trigger.cuioutevents), trigger.train);

            [sourcesort,targettriallist]=sort(trigger.cuioutevents(2,find(~(isnan(trigger.cuioutevents(2,:))))),2,'descend');

            %sort(trigger.cuioutevents(2,:),2,'descend');

            %%%sort(trigger.cuievents(2,find(~(isnan(trigger.cuievents(2,:))))),2,'descend');

            % New addition, find the average threshold. for multiple
            % class classifier.

            %            AverageThresh = 0;
            %           for count=1:trigger.numWindows
            %               AverageThresh = AverageThresh + Pdetect(count).thresh;
            %           end

            targettrialclasslist = sourcesort > Pdetect(1).thresh;    % This is zero anyway

            %% case with multiple windows  average  targettrialclasslist = sourcesort > AverageThresh;
            %%     targettrialclasslist = sourcesort > Pdetect(trigger.numWindows+1).thresh;
            %%   targettrialclasslist = sourcesort > Pdetect(1).thresh;


            testtruth=(trigger.cuioutevents(1,:)==200); % [0|1] ->[distractor|target]
            %% Single window code  testclass=trigger.cuioutevents(2,:) > Pdetect.thresh;

            %% Multiple windows average        testclass=trigger.cuioutevents(2,:) > AverageThresh;

            %            testclass=trigger.cuioutevents(2,:) > Pdetect(trigger.numWindows+1).thresh;
            testclass=trigger.cuioutevents(2,:) > Pdetect(1).thresh;    % This value is zero anyway

            % Keep track of target position before and after triage
            targetposition=find(testtruth);
            triagetargetposition=find(testtruth(targettriallist));
            trigger.pretesttriage=[trigger.pretesttriage; targetposition(1:2)];
            trigger.posttesttriage=[trigger.posttesttriage; triagetargetposition(1:2)];

            % Update E-Prime display

            heprime=serial('COM1');
            % This buffer should be enough for about 400 comma separated
            % integers (i.e. without decimals)

            set(heprime,'OutputBufferSize',1024);
            fopen(heprime);
            fprintf('events lenfth %d\n\n\n',length(targettriallist));
            comouttext=['~' num2str(targettriallist(1)) ',' num2str(targettrialclasslist(1))];
            for triali=2:100,
                comouttext=[comouttext ',' num2str(targettriallist(triali)) ',' num2str(targettrialclasslist(triali))];
            end
            comouttext=[comouttext ',' num2str(targetposition(1)) ',' num2str(targetposition(2)) ...
                ',' num2str(triagetargetposition(1)) ',' num2str(triagetargetposition(2))];
            comouttext=[comouttext ',' num2str(round(mean(trigger.pretesttriage(:,1)))) ',' num2str(round(mean(trigger.pretesttriage(:,2)))) ...
                ',' num2str(round(mean(trigger.posttesttriage(:,1)))) ',' num2str(round(mean(trigger.posttesttriage(:,2))))];
            comouttext=[comouttext '%'];
            %            disp(comouttext);
            fprintf(heprime,comouttext); % '%' is the termination character
            fclose(heprime);

            % THIS IS FOR DEBUGING
            trigger.N = 0;
            trigger.eventcounter=0; % This most probably needs to stay, not debug
            trigger.dataaquired =  trigger.dataaquired * 0;


            % Display triage raster and performance
            Ntarget=sum(eegdatafilt{6}==1);
            Nnontarget=sum(eegdatafilt{6}==0);
            [sorty sortindx]=sort(eegdatafilt{5},'descend');
            testtriagecdf=cumsum(eegdatafilt{6}(sortindx));
            testtriagedistcdf=cumsum(~eegdatafilt{6}(sortindx));
            testorigcdf=cumsum(eegdatafilt{6});
            testorigdistcdf=cumsum(~eegdatafilt{6});
            testorigperf=[testorigcdf./Ntarget]*[0 diff(testorigdistcdf)./Nnontarget]';
            testperf=[testtriagecdf./Ntarget]*[0 diff(testtriagedistcdf)./Nnontarget]';
            fprintf('\nPre-triage Az: %6.2f, Post-triage Az: %6.2f\n',testorigperf,testperf);



            testtriage=([testtriagecdf(1) diff(testtriagecdf)]);
            origtriage=[testorigcdf(1) diff(testorigcdf)];
            testmap=zeros(80,50);                 % Gray
            testmap(find(testtriage))=-1;     % Black
            testmap(find(testtriage==0))=1;   % White
            origmap=zeros(80,50);
            origmap(find(origtriage))=-1;
            origmap(find(origtriage==0))=1;

            if isempty(findobj('Tag','testtriageraster')),
                testtriagefig=figure;
                set(testtriagefig,'Tag','testtriageraster');

                % Pre-triage raster
                htesttriage(1)=subplot(1,3,1);
                set(gca,'Tag','testpretriage');
                htesttriage(2)=imagesc(-1.*ones(80,50));
                colormap(gray);
                %colormap([repmat([1 0 0],63,1);[.75 .75 .75]]);
                %colormap([repmat([0 1 0],63,1);[1 0 0]]);

                set(gca,'YTick',[1 5:5:80]);
%%                set(gca,'YTickLabel',[1 201:250:2451]);
                set(gca,'YTickLabel',[1 201:250:3951]);
                set(gca,'XTick',50); set(gca,'XTickLabel',4000);
                axis square;
                hold on;
                for i=1:50, h(i)=line([1 1].*i-.5,[0 81]); end
                for i=1:80, h(i+50)=line([0 51],[1 1].*i-.5); end
                set(h,'color',[.7 .7 .7],'LineWidth',1);
                titlestr=sprintf('Pre-triage Az: %6.2f',testorigperf);
                title(titlestr,'FontSize',12);
                set(gca,'FontSize',10);
                set(gcf,'color','w');


                % Post-triage raster
                htesttriage(3)=subplot(1,3,2);
                set(gca,'Tag','testposttriage');
                htesttriage(4)=imagesc(-1.*ones(80,50));
                colormap(gray);
                %colormap([repmat([1 0 0],63,1);[.75 .75 .75]]);
                %colormap([repmat([0 1 0],63,1);[1 0 0]]);
                set(gca,'YTick',[1 5:5:80]);
%%                set(gca,'YTickLabel',[1 201:250:2451]);
                set(gca,'YTickLabel',[1 201:250:3951]);
                set(gca,'XTick',50); set(gca,'XTickLabel',4000);
                axis square;
                hold on;
                for i=1:50, h(i)=line([1 1].*i-.5,[0 81]); end
                for i=1:80, h(i+50)=line([0 51],[1 1].*i-.5); end
                set(h,'color',[.7 .7 .7],'LineWidth',1);
                titlestr=sprintf('Post-triage Az: %6.2f',testperf);
                title(titlestr,'FontSize',12);
                set(gca,'FontSize',10);
                set(gcf,'color','w');


                % Triage CDF's
                htesttriage(5)=subplot(1,3,3);

                htesttriage(6)=plot(testorigdistcdf,testorigcdf,'color',[.7 .7 .7]);
                hold on; axis square; set(gca,'FontSize',10);

                htesttriage(7)=plot(testtriagedistcdf,testtriagecdf,'k-.','LineWidth',2);

                hlegend=legend([htesttriage(6:7)],'Pre-triage','EEG','location','southeast');
                set(hlegend,'FontSize',10);
                title(['Triage Performance'],'FontSize',12,'FontWeight','bold');
                xlabel('Distractors Presented','FontSize',12,'FontWeight','bold');
                ylabel('Targets Presented','FontSize',12,'FontWeight','bold');
                axis([0 3840 0 160]);
               % set(gca,'XTick',[0 500 1000 1500 2000 2450]);
                set(gca,'XTick',[0:1000:3000 3840]);
            end

            set(htesttriage(2),'CData',origmap');
            titlestr=sprintf('Pre-triage Az: %6.2f',testorigperf);
            set(get(htesttriage(1),'Title'),'String',titlestr);

            set(htesttriage(4),'CData',testmap');
            titlestr=sprintf('Post-triage Az: %6.2f',testperf);
            set(get(htesttriage(3),'Title'),'String',titlestr);


            set(htesttriage(6),'XData',testorigdistcdf,'YData',testorigcdf);

            set(htesttriage(7),'XData',testtriagedistcdf,'YData',testtriagecdf);

            drawnow;

            %
            % This clode will save the results of the classification of the
            % testing phase, the results are stored as a vector with the
            % The index of the array in the indicates the order that the
            % images where presented, and the value is the confidence of
            % the classifier.
            %
            test_results = eegdatafilt{5};
            test_button_response = eegdatafilt{8};
            save('test_classification.mat','test_results','test_button_response');    

            
        end  % end of sending data to e-prime (when testing)

    end  %% trigger.dataaquired(i)==trigger.duration,
end % for all triggers.


if ~isempty(events),
    if events(end)==blklen,
        %fprintf('Adams: %d  CHRIS: %d \n BLKLEN: %d  EVENT LEN: %d\n',Xfilter(1,eventonsets(end)),Xfilter(1,end),blklen,events(end));
        % ADAMS : trigger.continue=Xfilter(1,eventonsets(end)); else trigger.continue=0; end
        %trigger.continue=Xfilter(1,eventonsets(end)); else trigger.continue=0; end

         trigger.continue=Xfilter(1,end); else trigger.continue=0; end
end

%
% This is the olde code, It has the problem in identifying a new event in
% the signal is as follows
%
% 80 80 80 80 40 40 40 [end of block] 80 80 80 It will not recognize the new sequence of 80 as a new event.
%
% This situation, is not impossiple to happen, in fact, it apears almost at
% every run of the execution


% Set flag indicating whether event may continue into subsequent acquisition
%if ~isempty(events),
%    if events(end)==blklen, trigger.continue=Xfilter(1,eventonsets(end)); else trigger.continue=0; end
%end




if 0
    figure(fig);
    dd = zeros(1,1024);
    dd(1,eventonsets) = 100;
    % Display the data read.
    subplot(3,1,1);
    plot(Xfilter(1,:));
    axis([0 1024 0 200]);
    subplot(3,1,2);
    plot(Xfilter(10,:));
    %axis([0 1024 -1100 1100]);
    subplot(3,1,3);
    plot(Xfilter(4,:));
    axis([0 1024 -1400 1400]);

    drawnow;
end


%
% Do not edit the lines below, they are needed for communication with
% the C++ aquizition.
%

t = t + 1;
obj.triggersExecuted  = t;
res = obj;


return;


%**************************************************************************
%
% This part of the code filters the data, and extracts the event from the
% event channel. All the events are put in the eventsonset variable.
%
%**************************************************************************


plot(data(1,:));
drawnow;

%
% Do not edit the lines below, they are needed for communication with
% the C++ aquizition.
%
t = t + 1;
obj.triggersExecuted  = t;
res = obj;
