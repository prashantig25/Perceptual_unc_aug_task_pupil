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
num_cd_bins = 5;      % Number of condiff bins

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

% -------------------------------------------------------------------------
% PERMUTATION TESTS: for each PE bin, compare condiff bin 1 vs bin 2
% -------------------------------------------------------------------------
num_vars  = 1;
two_tailed = 1;
betas     = 0;

perm_results = struct();
for pe = 1:num_pe_bins
    var1 = subj_pupil(1,pe).signal;  % condiff bin 1, PE bin pe
    var2 = subj_pupil(2,pe).signal;  % condiff bin 2, PE bin pe
    perm_results(pe).perm = get_permtest(num_vars, num_subs, col, var1, var2, two_tailed, betas);
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
% -------------------------------------------------------------------------
% UPDATED PLOTTING SECTION
% -------------------------------------------------------------------------

% TIME AXIS
time_axis = linspace(0, col-1, col); 

% DYNAMIC LABELS
pe_labels = cell(num_pe_bins, 1);
for i = 1:num_pe_bins
    pe_labels{i} = sprintf('Absolute PE: %.2f-%.2f', pe_binedges(i), pe_binedges(i+1));
end

cd_labels = cell(num_cd_bins, 1);
for i = 1:num_cd_bins
    cd_labels{i} = sprintf('Contrast difference: %.2f-%.2f', cd_binedges(i), cd_binedges(i+1));
end

% COLORS: Generate a gradient for PE bins (e.g., from light to dark or a colormap)
% Using 'lines' or 'parula' for distinct PE curves
pe_colors = lines(num_pe_bins); 
alpha_fill = 0.15;

% CREATE FIGURE
figure('Units','normalized','Position',[0.05 0.3 0.9 0.4]);

% OUTER LOOP: Create one subplot per Condiff bin
for cd = 1:num_cd_bins
    ax = subplot(1, num_cd_bins, cd); 
    hold on;
    
    % INNER LOOP: Plot each PE bin as a different colored curve
    for pe = 1:num_pe_bins
        sig = subj_pupil(cd,pe).signal;               % [num_subs x col]
        
        % Calculate stats
        mn  = nanmean(sig, 1);
        sem = nanstd(sig, 0, 1) ./ sqrt(sum(~isnan(sig(:,1))));
        
        % 1. Plot Shaded SEM
        fill([time_axis, fliplr(time_axis)], ...
             [mn + sem, fliplr(mn - sem)], ...
             pe_colors(pe,:), 'FaceAlpha', alpha_fill, 'EdgeColor', 'none', ...
             'HandleVisibility', 'off'); % Hide from legend
        
        % 2. Plot Mean line
        plot(time_axis, mn, '-', 'Color', pe_colors(pe,:), ...
            'LineWidth', 2, 'DisplayName', pe_labels{pe});
    end
    
    % 3. SIGNIFICANCE BARS (Optional)
    % Note: Your current perm_results compares Condiff 1 vs 2. 
    % If you want to show where Condiff 1 and 2 differ for a specific PE, 
    % you'd need to decide which subplot to put that bar in.
    % Below is a placeholder if you have within-subplot stats:
    % (Example: plotting the 1v2 permutation result in the first subplot only)
    % if cd == 1
    %     for pe_idx = 1:num_pe_bins
    %         mask = perm_results(pe_idx).perm.mask;
    %         if any(mask)
    %             yl = ylim;
    %             % Offset bars vertically so they don't overlap
    %             bar_y = yl(1) + (0.02 * pe_idx) * diff(yl); 
    %             sig_x = time_axis(logical(mask));
    %             plot(sig_x, repmat(bar_y, size(sig_x)), '.', ...
    %                 'Color', pe_colors(pe_idx,:), 'MarkerSize', 4, 'HandleVisibility', 'off');
    %         end
    %     end
    % end
    
    % FORMATTING
    % grid on;
    xlabel('Time since feedback onset');
    ylabel('Pupil signal');
    title(cd_labels{cd}, 'FontWeight', 'normal');
    xlim([time_axis(1) time_axis(end)]);
    
    % Add vertical/horizontal lines for reference
    xline(0, '--k', 'Alpha', 0.5, 'HandleVisibility', 'off');
    yline(0, ':k', 'Alpha', 0.5, 'HandleVisibility', 'off');
    
    % Only add legend to the last subplot to save space
    if cd == num_cd_bins
        legend('Location', 'best', 'FontSize', 8);
    end
    
    set(ax, 'FontSize', 10, 'Box', 'off');
end

% Overall Figure Title
sgtitle('Pupil Response: PE Bins nested within Contrast Difference Bins', ...
    'FontSize', 14, 'FontWeight', 'normal');