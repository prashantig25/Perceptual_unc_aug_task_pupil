% figureSM8 plots betas from pupil model after regressing out RTs.
clc
clearvars

%% LOAD DATA

currentDir = cd;
reqPath    = 'Perceptual_unc_aug_task_pupil-main';
pathParts  = strsplit(currentDir, filesep);
if strcmp(pathParts{end}, reqPath)
    desiredPath = currentDir;
else
    desiredPath = createSavePaths(currentDir, reqPath);
end
het_save_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', ...
                        'regression', 'control analyses for revisions');
betas_struct = importdata(fullfile(het_save_dir,"param_estimates_hetero_noZeroPE_linearInt_20SPAbs3Width_pregenSP.mat")); 
coeff_names = importdata(fullfile(het_save_dir,"coeff_names_het.mat"));
x = linspace(-300, 2700, 300); 
num_subjs = 47;
num_params = 10;
col = 300;
% [num_subjs, num_params, col] = size(betas_struct);

% PREPARE AND RUN PERMUTATION TEST
fprintf('Running cluster-corrected permutation tests...\n');
perm = get_permtest(1:num_params, num_subjs, col, betas_struct.with_intercept, [], 0, 1);
safe_saveall(fullfile(het_save_dir,"permHet_linearInt_20SPAbs3Width.mat"),perm);

%% PLOT SETTINGS
neutral = [7, 53, 94]/255;
font_name = 'Arial';
font_size = 7;
line_style = '-';

% Order of coefficients to plot (indices from your param_names list)
% 4:omikron_0, 5:omikron_1, 3:Condiff, 6:PEXCondiff, 7:RT, 2:PE, 8:UP, 9:xgaze, 10:ygaze
ncoeffs = [2,6,3,7,8,9,10,4,5]; 

ylabel_strings = [ ...
    "PE-modulated pupil (a.u.)", ...           % ncoeff 3: Uncertainty
    "Uncertainty-weighted PE pupil (a.u.)", ...         % ncoeff 6: Interaction
    "BS-modulated pupil (a.u.)", ...           % ncoeff 7: Reaction Time
    "RT-modulated pupil (a.u.)", ...           % ncoeff 2: Prediction Error
    "UP-modulated pupil (a.u.)", ...           % ncoeff 8: Update (Unexpect. Purp.)
    "x-gaze-modulated pupil (a.u.)", ...        % ncoeff 9: x-gaze
    "y-gaze-modulated pupil (a.u.)", ...        % ncoeff 5: y-gaze
    "Residual intercept", ...                            % ncoeff 4: Baseline Noise
    "Residual slope"];                               % ncoeff 10: y-gaze

xpos_change = [-0.05,-0.02,0.02, 0.05,-0.05,-0.02, 0.05, 0.05, 0.05]; 
pval_position = [0.005, 0.005, -0.01, -0.01, -0.12, 0.01, 0.01, 0.01, 0.01]; 

%% TILED LAYOUT

data_plot = NaN(num_subjs,col);

figure('Position', [200, 200, 450, 500])
t = tiledlayout(3, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
letters = 'a':'i';   % 9 subplots

for a = ncoeffs-1
    nexttile(a);
    hold on;
    
    current_idx = ncoeffs(a);

    for s = 1:num_subjs
        for c = 1:col
            % coeffs.pe(s,c) = betas.with_intercept(1,5,s,c);
            % coeffs.pe_condiff(s,c) = betas.with_intercept(1,8,s,c);
            % coeffs.up(s,c) = betas.with_intercept(1,6,s,c);
            data_plot(s,c) = betas_struct.with_intercept(1, current_idx, s, c);
        end
    end
    
    % Extract data for this specific coefficient
    % data_plot: [num_subjs x col]
    % data_plot = squeeze(betas_struct(:, current_idx, :));
    
    % Compute Mean and SEM
    yAvg = nanmean(data_plot, 1);
    ySem = nanstd(data_plot, 1) ./ sqrt(num_subjs);
    ySmoothed = yAvg;
    
    % Plot Shaded Error Bar
    shadedErrorBar(x, ySmoothed, ySem, {'LineWidth', 2, 'Color', neutral}, 1);
    
    % PLOT PERMUTATION RESULTS (Significance Line)
    sig_mask = find(perm.prob(current_idx, :) < 0.05);
    if ~isempty(sig_mask)
        % Plot dots for significant timepoints
        plot(x(sig_mask), pval_position(a) * ones(1, length(sig_mask)), '.', ...
            'Color', [0.5 0.5 0.5], 'MarkerSize', 5);
        
        % Annotate p-value (minimum probability in the mask)
        p_val = min(perm.prob(current_idx, sig_mask));
        
        % Dynamic p-value text formatting
        if p_val < 0.001
            p_text = '\itp\rm < 0.001';
        else
            p_text = strcat("\itp\rm = ",num2str(round(p_val,3)));
        end
        
        % Position text in the middle of the significant cluster
        text(mean(x(sig_mask)), pval_position(a) + (0.05 * pval_position(a)), ...
            p_text, 'FontSize', 7, 'HorizontalAlignment', 'center');
    end
    
    % Adjust Axes
    ylabel(ylabel_strings(:,a), 'FontSize', font_size,'FontWeight','normal');
    xlim([-300, 2700]);
    xline(0, '--k', 'HandleVisibility', 'off');
    yline(0, '--k', 'HandleVisibility', 'off');
    xlabel('Time from feedback (ms)');
    % ylabel('Beta (a.u.)');
    set(gca, 'FontName', 'Arial', 'FontSize', 7);
    hold on
    % Subplot label (a, b, c, ...)
    text(-0.2, 1.05, letters(a), ...
        'Units', 'normalized', ...
        'FontSize', 12, ...
        'FontWeight', 'normal');
    box off;
end


%% SAVE AS PNG

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'coeffs_HeteroSkedasticModel_linearInt20SP.png', '-dpng', '-r600') 