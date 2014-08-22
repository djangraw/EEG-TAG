%%%
%%%This function compares the locations of ground truth (GT) sites to the
%%%locations of a set of image chips.  It determines which of the GT would
%%%appear in one (or more) of the chips, and which GT sites would not
%%%appear in any of the chips (GTstatus=false).
%%%
%%%[GTstatus] = GTvsChiparea(GTsites,Chipsites,Chipsize);
%%%
%%%Last modified Feb 2009 EAP

function [GTstatus] = GTvsChiparea(GTsites,Chipsites,Chipsize)

numGT    = size(GTsites,1);
error    = Chipsize*0.5;
GTstatus = false(numGT,1);
%%%Check the x-y region around each chip location (using the chip size), if
%%%the ground truth location falls within *any* chip region it will be
%%%shown by this set of chips
for k=1:numGT
    locationcomparison = abs([GTsites(k,1)-Chipsites(:,1) GTsites(k,2)-Chipsites(:,2)]) <= error;
    if max(sum(locationcomparison,2)) == 2
        GTstatus(k,1) = true;
    end
    if max(sum(locationcomparison,2)) > 2
        disp('Something weird in GTvsChiparea');
    end
end
        