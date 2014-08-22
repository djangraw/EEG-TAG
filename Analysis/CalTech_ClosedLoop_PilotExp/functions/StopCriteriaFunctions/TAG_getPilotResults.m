function [best_cats, best_pval] = TAG_getPilotResults(subjects,categories,pvalMethod,catMethod,cutoff)

% function [best_cats, best_pval] = TAG_getPilotResults(subjects,categories,pvalMethod,catMethod)
%
% Created 11/16/09 by DJ.
% Last updated 11/16/09 by DJ.

if ischar(categories)
    categories = {categories};
end
if nargin < 5
    cutoff = 0.05;
end

for i = 1:numel(subjects);    
    for j=1:numel(categories);
        disp('***********************************************************')
        disp(sprintf('Subject %d, Category %s, pvalMethod %s, catMethod %s',subjects(i),categories{j},pvalMethod,catMethod))
        
        % Load
        switch categories{j}
            case {'pizza','Pizza','pizzas','Pizzas', 1}
                load PizzaXML.mat
                load(['Subject' num2str(subjects(i)) '_pizza_TAGperformance']) 
                figtitle = sprintf('Pizzas, Subject %d, %s method',subjects(i),pvalMethod);
            case {'piano','Piano','grand_piano','GrandPiano','pianos','Pianos','grand_pianos','GrandPianos',2}
                load PianoXML.mat
                load(['Subject' num2str(subjects(i)) '_grand_piano_TAGperformance'])
                figtitle = sprintf('Pianos, Subject %d, %s method',subjects(i),pvalMethod);
            case {'elephant', 'Elephant','elephants', 'Elephants',3}
                load ElephantXML.mat
                load(['Subject' num2str(subjects(i)) '_elephant_TAGperformance'])
                figtitle = sprintf('Elephants, Subject %d, %s method',subjects(i),pvalMethod);
            otherwise
                error('Category not found!')
        end

        % Calculate
        [howmany_in howmany_out catlist] = TAG_howmanyinout([{file_list}; AllTAGresults(1:4)],TAGinputs);

        % Plot
%         figure((j-1)*max(subjects)+subjects(i)); clf;
%         MakeFigureTitle(figtitle);
%         p = TAG_plotPvalues(howmany_in,howmany_out,catlist,pvalMethod);
        p = TAG_getPvalues(howmany_in,howmany_out,pvalMethod);

        % Display winners
        [best_cats, best_pval] = TAG_getWinners(p,catlist,catMethod,cutoff);
    end
end