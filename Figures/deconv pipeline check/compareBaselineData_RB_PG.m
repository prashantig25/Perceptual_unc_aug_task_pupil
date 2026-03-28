clc
clearvars

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

PG_nonBasefbDir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'alternate pipeline', filesep, 'pupil signal', filesep, 'non-baseline corrected fb seed fixed - PG baseline curves');
PG_fbDir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'alternate pipeline', filesep, 'pupil signal', filesep, 'fb saccade correction and urai params PG');
RB_fbDir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'alternate pipeline', filesep, 'pupil signal', filesep, 'fb saccade correction and urai params RB');
RB_nonBasefbDir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'alternate pipeline', filesep, 'pupil signal', filesep, 'non-baseline corrected fb seed fixed - RB baseline curves');

% Load subject information
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
num_subs = length(subj_ids);

col = 1000;

for i = 1:num_subs

    % GET PUPIL DATA - PG BASELINE
    filename = strcat(PG_fbDir,filesep,subj_ids{i},'.mat');
    pupil = importdata(filename);
    pupil_PG = pupil(:,1:col);

    % GET PUPIL DATA - RB BASELINE
    filename = strcat(RB_fbDir,filesep,subj_ids{i},'.mat');
    pupil = importdata(filename);
    pupil_RB = pupil(:,1:col);

    fig = figure("Visible","off","Position",[100,100,600,300]);
    subplot(1,2,1)
    hold on
    plot(1:col,abs(pupil_PG - pupil_RB),'LineWidth',0.3,'Color',[0.5,0.5,0.5])
    title(num2str(subj_ids{i}))
    xlabel('Time')
    ylabel('Abs diff PG - RB baseline data (optimizer fixed + saccade changed)')


    subplot(1,2,2)
    hold on
    r = plot(1:col,pupil_RB,'LineWidth',0.3,'Color','b');
    hold on
    p = plot(1:col,pupil_PG,'LineWidth',0.3,'Color','r');
    xlabel('Time')
    ylabel('Feedback signal')
    set(findall(gcf, '-property', 'FontSize'), 'FontSize', 9)

    legend([r(1),p(1)],'RB baseline','PG baseline')

    print(fig, strcat(num2str(subj_ids{i}), '_baseline_comparison'), '-dpng', '-r300')
end

