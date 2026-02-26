% figureSM2 plots results from all regressors of the pupil analysis.

clc
clearvars

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
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff_linearInt.mat")); % add PE bin curves
coeff_names = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff_linearInt_coeffNames.mat")); % add PE bin curves
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff_linearInt.mat")); % add PE bin curves
[~,high_PU,mid_PU,low_PU,~,~,~,~,~,~,~,~,binned_dots,~,...
    ~,~,~,~,study2_blue] = colors_rgb(); % colors
x = linspace(-300,2700,300); % x-axis
num_subjs = 47; % number of subjects
neutral = [7, 53, 94]/255;

%% TILED LAYOUT

figure(Position=[200,200,400,400])
hold on
tiledlayout(2,3);
ax1 = nexttile(1,[1,1]);
ax2 = nexttile(2,[1,1]);
ax3 = nexttile(3,[1,1]);
ax4 = nexttile(4,[1,1]);
ax5 = nexttile(5,[1,1]);
ax1_new = ax1;
ax2_new = ax2;
ax3_new = ax3;
ax4_new = ax4;
ax5_new = ax5;
axes_new = [ax1_new,ax2_new,ax3_new,ax4_new,ax5_new];
axes_old = [ax1,ax2,ax3,ax4,ax5];

%% PLOT COEFFICIENT CURVES 

ylabel_strings = {'Uncertainty-modulated pupil (a.u.)','UP-modulated pupil (a.u.)','RT-modulated pupil (a.u.)','x-gaze-modulated pupil (a.u.)','y-gaze-modulated pupil (a.u.)'};
condiff_idx = find(strcmp(coeff_names,'zsc_condiff'));
ygaze_idx = find(strcmp(coeff_names,'ygaze'));
xgaze_idx = find(strcmp(coeff_names,'xgaze'));
up_idx = find(strcmp(coeff_names,'zsc_up'));
rt_idx = find(strcmp(coeff_names,'rt'));
ncoeffs = [condiff_idx,up_idx,rt_idx,xgaze_idx,ygaze_idx]; % order of coefficients 
pval = {'',' = 0.03','< 0.001',' = 0.04',' < 0.001'};
xpos_change = [-0.07,-0.0325,0,-0.07,-0.0325]; % change in axis position
ylim_lower = [-0.02,-0.02,-0.1,-0.1,-0.1]; % lower limit of y-axis
ylim_upper = [0.01,0.08,0.1,0.1,0.1]; % upper limit of y-axis

for a = 1:length(ncoeffs)

    % POSITION CHANGE
    new_pos = change_position(axes_old(a),[xpos_change(a),0,0,-0.02]);
    axes_new(a) = axes('Units', 'Normalized', 'Position', new_pos); % update
    box(axes_new(a), 'off'); % remove box
    delete(axes_old(a)); % delete old axis

    % GET POSITION TO PLOT P-VALUE
    ylim_axes = [ylim_lower(a),ylim_upper(a)];
    [pval_pos] = create_pvalpos(ylim_axes);

    color_cell = {neutral}; % colors for low and high perceptual uncertainty data
    col = 300; 

    % PLOT
    data_plot = zeros(num_subjs,col);
    for s = 1:num_subjs
        for c = 1:col
            data_plot(s,c) = betas_struct.with_intercept(1,ncoeffs(a),s,c);
        end
    end
    hold on
    color = color_cell;
    ySmoothed = nanmean(data_plot);
    plot(x,ySmoothed,"Color",color{1,:},'LineWidth',2)
    hold on
    color = cell2mat(color_cell);
    shadedErrorBar(x,ySmoothed,nanstd(data_plot,1)./sqrt(num_subjs),{'LineWidth',2,"Color",color(1,:)},1)
    hold on

    % PLOT P-VALUE
    disp_perm = 1;
    if disp_perm == 1
        ylim_axes = [ylim_lower(a),ylim_upper(a)];
        [pval_pos] = create_pvalpos(ylim_axes);
        plot(x(find(perm.mask(ncoeffs(a),:) == 1)), 0.08*ones(1, length(find(perm.mask(ncoeffs(a),:) == 1))), '.', 'color', ...
            [119, 119, 119]./255, 'markersize', 4);
    end

    % Compute summary p-values (minimum across timepoints), rounded to 3 decimal places
    pval = round(min(perm.prob(ncoeffs(a),:)), 3);

    % Format as strings
    if pval < 0.001
        pval_str = "\itp\rm < 0.001";
    else
        pval_str = sprintf("\\itp\\rm = %.3f", pval);
    end

    text(mean(x(perm.mask(ncoeffs(a),:) == 1)),pval_pos + 0.08,pval_str,"FontSize",7,"FontName",'Arial',"VerticalAlignment","bottom","HorizontalAlignment","center")
    
    % ADJUST FIGURE PROPERTIES
    adjust_figprops(axes_new(a),'Arial',7,0.5)
    xlim([-300,2700])
    % ylim([ylim_lower(a),ylim_upper(a)])
    xline(0,'--')
    yline(0,'--')
    xlabel('Time since feedback (ms)')
    ylabel(ylabel_strings(:,a))
end

%% ADD SUBPLOT LABELS

ax1_pos = axes_new(a).Position;
adjust_x = -0.06; % adjusted x-position for subplot label
adjust_y = ax1_pos(4)+0.02; % adjusted y-position for subplot label
[label_x,label_y] = change_plotlabel(axes_new(1),adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'a','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

[label_x,label_y] = change_plotlabel(axes_new(2),adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'b','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

[label_x,label_y] = change_plotlabel(axes_new(3),adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'c','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

[label_x,label_y] = change_plotlabel(axes_new(4),adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'd','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

[label_x,label_y] = change_plotlabel(axes_new(5),adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'e','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

%% SAVE AS PNG

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'reg_full2_linearInt1.png', '-dpng', '-r600') 