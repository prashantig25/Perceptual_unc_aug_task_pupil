function [data_all] = cleanUP_func(subj_ids, num_trials, format, behv_dir)
% function cleanUP_func cleans the behavioral data before further LR analyses by removing
% trials with no slider response.
%
% INPUT:
%   subj_ids: subject IDs
%   num_trials: number of trials
%   format: file format
%   behv_dir: directory for behavioral data
%
% OUTPUT:
%   data_all: cleaned up behavioral data

% INITIALISE VARS (NOTE: DON'T CHANGE SUBJECT IDs and NUM_SESS)
num_subjs = length(subj_ids); % number of subjects
data_subj = []; % empty array for each subjects data
data_all = []; % empty array for all participants' data

% LOOP OVER ALL SUBJECTS
for n = 1:num_subjs
    missed_trials_all = [];
    sess_trials = [];

    % LOOP OVER NUMBER OF SESSIONS FOR THAT PARTICIPANT
    filename = strcat(behv_dir,filesep,subj_ids{n},format); % filename
    data = readtable(filename); % read file
    
    % REMOVE MISSED SLIDER TRIALS
    missed_trials = []; % initialize array for index of missed trials
    for i = 1:height(data)
        if isnan(data.slider(i,:)) % check if participant has not responded
            missed_trials = [missed_trials;i];
        end
    end
    missed_trials_all = [missed_trials_all;missed_trials];
    data(missed_trials,:) = []; % delete such trials

    % ADD TRIAL NUMBERS FOR EACH BLOCK
    t = 0;
    for i = 1:height(data)
        if t > num_trials - 1
            t = 1;
        else
            t = t + 1;
        end
        data.trial(i) = t;
    end
    data_subj = data;
    data_all = [data_all; data_subj];
    data_subj = [];
end

end