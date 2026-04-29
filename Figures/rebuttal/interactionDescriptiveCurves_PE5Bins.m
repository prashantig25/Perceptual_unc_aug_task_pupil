% get_pupilPEbins_condiff computes pupil response for 3 PE bins,
% each split into 2 con_diff bins.

clc
clearvars

% INITIALISE VARS
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
timewindow = 'feedback';
col = 300;
num_subs = length(subj_ids);

% Storage: [num_subs x col] for each PE bin x condiff bin combination
% PE bins: 1=low, 2=med, 3=high | condiff bins: 1=low, 2=high
subj_pupil = struct();
for pe = 1:3
    for c = 1:2
        subj_pupil(pe,c).signal = NaN(num_subs, col);
    end
end

pe_binedges   = [0, 0.2,0.4,0.6,0.8, 1];   % 3 PE bins
cd_binedges   = [0, 0.05, 0.1];        % 2 condiff bins

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

% -------------------------------------------------------------------------
for i = 1:num_subs

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
    preds.pe_bins = discretize(abs(preds.pe),      pe_binedges);
    preds.cd_bins = discretize(abs(preds.con_diff), cd_binedges);

    % AVERAGE PUPIL SIGNAL PER PE BIN x CONDIFF BIN
    for pe = 1:5
        for cd = 1:2
            idx = (preds.pe_bins == pe) & (preds.cd_bins == cd);
            if any(idx)
                subj_pupil(pe,cd).signal(i,:) = nanmean(pupil_signal(idx,:), 1);
            end
        end
    end
end

% -------------------------------------------------------------------------
% PERMUTATION TESTS: for each PE bin, compare condiff bin 1 vs bin 2
% -------------------------------------------------------------------------
num_vars  = 1;
two_tailed = 1;
betas     = 0;

perm_results = struct();
for pe = 1:5
    var1 = subj_pupil(pe,1).signal;
    var2 = subj_pupil(pe,2).signal;
    perm_results(pe).perm = get_permtest(num_vars, num_subs, col, var1, var2, two_tailed, betas);
end

% -------------------------------------------------------------------------
% SAVE
% -------------------------------------------------------------------------
output = struct();
output.pe_binedges = pe_binedges;
output.cd_binedges = cd_binedges;
output.subj_pupil  = subj_pupil;
output.perm        = perm_results;
safe_saveall(strcat(save_dir, filesep, 'fb_PE5bins_condiff2bins_linearInt.mat'), output);

%% -------------------------------------------------------------------------
% PLOT
% -------------------------------------------------------------------------
time_axis  = linspace(0, col-1, col); % x-axis in samples; adjust to ms if needed
pe_labels  = {'PE 0 - 0.2', 'PE 0.2 - 0.4', 'PE 0.4 - 0.6', 'PE 0.6 - 0.8', 'PE 0.8 - 1'};
cd_colors  = {[0.2 0.5 0.8], [0.9 0.3 0.2]};   % blue = low condiff, red = high condiff
cd_labels  = {'Contrast difference 0 - 0.05', 'Contrast difference 0.05 - 0.1'};
alpha_fill = 0.15;

figure('Units','normalized','Position',[0.05 0.2 0.9 0.55]);

for pe = 1:5

    ax = subplot(1, 5, pe);
    hold on;

    for cd = 1:2
        sig   = subj_pupil(pe,cd).signal;               % [num_subs x col]
        mn    = nanmean(sig, 1);
        sem   = nanstd(sig, 0, 1) ./ sqrt(sum(~isnan(sig(:,1))));

        % Shaded SEM
        fill([time_axis, fliplr(time_axis)], ...
             [mn + sem, fliplr(mn - sem)], ...
             cd_colors{cd}, 'FaceAlpha', alpha_fill, 'EdgeColor', 'none');

        % Mean line
        plot(time_axis, mn, '-', 'Color', cd_colors{cd}, ...
             'LineWidth', 2, 'DisplayName', cd_labels{cd});
    end

    % ADD PERMUTATION MASK AS SIGNIFICANCE BAR
    % mask = perm_results(pe).perm.mask;       % logical vector [1 x col]
    % if any(mask)
    %     % Draw a horizontal bar at a fixed y position where sig. clusters occur
    %     yl     = ylim;
    %     bar_y  = yl(1) + 0.03 * diff(yl);   % slightly above x-axis
    %     sig_x  = time_axis(logical(mask));
    %     scatter(sig_x, repmat(bar_y, size(sig_x)), 6, ...
    %             [0.15 0.15 0.15], 'filled', 'HandleVisibility', 'off');
    % end

    % FORMATTING
    xlabel('Time');
    ylabel('Pupil signal');
    title(pe_labels{pe},'FontWeight','normal');
    xlim([time_axis(1) time_axis(end)]);
    xline(0, '--k', 'LineWidth', 1, 'HandleVisibility', 'off');
    yline(0, ':k', 'LineWidth', 0.8, 'HandleVisibility', 'off');
    if pe == 1
        legend('Location','northwest','FontSize',8);
    end
    set(ax, 'FontSize', 10, 'Box', 'off');
    hold off;
end

% sgtitle('Pupil response by PE bin and contrast difference', 'FontSize', 13, 'FontWeight', 'nor');

% Save figure
% saveas(gcf, strcat(save_dir, filesep, 'fb_PE3bins_condiff2bins_linearInt.png'));
% saveas(gcf, strcat(save_dir, filesep, 'fb_PE3bins_condiff2bins_linearInt.svg'));