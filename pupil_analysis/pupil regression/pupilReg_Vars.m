classdef pupilReg_Vars < handle
    % Superclass containing all configuration parameters for pupil regression analysis
    
    properties
        % Subject and session parameters
        subj_ids % subject IDs
        num_subs % number of subjects
        num_sess % number of sessions
        
        % Directory paths
        behv_dir % behavioral data directory
        pupil_dir % pupil preprocessed data directory
        xgaze_dir % x-gaze preprocessed data directory
        ygaze_dir % y-gaze preprocessed data directory
        base_dir % baseline preprocessed directory
        save_dir % where to save directory
        
        % Analysis parameters
        timewindow % timewindow for analysis
        regress_rt % whether to regress the impact of RT before fitting the model
        baseline_mdl % whether to fit the regression model with baseline as a regressor
        binned % whether to run the binned regression model 
        bins % bins  
        bins_array % bins index array
        binned_accuracy % whether to fit the model separately for two separate bins of trials divided by accuracy
        two_tailed % whether the t-test is supposed to be one or two-tailed during permutation testing
        col % total number of time points
        residuals_predicted % whether we want to store regression residuals and model-predicted pupil responses
        
        % Model specification
        num_vars % number of variables in the model
        model_def % define the linear model
        pred_vars % predictor variables
        cat_vars % categorical variables
        resp_var % response variable
        
        % Data
        preds_all % all predictors from the behavioral data
        
        % File names
        betas_save % name under which betas should be saved
        perm_save % name under which the results from the permutation testing should be saved
        residuals_save % name under which the residuals should be saved
        predicted_save % name under which the model predicted pupil values must be saved
    end
    
    methods
        function obj = pupilReg_Vars()
            % Constructor - Creates a new instance of pupilReg_Vars with default values
            % 
            % Returns:
            %   obj - pupilReg_Vars object initialized with default parameters
            obj.initializeDefaults();
        end
        
        function initializeDefaults(obj)
            % Initialize all configuration parameters to their default values
            % Sets up standard analysis parameters, predictor variables, and categorical variables
            % for pupil regression analysis
            obj.timewindow = 'feedback';
            obj.regress_rt = 0;
            obj.baseline_mdl = 0;
            obj.binned = 0;
            obj.binned_accuracy = 0;
            obj.two_tailed = 0;
            obj.col = 300;
            obj.bins_array = 1;
            obj.resp_var = 'pupil';
            obj.pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf','pe_condiff'};
            obj.cat_vars = {'condition','reward','ecoperf'};
        end
        
        function setSubjects(obj, subj_ids, num_sess)
            % Configure subject identifiers and session parameters
            % 
            % Parameters:
            %   subj_ids - cell array or vector of subject identifiers
            %   num_sess - number of sessions per subject
            %
            % Updates obj.subj_ids, obj.num_subs (calculated from length), and obj.num_sess
            obj.subj_ids = subj_ids;
            obj.num_subs = length(subj_ids);
            obj.num_sess = num_sess;
        end
        
        function setPaths(obj, behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir)
            % Set all directory paths for input data and output files
            %
            % Parameters:
            %   behv_dir - path to behavioral data directory
            %   pupil_dir - path to pupil preprocessed data directory  
            %   xgaze_dir - path to x-gaze preprocessed data directory
            %   ygaze_dir - path to y-gaze preprocessed data directory
            %   base_dir - path to baseline preprocessed data directory
            %   save_dir - path to output directory for saving results
            obj.behv_dir = behv_dir;
            obj.pupil_dir = pupil_dir;
            obj.xgaze_dir = xgaze_dir;
            obj.ygaze_dir = ygaze_dir;
            obj.base_dir = base_dir;
            obj.save_dir = save_dir;
        end
        
        function setModel(obj, model_def, pred_vars, cat_vars, num_vars)
            % Configure the linear regression model specification
            %
            % Parameters:
            %   model_def - string defining the linear model formula
            %   pred_vars - cell array of predictor variable names
            %   cat_vars - cell array of categorical variable names  
            %   num_vars - integer specifying total number of variables in model
            obj.model_def = model_def;
            obj.pred_vars = pred_vars;
            obj.cat_vars = cat_vars;
            obj.num_vars = num_vars;
        end
        
        function setFileNames(obj, betas_save, perm_save, residuals_save, predicted_save)
            % Set output file names for different analysis results
            %
            % Parameters:
            %   betas_save - filename for saving regression beta coefficients
            %   perm_save - filename for saving permutation test results
            %   residuals_save - filename for saving model residuals
            %   predicted_save - filename for saving model-predicted pupil responses
            obj.betas_save = betas_save;
            obj.perm_save = perm_save;
            obj.residuals_save = residuals_save;
            obj.predicted_save = predicted_save;
        end
        
        function validateConfig(obj)
            % Validate that all required configuration parameters are properly set
            % Performs basic checks to ensure the object is ready for analysis
            %
            % Throws assertion errors if required parameters are missing or invalid
            assert(~isempty(obj.subj_ids), 'Subject IDs must be specified');
            assert(~isempty(obj.behv_dir), 'Behavioral data directory must be specified');
            assert(~isempty(obj.pupil_dir), 'Pupil data directory must be specified');
            assert(~isempty(obj.model_def), 'Model definition must be specified');
            assert(obj.num_vars > 0, 'Number of variables must be positive');
        end
    end
end