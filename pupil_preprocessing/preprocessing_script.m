% preprocessing_script runs the preprocessing pipeline on the raw pupil
% data, saves the preprocessed data with trial numbers and event names.
% This script runs two pipelines: main (no filtering) and alternate (with filtering)

clc
clearvars

rng(123); % general seed

% COMMON PARAMETERS (shared across both pipelines)
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
plot_steps = 0; % if you want to visualise data for each preprocessing step
sampling_rate = 1000; % original sampling rate
freqs = [0.01 10]; % filter cutoffs [lo hi]
downsample_rate = 100; % sampling rate after down sampling
event_names = {'blinks','saccades'}; % event names
deconv_time = [0,6]; % deconvolution time interval
using_DAT = 1; % always set to 0 if you are preprocessing files for the VERY (!!!) first time.

% SETUP PATHS (common to both pipelines)
currentDir = cd; % current directory
reqPath = 'Perceptual_unc_aug_task_pupil'; % to which directory one must save in
pathParts = strsplit(currentDir, filesep);
if startsWith(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    % Call the function to create the desired path
    desiredPath = createSavePaths(currentDir, reqPath);
end

baseDir = strcat("pupil_dataset", filesep, "pupil_converted");

% Use filesep for platform independence and strcat for concatenation
currentDir_asc = strcat(desiredPath, filesep, baseDir, filesep, 'ASC'); % Construct ASC directory path
currentDir_dat = strcat(desiredPath, filesep, baseDir, filesep, 'DAT'); % Construct DAT directory path

% Save directory for ASC to DAT conversion (shared)
save_dirASC = strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'preprocessing', filesep, 'asc2dat_converted'); 
mkdir(save_dirASC);

%% RUN MAIN PIPELINE (no filtering, linear interpolation)

disp('===== RUNNING MAIN PIPELINE WITH LINEAR INTERPOLATION =====');
noFiltering = 1; % no filter applied (main MS pipeline)
linearInt = 1; % cubic-spline interpolation (main MS pipeline)

% Set up save directory for main pipeline
save_dir_main = strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'preprocessing', filesep, 'main pipeline', filesep, 'preprocessed linear int'); 
mkdir(save_dir_main);

% % Preprocess
% preprocessing_fun(subj_ids, num_sess, plot_steps, sampling_rate, freqs, ...
%     downsample_rate, event_names, deconv_time, save_dir_main, currentDir_asc, currentDir_dat, ...
%     save_dirASC, using_DAT, noFiltering, linearInt)
% 
% % Add event names and trial numbers
% preproc_dir = save_dir_main;
% save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'preprocessing', filesep, 'main pipeline', filesep, 'preprocessed linear int trials and events added'); 
% add_eventstrials;

%% RUN MAIN PIPELINE (no filtering, cubic-spline interpolation)

disp('===== RUNNING MAIN PIPELINE WITH CUBIC SPLINE INTERPOLATION =====');
noFiltering = 1; % no filter applied (main MS pipeline)
linearInt = 0; % cubic-spline interpolation (main MS pipeline)

% Set up save directory for main pipeline
save_dir_main = strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'preprocessing', filesep, 'main pipeline', filesep, 'preprocessed cubic spline new'); 
mkdir(save_dir_main);

% % Preprocess
% preprocessing_fun(subj_ids, num_sess, plot_steps, sampling_rate, freqs, ...
%     downsample_rate, event_names, deconv_time, save_dir_main, currentDir_asc, currentDir_dat, ...
%     save_dirASC, using_DAT, noFiltering, linearInt)
% 
% % Add event names and trial numbers
% preproc_dir = save_dir_main;
% save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'preprocessing', filesep, 'main pipeline', filesep, 'preprocessed cubic spline new trials and events added'); 
% add_eventstrials;

%% RUN ALTERNATE PIPELINE (with filtering, deconvolution-based)

disp('===== RUNNING ALTERNATE PIPELINE =====');
noFiltering = 0; % filter applied (supplement pipeline)
linearInt = 1; % linear interpolation (supplement pipeline)

save_dir_alt = strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'preprocessing', filesep, 'alternate pipeline', filesep, 'preprocessed fixed seed');
% Define individual path variables
pupil_og_path           = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'pupil', filesep, 'preprocessing', filesep, 'alternate pipeline', filesep, 'pupil og');
pupil_lin_interp_path   = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'pupil', filesep, 'preprocessing', filesep, 'alternate pipeline', filesep, 'pupil linear interpolation');
pupil_urai_peak_path    = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'pupil', filesep, 'preprocessing', filesep, 'alternate pipeline', filesep, 'pupil urai peak correction');
pupil_low_filter_path   = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'pupil', filesep, 'preprocessing', filesep, 'alternate pipeline', filesep, 'pupil low filter');
pupil_band_filter_path  = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'pupil', filesep, 'preprocessing', filesep, 'alternate pipeline', filesep, 'pupil band filter');
pupil_downsamp_path     = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'pupil', filesep, 'preprocessing', filesep, 'alternate pipeline', filesep, 'pupil downsampling for deconv');
pupil_cleaned_bp_path   = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'pupil', filesep, 'preprocessing', filesep, 'alternate pipeline', filesep, 'pupil cleaned bp');
pupil_cleaned_lp_path   = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'pupil', filesep, 'preprocessing', filesep, 'alternate pipeline', filesep, 'pupil cleaned lp');
pupil_zsc_path          = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'pupil', filesep, 'preprocessing', filesep, 'alternate pipeline', filesep, 'pupil zsc');

% Create directories
if ~isfolder(save_dir_alt);    mkdir(save_dir_alt);    end
if ~isfolder(pupil_og_path);          mkdir(pupil_og_path);          end
if ~isfolder(pupil_lin_interp_path);  mkdir(pupil_lin_interp_path);  end
if ~isfolder(pupil_urai_peak_path);   mkdir(pupil_urai_peak_path);   end
if ~isfolder(pupil_low_filter_path);  mkdir(pupil_low_filter_path);  end
if ~isfolder(pupil_band_filter_path); mkdir(pupil_band_filter_path); end
if ~isfolder(pupil_downsamp_path);    mkdir(pupil_downsamp_path);    end
if ~isfolder(pupil_cleaned_bp_path);  mkdir(pupil_cleaned_bp_path);  end
if ~isfolder(pupil_cleaned_lp_path);  mkdir(pupil_cleaned_lp_path);  end
if ~isfolder(pupil_zsc_path);         mkdir(pupil_zsc_path);         end

% Preprocess
preprocessing_fun(subj_ids, num_sess, plot_steps, sampling_rate, freqs, ...
    downsample_rate, event_names, deconv_time, save_dir_alt, currentDir_asc, currentDir_dat, ...
    save_dirASC, using_DAT, noFiltering, linearInt, ...
    pupil_og_path, pupil_lin_interp_path, pupil_urai_peak_path, pupil_low_filter_path, ...
    pupil_band_filter_path, pupil_downsamp_path, pupil_cleaned_bp_path, pupil_cleaned_lp_path, ...
    pupil_zsc_path);

preproc_dir = save_dir_alt;
save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'preprocessing', filesep, 'alternate pipeline', filesep, 'preprocessed trials and events added fixed seed');
add_eventstrials;
disp('===== PREPROCESSING COMPLETE =====');