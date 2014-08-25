EEG-TAG
=======

Rapid Image Search via EEG (Rapid Serial Visual Presentation paradigm) and TAG (graph-based computer vision) in a closed loop

=======

The following article explains how this software can be used for rapid image search. Users employing this software in a publication should cite this paper.

Eric A Pohlmeyer et al. (2011) "Closing the loop in cortically-coupled computer vision: a brain–computer interface for searching image databases." J. Neural Eng. 8 036025 [doi:10.1088/1741-2560/8/3/036025](http://dx.doi.org/10.1088/1741-2560/8/3/036025)

=======

To get started with this software:
<ol>
<li>Download this repository</li>
<li>Download the Third Party software here: https://dl.dropboxusercontent.com/u/10809610/EEG-TAG/ThirdParty.zip </li>
<li>Download the TAG CV graph here: https://dl.dropboxusercontent.com/u/10809610/EEG-TAG/CaltechGistGraph_BM.mat 
and place it in the Analysis/CalTech_ClosedLoop_PilotExp/DataFiles folder. (This graph was built for the CalTech101 image set; a new image set will require a new graph if you want to use the closed-loop MATLAB code. Alternatively, the RSVP display code and EEG analysis can run with a new image set without requiring a graph.) </li>
<li>Follow the setup instructions in Documentation/Readme.txt .</li>
</ol>
[Documentation/Readme.txt](Documentation/Readme.txt)
