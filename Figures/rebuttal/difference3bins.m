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
    pupil_signal(preds.pe == 0,:) = [];
    preds(preds.pe == 0,:) = [];

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

% for p = 1:num_pairs
%     c1 = cd_pairs(p,1);
%     c2 = cd_pairs(p,2);
% 
%     between_perm = get_permtest(1, num_subs, col, diff_signals{c2}, diff_signals{c1}, 1, 0);
%     mask = logical(between_perm.mask);
% 
%     if any(mask)
%         % Offset each pair's bar so they don't overlap
%         bar_y   = y_top - (p * y_step);
%         bar_col = mean([cd_colors(c1,:); cd_colors(c2,:)]);   % blend the two CD bin colours
%         plot(time_axis(mask), repmat(bar_y, 1, sum(mask)), '.', ...
%             'Color', bar_col, 'MarkerSize', 5, 'HandleVisibility', 'off');
% 
%         % Small label at the left edge of the bar indicating which pair
%         text(time_axis(find(mask,1,'first')), bar_y, ...
%             sprintf('CD%d vs CD%d', c1, c2), ...
%             'FontSize', 7, 'Color', bar_col, 'VerticalAlignment', 'bottom');
%     end
% end

xlabel('Time since feedback onset');
ylabel('Pupil signal difference (high PE - low PE)');
legend('Location', 'best', 'FontSize', 9);
xlim([time_axis(1) time_axis(end)]);
title('PE effect (high PE - low PE) per contrast difference bin', 'FontWeight', 'normal');
set(gca, 'FontSize', 10, 'Box', 'off');

%%

diff_win1 = diff_signals{1,1}(:,151:200);
diff_win2 = diff_signals{2,1}(:,151:200);
diff_win3 = diff_signals{3,1}(:,151:200);

diff_cd2_mean = mean(diff_win2,2);
diff_cd1_mean = mean(diff_win1,2);
diff_cd3_mean = mean(diff_win3,2);

[h,p_mean] = ttest(diff_cd3_mean,diff_cd1_mean);

diff_cd2_max = max(diff_win2,[],2);
diff_cd1_max = max(diff_win1,[],2);
diff_cd3_max = max(diff_win3,[],2);

[h,p_max] = ttest(diff_cd3_max,diff_cd1_max);

% Data Preparation (Assuming you have these from your snippet)
% data1 = diff_cd1_mean; data2 = diff_cd2_mean;
% data1_max = diff_cd1_max; data2_max = diff_cd2_max;

figure('Color', 'w', 'Position', [100 100 1000 500]);

% --- Plot 1: Mean Differences ---
subplot(1,2,1); hold on;
plot_bar_with_dots(diff_cd1_mean, diff_cd3_mean, 'Mean Pupil Difference (time window = 1 to 2 ms)', p_mean);

% --- Plot 2: Max Differences ---
subplot(1,2,2); hold on;
plot_bar_with_dots(diff_cd1_max, diff_cd3_max, 'Max Pupil Difference (time window = 1 to 2 ms)', p_max);


% Helper Function for the plotting
function plot_bar_with_dots(d1, d2, title_str, p_val)
    data = [d1, d2];
    means = mean(data);
    sems = std(data) ./ sqrt(length(data));
    
    % Plot Bars
    b = bar(means, 'FaceColor', 'flat', 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    b.CData(1,:) = [0.2 0.6 0.8]; % Blueish
    b.CData(2,:) = [0.9 0.5 0.2]; % Orangish
    
    % Plot SEM Error Bars
    errorbar(1:2, means, sems, 'k', 'linestyle', 'none', 'LineWidth', 1.5);
    
    % Plot Individual Subject Dots (with jitter)
    rng(1); % for consistent jitter
    jitter = (rand(size(data)) - 0.5) * 0.1;
    scatter(ones(size(d1)) + jitter(:,1), d1, 30, 'k', 'filled', 'MarkerFaceAlpha', 0.3);
    scatter(2*ones(size(d2)) + jitter(:,2), d2, 30, 'k', 'filled', 'MarkerFaceAlpha', 0.3);
    
    % Connect paired subjects (Optional but recommended for paired t-tests)
    % for i = 1:length(d1)
    %     plot([1+jitter(i,1), 2+jitter(i,2)], [d1(i), d2(i)], 'Color', [0.5 0.5 0.5 0.2]);
    % end
    
    % Formatting
    ylabel('Pupil Signal Difference (PE High - Low)');
    xlabel('Contrast difference')
    set(gca, 'XTick', 1:2, 'XTickLabel', {'0.00-0.05', '0.05-0.10'}, 'Box', 'off');
    title(title_str);
    
    % Add P-value text
    yl = ylim;
    text(1.5, yl(2)*0.9, sprintf('p = %.4f', p_val), 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
end

%%

% --- Data Extraction ---
% Windowing the signals (assuming 50ms window from indices 151 to 200)
diff_win1 = diff_signals{1,1}(:,151:200);
diff_win2 = diff_signals{2,1}(:,151:200);
diff_win3 = diff_signals{3,1}(:,151:200);

% Calculate Subject Means
diff_cd1_mean = mean(diff_win1, 2);
diff_cd2_mean = mean(diff_win2, 2);
diff_cd3_mean = mean(diff_win3, 2);

% Calculate Subject Maxima
diff_cd1_max = max(diff_win1, [], 2);
diff_cd2_max = max(diff_win2, [], 2);
diff_cd3_max = max(diff_win3, [], 2);

% --- Statistical Analysis (One-way ANOVA) ---
% We group the data into matrices where each column is a condition
[p_mean, ~, ~] = anova1([diff_cd1_mean, diff_cd2_mean, diff_cd3_mean], [], 'off');
[p_max, ~, ~]  = anova1([diff_cd1_max, diff_cd2_max, diff_cd3_max], [], 'off');

% --- Plotting ---
figure('Color', 'w', 'Position', [100 100 1200 500]);

% Plot 1: Mean Differences
subplot(1,2,1); hold on;
data_mean = {diff_cd1_mean, diff_cd2_mean, diff_cd3_mean};
plot_bar_with_dots_anova(data_mean, 'Mean Pupil Difference (150-200ms)', p_mean);

% Plot 2: Max Differences
subplot(1,2,2); hold on;
data_max = {diff_cd1_max, diff_cd2_max, diff_cd3_max};
plot_bar_with_dots_anova(data_max, 'Max Pupil Difference (150-200ms)', p_max);

% --- Refactored Helper Function ---
function plot_bar_with_dots_anova(data_cell, title_str, p_val)
    % data_cell: {condition1, condition2, condition3}
    num_groups = length(data_cell);
    means = cellfun(@mean, data_cell);
    sems  = cellfun(@(x) std(x)/sqrt(length(x)), data_cell);
    
    % Colors for 3 conditions
    colors = [0.2 0.6 0.8;  % Blueish
              0.9 0.5 0.2;  % Orangish
              0.4 0.7 0.4]; % Greenish
    
    % Plot Bars
    for i = 1:num_groups
        bar(i, means(i), 'FaceColor', colors(i,:), 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    end
    
    % Plot SEM Error Bars
    errorbar(1:num_groups, means, sems, 'k', 'linestyle', 'none', 'LineWidth', 1.5);
    
    % Plot Individual Subject Dots (with jitter)
    rng(1); 
    for i = 1:num_groups
        curr_data = data_cell{i};
        jitter = (rand(size(curr_data)) - 0.5) * 0.15;
        scatter(ones(size(curr_data))*i + jitter, curr_data, 30, 'k', 'filled', 'MarkerFaceAlpha', 0.3);
    end
    
    % Formatting
    ylabel('Pupil Signal Difference (PE High - Low)');
    xlabel('Contrast Difference');
    xticks(1:num_groups);
    xticklabels({'0.00-0.033', '0.033-0.066', '0.066-0.1'});
    set(gca, 'Box', 'off', 'TickDir', 'out');
    title(title_str);
    
    % Add ANOVA P-value text
    yl = ylim;
    text(num_groups/2 + 0.5, yl(2)*0.95, sprintf('ANOVA p = %.4f', p_val), ...
        'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
end

%%

% --- Data Extraction ---
diff_win1 = diff_signals{1,1}(:,101:200);
diff_win2 = diff_signals{2,1}(:,101:200);
diff_win3 = diff_signals{3,1}(:,101:200);

% Subject Means
diff_cd1_mean = mean(diff_win1, 2);
diff_cd2_mean = mean(diff_win2, 2);
diff_cd3_mean = mean(diff_win3, 2);

% Subject Maxima
diff_cd1_max = max(diff_win1, [], 2);
diff_cd2_max = max(diff_win2, [], 2);
diff_cd3_max = max(diff_win3, [], 2);

% --- Statistical Analysis ---
% 1. One-way ANOVA
[p_anova_mean, ~, ~] = anova1([diff_cd1_mean, diff_cd2_mean, diff_cd3_mean], [], 'off');
[p_anova_max, ~, ~]  = anova1([diff_cd1_max, diff_cd2_max, diff_cd3_max], [], 'off');

% 2. Pairwise Paired T-Tests (Mean)
[~, p12_m] = ttest(diff_cd1_mean, diff_cd2_mean);
[~, p23_m] = ttest(diff_cd2_mean, diff_cd3_mean);
[~, p13_m] = ttest(diff_cd1_mean, diff_cd3_mean);

% 3. Pairwise Paired T-Tests (Max)
[~, p12_x] = ttest(diff_cd1_max, diff_cd2_max);
[~, p23_x] = ttest(diff_cd2_max, diff_cd3_max);
[~, p13_x] = ttest(diff_cd1_max, diff_cd3_max);

% --- Plotting ---
figure('Color', 'w', 'Position', [100 100 1300 600]);

% Plot 1: Mean Differences
subplot(1,2,1); hold on;
data_mean = {diff_cd1_mean, diff_cd2_mean, diff_cd3_mean};
p_pairs_mean = [p12_m, p23_m, p13_m];
plot_neuro_stats(data_mean, 'Mean Pupil Difference', p_anova_mean, p_pairs_mean);

% Plot 2: Max Differences
subplot(1,2,2); hold on;
data_max = {diff_cd1_max, diff_cd2_max, diff_cd3_max};
p_pairs_max = [p12_x, p23_x, p13_x];
plot_neuro_stats(data_max, 'Max Pupil Difference', p_anova_max, p_pairs_max);

% --- Helper Function ---
function plot_neuro_stats(data_cell, title_str, p_anova, p_pairs)
    num_groups = length(data_cell);
    means = cellfun(@mean, data_cell);
    sems  = cellfun(@(x) std(x)/sqrt(length(x)), data_cell);
    
    colors = [0.2 0.6 0.8; 0.9 0.5 0.2; 0.4 0.7 0.4];
    
    % Plot Bars & SEM
    for i = 1:num_groups
        bar(i, means(i), 'FaceColor', colors(i,:), 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    end
    errorbar(1:num_groups, means, sems, 'k', 'linestyle', 'none', 'LineWidth', 1.5);
    
    % Individual Jitter Dots
    rng(1); 
    for i = 1:num_groups
        curr_data = data_cell{i};
        jitter = (rand(size(curr_data)) - 0.5) * 0.15;
        scatter(ones(size(curr_data))*i + jitter, curr_data, 25, 'k', 'filled', 'MarkerFaceAlpha', 0.2);
    end
    
    % Annotate ANOVA
    yl = ylim;
    y_top = yl(2) + (yl(2)-yl(1))*0.2; % Space for brackets
    text(2, y_top, sprintf('ANOVA p = %.4f', p_anova), 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    
% Significance Brackets (1-2, 2-3, 1-3)
    comparisons = [1, 2, p_pairs(1), 1; 
                   2, 3, p_pairs(2), 1; 
                   1, 3, p_pairs(3), 2.5];
               
    for i = 1:size(comparisons, 1)
        g1 = comparisons(i,1); g2 = comparisons(i,2); p = comparisons(i,3);
        
        % Calculate vertical position
        offset = comparisons(i,4) * (yl(2)-yl(1)) * 0.2;
        y_bracket = max(means([g1, g2])) + offset + 50;
        
        % Draw bracket
        line([g1, g1, g2, g2], [y_bracket, y_bracket+10, y_bracket+10, y_bracket], 'Color', 'k');
        
        % --- ADDED: Display p-value directly ---
        if p < 0.001
            txt = 'p < .001';
        else
            txt = sprintf('p = %.3f', p);
        end
        
        % Add text with a slight bold for significant values (p < .05)
        fw = 'normal'; if p < 0.05, fw = 'bold'; end
        text(mean([g1, g2]), y_bracket + 0.04, txt, ...
            'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', fw);
    end    
    % Formatting
    ylabel('Pupil Signal Difference');
    xticks(1:3); xticklabels({'0.00-0.033', '0.033-0.066', '0.066-0.1'});
    set(gca, 'Box', 'off', 'TickDir', 'out');
    title(title_str);
    ylim([yl(1), y_top + (yl(2)-yl(1))*0.1]); % Adjust limit for text
end