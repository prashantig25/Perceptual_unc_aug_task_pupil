classdef lr_vars < handle
% LR_VARS superclass specifies variables for the model-based analysis of
% learning rates.
    properties
        filename = 'preprocessed_lr_pupil_no_zerope.xlsx'; % filename with pre-processed data
        data % pre-processed data
        mdl % variable to store model definition
        lr_mdl % run best behavioral model 
        baseline_mdl = 0 % run a baseline model to compute pseudo-rsquare
        pred_vars  % cell array with names of predictor variables
        resp_var % name of response variable
        cat_vars % cell array with names of categorical variables
        num_vars % number of predictor variables
        res_subjs = []; % empty array to store residuals
        weight_y_n = 1; % if non-weighted regression, weight_y_n = 0
        num_subjs = 47; % number of participants
        weighted = 1; % if weighted regression needs to be run
        var_names = {'pe','contrast_diff','salience','congruence','pe_sign'}; % variable names for posterior updates
        absolute_analysis % pre-process data for absolute LR analysis
    end
end