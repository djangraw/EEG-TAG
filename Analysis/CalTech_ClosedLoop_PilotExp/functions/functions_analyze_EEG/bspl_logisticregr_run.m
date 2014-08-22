function [Ey,pot] = bspl_logisticregr_run(x,theta)
% [Ey,pot] = logisticregr_run(x,theta)

% Author: Mads Dyrholm
pot = (x'*theta(2:end) + theta(1))';
Ey = 1./ (1+exp(-(pot)));
