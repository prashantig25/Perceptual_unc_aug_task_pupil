clc
clearvars

% --- 1. INITIALIZE VARIABLES ---
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
xaxis = linspace(-0.3, 9.7, 1000); % Time axis for 1000 samples

% --- 2. PATH SETUP ---
currentDir = cd; 
reqPath = 'Perceptual_unc_aug_task_pupil-main'; 

% Determine paths
pathParts = strsplit(currentDir, filesep);
if strcmp(pathParts{end}, reqPath)
    desiredPath = currentDir;
else
    % Note: Ensure createSavePaths.m is in your MATLAB path
    desiredPath = createSavePaths(currentDir, reqPath);
end

% Directory definitions for both pipelines
main_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'fb Mathot 2023 linearInt');
alt_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'non-baseline corrected fb linearInt');

% --- 3. GENERATE COMPARISON FIGURE ---
% Top panel: Main Pipeline | Bottom panel: Alternate Pipeline
figure("Position", [100, 100, 400, 400])
participants = [1, 26, 31]; % Indices for 0806, 4738, 3337

for i = 1:length(participants)
    subj_idx = participants(i);
    subj_name = subj_ids{subj_idx};
    
    % --- TOP ROW: MAIN PIPELINE ---
    subplot(2, 3, i)
    hold on
    
    filename_main = fullfile(main_dir, [subj_name, '.mat']);
    if exist(filename_main, 'file')
        fb_main = importdata(filename_main);
        % Calculate subject mean
        trial_subj_main = nanmean(fb_main(:, 1:1000), 1);
        
        % Plot individual trials (Grey) and Mean (Dark Blue)
        plot(xaxis, fb_main(:, 1:1000), "Color", [200, 200, 200]./255, 'LineWidth', 0.4, 'HandleVisibility', 'off')
        plot(xaxis, trial_subj_main, "Color", [7, 53, 94]/255, 'LineWidth', 2)
    end
    
    xlim([-0.3, 6]); 
    xline(0, '--', 'Color', [0.3 0.3 0.3], 'LineWidth', 0.5);
    title(strcat("Main pipeline: Subj ", subj_name), 'FontWeight', 'Normal')
    % grid on
    set(gca, 'FontSize', 7)
    if i == 1; ylabel('Pupil dilation'); end

    % --- BOTTOM ROW: ALTERNATE PIPELINE ---
    subplot(2, 3, i + 3)
    hold on
    
    filename_alt = fullfile(alt_dir, [subj_name, '.mat']);
    if exist(filename_alt, 'file')
        fb_alt = importdata(filename_alt);
        % Calculate subject mean
        trial_subj_alt = nanmean(fb_alt(:, 1:1000), 1);
        
        % Plot individual trials (Grey) and Mean (Red)
        plot(xaxis, fb_alt(:, 1:1000), "Color", [200, 200, 200]./255, 'LineWidth', 0.4, 'HandleVisibility', 'off')
        plot(xaxis, trial_subj_alt, "Color", [150, 56, 56]./255, 'LineWidth', 2)
    end
    
    xlim([-0.3, 6]); 
    xline(0, '--', 'Color', [0.3 0.3 0.3], 'LineWidth', 0.5);
    xlabel('Time from feedback onset (s)')
    title(strcat("Alternate pipeline: Subj ", subj_name), 'FontWeight', 'Normal')
    % grid on
    set(gca, 'FontSize', 7)
    if i == 1; ylabel('Pupil signal'); end
end

% --- 4. EXPORT FIGURE ---
fig = gcf;
fig.PaperPositionMode = 'auto';
print(fig, 'fb_comparison_MainVsAlt_linearInt.png', '-dpng', '-r600')

