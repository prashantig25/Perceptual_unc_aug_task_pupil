% figureSM8 plots betas from pupil model after regressing out RTs.

clc
clearvars

betas_struct = importdata("C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\Perceptual_unc_aug_task_pupil-main\data\GB data peak corrected\pupil\regression\main\pe_condiff_regressedRT.mat");
perm = importdata("C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\Perceptual_unc_aug_task_pupil-main\data\GB data peak corrected\pupil\regression\main\perm_pe_condiff_regressedRT.mat");
x = linspace(-300,2700,300); % x-axis
num_subjs = 47; % number of subjects
neutral = [7, 53, 94]/255;
font_name = 'Arial'; % font name
font_size = 7; % font size
fontsize_label = 12; % font size for subplot labels
line_style = '-'; % line style

%% TILED LAYOUT

figure(Position=[200,200,600,300])
hold on
tiledlayout(2,4);
ax1 = nexttile(1,[1,1]);
ax2 = nexttile(2,[1,1]);
ax3 = nexttile(3,[1,1]);
ax4 = nexttile(4,[1,1]);
ax5 = nexttile(5,[1,1]);
ax6 = nexttile(6,[1,1]);
ax7 = nexttile(7,[1,1]);
ax1_new = ax1;
ax2_new = ax2;
ax3_new = ax3;
ax4_new = ax4;
ax5_new = ax5;
ax6_new = ax6;
ax7_new = ax7;
axes_new = [ax1_new,ax2_new,ax3_new,ax4_new,ax5_new,ax6_new,ax7_new];
axes_old = [ax1,ax2,ax3,ax4,ax5,ax6,ax7];

%% PLOT COEFFICIENT CURVES

ylabel_strings = [{"BS-modulated";"pupil (a.u.)"},{"PE-modulated";"pupil (a.u.)"},{"BS-weighted PE";"pupil (a.u.)"},{"UP-modulated";"pupil (a.u.)"},{"RT-modulated";"pupil (a.u.)"},{"xgaze-modulated";"pupil (a.u.)"},{"ygaze-modulated";"pupil (a.u.)"}];
ncoeffs = [4,5,8,6,7,2,3]; % order of coefficients
xpos_change = [-0.05,-0.02,0.02,0.05,-0.05,-0.02,0.02]; % position change for axes
pval_position = [NaN,-0.02,-0.01,-0.01,-0.12,0.01,0.01]; % position to plot p-values
ylim_lower = [-0.02,-0.04,-0.02,-0.025,-0.17,-0.1,-0.1]; % lower limit for y-axis
ylim_upper = [0.01,0.07,0.025,0.05,0.15,0.15,0.05,-0.1]; % upper limit for y-axis

for a = 1:length(ncoeffs)

    % POSITION CHANGE
    new_pos = change_position(axes_old(a),[xpos_change(a),0,0,-0.02]);
    axes_new(a) = axes('Units', 'Normalized', 'Position', new_pos); % update
    box(axes_new(a), 'off'); % remove box
    delete(axes_old(a)); % delete old axis

    color_cell = {neutral}; % colors for low and high perceptual uncertainty data
    col = 300; % length of x-axis

    % PLOT
    data_plot = zeros(num_subjs,col);
    for s = 1:num_subjs
        for c = 1:col
            data_plot(s,c) = betas_struct.with_intercept(1,ncoeffs(a),s,c);
        end
    end
    hold on
    color = color_cell;
    ySmoothed = smoothdata(nanmean(data_plot,1));
    plot(x,ySmoothed,"Color",color{1,:},'LineWidth',2)
    hold on
    color = cell2mat(color_cell);
    shadedErrorBar(x,ySmoothed,nanstd(data_plot,1)./sqrt(num_subjs),{'LineWidth',2,"Color",color(1,:)},1)
    hold on

    % PLOT PERMUTATION TEST
    disp_perm = 1;
    if disp_perm == 1
        ylim_axes = [ylim_lower(a),ylim_upper(a)];
        [pval_pos] = create_pvalpos(ylim_axes);
        plot(x(find(perm.mask(ncoeffs(a),:) == 1)), (pval_position(a))*ones(1, length(find(perm.mask(ncoeffs(a),:) == 1))), '.', 'color', ...
            [119, 119, 119]./255, 'markersize', 4);
        p_val = min(unique(perm.prob(ncoeffs(a),perm.mask(ncoeffs(a),:) == 1)));
    end
    if p_val < 0.001
        text(mean(x(perm.mask(ncoeffs(a),:) == 1)),pval_position(a) + pval_pos,"\itp\rm < 0.001","FontSize",7,"FontName",'Arial',"VerticalAlignment","middle","HorizontalAlignment","center")
    elseif p_val < 0.01
            text(mean(x(perm.mask(ncoeffs(a),:) == 1)),pval_position(a) + pval_pos,strcat("\itp\rm = ",num2str(round(p_val,3))),"FontSize",7,"FontName",'Arial',"VerticalAlignment","middle","HorizontalAlignment","center")
    elseif p_val < 0.05 & p_val > 0.01
            text(mean(x(perm.mask(ncoeffs(a),:) == 1)),pval_position(a) + pval_pos,strcat("\itp\rm = ",num2str(round(p_val,3))),"FontSize",7,"FontName",'Arial',"VerticalAlignment","middle","HorizontalAlignment","center")
    end

    % ADJUST FIGURE PROPERTIES
    adjust_figprops(axes_new(a),'Arial',7,0.5)
    xlim([-300,2700])
    ylim([ylim_lower(a),ylim_upper(a)])
    xline(0,'--')
    yline(0,'--')
    xlabel('Time since feedback (ms)')
    ylabel(ylabel_strings(:,a))
end

%% ADD SUBPLOT LABELS

ax1_pos = axes_new(a).Position;
adjust_x = -0.07; % adjusted x-position for subplot label
adjust_y = ax1_pos(4)+0.05; % adjusted y-position for subplot label
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

[label_x,label_y] = change_plotlabel(axes_new(6),adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'f','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

[label_x,label_y] = change_plotlabel(axes_new(7),adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'g','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

%% SAVE AS PNG

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'mdl_regressedRT1.png', '-dpng', '-r600') 