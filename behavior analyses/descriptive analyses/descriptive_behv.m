% descriptive_behv saves descriptive data about participants' 
% choice and learning.

clc
clearvars

% INITIALISE VARS
subj_ids = {'806','3970','4300','4885','4954','907','2505','3985','4711',...
    '3376','4927','190','306','3391','5047','3922','659','421','3943',...
    '4225','4792','3952','4249','4681','4738','3904','852','3337',...
    '3442','3571','4360','4522','4807','4943','594','379','4057','4813',...
    '601','3319','129','4684','3886','620','901','900'}; % removed 4672 for basic descriptive analyses because 1 trial missing 
num_subjs = length(subj_ids); % number of subjects
num_cond = 2; % number of conditions
num_contrast = 2; % high and low contrast blocks
t = 20; % number of trials
num_blocks = 8; % number of blocks

% USER-BASED PATH
currentDir = cd; % current directory
reqPath = 'Perceptual_unc_aug_task_pupil-main'; % to which directory one must save in
pathParts = strsplit(currentDir, filesep);
if strcmp(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    % Call the function to create the desired path
    desiredPath = createSavePaths(currentDir, reqPath);
end
behv_dir = strcat(desiredPath, filesep, 'pupil_dataset',filesep,'behavior_BIDS');
save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data',filesep, 'behavior', filesep, 'descriptive'); 
mkdir(save_dir);

% INITIALIZE VARS TO STORE
mix_ecoperf = NaN(num_subjs,1);
perc_ecoperf = NaN(num_subjs,1);

mix_mu = NaN(num_subjs,1);
perc_mu = NaN(num_subjs,1);

mix_curve = NaN(num_subjs,t);
perc_curve = NaN(num_subjs,t);

for n = 1:num_subjs

    % GET BEHAVIORAL DATA
    tsv_file = fullfile(behv_dir,strcat('sub_',num2str(subj_ids{n})),'behav', ...
            strcat('sub_',num2str(subj_ids{n}),".tsv")); % path and file name for TSV file
    data = readtable(tsv_file,"FileType","text",'Delimiter', '\t'); % read file

    % CORRECT MU FOR CONGRUENCE
    data.flipped_mu = data.mu;
    for h = 1:height(data)
        if data.congruence(h) == 0
            data.flipped_mu(h) = 1-data.mu(h);
        end
    end
 
    % CALCULATE MEAN ECOPERF AND MU
    mix_ecoperf(n,:) = nanmean(data.ecoperf(data.condition == 1),1);
    perc_ecoperf(n,:) = nanmean(data.ecoperf(data.condition == 2),1);
    mix_mu(n,:) = nanmean(data.flipped_mu(data.condition == 1),1);
    perc_mu(n,:) = nanmean(data.flipped_mu(data.condition == 2),1); 

    uni_mix = unique(data.blocks(data.condition==1)); % block number for condition = 1
    uni_perc = unique(data.blocks(data.condition==2)); % block number for condition = 2
    mix_subj = NaN(num_blocks,t);
    perc_subj = NaN(num_blocks,t);
    for b = 1:num_blocks./2
        mix_subj(b,:) = data.flipped_mu(and(data.blocks == uni_mix(b),data.condition == 1));
        perc_subj(b,:) = data.flipped_mu(and(data.blocks == uni_perc(b),data.condition == 2));
    end
    mix_curve(n,:) = nanmean(mix_subj);
    perc_curve(n,:) = nanmean(perc_subj);    
end

% SAVE
safe_saveall(fullfile(save_dir,"mix_curve.mat"),mix_curve)
safe_saveall(fullfile(save_dir,"perc_curve.mat"),perc_curve)

safe_saveall(fullfile(save_dir,"mix_ecoperf.mat"),mix_ecoperf)
safe_saveall(fullfile(save_dir,"perc_ecoperf.mat"),perc_ecoperf)

safe_saveall(fullfile(save_dir,"mix_mu.mat"),mix_mu)
safe_saveall(fullfile(save_dir,"perc_mu.mat"),perc_mu)
