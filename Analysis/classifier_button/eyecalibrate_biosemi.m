function V = eyecalibrate_biosemi(file,show,channels,lead)

% V = eyecalibrate(file,show,channels,lead) returns 3 subspace orientations spaning
% the activity of eye blinks, vertical eye motion, and horizontal eye
% motion. The imput file must contain a sequence of such EEG activity. The
% time the subject blinks repeatedly with their eyes should be marked by
% event 51. Left and right horizontal eye positions should be marked by
% events 151 and 176. Up and down vertical eye positions should be maked by
% events 201 and 226. The mean and standard deviate of the voltage levesl
% corresponding to all 256 posible event markers are iven in variables m and
% s. If show>0 some plots are shown to demonstrate what happened. Use
% lead to cut out lead samples at the begining of the file.
%
% To remove the eye activity components use something like: 
%     y = x-V*(V\x); 

% Adam Gerson, 4/22/2005, Updated for use with biosemi online
% (c) Lucas Parra, Jan 14, 2003

if nargin<6 | isempty(lead), lead=1; end;
if nargin<5 | isempty(channels), channels=2:137; end;

% read in eye activity calibration data

x=daqread(file)'; % Load eye calibration file saved in daqdetectdemo.m
x=x(:,find(~isnan(x(1,:)))); % Remove NaN
x=x(:,lead:end);

conversionfactor=0.0000000023283064370807974; % Conversion factor for event channel
events = (x(1,:)./conversionfactor-1)./512;
%events = bitand(uint32(round(data*5e5)), 255); 
fs=2048;

eindx=[0    50   125   150   175   200   225];

% dump event and blank channels
x = x(channels,:);

% and shift to start at zero (avoid jump for filtering)
x = x - repmat(x(:,1),[1 length(x)]);

% High-pass filter (2nd order Butterworth, cutoof f = 0.05 Hz).
[b,a]=butter(5,0.5/fs*2,'high');
x = filtfilt(b,a,x')';

% recording bug work-around
%tmp = find(events==4); events(tmp(length(find(events==6))+1:end))=1;

% extract eye blinks (1st PC)
tmp=x(:,find(events==eindx(2))); tmp=tmp-repmat(mean(tmp,2),[1 length(tmp)]);
[vb,tmp] = eig(tmp*tmp');
V(:,1)=vb(:,end);

% extract vertical and horizontal motion
V(:,2) = mean(x(:,find(events==eindx(4))),2)-mean(x(:,find(events==eindx(5))),2);
V(:,3) = mean(x(:,find(events==eindx(6))),2)-mean(x(:,find(events==eindx(7))),2);

V = V./repmat(sqrt(sum(V.^2)),[length(channels) 1]);

% do some ploting if required 
if exist('show'), if show, 
  subplot(2,2,1); hold off
  i = find(events==eindx(2));  plot(x(1,i),x(2,i),'.b','markersize',3); hold on
  i = find(events==eindx(4)); plot(x(1,i),x(2,i),'.g','markersize',3);
  i = find(events==eindx(5)); plot(x(1,i),x(2,i),'.g','markersize',3);
  i = find(events==eindx(6)); plot(x(1,i),x(2,i),'.r','markersize',3);
  i = find(events==eindx(7)); plot(x(1,i),x(2,i),'.r','markersize',3);
  title('blink, horizontal, vertical movement')
  xlabel('VEOG'); ylabel('F1'); set(gca,'XTick',[]); set(gca,'YTick',[])
  
  subplot(2,2,2); plot([V\x; events]'); stkplt; 
  ax=axis; axis([1 length(x) ax(3:4)])   
  title('extracted activity and event markers')
  ylabel('events/horiz./vert./blinks'); 
  xlabel(['time (' num2str(round(length(x)/fs)) 's)']) 
  set(gca,'XTick',[])
  
  % this is how to remove the components
  y = x-V*(V\x);

  subplot(2,2,3); plot(x(1:3,:)'); stkplt; title('before removal')
  ax=axis; axis([1 length(x) ax(3:4)]);   set(gca,'XTick',[])
  ylabel('exempl. EEG channels'); 
  xlabel(['time (' num2str(round(length(x)/fs)) 's)']) 
  subplot(2,2,4); plot(y(1:3,:)'); stkplt; title('after removal')
  ax=axis; axis([1 length(x) ax(3:4)]);   set(gca,'XTick',[])   
  ylabel('exempl. EEG channels'); 
  xlabel(['time (' num2str(round(length(x)/fs)) 's)']) 


end; end;
















