clc
clearvars

betas_struct = importdata("pe_condiff.mat");
perm = importdata("perm_pe_condiff.mat");
[~,high_PU,mid_PU,low_PU,~,~,~,~,~,~,~,~,binned_dots,~,...
    ~,~,~,~,study2_blue] = colors_rgb(); % colors
x = linspace(-300,2700,300); % x-axis
num_subjs = 47; % number of subjects
neutral = [7, 53, 94]/255;

%% TILED LAYOUT

figure(Position=[200,200,700,175])
hold on
tiledlayout(1,5);
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

ylabel_strings = {'BS-modulated pupil (a.u.)','UP-modulated pupil (a.u.)','RT-modulated pupil (a.u.)','xgaze-modulated pupil (a.u.)','ygaze-modulated pupil (a.u.)'};
ncoeffs = [4,6,7,2,3]; % order of coefficients 
xpos_change = [-0.07,-0.0325,0,0.0325,0.07]; % change in axis position
ylim_lower = [-0.03,-0.02,-0.15,-0.15,-0.25]; % lower limit of y-axis
ylim_upper = [0.02,0.08,0.01,0.1,0.1]; % upper limit of y-axis

for a = 1:length(ncoeffs)

    % POSITION CHANGE
    new_pos = change_position(axes_old(a),[xpos_change(a),0,0,-0.02]);
    axes_new(a) = axes('Units', 'Normalized', 'Position', new_pos); % update
    box(axes_new(a), 'off'); % remove box
    delete(axes_old(a)); % delete old axis

    % GET POSITION TO PLOT P-VALUE
    ylim_axes = [-0.02,0.08];
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
    ySmoothed = smoothdata(nanmean(data_plot,1));
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
    text(mean(x(perm.mask(ncoeffs(a),:) == 1)),pval_pos + 0.08,"\itp\rm = 0.02","FontSize",7,"FontName",'Arial',"VerticalAlignment","bottom","HorizontalAlignment","center")
    
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
adjust_x = -0.06; % adjusted x-position for subplot label
adjust_y = ax1_pos(4)+0.115; % adjusted y-position for subplot label
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
print(fig, 'reg_full2.png', '-dpng', '-r600') 