function [best_cats, best_pval] = TAG_getWinners(p,catlist,method,cutoff)

% function [top_cats, pMin] = TAG_getWinners(p,catlist,method,cutoff)
%
% Created 11/16/09 by DJ.
% Last updated 11/16/09 by DJ.

nRuns = size(p,1);
if nargin<4 cutoff=0.05; end

switch method
    case 'lowest'
        disp(sprintf('***LOWEST PVAL METHOD, bottom %d***',cutoff))
        for i=1:nRuns
            [best_pval{i} order] = sort(p(i,:),'ascend');
            best_pval{i} = best_pval{i}(1:cutoff);
            best_cats{i} = catlist(order(1:cutoff));
            disp(sprintf('---Run %g:---',i))
            for j=1:cutoff
                disp(sprintf('%s: p = %0.2g',best_cats{i}{j},best_pval{i}(j)))
            end
        end
    case 'cutoff'
        disp(sprintf('***CUTOFF METHOD, Cutoff = %g***',cutoff))
        for i = 1:nRuns
            [best_pval{i} order] = sort(p(i,:),'ascend');
            okcats = find(best_pval{i}<cutoff);
            best_pval{i} = best_pval{i}(okcats);
            best_cats{i} = catlist(order(okcats));
            disp(sprintf('---Run %g:---',i))
            if ~isempty(okcats)
                for j=1:numel(best_cats{i})
                    disp(sprintf('%s: p = %0.2g',best_cats{i}{j},best_pval{i}(j)))
                end
            else
                disp('No winner found.')
            end
        end   
    case 'multiplication'
        disp(sprintf('***MULTIPLICATION METHOD, bottom %d***',cutoff))
        pProduct = ones(1,size(p,2));
        for i=1:nRuns
            pProduct = pProduct.*p(i,:);
            [best_pval{i} order] = sort(pProduct,'ascend');
            okcats = 1:cutoff;
            best_pval{i} = best_pval{i}(okcats);
            best_cats{i} = catlist(order(okcats));
            disp(sprintf('---Run %g:---',i))
            if ~isempty(okcats)
                for j=1:numel(best_cats{i})
                    disp(sprintf('%s: p = %0.2g',best_cats{i}{j},best_pval{i}(j)))
                end
            else
                disp('No winner found.')
            end
        end            
    otherwise
        error('Method not found!')
end