%%%
%%%this is just a quick function that does one of the main underlying
%%%processes of the TAG calculation.  Namely, creating the node
%%%regularizing matrix (V) and the class labels vector (Y).
%%%
%%%if multEntriesFlag==1, then multiple entries are handled by scaling the
%%%Y vector, if multEntriesFlag==2, then multiple entries are handled by
%%%adjusting the V matrix, if multEntriesFlag==3, then multiple entries are
%%%handled by BOTH scaling the Y vector AND adjusting the V matrix.


function [Y V] = TAGutility(labeled_ind, data_num, class_num, W, multEntriesFlag)

if nargin < 5
    multEntriesFlag = 0;
end
if ( (multEntriesFlag < 0) || (multEntriesFlag > 3) )
    multEntriesFlag = 0;
end

%%%Determine if there are duplicate labels, if there are you must deal with
%%%them by modifying the calculation of the Y and/or the V matrix (ie
%%%multEntriesFlag must specify a value from 1-3).
if length(labeled_ind) ~= length(unique(labeled_ind))%%%This means there are duplicate labels
    if multEntriesFlag == 0
        %%%this means that there are duplicate entries, and the user has
        %%%not specified how to deal with that.  We will go to the defualt
        %%%method of just modifying the Y matrix
        disp('.......')
        disp('            There are duplications in the TAG entries, thus producing a modified Y/label vector');
        disp('.......')
        multEntriesFlag = 1;
    end
end

%%%
%%%calculating the node vector (Y)
if ( (multEntriesFlag == 1) || (multEntriesFlag == 3) )
    %%%
    %%%Alternative Y calculation to weight multiple inputs of the same
    %%%node/image, ie if an image is labeled twice, it will have a value of 2
    %%%in the Y vector
    Y=zeros(data_num,class_num);
    for i=1:length(labeled_ind)
        ii=labeled_ind(i);
        Y(ii)=1+Y(ii);         
    end
else
    %%%original/standard Y calculation
    Y=zeros(data_num,class_num);
    for i=1:length(labeled_ind)
        ii=labeled_ind(i);
        Y(ii)=1;         
    end
end    

%%%
%%%Calculating the node regularization matrix (V)
if ( (multEntriesFlag == 2) || (multEntriesFlag == 3) )
    %%%
    %%%Alternative V calculation to weight multiple inputs of the same
    %%%node/image, ie if an image is labeled twice, it will have two times the
    %%%V numerator (but not two times the denominator), ie this is
    %%%different than a factor of two in the Y vector.
    V=zeros(data_num,data_num);
    subW=W(labeled_ind,labeled_ind);
    subD=sum(subW);
    %%%
    for i=1:length(labeled_ind)
        ii=labeled_ind(i);
        %%%
        %%%Number of times this node is repeated in labeled_ind
        count = sum(labeled_ind == ii);
        %%%
        V(ii,ii) = max([ 0.001 (count * subD(i))/sum(subD) ]);
        %V(ii,ii) = (V(ii,ii)*sum(subD) + subD(i)) / sum(subD);
    end  
    %%%ensure each entry in V has a value of at least .001
    for i=1:length(labeled_ind)
        ii=labeled_ind(i);
        %%%
        V(ii,ii) = max([0.001 V(ii,ii)]);
    end      
    %%%
else
    %%%else we want to make a V matrix that only reflects the unique node
    %%%labels (original method).
    %%%
    %%%Get rid of any duplicate labels there may be
    labeled_ind = unique(labeled_ind);
    %%%
    %%%original/standard V calculation (only works for no duplicate labels)
    V=zeros(data_num,data_num);
    subW=W(labeled_ind,labeled_ind);
    subD=sum(subW);
    %%%
%     safe_guardcount = 0;%this was for troubleshooting, just wanted to see how often the .001 thing happened    
    for i=1:length(labeled_ind)
        ii=labeled_ind(i);
        V(ii,ii)=max([0.001 subD(i)/sum(subD)]);
        %%%
%         if V(ii,ii) <= .001
%             safe_guardcount = safe_guardcount + 1;
%         end        
    end  
%     fprintf('There were %u entries replaced with a value of .001 \n',safe_guardcount);
    %%%
end  


