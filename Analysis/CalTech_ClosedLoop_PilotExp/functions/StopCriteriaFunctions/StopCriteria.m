%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Here we run some tests to see if the stop criteria have been satisfied
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
function [hstop best_cats best_pval] = StopCriteria(xmlfilename, file_list_All, categorydistribution)

%%%This is how much smaller the smallest pvalue must be compared to the
%%%second smallest in order for us to declare a winner.
stopmultiplier = .001;

%%%
%%%First, update the Displayedimages and EEGresults data matrices with the
%%%information from the most recent round.
%%%
%%%Load the available EEGdata and displayed data accumulated so far (if no
%%%file is available, then create one).
%history_filename = [xmlfilename(1,1:8),xmlfilename(1,11:end-4),'_DisplayHistory.mat'];
history_filename = [xmlfilename(1,1:end-6),'_DisplayHistory.mat'];
try
    load(history_filename);
catch
    disp('No historical data available, assuming this is the first iteration');
    DisplayedImages = cell(1,5);
    EEGresults      = cell(1,5);
    LastIteration   = 0;
end
%%%
%%%Update the data with the current run
LastIteration                    = LastIteration+1;
DisplayedImages{1,LastIteration} = file_list_All;
EEGresults{1,LastIteration}      = categorydistribution; 
%%%
%%%Determine the distributions of categories that were shown during the
%%%RSVP (howmany_in) and what the distribution of target categories were in
%%%the top 20 (howmany_out), as well as the overall list of all the
%%%category labels (catlist)
[howmany_in howmany_out catlist] = TAG_howmanyinout(DisplayedImages(1,1:LastIteration),EEGresults(1,1:LastIteration));
%%%
%%%Determine what the p values are for the probability of having a certain
%%%qty of images appear in the top 20 given the prevelence (the prevelance
%%%used depends on the method chosen).
p_results{1,1} = TAG_getPvalues(howmany_in,howmany_out,'default');
p_results{2,1} = TAG_getPvalues(howmany_in,howmany_out,'firstrun');
p_results{3,1} = TAG_getPvalues(howmany_in,howmany_out,'cumulative');
%%%
%%%Given the p-values, determine whether any of the categories satisfies
%%%the stop criteria
p_type = {'default';'firstrun';'cumulative'};
method = {'lowest';'cutoff';'multiplication'};
cutoff = [3 .05 3]';%either lowest integer # scores, or a pvalue threshold
for zz=1:3%p_type
    disp('_______________________________________________________');
    fprintf('Evaluating cut-off for method: %s \n' , p_type{zz,1});
    disp('_______________________________________________________');
     for qq=1:3%method/cutoff
        [best_cats{zz,qq}, best_pval{zz,qq}] = TAG_getWinners(p_results{zz,1},catlist,method{qq,1},cutoff(qq,1));
    end
    disp('_______________________________________________________');
end

%%%
%%%Make a plot reflecting the scales of the smallest pvalues
hstop = figure; hold on; box off;
cutoff_meth = 3;%only look at the multiplication method
for zz=1:3
    for qq=1:LastIteration
        if size(best_pval{zz,cutoff_meth}{1,qq},2)>0
            subplot(LastIteration,3,(-2 + qq*3)-1+zz), bar(1./best_pval{zz,cutoff_meth}{1,qq}(1:end)); box 'off';
            set(gca,'FontSize',8), axis([0 4 0 inf]);
            set(gca,'XTick',1:size(best_pval{zz,cutoff_meth}{1,qq},2),'XTickLabel',best_cats{zz,cutoff_meth}{1,qq}(1:end))
        end
    end
end;
subplot(LastIteration,3,1),title('Default');subplot(LastIteration,3,2),title('First Run');
subplot(LastIteration,3,3),title('Cumulative');hold off;
%%%
%%%Now, check to see if any of the p values are sufficiently small to
%%%satisfy the stop criteria
for cutoff_meth = 1:3
    for zz=1:3%p_type
        if size(best_pval{zz,cutoff_meth}{1,end},2) >= 2
            if best_pval{zz,cutoff_meth}{1,end}(1,1) < stopmultiplier*best_pval{zz,cutoff_meth}{1,end}(1,2);
                fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!We have a winner (using the %s method with %s): %s \n', p_type{zz,1}, method{cutoff_meth,1}, best_cats{zz,cutoff_meth}{1,end}{1,1});
            else
                disp('No winners yet, keep going');
            end
        else
            fprintf('Not enough qualifiers yet to test (using the %s method with %s), keep going \n', p_type{zz,1}, method{cutoff_meth,1});
        end
    end
end
%%%
%%%Save the updated history of displayed imagery
save(history_filename, 'DisplayedImages','EEGresults','LastIteration');