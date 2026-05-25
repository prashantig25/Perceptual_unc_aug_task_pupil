% descriptive_behv saves descriptive data about participants' 
% choice and learning.

clc
clearvars

% INITIALISE VARS
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
num_subjs = length(subj_ids); % number of subjects
num_cond = 2; % number of conditions
num_contrast = 2; % high and low contrast blocks
t = 20; % number of trials
num_blocks = 8; % number of blocks

% USER-BASED PATH
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
behv_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines', filesep, 'behavior', filesep, 'BIDS');
save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines',filesep, 'behavior', filesep, 'descriptive (n = 47)');
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
    if strcmp(subj_ids{n},"0806")
        subj_ids{n} = "806";
    end
    tsv_file = fullfile(behv_dir,strcat('sub_',num2str(subj_ids{n})),'behav', ...
            strcat('sub_',num2str(subj_ids{n}),".tsv")); % path and file name for TSV file
    data = readtable(tsv_file,"FileType","text",'Delimiter', '\t'); % read file

    % ADJUST FOR TRIAL MISSING PARTICIPANT
    if strcmp(subj_ids{n}, "4672")
        % Block sizes for participant 4672:
        % Blocks 1-5: 20 trials each
        % Block 6:    19 trials % because interruption
        % Blocks 7-8: 20 trials each
        block_sizes = [20, 20, 20, 20, 20, 19, 20, 20];
        block_ends  = cumsum(block_sizes);           % [20, 40, 60, 80, 100, 119, 139, 159]
        block_starts = [1, block_ends(1:end-1) + 1]; % [1,  21, 41, 61, 81, 101, 120, 140]
    
        % Assign block number to each trial
        block_num = zeros(1, sum(block_sizes));
        for b = 1:length(block_sizes)
            block_num(block_starts(b):block_ends(b)) = b;
        end
        data.blocks = block_num.';
    end

    % CORRECT MU FOR CONGRUENCE
    % futuretodo: no preprocessing at this stage. We should have one
    % preprocessing file that is used consistently.
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

        mix = data.flipped_mu(and(data.blocks == uni_mix(b),data.condition == 1));
        perc = data.flipped_mu(and(data.blocks == uni_perc(b),data.condition == 2));

        if length(mix) < 20 
            mix = [mix; NaN];
        elseif length(perc) < 20
            perc = [perc; NaN];
        end
        mix_subj(b,:) = mix;
        perc_subj(b,:) = perc;
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

