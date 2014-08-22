%%% 
%%%This script is used for the final set of Caltech101 closed-loop
%%%experiments where we are trying to determine what the subjects are
%%%looking for without using ANY of the textual metadata attached to the
%%%images that are shown, but rather simply evaluating how much the input
%%%images have in common using TAG numerics.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Parameter settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%This is how the most interesting images are identifed. The mean and STD
%%%of the EEG scores in the training data are determined, and then the
%%%images that exceed that mean (plus so many STDs) are used for the
%%%example images.  The final set of TAG scores are then used to output a
%%%set of the 'most interesting' images from the whole database that is
%%%used to predict what the target category was.
%%%
OutlierMultiplier   = [2 1.64 1];%use this many stan dev from mean to ID the images to consider from the EEG scores  
MinExampleSetSize   = 5; %must have this many 'interesting images before bothering to consider commonality 
CommonalitySTD      = 3;%use 3 STDs of deltaQ scores for commonality checks 
outputSTD           = 3;%top 3 STDs of TAG output z scores for final target catgory prediction 
%classifier          = '_cbci_734171.6579';%PS at 5Hz
%classifier          = '_cbci_734271.6061';%PS at 10Hz
%classifier          = '_cbci_734802.6909';% Dave at 5Hz
classifier          = '_cbci_111111.1111';% Dave at 5Hz
force_classifier	= false; % set this to true to use the above classifier
classifier_dir      = 'C:\Program Files\Neuromatters\CBCI';
image_dir           = 'C:\DARPA_PHASEII\TAG_test_Images\CALTECH_081209\101_samesize_resized'; % DJ, 2/19/13
prompt_data			= false; % set this to true to prompt for the data file, false to use the most recently modified file
TAGgraph            = 'CaltechGistGraph_BM.mat';%%%TAG graph being used
QtynextRSVP         = 200;%Number of images in the next RSVP (if more RSVP's necessary)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Find the most recently created classifier based on the floating point
%%% representation of the creation date embedded in the folder name.
if (~force_classifier)
	listing = dir([classifier_dir '\_cbci_*']);
	classifiers = {listing(:).name}';
	ids = cellfun(@(X)strrep(X,'_cbci_',''),classifiers,'UniformOutput',false);
	ids = str2double(ids);
	vals = [ids, (1:length(ids))'];
	sorted = sortrows(vals, 1);
    classifier = classifiers{sorted(end, 2)};
end
	
%%%
%%%Function paths
addpath(genpath(fullfile(cd,'functions')));
addpath(genpath(fullfile(cd,'DataFiles')));
%%%

ImageToolboxExists = license('checkout','Image_Toolbox');
if (~ImageToolboxExists)
    fprintf('Image Processing Toolbox not found. (no licenses available)\n');
    fprintf('No images will be displayed.\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Get the scores from the training data
[scores_train status_train] = getTrainingScores(fullfile(classifier_dir,classifier));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Load the names of the images in the TAG graph
load TAGimageOrdering %lists of image names in the sequence of the TAG graph (TAGFileList and TAGnames)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Load the TAG graph information
disp('loading TAG graph'); tic; load(TAGgraph); toc
disp('finished loading TAG graph')
A = graph.gradient; IS = graph.propm; W = graph.weight;
data_num = 3798; class_num = 1; clear graph;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Get info related to the XML filenaming
if (prompt_data)
	target_cat      = input('Enter the case sensitive ID for the exp series [A,B,C... etc]=> ', 's');
	iterationNumber = input('Please enter the number of the Closed-Loop Iteration: ');
else
	listing = dir('ClosedLoopTAG_*_*.xml');
	dates = [listing(:).datenum]';
	ids = [1:length(dates)]';
	vals = [ids, dates];
	sorted = sortrows(vals, 2);
	filename = listing(sorted(end, 1)).name;
	filename = strrep(filename, 'ClosedLoopTAG_', '');
	filename = strrep(filename, '.xml', '');
	target_cat = filename(1:findstr(filename, '_')-1);
	iterationNumber = str2double(filename(findstr(filename, '_')+1:end)); % DJ, 2/19/13
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Load the results XML file
xmlfilename    = ['ClosedLoopTAG_',target_cat,'_',int2str(iterationNumber),'.xml']; disp('Loading the XML');
tic; XMLstruct = convertXML2XMLstruct(xmlfilename); toc
%%%
%%%Check the integrity of the XMLstruct.  Ensure that each image has an
%%%entry of eeg confidence
toremove = [];
for k=1:length(XMLstruct.object_info)
    if ~isstruct(XMLstruct.object_info{k}.eegconfidence)
        disp(['Entry ',int2str(k),' is corrupt, removing it from the structure']);
        XMLstruct.object_info{k}.file_name
        toremove = [toremove; k];
        %XMLstruct.object_info{k}.eegconfidence = struct('econf',['-9999999999']);
    elseif iscell(XMLstruct.object_info{k}.eegconfidence.econf)
        disp(['Entry ',int2str(k),' has duplicate entries, removing it from the structure']);
        toremove = [toremove; k];
    end
end
if ~isempty(toremove)
    spots = setdiff([1:length(XMLstruct.object_info)],toremove);
    XMLstruct.object_info = XMLstruct.object_info(spots);
end
%%%Save a .mat form of the XML struct
XMLstruct_prev = XMLstruct;
save([xmlfilename(1:end-4),'.mat'],'XMLstruct_prev'); clear XMLstruct_prev
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Retrieve the names and EEG scores of all the images that were shown
[EEGscores]         = getXMLstructfieldvalue(XMLstruct,'eegconfidence.econf');
[image_names]       = getXMLstructfieldvalue(XMLstruct,'file_name',1);
%%%Eliminate any file path aspect from the filenames. 
for k=1:size(image_names,1);
    spots = strfind(image_names{k,1},'/');
    if isempty(spots)~=1
        image_names{k,1} = image_names{k,1}(1,(spots(end)+1):end);
    end
end
%%%Get a list of all the imaee names as a cell (the breaks up the category and
%%%filenames part of the XML entries).
[categorydistribution file_list_All] = CalTech101categories(image_names);
%%%
%%%ScoreList and ImageList have the full lists of potential images to use
%%%as inputs to the TAG
ScoreList           = EEGscores;
ImageList           = image_names;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Determine how many/which images exceed the EEG cutoff and should be used
%%%for the TAG.
%%%
%%%First, retrieve all images from all prev RSVPs that each exceeded the
%%%threshold, averaging the scores of any images shown multiple times.  Do this
%%%prior to checking the EEG cutoff.
if iterationNumber>1
    prevscores = []; previmagenames = [];
    for k=1:(iterationNumber-1)
        %%%Load the XML struct
        load(['ClosedLoopTAG_',target_cat,'_',int2str(k),'.mat'])
        fprintf('\n.....Getting peak images from prev file %s \n',['ClosedLoopTAG_',target_cat,'_',int2str(k),'.mat'])
        %%%Compile a list of all scores and imagenames to be considered
        prevscores     = [prevscores; getXMLstructfieldvalue(XMLstruct_prev,'eegconfidence.econf')];
        previmagenames = [previmagenames; getXMLstructfieldvalue(XMLstruct_prev,'file_name',1)];
        %%%
        clear XMLstruct_prev
    end
    %%%Only keep scores that exceeded the cut-off  
    ExtraScores = prevscores( prevscores>=(mean(scores_train) + OutlierMultiplier(1)*std(scores_train)),1);
    ExtraImages = previmagenames( prevscores>=(mean(scores_train) + OutlierMultiplier(1)*std(scores_train)),1);
    fprintf('There were %u prev images that exceeded the cut-off \n',length(ExtraImages))
    %%%
    %%%B is a list of unque images that were shown and exceeded the cutoff
    [B,I,J]     = unique(ExtraImages);%is a unique list
    %%%for any previous images that were just shown once (including the current
    %%%RSVP), just add them to the list, otherwise if there are multiple
    %%%showings average the scores in the current scores list
    for kk=1:size(B,1)
        if sum(strcmp(B{kk,1}, ImageList)) > 0
            %%%this image is already listed, update its
            %%%entry to the average of all its showing in the
            %%%current RSVP and all prev RSVPs
            ScoreList(strcmp(B{kk,1}, ImageList),1) = sum([ScoreList(strcmp(B{kk,1}, ImageList),1); ExtraScores( strcmp(B{kk,1},ExtraImages) )]);
            ScoreList(strcmp(B{kk,1}, ImageList),1) = ScoreList(strcmp(B{kk,1}, ImageList),1) / (1+sum( strcmp( B{kk,1},ExtraImages ) ) );
        else
            %%%add the image and score to the list (if
            %%%shown more than once in prior RSVPs make
            %%%sure you average).
            newscore  = sum(ExtraScores(strcmp(B{kk,1}, ExtraImages)))/sum(strcmp(B{kk,1}, ExtraImages));
            ScoreList = cat(1,ScoreList,newscore);
            ImageList = cat(1,ImageList,B{kk,1});
            clear newscore
        end
    end
end
%%%ScoreList and ImageList have the full lists of potential images to use
%%%
%%%Determine how many images qualify, basically you go through the list of
%%%STDs to use until you get the minimum number of of images that you are
%%%looking for (if you never do just use the top 20).  You will only bother
%%%checking for commonality if that minimum is achieved when using the
%%%first (ie highest) STD value.
NumberImages = 0; counter = 0;
while NumberImages < MinExampleSetSize
    counter = counter + 1;
    if counter > length(OutlierMultiplier)
        %%%if you never got enough, just use top twenty
        disp('being forced to just use top 20 images')
        NumTopTargets = 20;
        break;
        %%%
    end    
    Cut_off = mean(scores_train) + OutlierMultiplier(1,counter)*std(scores_train);
    NumberImages = sum(ScoreList >= Cut_off);
    fprintf('Mean plus %2.2f stan dev yields cutoff of: %5.2f, and %u images \n',...
        OutlierMultiplier(1,counter), Cut_off, NumberImages);
    NumTopTargets = NumberImages;
end
disp('.............');
fprintf('There are %u images above cutoff\n', sum(ScoreList >= Cut_off));
fprintf('\nUsing %u Examples for the TAG. \n\n', NumTopTargets);
disp('.............'); 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Get the details of the TAG input set images
%%%
%%%Get the images with the top scores
[rankedScores,score_Idx] = sort(ScoreList,'descend');
TopImages                = ImageList(score_Idx(1:NumTopTargets));
%%%Get the TAG ID numbers for the input images
[TAGids]                 = getTAGIDnumbers(TopImages);
%%%
%%%Check to see how the Top EEG scores look
figure; hold on;
[categorydistribution file_list] = filecategories(TopImages);
title('TAG input set Image results'); pause(.2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Run the TAG (with no self-tuning) for this set  of imagse
tic; disp('Running TAG with no self-tuning');
[Y V]          = TAGutility(TAGids, data_num, class_num, W, 0); 
normalizedY    = V*Y;
%%%All image final TAG scores (f)
TAG_f          = IS*V*Y;
disp('finished TAG'); toc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%If you got above the cut-off of images using the largest EEG STD, then
%%%check the example set and see if you achieve commonality
CommonalityAchieved = false;
%if counter == 1
if counter >= 0
    disp('Checking commonality');
    %%%
    %%%similarity scores (deltaQ)
    TAG_DeltaQ     = A*normalizedY;
    %%%Rescale the random sim data to match TAG input set size
    load Random10input_GistBMsimresults%has:Qty_random random_noninputs random_inputs
    random_data = (Qty_random/NumTopTargets)*[random_inputs-mean(random_noninputs)] + mean(random_noninputs);
    random_mean = mean(random_data);
    %%%
    %%%To get the estimate of what the STD would be for
    %%%random sims of that input size, rescale the known
    %%%STD rather than just taking the STD of the rescaled
    %%%data.
    random_STD  = [ [(Qty_random^2)*[std(random_inputs) + mean(random_noninputs)/Qty_random]]/(NumTopTargets^2) ] - (mean(random_noninputs)/NumTopTargets);
    %random_STD  = std(random_data);
    %%%
    %%%Check for commonality
    CommonalityAchieved = abs(mean(TAG_DeltaQ(TAGids)) - random_mean) >= CommonalitySTD*random_STD;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%If commonality was not achieved, ask experimenter if they want to finish
%%%this cycle of experiments anyway
if ~CommonalityAchieved
    question = input('Commonality has not been achieved, do you want to end anyway? [enter 1 if so] ');
    if question == 1
        CommonalityAchieved = true;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%If commonality was achieved, run the final TAG with 50% self-tuning and
%%%make the predicion of what the target category was.  If commonality
%%%wasn't achieved then build an XML file for the next RSVP iteration.
if CommonalityAchieved
    disp('       Commonality has been achieved!  Let there be much rejoicing!');
    %%%Run the final TAG calculations
%    options.rmvnum = floor(0.5*length(TAGids));
    options.rmvnum = floor(0.25*length(TAGids));%  25%TAG self-tuning
    options.rmvnum = options.rmvnum - 1;%adjust
    fprintf('Self-tuning is for %u images \n ', floor(0.25*length(TAGids)));
    %%%
    disp('Running TAG with self-tuning'); tic;
    new_score      = GTAM_eegwronglabels(TAGids',A,W,IS,options); % THE TAG RERANKING
    disp('Finished TAG calculations'); toc
    %%%
    %%%make the prediction of the target category
    %%%
    %%%Get top z scores of TAG results, for each target category reprsented,
    %%%state the percentage of that category (print the top 3), the highest is
    %%%the official 'guess' of what they were looking for.
    Z            = zscore(new_score);
    OutputImages = Z >= outputSTD;
    if sum(OutputImages) > 0
        fprintf('%u images recomended by the TAG for review \n', sum(OutputImages));
    else
        disp('No images passed the TAG output prediction threshold, using the top 20');
        [junk,rerank_ind] = sort(new_score,'descend'); % TAG output was a vector of numbers between 0 and 1.  The highest is the best.
        OutputImages = new_score>=rerank_ind(20);
    end
    %%%
    %%%Break down by category the outputted images
    RecomendedImages = strcat('category_',TAGnames(OutputImages,1),'_filename_',TAGnames(OutputImages,2)); 
    figure; hold on;
    [categorydistribution file_list] = filecategories(RecomendedImages);
    title('Top TAG-ranked Images'); pause(.2);
    [Y,I] = sort(cell2mat(categorydistribution(:,2)),'descend');
    fprintf('TAG recommends %u images for user''s review \n' , sum(OutputImages));
    fprintf('...........Prediction! target category was %s, with prevelence of: %4.2f%% (%4.2f%% of that category''s images) \n',...
        categorydistribution{I(1),1}, 100*categorydistribution{I(1),2}/sum(OutputImages),...
        100*categorydistribution{I(1),2}/sum(strcmp(categorydistribution{I(1),1},TAGnames(:,1))) );
    %%%List the runner ups
    for z = 2:min(length(I),3)
        fprintf('Runner up: Category %s; prevelence of %4.2f%% which is %4.2f%% of that category''s images  \n',...
            categorydistribution{I(z),1}, 100*categorydistribution{I(z),2}/sum(OutputImages),...
            100*categorydistribution{I(z),2}/sum(strcmp(categorydistribution{I(z),1},TAGnames(:,1))));
    end
    %%%
    %%%Now get the list of ALL the images in order of their new TAG rankings
    [rerank_score,rerank_ind] = sort(new_score,'descend'); % TAG output was a vector of numbers between 0 and 1.  The highest is the best.
    TAGresults                = strcat('category_',TAGnames(rerank_ind,1),'_filename_',TAGnames(rerank_ind,2));
    %%%
    %%%
    %%%Base the prediction on the top 20 images
    OutputImages = new_score>=new_score(rerank_ind(20));
    RecomendedImages = strcat('category_',TAGnames(OutputImages,1),'_filename_',TAGnames(OutputImages,2)); 
    figure; hold on;
    [categorydistribution file_list] = filecategories(RecomendedImages);
    title('Top 20 TAG-ranked Images'); pause(.2);
    [Y,I] = sort(cell2mat(categorydistribution(:,2)),'descend');
    disp(' ');
    disp('If basing prediction on the top 20:');
    fprintf('...........Prediction! target category was %s, with prevelence of: %4.2f%% (%4.2f%% of that category''s images) \n',...
        categorydistribution{I(1),1}, 100*categorydistribution{I(1),2}/sum(OutputImages),...
        100*categorydistribution{I(1),2}/sum(strcmp(categorydistribution{I(1),1},TAGnames(:,1))) );
    %%%
    %%%
    %%%display the top 40 TAG ranked categories
    if (ImageToolboxExists)
    showimagethumbs(TAGresults(1:40), image_dir) % DJ, 2/19/13
    end
    %%%
    %%%
    %%%Rename the last input file XML file used for the experiment.
    outfilename = 'ClosedLoopTAG.xml';
    [SUCCESS,MESSAGE,MESSAGEID] = movefile(['C:/DARPA_PHASEII/TAG_test_Images/CALTECH_081209/',outfilename],...
        ['C:/DARPA_PHASEII/TAG_test_Images/CALTECH_081209/AnalysisLaptop/',outfilename(1:end-4),'_',target_cat,'lastone.xml']);
    if SUCCESS~=1;
        disp('WARNING: Could not rename final input XML file');
    else
        %%%Move a new (random) starting XML file to the main directory and
        %%%rename it to the standard name: 'ClosedLoopTAG.xml'
        source_dir          = 'C:\DARPA_PHASEII\TAG_test_Images\CALTECH_081209\CL_TAG_StartingFiles';
        potentialstartfiles = dir([source_dir,'\*.xml']);
        choices             = randperm(length(potentialstartfiles));
        [SUCCESS,MESSAGE,MESSAGEID] = movefile(fullfile(source_dir,potentialstartfiles(choices(1)).name),...
            ['C:/DARPA_PHASEII/TAG_test_Images/CALTECH_081209/',outfilename]);
        if SUCCESS~=1; disp('            WARNING: Could not get the next input XML file prepared!!'); end;        
    end;
        %%%
else
    %%%You need to build an XML for another RSVP, use the zero self-tuning
    %%%TAG results
    disp('Preparing the XML file for the next RSVP run');
    [rerank_score,rerank_ind] = sort(TAG_f,'descend'); % TAG output was a vector of numbers between 0 and 1.  The highest is the best.
    TAGresults                = TAGnames(rerank_ind,:);    
    %%%
    [XMLstruct_TAG]           = createPythonXMLstruct(QtynextRSVP);
    XMLstruct_TAG.file_name   = ['C:/DARPA_PHASEII/TAG_test_Images/CALTECH_081209/101_samesize_resized/'];
    %%%Populate with proper filenames
    if iterationNumber <= 1; rand('state',sum(100*clock)); end;
    ordering = randperm(QtynextRSVP);
    for k=1:QtynextRSVP
        XMLstruct_TAG.object_info{k}.file_name     = ['category_',TAGresults{k,1},'_filename_',TAGresults{k,2}];
        XMLstruct_TAG.object_info{k}.id            = [int2str(k)];
        XMLstruct_TAG.object_info{k}.eegconfidence = [num2str(0)];%[num2str(round(rand(1)*1000)/1000)];%fake eeg confidence values
        XMLstruct_TAG.object_info{k}.dispOrder     = [int2str(ordering(k))];
        XMLstruct_TAG.object_info{k}.groundTruth   = [int2str(1)];
        XMLstruct_TAG.object_info{k}.confidence    = [num2str(rerank_score(k))];
    end
    %%%
    %%%Write the XML
    %%%If doing an 'open-ended' closed loop session, just keep overwriting the
    %%%original start file
    outfilename = 'ClosedLoopTAG.xml';
    [output]    = Convert2XML(XMLstruct_TAG,outfilename);
    [SUCCESS,MESSAGE,MESSAGEID] = movefile(fullfile(cd,[outfilename]),'C:/DARPA_PHASEII/TAG_test_Images/CALTECH_081209/');
    if SUCCESS~=1; disp('WARNING: Could not move XML file'); end;
    %%%
    %%%Get the breakdown of what the images in the next RSVP will be
    TAGresults       = strcat('category_',TAGnames(rerank_ind,1),'_filename_',TAGnames(rerank_ind,2));
    figure; hold on; [categorydistribution file_list] = filecategories(TAGresults(1:200));
    title('200 Images of the Next RSVP'); pause(.2);    
end


