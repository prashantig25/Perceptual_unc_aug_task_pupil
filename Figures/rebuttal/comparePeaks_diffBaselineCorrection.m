clc
clearvars

% INITIALIZE VARS
subj_ids = importdata("subj_ids.mat");
num_subjs = length(subj_ids);
num_break = 30;
col_patch = 100;
col_fb = 300;
total = 630;
trial_all = NaN(num_subjs, total);
currentDir = cd;
reqPath = 'Perceptual_unc_aug_task_pupil';
pathParts = strsplit(currentDir, filesep);
if startsWith(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    desiredPath = createSavePaths(currentDir, reqPath);
end

x = 300;
preTrial_pupil_subj_all = NaN(num_subjs, x);
preEvent_pupil_subj_all = NaN(num_subjs, x);

preEvent = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb full trial linear int');
preTrial = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb Mathot 2023 linearInt');

% LOOP OVER SUBJECTS
for i = 1:num_subjs
    filename = strcat(preEvent, filesep, subj_ids{i}, '.mat');
    preEvent_pupil = importdata(filename);
    preEvent_pupil_subj_all(i,:) = mean(preEvent_pupil(:,1:x), 1);

    filename = strcat(preTrial, filesep, subj_ids{i}, '.mat');
    preTrial_pupil = importdata(filename);
    preTrial_pupil_subj_all(i,:) = mean(preTrial_pupil(:,1:x), 1);
end

% LOAD PE BIN DATA
condiffbin = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", ...
    filesep, "pupil", filesep, "descriptive", filesep, "fb_PE2bins_linearInt.mat"));
pe_bin1 = condiffbin.pebin1;  % expected: num_subjs x x
pe_bin2 = condiffbin.pebin2;

% COMPUTE MEANS AND SEM FOR ALL 3 CONDITIONS
t = 1:x;

preEvent_mean = mean(preEvent_pupil_subj_all, 1);
preEvent_sem  = std(preEvent_pupil_subj_all, 0, 1) / sqrt(num_subjs);

preTrial_mean = mean(preTrial_pupil_subj_all, 1);
preTrial_sem  = std(preTrial_pupil_subj_all, 0, 1) / sqrt(num_subjs);

pebin1_mean = mean(pe_bin1(:,1:x), 1);
pebin1_sem  = std(pe_bin1(:,1:x), 0, 1) / sqrt(num_subjs);

pebin2_mean = mean(pe_bin2(:,1:x), 1);
pebin2_sem  = std(pe_bin2(:,1:x), 0, 1) / sqrt(num_subjs);

% DEFINE COLORS
c_preEvent = [0.31 0.58 0.80];   % blue
c_preTrial = [0.90 0.45 0.18];   % orange
c_bin1     = [0.20 0.63 0.37];   % green  (low PE)
c_bin2     = [0.72 0.23 0.60];   % purple (high PE)

alpha_shade = 0.20;

% HELPER FUNCTION: shaded band
shade = @(t, mn, se, col) fill([t, fliplr(t)], ...
    [mn + se, fliplr(mn - se)], col, ...
    'FaceAlpha', alpha_shade, 'EdgeColor', 'none');

% PLOT
figure; hold on;

% --- Shaded SEM bands (drawn first, behind lines) ---
shade(t, preEvent_mean, preEvent_sem, c_preEvent);
shade(t, preTrial_mean, preTrial_sem, c_preTrial);
shade(t, pebin1_mean,   pebin1_sem,   c_bin1);
shade(t, pebin2_mean,   pebin2_sem,   c_bin2);

% --- Mean lines ---
p1 = plot(t, preEvent_mean, 'Color', c_preEvent, 'LineWidth', 2);
p2 = plot(t, preTrial_mean, 'Color', c_preTrial, 'LineWidth', 2);
p3 = plot(t, pebin1_mean,   'Color', c_bin1,     'LineWidth', 2);
p4 = plot(t, pebin2_mean,   'Color', c_bin2,     'LineWidth', 2);

% --- Labels ---
xlabel('Time (ms)');
ylabel('Pupil size (a.u.)');
legend([p1 p2 p3 p4], ...
    {'Pre-event baseline', 'Pre-trial baseline', 'Low PE bin', 'High PE bin'}, ...
    'Location', 'best');
title('Pupil dilation by baseline correction and PE bin');
box off;
hold off;