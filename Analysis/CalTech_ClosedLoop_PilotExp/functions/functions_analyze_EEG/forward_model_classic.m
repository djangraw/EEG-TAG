%%%
%%%This function creates the forward model (alpha) for a set of analog data (X3)
%%%recorded under target and nontarget conditions.
%%%
%%%This model best differentiates the trial and non-trial conditions based
%%%on the neural data using a Fisher Linear Determinant method.
%%%
%%%You can also determine the temporal model (beta) using a logistic regression
%%%approach.
%%%
%%%[alpha beta Y] = forward_model_classic(X3,y,conditioning_eigenvalue,plotflag);
%%%
%%%X3 => Matrix describing the EEG activity for D electrodes (rows) for a
%%%specific amount of time T (columns) for N trials, making X3 a D by T by
%%%N matrix.
%%%
%%%y => vector of length N identifying each trial as being a target trial
%%%(y==1) or a distracter trial (y==0)
%%%
%%%X3 and y can be generated with the convertanalog2trial.m function.
%%%
%%%Created Jan 2009, EAP
%%%
%%%Sept 2009, Corrected an error in the determination of how effective the
%%%classifier is (specifically corrected a bug where the trial values in y
%%%were not properly matched to the output of the classifier in the event
%%%that y was not a row vector), also added
%%%an (unused line) for an alternative calculation of pooled variance(sigma)

function [alpha beta Y c u] = forward_model_classic(X3,y,conditioning_eigenvalue,plotflag)

if nargin < 3
    conditioning_eigenvalue = 50;
end

if nargin < 4
    plotflag = 'noplot';
end

%%%This makes y a row vector.
y = y(:)';

%%%%
%%%These variables describe the temporal aspects of the information used in
%%%the model
K = 10;     %Number of slices of information used in model
L = 1000; % total length of temporal trial in ms; thus each slice is L/K ms long
%%%
%%%Here we determine the number of electrodes (D), trials (N), and analog samples
%%%per trial (J) are available in the data (X3)
[D J N] = size(X3);
%%%
%%%Here we define the boundaries of each of the slices/windows of data that
%%%are used in the model 
window_size  = ceil(J/K);
window_start = floor(1:J/K:J);
%%%
%%%Here we determine which trials represent a target presentation
%%%(indx_c2), and which involve a nontarget/distracter (indx_c1)
indx_c1 = find(y==0);
indx_c2 = find(y==1);

%%%
%%%For each of the 'K' temporal windows/slices of data that are used in the
%%%model, determine the characteristics of the input data for each
%%%electrode (at each timpoint that falls within the specified window)
for k=1:K,
    %%%
    %%%These are the bins of analog data that correspond to this window of
    %%%time
    currwindex = window_start(k)+(0:window_size-1);
    %%%
    %%%Determine the mean and covariance of the analog data accross all the
    %%%the available trials (this average is for each
    %%%electrode at each point of time that spans that window) 
    %%%
    %%%Do this for the distracter/nontarget trials
    X = X3(:,currwindex,indx_c1);
    m1 = mean(X(:,:),2);
    S1 = cov(X(:,:)');%covariance of the activities accross the electrodes
    %%%Cov matrix is of size D by D and gives the covariance across
    %%%electrodes
    %%%
    %%%Do this for the target trials
    X = X3(:,currwindex,indx_c2); 
    m2 = mean(X(:,:),2);
    S2 = cov(X(:,:)');%do transpose so each column related to a diff electrode
    %%%

    % pooled covariance between distracter (S1) and targets (S2)
    SigmaPool = 0.5*S1 + 0.5*S2;
    %%%
    %SigmaPool = [sum(indx_c1)*S1 + sum(indx_c2)*S2] ./ (sum(indx_c1)+sum(indx_c1));
    
    % regularizing diagonal (eigenvalues of the pooled covariance matrix)
    Lambda = sort(eig(SigmaPool));
    %%%
    %%%Get an estimate of the noise by using one of the eigenvalues
    %Noise = 0*eye(64);%no noise
    %Noise = Lambda(end-60)*eye(D);
    %Noise = Lambda(50)*eye(D);  % eigenvalue index of condition is hard-coded
    Noise = Lambda(conditioning_eigenvalue)*eye(D);

    %%%
    %%%Use the noise estimates to compensate for the poor conditioning of the
    %%%of the matrix prior to its inversion
    %%%Do a regularized LFD (ratio of difference in means to pooled
    %%%covariance between the two conditions)
    %u(:,k) = pinv(SigmaPool+Noise)*(m2-m1);
    u(:,k) = inv(SigmaPool+Noise)*(m2-m1);

    %%%
    % Project all the data onto the proper subspace for this particular
    % window of data
    X = X3(:,currwindex,:); 
    %%%X(:,:) still has the same # of rows as X, but the third dimension (accross
    %%%trials aspect) is collapsed down into the 2nd dimension, so you are
    %%%putting all the time data for each trial into a single row for each
    %%%electrode).  This makes X(:,:) of size D x [N * (# of relevent slice pts per window, ie J/K)]
    %%%This is done so that you have several analog data points for each
    %%%window/time slice for a given trial, rather than simply filtering and
    %%%downsampling the analog data such that there is a single data point
    %%%for each window.  Apparently this 'oversampling' can help improve the
    %%%model estimation.  It is called oversampling, as by doing this for a
    %%%single trial you get several different (although not truly
    %%%independant) values of the EEG activity for each electrode that can be
    %%%related to the output (for this model the ouput being the status of the
    %%%presented image as a target or a distracter).
    %%%
    Y(k,:) = u(:,k)'*X(:,:);
    clear X
end

%%%Now estimate the forward model
%%%The forward model for each of the K time windows are found independently
alpha = zeros(D,K);
for k=1:K,
    %%%
    %These are the indices of the data that falls within the current window
    currwindex = window_start(k)+(0:window_size-1);
    %%%
    %%%estimate the model (alpha)
    %%%Define X so that each of rows (D) are for a different electrode, and
    %%%contains all the data pts from each trial that would fall within this
    %%%window (this use of reshape is equivalent to doing X2(:,:)
    X = reshape(X3(:,currwindex,:),[D length(currwindex)*N]);
    R = X*X';%covariance of the data
    alpha(:,k) = R*u(:,k)/(u(:,k)'*R*u(:,k));  
end;

% Make a scalp plot of the forward model
if strcmp(plotflag,'plot');
    fighandle = generatescalpplot(alpha,'BioSemi64.loc',L);%plotting the forward model
%    fighandle = generatescalpplot(u,'BioSemi64.loc',L);    %this is for plotting the pure weights
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%The following determines how effective the logisic regression can be as
%%%dividing the data into the two classes
%%%
%kron(y,ones(1,window_size)): this gives you a matrix of 0 or 1 for each
%data point (y is already 0 or 1, so you just multiply that by a matrix of
%ones).  This tells the classifier whether each data point in Y corresponds
%to either a target or a non-target class.
%%%
%obtain the temporal projection
%%%
%c        = bspl_logisticregr(Y,kron(y,ones(1,window_size))); %INCORRECT, does not line up the target/one values in y with Y properly unless y is a row vector 
%%%The next line properly reshapes y to match Y regardless of whether y is
%%%a row or column vector
c        = bspl_logisticregr(Y,reshape(kron(y,ones(1,window_size))',[],1));

%c contains the weights (last part of c) and the offset (first value in c)
%that when applied to y give the probabilities
%%%bspl_logisticregr_run applies the logistic weights in c to the values in
%%%Y
[Ey,pot] = bspl_logisticregr_run(Y,c);
%%%pot is w*y + beta, and Ey is expectation
%%%
p        = mean(reshape(pot,window_size,length(pot)/window_size));

%%This figure plots 'p', which shows the distribution of the probabilities
%%for both the target and non-target data, adding it to the previous figure
if strcmp(plotflag,'plot');
    subplot(3,2,6)
    n=min(p):(max(p)-min(p))/20:max(p);
    h1=hist(p(indx_c1),n); %nontargets
    h2=hist(p(indx_c2),n); %targets
    bar(n,[h1'/sum(h1) h2'/sum(h2)],1); 
    xlim([min(n) max(n)]);
    %%%Labels
    legend('non-target','target')
    colormap('jet');
    title('class conditional likelihood')
    xlabel('classifier output y (a.u.)')
    ylabel('probability')
end

%%%In case you'd want to print the figure
%print -depsc miniClassifierFigures.eps



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%Now we are going to create an estimate of the temporal forward model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for k=1:K,
    % select current samples within this window
    currwindex = window_start(k)+(0:window_size-1);
    %%%
    %%%Find the ...
    v(:,k) = zeros(J,1);
    v(currwindex,k) = 1/c(k+1);
    %%%The raw data is projected onto xxx
    %%%And then the projection is reshaped so that each row corresponds to
    %%%the amoutn of analog data during a trial, and each column represents
    %%%a different trail
    X = reshape(u(:,k)'*X3(:,:),[J N]);
    %%%Cov matrix of the data accross 
    R = X*X';
    %%%
    beta(:,k) = R*v(:,k)/(v(:,k)'*R*v(:,k));
end;


if strcmp(plotflag,'plot');
    hold off; figure; hold on;
    range2 = [0 max(beta(:))];
    for k=1:K,
        subplot(3,4,k);
        plot((1:J)*1000/128,beta(:,k));  
        if k==5 || k==10, xlabel('time (ms)'); else set(gca, 'xtick',[]); end;
        xlim([0 1000]); ylim(range2); set(gca,'ytick',[]);
    end
end



