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
num_cd_bins = 3;      % Number of condiff bins

pe_binedges = [0, 0.5, 1];               % num_pe_bins + 1 values
cd_binedges = [0, 0.033, 0.066, 0.1];   % num_cd_bins + 1 values

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
        rt     = table(data_run.("choice.rt"),               'VariableNames', {'rt'});
        slider = table(data_run.("slider_respond.response"), 'VariableNames', {'slider'});
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
    preds.pe_bins = discretize(abs(preds.pe),       pe_binedges);
    preds.cd_bins = discretize(abs(preds.con_diff),  cd_binedges);

    % AVERAGE PUPIL SIGNAL PER CONDIFF BIN x PE BIN
    for cd = 1:num_cd_bins
        for pe = 1:num_pe_bins
            idx = (preds.pe_bins == pe) & (preds.cd_bins == cd);
            if any(idx)
                subj_pupil(cd,pe).signal(i,:) = nanmean(pupil_signal(idx,:), 1);
            end
        end
    end
end

% -------------------------------------------------------------------------
% PERMUTATION TESTS: for each PE bin, compare all pairs of condiff bins
% -------------------------------------------------------------------------
num_vars   = 1;
two_tailed = 1;
betas      = 0;

% Generate all unique pairs of CD bins
cd_pairs = nchoosek(1:num_cd_bins, 2);   % [num_pairs x 2]
num_pairs = size(cd_pairs, 1);

perm_results = struct();
for pe = 1:num_pe_bins
    for p = 1:num_pairs
        c1 = cd_pairs(p,1);
        c2 = cd_pairs(p,2);
        var1 = subj_pupil(c1, pe).signal;
        var2 = subj_pupil(c2, pe).signal;
        perm_results(pe, p).perm   = get_permtest(num_vars, num_subs, col, var1, var2, two_tailed, betas);
        perm_results(pe, p).cd_pair = [c1, c2];
    end
end

% -------------------------------------------------------------------------
% SAVE
% -------------------------------------------------------------------------
output = struct();
output.num_pe_bins  = num_pe_bins;
output.num_cd_bins  = num_cd_bins;
output.pe_binedges  = pe_binedges;
output.cd_binedges  = cd_binedges;
output.subj_pupil   = subj_pupil;
output.perm         = perm_results;
output.cd_pairs     = cd_pairs;
safe_saveall(strcat(save_dir, filesep, 'fb_PE', num2str(num_pe_bins), 'bins_condiff', num2str(num_cd_bins), 'bins_linearInt.mat'), output);

% -------------------------------------------------------------------------
% PLOT 1: PE curves nested within condiff bins (one subplot per CD bin)
% -------------------------------------------------------------------------
time_axis = linspace(0, col-1, col);

pe_labels = cell(num_pe_bins, 1);
for i = 1:num_pe_bins
    pe_labels{i} = sprintf('Absolute PE: %.2f-%.2f', pe_binedges(i), pe_binedges(i+1));
end

cd_labels = cell(num_cd_bins, 1);
for i = 1:num_cd_bins
    cd_labels{i} = sprintf('Contrast difference: %.2f-%.2f', cd_binedges(i), cd_binedges(i+1));
end

pe_colors  = lines(num_pe_bins);
alpha_fill = 0.15;

figure('Units', 'normalized', 'Position', [0.05 0.3 0.9 0.4]);

for cd = 1:num_cd_bins
    ax = subplot(1, num_cd_bins, cd);
    hold on;

    for pe = 1:num_pe_bins
        sig = subj_pupil(cd,pe).signal;
        mn  = nanmean(sig, 1);
        sem = nanstd(sig, 0, 1) ./ sqrt(sum(~isnan(sig(:,1))));

        fill([time_axis, fliplr(time_axis)], ...
             [mn + sem, fliplr(mn - sem)], ...
             pe_colors(pe,:), 'FaceAlpha', alpha_fill, 'EdgeColor', 'none', ...
             'HandleVisibility', 'off');

        plot(time_axis, mn, '-', 'Color', pe_colors(pe,:), ...
            'LineWidth', 2, 'DisplayName', pe_labels{pe});
    end

    xlabel('Time since feedback onset');
    ylabel('Pupil signal');
    title(cd_labels{cd}, 'FontWeight', 'normal');
    xlim([time_axis(1) time_axis(end)]);
    xline(0, '--k', 'Alpha', 0.5, 'HandleVisibility', 'off');
    yline(0, ':k',  'Alpha', 0.5, 'HandleVisibility', 'off');

    if cd == num_cd_bins
        legend('Location', 'best', 'FontSize', 8);
    end

    set(ax, 'FontSize', 10, 'Box', 'off');
end

sgtitle('Pupil Response: PE Bins nested within Contrast Difference Bins', ...
    'FontSize', 14, 'FontWeight', 'normal');

% -------------------------------------------------------------------------
% PLOT 2: Difference curves (high PE - low PE) per CD bin
%         + pairwise significance bars between all CD bin pairs
% -------------------------------------------------------------------------
cd_colors  = lines(num_cd_bins);
alpha_fill = 0.15;

figure('Units', 'normalized', 'Position', [0.15 0.3 0.55 0.4]);
hold on;

% Compute and store subject-wise PE difference for each CD bin
diff_signals = cell(num_cd_bins, 1);
for cd = 1:num_cd_bins
    diff_signals{cd} = subj_pupil(cd, 2).signal - subj_pupil(cd, 1).signal;  % [num_subs x col]

    mn  = nanmean(diff_signals{cd}, 1);
    sem = nanstd(diff_signals{cd}, 0, 1) ./ sqrt(sum(~isnan(diff_signals{cd}(:,1))));

    fill([time_axis, fliplr(time_axis)], ...
         [mn + sem, fliplr(mn - sem)], ...
         cd_colors(cd,:), 'FaceAlpha', alpha_fill, 'EdgeColor', 'none', ...
         'HandleVisibility', 'off');

    plot(time_axis, mn, '-', 'Color', cd_colors(cd,:), ...
        'LineWidth', 2, 'DisplayName', cd_labels{cd});
end

% Permutation tests: compare PE-difference curves between all CD bin pairs
% Each pair gets its own significance bar, offset vertically to avoid overlap
yline(0, ':k', 'Alpha', 0.4, 'HandleVisibility', 'off');
xline(0, '--k', 'Alpha', 0.4, 'HandleVisibility', 'off');

yl    = ylim;
y_top = yl(2);
y_step = 0.05 * diff(yl);   % vertical spacing between significance bars

for p = 1:num_pairs
    c1 = cd_pairs(p,1);
    c2 = cd_pairs(p,2);

    between_perm = get_permtest(1, num_subs, col, diff_signals{c2}, diff_signals{c1}, 1, 0);
    mask = logical(between_perm.mask);

    if any(mask)
        % Offset each pair's bar so they don't overlap
        bar_y   = y_top - (p * y_step);
        bar_col = mean([cd_colors(c1,:); cd_colors(c2,:)]);   % blend the two CD bin colours
        plot(time_axis(mask), repmat(bar_y, 1, sum(mask)), '.', ...
            'Color', bar_col, 'MarkerSize', 5, 'HandleVisibility', 'off');

        % Small label at the left edge of the bar indicating which pair
        text(time_axis(find(mask,1,'first')), bar_y, ...
            sprintf('CD%d vs CD%d', c1, c2), ...
            'FontSize', 7, 'Color', bar_col, 'VerticalAlignment', 'bottom');
    end
end

xlabel('Time since feedback onset');
ylabel('Pupil signal difference (high PE - low PE)');
legend('Location', 'best', 'FontSize', 9);
xlim([time_axis(1) time_axis(end)]);
title('PE effect (high PE - low PE) per contrast difference bin', 'FontWeight', 'normal');
set(gca, 'FontSize', 10, 'Box', 'off');