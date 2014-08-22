%%%Creates a blank, monochromatic image.
%%%
%%%Can specify width, height, depth (3 for full color, 1 for B/W or
%%%grayscale), and the color.  Default is a 500 by 500 gray image.
%%%
%%%blankimage  = createmonochromaticimage(blankwidth, blankheight, whichcolor, blankdepth);
%%%
%%%Last modified Dec 2008, EAP

function blankimage  = createmonochromaticimage(blankwidth, blankheight, whichcolor, blankdepth)

if nargin < 4
    blankdepth = 3;
end

if nargin < 3
    whichcolor = 127;
end

if nargin == 0
    blankheight = 500;
    blankwidth  = 500;   
end

if nargin == 1
    disp('When specifying size, must specify both width AND height');
    return;
end

%%%Make the background
blankimage  = uint8(whichcolor*ones(blankheight,blankwidth,blankdepth));