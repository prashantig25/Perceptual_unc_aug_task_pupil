clc
clearvars

% INITIALISE VARS
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
timewindow = 'feedback';
col = 300;
num_subs = length(subj_ids);

% -------------------------------------------------------------------------
% ADJUSTABLE BIN NUMBERS
% -------------------------------------------------------------------------
num_pe_bins = 2;      % Number of PE bins
num_cd_bins = 2;      % Number of condiff bins

pe_binedges   = [0, 0.5, 1];        % Define PE bin edges (must have num_pe_bins + 1 values)
cd_binedges   = [0, 0.05, 0.1];                    % Define condiff bin edges (must have num_cd_bins + 1 values)

% -------------------------------------------------------------------------
% Storage: [num_cd_bins x num_pe_bins] structure
% First dimension: condiff bins | Second dimension: PE bins
% -------------------------------------------------------------------------
subj_pupil = struct();
for c = 1:num_cd_bins
    for pe = 1:num_pe_bins
        subj_pupil(c,pe).signal = NaN(num_subs, col);
    end
end

% USER-BASED PATH
currentDir = cd;
reqPath = 'Perceptual_unc_aug_task_pupil';
pathParts = strsplit(currentDir, filesep);
if startsWith(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    desiredPath = createSavePaths(currentDir, reqPath);
end

save_dir  = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'pupil', filesep, 'descriptive');
pupil_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb Mathot 2023 linearInt');
behv_dir  = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'behavior', filesep, 'raw data');
preds_all = readtable(strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'behavior', filesep, 'LR analyses', filesep, 'preprocessed_lr_pupil.xlsx'));
mkdir(save_dir);

meanPE_all      = NaN(num_subs, num_pe_bins);
meanCondiff_all = NaN(num_subs, num_cd_bins);

% -------------------------------------------------------------------------
for i = 1:num_subs

    % todo: should be based on descriptive object    

    % GET BEHAVIORAL DATA
    behv_data = [];
    for j = 1:num_sess(i)
        filename = strcat(behv_dir, filesep, subj_ids{i}, '_', 'main', num2str(j), '.xlsx');
        if strcmp(subj_ids{i}, '4672')
            filename = strcat(behv_dir, filesep, subj_ids{i}, '_', 'main', num2str(j), '_red.xlsx');
        end
        data_run = readtable(filename, 'VariableNamingRule', 'preserve');
        rt     = table(data_run.("choice.rt"),              'VariableNames', {'rt'});
        slider = table(data_run.("slider_respond.response"),'VariableNames', {'slider'});
        data_run = [data_run(:,1:16), rt, slider];
        behv_data = [behv_data; data_run];
    end

    % REMOVE MISSED TRIALS
    missed_trials = [];
    for b = 1:height(behv_data)
        if isnan(behv_data.rt(b,:))
            missed_trials = [missed_trials; b];
        end
    end
    behv_data(missed_trials,:) = [];
    missedSlider = isnan(behv_data.slider);

    % GET PREDICTOR DATA FOR THIS SUBJECT
    preds = preds_all(preds_all.id == str2num(subj_ids{i}), :);

    % GET PUPIL DATA
    filename     = strcat(pupil_dir, filesep, subj_ids{i}, '.mat');
    pupil        = importdata(filename);
    pupil_signal = pupil(:, 1:col);
    pupil_signal(missedSlider == 1, :) = [];

    % BIN PE AND CONDIFF
    preds.pe_bins = discretize(abs(preds.pe), pe_binedges);
    preds.cd_bins = discretize(abs(preds.con_diff), cd_binedges);
    pupil_signal(preds.pe == 0,:) = [];
    preds(preds.pe == 0,:) = [];
    
    % Mean PE per bin
    for pe = 1:num_pe_bins
        idx = preds.pe_bins == pe;
        if any(idx)
            meanPE_all(i, pe) = mean(abs(preds.pe(idx)), 'omitnan');
        end
    end
    
    % Mean condiff per bin
    for cd = 1:num_cd_bins
        idx = preds.cd_bins == cd;
        if any(idx)
            meanCondiff_all(i, cd) = mean(abs(preds.con_diff(idx)), 'omitnan');
        end
    end

    % AVERAGE PUPIL SIGNAL PER CONDIFF BIN x PE BIN
    % First loop over condiff bins, then within each condiff bin, loop over PE bins
    for cd = 1:num_cd_bins
        for pe = 1:num_pe_bins
            idx = (preds.pe_bins == pe) & (preds.cd_bins == cd);
            if any(idx)
                subj_pupil(cd,pe).signal(i,:) = nanmean(pupil_signal(idx,:), 1);
            end
        end
    end
end

% SAVE
safe_saveall(fullfile(save_dir, 'meanPE_all.mat'),      meanPE_all);
safe_saveall(fullfile(save_dir, 'meanCondiff_all.mat'), meanCondiff_all);

% -------------------------------------------------------------------------
% PERMUTATION TESTS: for each PE bin, compare condiff bin 1 vs bin 2
% -------------------------------------------------------------------------
num_vars  = 1;
two_tailed = 1;
betas     = 0;

% PERMUTATION TESTS: For each Contrast bin, compare PE bin 1 vs PE bin 2
perm_results = struct();
for cd = 1:num_cd_bins
    var1 = subj_pupil(cd,1).signal;  % PE bin 1 (Blue)
    var2 = subj_pupil(cd,2).signal;  % PE bin 2 (Orange)

    var1 = reshape(var1, [1, num_subs, col]);
    var2 = reshape(var2, [1, num_subs, col]);

    perm_results(cd).perm = get_permtest_updated(num_vars, num_subs, col, var1, var2);
end
% -------------------------------------------------------------------------
% SAVE
% -------------------------------------------------------------------------
output = struct();
output.num_pe_bins = num_pe_bins;
output.num_cd_bins = num_cd_bins;
output.pe_binedges = pe_binedges;
output.cd_binedges = cd_binedges;
output.subj_pupil  = subj_pupil;
output.perm        = perm_results;
safe_saveall(strcat(save_dir, filesep, 'fb_PE', num2str(num_pe_bins), 'bins_condiff', num2str(num_cd_bins), 'bins_linearInt.mat'), output);
