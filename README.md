This repository contains the code required to reproduce all of the analyses and figures from INSERT OUR PREPRINT LINK.

# Where can I get the data from?

To access all the raw behavioral and pupillometry data (preprocessed versions also included), please follow these steps:

1. Download Datalad (https://handbook.datalad.org/en/latest/intro/installation.html) to your computer.
2. Next, clone the repo with the data using this command (datalad clone git@gin.g-node.org:/prashantig25/pupil_dataset.git) using command prompt. 
3. If the cloned folder is NOT already inside the path of the repo ('Perceptual_unc_aug_task_pupil'), please move it inside the repo ('Perceptual_unc_aug_task_pupil') folder on your local path.
4. Change the current directory on your command prompt to the directory of the cloned repo.
5. Finally, to save the data use this command (datalad get .).

Note for us: we can skip this entire thing at least for reviewers if it feels too complex and time consuming. reviewers can still run all analysis and plot figures. they would only need behavioral data which is not large and can be shared via github.

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