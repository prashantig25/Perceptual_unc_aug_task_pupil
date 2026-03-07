% fullTrial saves pupil signal from different events for the entire trial.

clc
clearvars

% INITIALIZE VARS
subj_ids = importdata("subj_ids.mat");
num_subjs = length(subj_ids);
num_break = 30; % how long should the pupil signal be broken
col_patch = 100; % how long should the patch-related pupil signal
col_fb = 300; % how long should the patch-related pupil signal
total = 630; % how long should the entire trial be
trial_all = NaN(num_subjs,total);

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

save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'descriptive'); 
fb_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'non-baseline corrected fb linearInt'); % directory to get preprocessed data
patch_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'patch non-baseline corrected linear int'); % directory to get preprocessed data
resp_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'resp non-baseline corrected linear int'); % directory to get preprocessed data
mkdir(save_dir);

% LOOP OVER SUBJECTS
for i = 1:num_subjs

    % IMPORT EVENT-RELATED DATA
    filename = strcat(patch_dir,filesep,subj_ids{i},'.mat');
    pupil = importdata(filename); patch = pupil(:,1:col_patch);

    filename = strcat(resp_dir,filesep,subj_ids{i},'.mat');
    pupil = importdata(filename); resp = pupil;

    filename = strcat(fb_dir,filesep,subj_ids{i},'.mat');
    pupil = importdata(filename); fb = pupil(:,1:col_fb);

    % INITIALIZE ARRAY FOR TIME POINT
    patch_tp = repelem(1,1,size(patch,2));
    resp_tp = [zeros(1,num_break),repelem(2,1,size(resp,2)-num_break)];
    fb_tp = [zeros(1,num_break),repelem(3,1,size(fb,2)-num_break)];

    % CONCATANATE
    trial = [patch,resp,fb];
    trial_subj = nanmean(trial,1);
    trial_all(i,:) = trial_subj;
end

% SAVE
safe_saveall(strcat(save_dir,filesep,"full_trial non-baseline corrected_linearInt.mat"),trial_all);

%% Figure for rebuttal ...

% --- 1. SETUP PATHS & DATA ---
% (Assuming desiredPath is already defined or found via your createSavePaths function)
currentDir = cd; 
reqPath = 'Perceptual_unc_aug_task_pupil-main'; 
desiredPath = currentDir; % Placeholder

% Load Alternate Pipeline Data (Non-baseline corrected)
data_alt = importdata('full_trial non-baseline corrected_linearInt.mat');

% Load Main Pipeline Data (Baseline corrected / Processed)
data_main = importdata('full_trial.mat');

% Parameters
num_subjs = size(data_main, 1);
neutral_blue = [7, 53, 94]/255; % The blue color from your scrip
muted_red = [150, 56, 56]./255;  % Softer red
x_full = 1:630;

% Time point definitions for separators
patch_len = 100;
resp_len = 230; 
fb_len = 300;

% --- 2. CREATE FIGURE ---
figure('Position', [100, 100, 400, 150]);
t = tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing','compact');

% SUBPLOT 1: Alternate Pipeline
nexttile;
hold on;
plot_with_error(data_alt, muted_red, num_subjs, "Alternate pre-processing pipeline 1");
text(-0.16, 1, 'a', 'Units', 'normalized', 'FontSize', 12, 'FontWeight', 'normal');
hold on
text(length(patch_tp), 5000 + 125, '//', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
text(length(patch_tp) + length(resp_tp), 5000 + 125, '//', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
hold on
xlabel("Time since patch onset (ms)", 'FontSize', 7);
ylabel("Pupil signal", 'FontSize', 7);
hold on
text(145,5200,"Response","FontSize",6,"FontName",'Arial',"BackgroundColor",[222, 228, 233]./255)
text(375,5200,"Feedback","FontSize",6,"FontName",'Arial',"BackgroundColor",[222, 228, 233]./255)

% SUBPLOT 2: Main Pipeline
nexttile;
hold on;
plot_with_error(data_main, neutral_blue, num_subjs, "Main pre-processing pipeline");
text(-0.15, 1, 'b', 'Units', 'normalized', 'FontSize', 12, 'FontWeight', 'normal');
hold on
text(length(patch_tp), -50+12, '//', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
text(length(patch_tp) + length(resp_tp), -50+12, '//', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
hold on
xlabel("Time since patch onset (ms)", 'FontSize', 7);
ylabel("Pupil dilation", 'FontSize', 7);
hold on
text(145,0,"Response","FontSize",6,"FontName",'Arial',"BackgroundColor",[222, 228, 233]./255)
text(375,0,"Feedback","FontSize",6,"FontName",'Arial',"BackgroundColor",[222, 228, 233]./255)


fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'descriptivePipelines_linearInt.png', '-dpng', '-r600') 

% --- HELPER FUNCTION FOR SHADED ERROR BARS & FORMATTING ---
function plot_with_error(data, col, n, titleStr)
    x = 1:size(data, 2);
    m = nanmean(data, 1);
    sem = nanstd(data, 0, 1) ./ sqrt(n);
    
    % Plot Shaded Error Bar
    fill([x, fliplr(x)], [m + sem, fliplr(m - sem)], col, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    plot(x, m, 'Color', col, 'LineWidth', 2);
    
    % Formatting
    title(titleStr, 'FontSize', 9, 'FontWeight','normal');
    set(gca, 'FontSize', 7, 'FontName', 'Arial', 'Box', 'off');
    xlim([1, 630]);
    
    % Add Event Separators (Visual // gaps)
    yl = ylim;
    line([100 100], yl, 'Color', [0.9, 0.9, 0.9], 'LineWidth', 3);
    line([330 330], yl, 'Color', [0.9, 0.9, 0.9], 'LineWidth', 3);
    
    % Add Vertical Onset Markers
    line([20 20], yl, 'Color', 'k', 'LineStyle', ':', 'LineWidth', 0.5);
    line([130 130], yl, 'Color', 'k', 'LineStyle', ':', 'LineWidth', 0.5);
    line([360 360], yl, 'Color', 'k', 'LineStyle', ':', 'LineWidth', 0.5);
    
    % Ticks and Labels
    xticks([0, 50, 130, 230, 360, 460, 560]);
    xticklabels({'0','500','0','1000','0','500','1000'});
end
