% Figure 4: Plot model-based analysis of pupil data.

clc
clearvars

% INITIALIZE VARS
font_name = 'Arial'; % font name
font_size = 7; % font size
linewidth_plot = 0.5; % line width for plot
linewidth_curves = 2; % line width for curves
xaxis = linspace(-300,2700,300); % x-axis
[~,high_PU_col,~,low_PU_col,~,~,~,~,~,~,~,~,~,~,~,~,~,~,~] = colors_rgb(); % colors
neutral = [7, 53, 94]/255;
subj_ids = importdata("subj_ids.mat");
num_subs = length(subj_ids); % number of subjects
col = 300;

% USER-BASED PATH
currentDir = cd; % current directory
reqPath = 'GBSliderPupil_NatComms'; % to which directory one must save in
pathParts = strsplit(currentDir, filesep);
if startsWith(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    % Call the function to create the desired path
    desiredPath = createSavePaths(currentDir, reqPath);
end
betas = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff_linearInt.mat")); % add PE bin curves
coeff_names = betas.coeff_names;
pe_idx = find(strcmp(coeff_names,'pe'));
up_idx = find(strcmp(coeff_names,'zsc_up'));
peCondiff_idx = find(strcmp(coeff_names,'zsc_condiff:pe'));
condiff_idx = find(strcmp(coeff_names,'zsc_condiff'));
for s = 1:num_subs
    for c = 1:col
        coeffs.pe(s,c) = betas.with_intercept(1,pe_idx,s,c);
        coeffs.pe_condiff(s,c) = betas.with_intercept(1,peCondiff_idx,s,c);
        coeffs.up(s,c) = betas.with_intercept(1,up_idx,s,c);
    end
end

perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff_linearInt.mat")); % add PE bin curves
pe_pval = perm.mask(pe_idx,:);
pecondiff_pval = perm.prob(peCondiff_idx,:);
interaction = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep,"descriptive",filesep,"fb_PE2bins_condiff2bins_linearInt.mat"));

% Compute summary p-values (minimum across timepoints), rounded to 3 decimal places
pe_min_pval = round(min(perm.prob(pe_idx,:)), 3);
pecondiff_min_pval = round(min(pecondiff_pval), 3);

% Format as strings
if pe_min_pval <= 0.001
    pe_pval_str = "\itp\rm < 0.001";
else
    pe_pval_str = sprintf("\\itp\\rm = %.3f", pe_min_pval);
end

if pecondiff_min_pval < 0.001
    pecondiff_pval_str = "\itp\rm < 0.001";
else
    pecondiff_pval_str = sprintf("\\itp\\rm = %.3f", pecondiff_min_pval);
end

preds_all = readtable(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines",...
    filesep, "behavior", filesep, "LR analyses", filesep, "preprocessed_lr_pupil_no_zerope.xlsx"));
save_dir = strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines",...
    filesep, "pupil", filesep, "regression", filesep, "main");
descriptive_dir  = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'pupil', filesep, 'descriptive');
peVals = importdata(fullfile(descriptive_dir, 'meanPE_all.mat'));
condiffVals = importdata(fullfile(descriptive_dir, 'meanCondiff_all.mat'));
betas_field = betas.with_intercept;
maxTrials = 160; % max trials presented to a participant

% Compute contrast-difference values
highPU_val = mean(condiffVals(:,1)); % high state uncertainty
lowPU_val = mean(condiffVals(:,2)); % low state uncertainty

% Mean and standard deviation of uniform contrast-difference distribution
refVals = linspace(0, 0.1, maxTrials);
refMean = mean(refVals);
refSD = std(refVals);

% Z-score highPU and lowPU using the reference distribution's parameters
highPU = (highPU_val - refMean) / refSD;
lowPU = (lowPU_val  - refMean) / refSD;

% Compute prediction-error values
highPE = mean(peVals(:,2)); % high PE
lowPE = mean(peVals(:,1)); % low PE

% Mean and standard deviation of prediction-error distribution
refPEMean = mean(abs(preds_all.pe));
refPESD = std(abs(preds_all.pe));

highPE = (highPE - refPEMean) / refPESD;
lowPE  = (lowPE  - refPEMean) / refPESD;

% LOOP OVER SUBJECTS
for s = 1:num_subs
    preds = preds_all(preds_all.id == str2num(subj_ids{s}),:);
    preds.zsc_condiff = zscore(preds.norm_condiff);
    for c = 1:col
        coeffs.pe(s,c) = betas_field(1,pe_idx,s,c);
        coeffs.pe_condiff(s,c) = betas_field(1,peCondiff_idx,s,c);
        coeffs.intercept(s,c) = betas_field(1,1,s,c);
        coeffs.con_diff(s,c) = betas_field(1,condiff_idx,s,c);
    end
    
    % Generate model predictions
    posterior.highPU_highPE(s,:) = coeffs.intercept(s,:) + coeffs.pe_condiff(s,:).*highPU.*highPE + coeffs.pe(s,:).*highPE + coeffs.con_diff(s,:).*highPU;
    posterior.lowPU_lowPE(s,:) = coeffs.intercept(s,:) + coeffs.pe_condiff(s,:).*lowPU.*lowPE + coeffs.pe(s,:).*lowPE + coeffs.con_diff(s,:).*lowPU;
    posterior.highPU_lowPE(s,:) = coeffs.intercept(s,:) + coeffs.pe_condiff(s,:).*highPU.*lowPE + coeffs.pe(s,:).*lowPE + coeffs.con_diff(s,:).*highPU;
    posterior.lowPU_highPE(s,:) = coeffs.intercept(s,:) + coeffs.pe_condiff(s,:).*lowPU.*highPE + coeffs.pe(s,:).*highPE + coeffs.con_diff(s,:).*lowPU;

end

% SAVE
safe_saveall(strcat(save_dir, filesep, "posteriorCurves_regression.mat"),posterior);

%% INITIALIZE TILE LAYOUT

fig = figure; 
set(fig, 'Visible', 'on');

% Size in CM
width_cm = 15; 
height_cm = 7;
set(fig, 'Units', 'centimeters');
set(fig, 'Position', [10, 10, width_cm, height_cm]);
set(fig, 'Units', 'centimeters');
set(fig, 'Position', [10, 10, width_cm, height_cm]);
set(fig, 'PaperUnits', 'centimeters');
set(fig, 'PaperSize', [width_cm, height_cm]);
set(fig, 'PaperPosition', [0, 0, width_cm, height_cm]);

hold on
t = tiledlayout(1,3,"Padding","compact","TileSpacing","compact");
ax1 = nexttile(1,[1,1]);
ax2 = nexttile(2,[1,1]);
ax3 = nexttile(3,[1,1]);

sg = sgtitle('Pupil dilation = \beta_0 + \beta_1 \cdot |PE| + \beta_2 \cdot |PE| \cdot |Contrast difference| + \beta_3 \cdot |Update| + ... + \epsilon', ...
    'Interpreter','Tex','FontSize',8,'FontName',font_name);

%% PLOT MAIN EFFECT OF PE

% POSITION CHANGE
position_change = [0.0, 0.0, 0.0, -0.05];
new_pos = change_position(ax1, position_change);
ax1_new = axes('Units', 'Normalized', 'Position', new_pos); % new position
delete(ax1);

% PLOT
hold on
shadedErrorBar(xaxis, mean(coeffs.pe), std(coeffs.pe)./sqrt(num_subs), ...
    {'Color', neutral, 'LineWidth', linewidth_curves}, 1);
xline(0,'LineStyle','--','LineWidth',0.5);
yline(0,'LineStyle','--','LineWidth',0.5);

% ADJUST FIGURE PROPERTIES
adjust_figprops(ax1_new,font_name,font_size,linewidth_plot);
xlim([-300, 2700])
xlabel('Time since feedback (ms)')
ylabel('PE-modulated pupil ({\bf\beta_1})','FontWeight','normal','FontName',font_name,'FontSize',font_size)

% DISPLAY PERMUTATION TEST RESULTS
pval_position = 1;
pval_sign = 1;
pval_text_dist = 0.05;
printPermTest(perm, xaxis, pe_idx, pval_position, pval_sign, pval_text_dist, font_size, font_name)

%% PLOT UNCERTAINTY-WEIGHTED PE

% POSITION CHANGE
new_pos = change_position(ax2, position_change);
ax2_new = axes('Units', 'Normalized', 'Position', new_pos); % new position
delete(ax2);

% PLOT
hold on
shadedErrorBar(xaxis, mean(coeffs.pe_condiff), std(coeffs.pe_condiff)./sqrt(num_subs), ...
    {'Color', neutral, 'LineWidth', linewidth_curves},1);

% ADJUST FIGURE PROPERTIES
xline(0, 'LineStyle', '--', 'LineWidth', 0.5);
yline(0, 'LineStyle', '--', 'LineWidth', 0.5);
adjust_figprops(ax2_new,font_name,font_size,linewidth_plot);
xlabel('Time since feedback (ms)')
ylabel('Uncertainty-weighted PE ({\bf\beta_2})','FontWeight','normal','FontName',font_name,'FontSize',font_size)
hold on

% DISPLAY PERMUTATION TEST RESULTS
pval_position = 1;
pval_sign = 1;
pval_text_dist = 0.05;
printPermTest(perm, xaxis, peCondiff_idx, pval_position, pval_sign, pval_text_dist, font_size, font_name)
xlim([-300, 2700])

%% ADD POSTERIOR-PREDICTED CURVES

% Compute standard error of the mean
diff1 = interaction.subj_pupil(1,2).signal - interaction.subj_pupil(1,1).signal;
diff2 = interaction.subj_pupil(2,2).signal - interaction.subj_pupil(2,1).signal;
sem_diff1 = std(diff1)./sqrt(num_subs);
sem_diff2 = std(diff2)./sqrt(num_subs);

% Calculate the difference waves for the pupil (interaction) data
pupil_diff1 = mean(interaction.subj_pupil(1, 2).signal) - mean(interaction.subj_pupil(1,1).signal);
pupil_diff2 = mean(interaction.subj_pupil(2, 2).signal) - mean(interaction.subj_pupil(2,1).signal);

% Calculate the difference waves for the posterior data
post_diff1 = mean(posterior.highPU_highPE) - mean(posterior.highPU_lowPE);
post_diff2 = mean(posterior.lowPU_highPE) - mean(posterior.lowPU_lowPE);

% POSITION CHANGE
new_pos = change_position(ax3, [0.02, 0.0, 0.0, -0.05]);
ax3_new = axes('Units', 'Normalized', 'Position', new_pos); % new position
delete(ax3);

% PLOT
hold on

% Note: shadedErrorBar returns a struct. We want the 'mainLine' field.
h1 = shadedErrorBar(xaxis, pupil_diff1, sem_diff1, {'Color', high_PU_col, 'LineWidth', linewidth_curves}, 0.15);
h2 = shadedErrorBar(xaxis, pupil_diff2, sem_diff2, {'Color', low_PU_col, 'LineWidth', linewidth_curves}, 0.15);

% Capture handles for the posterior curves (Model Data)
p1 = plot(xaxis, post_diff1, 'Color', high_PU_col, 'LineWidth', linewidth_curves, 'LineStyle', ':');
p2 = plot(xaxis, post_diff2, 'Color', low_PU_col, 'LineWidth', linewidth_curves, 'LineStyle', ':');

% Legend text
highPU_str = "Model: low difference";
lowPU_str = "Model: high difference";
set(gca,'Color', 'none', 'FontName', font_name, 'FontSize', font_size)
xline(0, '--', 'LineWidth', 0.5)
yline(0, '--', 'LineWidth', 0.5)
xlim([-300, 2700])
ylim([-30, 120])

xlabel('Time since feedback (ms)')
ylabel('Pupil difference (high - low PE)', 'FontSize', font_size);

l = legend([h1.mainLine, h2.mainLine, p1, p2], ...
    {'Data: low contrast difference', 'Data: high difference', ...
     highPU_str, lowPU_str'}, 'EdgeColor', 'none', 'AutoUpdate', 'off', ...
    'FontSize', font_size, 'FontName', font_name, 'Color', 'none');
l.Position = [0.72, 0.78, 0.2710, 0.0400];
l.ItemTokenSize = [7 7];

a1 = annotation("arrow", [0.78, 0.78], [0.52, 0.62], 'LineWidth', 0.5, 'Color', low_PU_col);
a2 = annotation("arrow", [0.78, 0.78], [0.49, 0.39], 'LineWidth', 0.5, 'Color', high_PU_col);
a1.HeadLength = 5; a2.HeadLength = 5;
adjust_figprops(ax3_new,font_name,font_size,linewidth_plot);


%% ADD SUBPLOT LABELS

ax1_pos = ax1_new.Position;
adjust_x = -0.065; % adjusted x-position for subplot label
adjust_y = ax1_pos(4)+0.05; % adjusted y-position for subplot label
[label_x,label_y] = change_plotlabel(ax1_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'a','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

[label_x,label_y] = change_plotlabel(ax2_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'b','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

[label_x,label_y] = change_plotlabel(ax3_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'c','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

%% SAVE

fig = gcf; 
fig.PaperPositionMode = 'auto'; 
%print(fig, 'regression_pupil_linearInt1New_3panels.png', '-dpng', '-r600')

% We are using a slightly outdated way to save the figure as PDF
style = hgexport('factorystyle');
style.Format = 'pdf';
style.Width = width_cm;
style.Height = height_cm;
style.Units = 'centimeters';
style.Renderer = 'painters'; 
style.FontMode = 'none';
hgexport(fig, 'Figures/PDF_Versions/Figure_4.pdf', style);