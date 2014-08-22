%%%
%%%This function emulates the online ProducerConsumer software.  By
%%%specifying a .dat file you can run the same scripts as ProducerConsumer
%%%and create the same output files.  This enables you to create a
%%%classifier in the exact same manner as the online code.  Similarly, you
%%%can apply an already created classifier to a .dat file and produce the
%%%exact same confidence values as those that would be generated from the
%%%online code.
%%%
%%%The configuration file 'CBCI.ini' that matches the one used in the
%%%online experiments you wish to emulate MUST be in eith the current
%%%working directory or in a directory in the matlab path so that it can be
%%%found by the called functions.
%%%
%%%This version uses the original 'dat2core' function to load the data as
%%%opposed to the fancier 'load_dat_file' function used in version 2.
%%%
%%%It is important that you instruct the simulator to use the exact same
%%%versions of the matlab scripts as were compiled into ProducerConsumer so
%%%that same results are obtained.
%%%
%%%This function will output a set of .res files in a folder called
%%%'simmulationResults' (yes it is misspelt, what can you do?) in the
%%%current working directory.
%%%
%%%If the .dat file was a training file, a classifier will be created based
%%%on the contents of that file (also placed in the current working directory).
%%%
%%%[output] = ProdConsumer_simulator_1(Datfile, RT_repository, Classifier);
%%%
%%%Datfile => .dat file to be used
%%%
%%%Classifier    => folder name of previously created classifier.
%%%             This is only necessary if running the simulator in test mode.
%%%             *Must* be located in the current working directory.
%%%             *Must* be specified as string, eg '_cbci_734026.4107'
%%%WARNING:  If it datdetect cannot find the proper Classifier folder,
%%%there is not a good warning (in fact a message that the classifier was
%%%found is still often given) and daqdect will simply use a set of
%%%default values during the execution rather than the actual classifier,
%%%which will screw up your output.
%%%
%%%RT_repository => Location of the uncompiled matlab code used for the RT
%%%system
%%%
%%%Last modified Sept 2009, EAP

function [output] = ProdConsumer_simulator_1(Datfile, RT_repository, Classifier)

output = 0;

if (nargin < 2)||isempty(RT_repository)
    RT_repository = ['D:\DataFiles\ProdConsOffTest\Test2\classifier_button'];
end
    
if (nargin < 3)
    Classifier = [];
end

%%%
%%%Location in RT_repository that has additional functions called by the
%%%real-time code
RT_subdir = 'classifieralgorithms';

%%%
%%%Add paths so needed functions can be found
addpath(RT_repository);
addpath(fullfile(RT_repository,RT_subdir));

%%%
%%%Settings for obj structure
obj.samplesPerTrigger = 1024;           % Specifies the number of Triggers. 
obj.triggersExecuted  = 0;
obj.feedback          = 2;  %0:none, 1: text, 2:GUI
obj.simmulation       = 1;
if ~isempty(Classifier)
    obj.simClassifier = Classifier;
end

%%%
%%%File loading parameters
mode = 2;
NS   = 1024;
%%%Begin loading chunks of data and send them to the online functions for
%%%processing
[X filetell] = dat2core(Datfile, NS, mode);
while size(X,2) == NS
    obj = daqdetect(obj,X);
    %%%Load the next chunk of data
    [X filetell] = dat2core(Datfile, NS, mode, filetell);
end;

