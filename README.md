This repository contains the code required to reproduce all of the analyses and figures from INSERT OUR PREPRINT LINK.

# Where can I get the data from?

To access all the raw behavioral and pupillometry data (preprocessed versions also included), please use INSERT GIN REPO LINK.

# How to reproduce all the analyses?

Please follow these steps to run all the main and supplementary analyses from our manuscript. 

To reproduce our behavioural results, these are the required steps:
1. To preprocess and clean up the behavioral data, run preprocess_descriptive.m 
2. To get descriptive data about participants' choices and learning, run descriptive_behv.m
3. Next to reproduce all our model-based analyses of participants' learning behavior, run LR_analysis_pupil.

To reproduce our pupillometry results, please follow these steps. 

1. To preprocess the raw pupil signal, run preprocessing_script.m (Please note, this is optional. Since preprocessing steps can be time consuming, you can skip it and still replicate all our results).
2. To reproduce our descriptive pupil results, run 
3. To reproduce our modeling results, run
4. To reproduce our analysis of arousal and learning residuals, run

# Software

The scripts can be run in MATLAB.

# Questions ?

Please contact prashantig25@gmail.com in case of questions, queries or clarifications. 

# Just making some notes for myself.

Steps to work with the pupil dataset:
1. Preprocess data
	a. Save it as .txt or .xlsx and continue with step 2
    b. If you don't want to run the preprocessing, just use the preprocessed files in BIDS format
2. Add trials and events
3. Get pupil signal according to your needs
4. Run any other analysis or figure coe