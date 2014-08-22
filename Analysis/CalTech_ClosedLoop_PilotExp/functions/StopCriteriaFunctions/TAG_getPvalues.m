function p = TAG_getPvalues(howmany_in,howmany_out,method)

% Created 11/13/09 by DJ.
% update 11/20: EAP
%           modified firstrun to account for scenario wherein a category was not shown
%           at all during the first one (or more) runs
% Last updated 11/20/09 by EAP.
%

% Set up
if nargin<3
    method = 'default'
end
load pMatrix.mat
p = ones(size(howmany_in));

% Do it up
switch method
    case 'default'
        for i=1:size(p,1) %nRuns
            for j=1:size(p,2) %nCategories
                if howmany_out(i,j)>0
                    p(i,j) = pMatrix{1}(howmany_out(i,j),howmany_in(i,j));
                end
            end
        end
    case 'firstrun'
        for i=1:size(p,1) %nRuns
            for j=1:size(p,2) %nCategories
                if howmany_out(i,j)>0
                    %%%Verify this category had a value in the first run
                    %%%on which to base the prevelnce, if not, base the
                    %%%prevelence on its first appearence.
                    firstpop = howmany_in(1,j);
                    if firstpop == 0
                        disp(['Category ',int2str(j),' wasn''t present in the first run, using later run for prevelence']);
                        for ii=1:size(p,1) %nRuns
                            firstpop = howmany_in(ii,j);
                            if firstpop>0; break; end;
                        end
                    end
                    if firstpop == 0
                        %%%I don't think this is possible, but just in case
                        %%%I'm including it.
                        disp(['Could not calculate p for category ',int2str(j),', as there''s early population on which to base it']);
                    else
                        p(i,j) = pMatrix{1}(howmany_out(i,j),firstpop);
                    end
                end
            end
        end
    case 'cumulative'
        for i=1:size(p,1) %nRuns
            for j=1:size(p,2) %nCategories
                if howmany_out(i,j)>0
                    p(i,j) = pMatrix{i}(sum(howmany_out(1:i,j)),sum(howmany_in(1:i,j)));
                end
            end
        end
    otherwise
        error('Method not found!')
end