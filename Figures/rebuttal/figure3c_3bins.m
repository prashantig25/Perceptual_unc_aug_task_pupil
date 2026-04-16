% figure3 plots descriptive pupil data.

clc
clearvars

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

betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff3bins_linearInt.mat")); % add PE bin curves
coeff_names = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff2bins_linearInt_coeffNames.mat")); % add PE bin curves

[~,high_PU,mid_PU,low_PU,~,~,~,~,~,~,~,~,binned_dots,~,...
    ~,~,~,~,study2_blue] = colors_rgb(); % colors
x = linspace(-300,2700,300); % x-axis
subj_ids = importdata("subj_ids.mat");
num_subjs = length(subj_ids); % number of subjects
neutral = [7, 53, 94]/255;
bin_edges = [0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1];
dark_violet = [17, 0, 70]./255;
mid_violet = [88, 86, 138]./255;
light_violet = [158, 172, 206]./255;
%% TILED LAYOUT

figure(Position=[200,200,450,175])
hold on
tiledlayout(1,1,"Padding","compact","TileSpacing","compact");
ax3 = nexttile(1,[1,1]);

% POSITION CHANGE
new_pos = change_position(ax3,[0.02,0.05,0,-0.08]);
ax5_new = axes('Units', 'Normalized', 'Position', new_pos); % update
box(ax5_new, 'off'); % remove box
delete(ax3); % delete old axis

% GET POSITION FOR P-VALUE
ylim_axes = [-0.05,0.1];
[pval_pos] = create_pvalpos(ylim_axes);

ncoeffs  = find(strcmp(coeff_names, 'pe'));
ncats = repelem(3,1,9);
xlabel_name = 'Time since feedback onset';
cats = [1,2,3];
color_cell = {high_PU; mid_PU;low_PU}; % colors for low and high perceptual uncertainty data
col = 300; m = 0; start = 0;

% PLOT
for j = cats
    data_plot = zeros(num_subjs,col);
    for s = 1:num_subjs
        for c = 1:col
            data_plot(s,c) = betas_struct.with_intercept(j,ncoeffs,s,c);
        end
    end
    hold on
    color = color_cell;
    ySmoothed = nanmean(data_plot,1);
    plot(x,ySmoothed,"Color",color{j,:},'LineWidth',2)
    hold on
    m = m + num_subjs;
    start = start + m;
end

for j = cats
    data_plot = zeros(num_subjs,col);
    for s = 1:num_subjs
        for c = 1:col
            data_plot(s,c) = betas_struct.with_intercept(j,ncoeffs,s,c);
        end
    end
    ySmoothed = nanmean(data_plot,1);
    color = cell2mat(color_cell);
    shadedErrorBar(x,ySmoothed,nanstd(data_plot,1)./sqrt(num_subjs),{'LineWidth',2,"Color",color(j,:)},1)
    hold on
end

% ADJUST FIGURE PROPERTIES
adjust_figprops(ax5_new,'Arial',7,0.5)
xlim([-300,2700])
% ylim(ylim_axes)
l = legend('High state uncertainty','Mid state uncertainty','Low state uncertainty','Location','best','EdgeColor', ...
    'none','AutoUpdate','off','FontSize',7,'FontName','Arial','Color','none');
l.ItemTokenSize = [7 7];
xline(0,'--')
yline(0,'--')
xlabel('Time since feedback onset (ms)')
ylabel('PE-modulated pupil (a.u.)')

%% ADD SUBPLOT LABELS

ax1_pos = ax5_new.Position;
adjust_x = -0.06; % adjusted x-position for subplot label
adjust_y = ax1_pos(4) + 0.05; % adjusted y-position for subplot label
[label_x,label_y] = change_plotlabel(ax1_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'a','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

[label_x,label_y] = change_plotlabel(ax4_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'b','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

[label_x,label_y] = change_plotlabel(ax5_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'c','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

%% SAVE 

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'fig3c_3bins.png', '-dpng', '-r600') 