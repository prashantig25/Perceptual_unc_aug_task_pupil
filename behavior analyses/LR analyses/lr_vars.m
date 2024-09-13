classdef lr_vars < handle
% LR_VARS superclass specifies variables for the model-based analysis of
% learning rates.
    properties
        filename = 'preprocessed_lr_pupil_no_zerope.xlsx'; % filename with pre-processed data
        data % pre-processed data
        mdl % variable to store model definition
        lr_mdl = 1 % run best behavioral model 
        pred_vars  % cell array with names of predictor variables
        resp_var = 'up'; % name of response variable
        cat_vars % cell array with names of categorical variables
        num_vars % number of predictor variables
        res_subjs = []; % empty array to store residuals
        weight_y_n = 1; % if non-weighted regression, weight_y_n = 0
        num_subjs = 47; % number of participants
        weighted = 1; % if weighted regression needs to be run
        var_names = {'pe','contrast_diff','salience','congruence','pe_sign'}; % variable names for posterior updates
        absolute_analysis = 1; % pre-process data for absolute LR analysis
        grouped = 0; % set to 1 if regression model needs to be fit separately for different groups of trials
        num_groups = 2; % number of groups for grouped regression
        pupil = 1; % fit model to pupil dataset
        posterior = 1; % posterior updates for pupil dataset
        space_instrumental = 0; % fit model to space dataset
        space_pavlovian = 0; % fit model to space pavlovian dataset
        sensitivity = 0; % fit model to sensitivity dataset
        online = 0; % fit model to eLife online dataset
        agent = 0; % fit model to agent dataset
    end
end