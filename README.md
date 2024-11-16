This repository contains the code required to reproduce all of the analyses and figures from INSERT OUR PREPRINT LINK.

# Where can I get the data from?

To access all the raw behavioral and pupillometry data (preprocessed versions also included), please use INSERT GIN REPO LINK.
Please download the .zip file from the 'main' branch of this repository. 
Add all the extracted files (called 'pupil_dataset') to the repository folder on your local path.

# How to reproduce all the analyses?

Please follow these steps to run all the main and supplementary analyses from our manuscript. 

To reproduce our behavioral results, these are the required steps:
1. To preprocess and clean up the behavioral data, run preprocess_descriptive.m 
2. To get descriptive data about participants' choices and learning, run descriptive_behv.m
3. Next to reproduce all our model-based analyses of participants' learning behavior, run LR_analysis_pupil.m.

To reproduce our pupillometry results, please follow these steps. 

1. To preprocess the raw pupil signal, run preprocessing_script.m followed by add_eventstrials.m (Please note, this step is optional. Since preprocessing can be time-consuming (around 1 hour to preprocess all files), you can skip it and still replicate all our results).
2. To reproduce our descriptive pupil results (Figure 3), run get_pupilsignal.m, gazeposition.m, get_pupilPEbins.m, and fullTrial.m. 
3. To reproduce our modeling results (Figure 4), run pupil_regressionNew.m and posteriorcurves_pecondiff.m.
4. To reproduce our analysis of arousal and learning residuals (Figure 5), run residualUP_analysis.m and arousal_variabilityInteractions.m.

# Software

The scripts can be run in MATLAB. For statistical analyses of the pupil results, we rely on FieldTrip (https://www.fieldtriptoolbox.org/download/). Please download it and add it to your local path that contains this repository. 

# Questions ?

Please contact prashantig25@gmail.com in case of questions, queries, or clarifications. 