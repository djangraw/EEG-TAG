function res = initialize(inp,sessionid)
% res = initialize()
% 
% This function initializes the data structure used to configure the
% data aquisition procedure. The parameters that can be configured 
% are defined in the documentation provided.
%
%  Input
%        inp(1) : Specifies the record from parameter, 0 : simmulation >0
%        other device input
%        inp(2) : Specifies the display mode, integer value to be
%        interpreated by the code.
%
%        sessionid : trained classifer session to be used string. 
% Author: Christoforos Christoforou
%
% revised: August 31, 2008
%          Allow for inputs to specify the 'feedback' user selection,
%          'simulation mode; sellection and sessionid
%          Author: Christoforos Christoforou
% 


aidetect.stopSession = 0;                    % flag variable to allow online termination of the session
aidetect.simmulation = (inp(1)==0);                           % allocate structure, do not modify, it it initialized by C++
aidetect.feedback = inp(2);                       % allocate memory for 'feedback' field, it is initialized by C++
aidetect.simClassifier = sessionid;
aidetect.samplesPerTrigger = 1024;           % Specifies the number of Triggers. 
aidetect.triggersExecuted = 0;               % Keeps count of number of triggers executed.

%{
aidetect.triggerRepeat = -1;                 % specifies the number of repeats per Trigger.
%aidetect.channels = [1 0 2:128 234:241];          % Specifies the list of channels.
aidetect.channels = [1 0 2:65 234:241];            % Specifies the list of channels.

aidetect.nchannels = 73;                    % indicates the number of channels.
aidetect.loginMode = 0;                     % 0 - Record in memory and file
                                            % 1 - Record ONLY in memory
                                            % 2 - Record ONLY in file
                                            
                                            
aidetect.triggerFunction = 'rsvpdetect';    % Specifies the function to be called. DO NOT CHANGE THIS
                                            % even if you do currently only
                                            % the function rsvpdetect will
                                            % be called.
                                            


aidetect.filename_output = 'session_user_date.dat'    % The name of the file %
%aidetect.recordFrom = 'File';                              %  = 'File' - simulation of data through file
                                                           %  = 'ActiveII' - record data

                                                           
aidetect.recordFrom = 'ActiveII';                          %  = 'File' - simulation of data through file
                                                           %  = 'ActiveII' - record data
                                                           %  from active two device
                                                           %  from active two device
                                          

%aidetect.inputFile = 'james_testset.dat';
                      
%aidetect.inputFile = 'session_james_may11_simull.dat';
%aidetect.inputFile = 'session_alice_mode_2save.dat';
%aidetect.inputFile = 'jaffa_64chan.dat';     % If recotdFrom is set to 'File', then this parameters
                                            % shoud specify the file where the data will be read from
                                            % if recordFrom is set to 'ActiveII' Then this paremeter should specify
                                            % the path and filename where
                                            % the parameters.ini file is located

% Uncomment this for recording from Active II
aidetect.inputFile = 'c:/parameters.ini'; 

                                            
% Defines how long the experiment should last. The value is given in
% miliseconds.

aidetect.experimentEstimatedTime = 1800000;
%}

%
% more functionaliry to be added as we go.
%

res = aidetect;
 