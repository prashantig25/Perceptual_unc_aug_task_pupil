% figureSM2 plots results from all regressors of the binned pupil analysis.

clc
clearvars

betas_struct = importdata("pe_condiff2bins.mat");
perm = importdata("perm_pe_condiff2bins.mat");
[~,high_PU,mid_PU,low_PU,~,~,~,~,~,~,~,~,binned_dots,~,...
    ~,~,~,~,study2_blue] = colors_rgb(); % colors
x = linspace(-300,2700,300); % x-axis 
num_subjs = 47; % number of subjects
font_name = 'Arial'; % font name
font_size = 7; % font size
fontsize_label = 12; % font size for subplot labels
line_style = '-'; % line style

%% TILED LAYOUT

figure(Position=[200,200,600,175])
hold on
tiledlayout(1,4);
ax1 = nexttile(1,[1,1]);
ax2 = nexttile(2,[1,1]);
ax3 = nexttile(3,[1,1]);
ax4 = nexttile(4,[1,1]);
axes_old = [ax1,ax2,ax3,ax4];
ax1_new = ax1;
ax2_new = ax2;
ax3_new = ax3;
ax4_new = ax4;
axes_new = [ax1_new,ax2_new,ax3_new,ax4_new];

%% PLOT COEFFICIENTS

ylabel_strings = {'UP-modulated pupil (a.u.)','RT-modulated pupil (a.u.)','xgaze-modulated pupil (a.u.)','ygaze-modulated pupil (a.u.)'};
ncoeffs = [5,6,2,3]; % order of coefficients
xpos_change = [-0.07,-0.035,0,0.04]; % change in position of tile
ylim_lower = [-0.05,-0.14,-0.2,-0.3]; % y-axis lower limit
ylim_upper = [0.1,-0.02,0.1,0.1]; % y-axisx upper limit

for a = 1:length(ncoeffs)

    % POSITION CHANGE
    new_pos = change_position(axes_old(a),[xpos_change(a),0,0.02,0]);
    axes_new(a) = axes('Units', 'Normalized', 'Position', new_pos); % update
    box(axes_new(a), 'off'); % remove box
    delete(axes_old(a)); % delete old axis

    cats = [1,2]; % number of categories
    color_cell = {high_PU; low_PU}; % colors for low and high perceptual uncertainty data
    col = 300; % number of time points

    % PLOT FOR EACH OF THE BIN CATEGORIES
    for j = cats
        data_plot = zeros(num_subjs,col);
        for s = 1:num_subjs
            for c = 1:col
                data_plot(s,c) = betas_struct.with_intercept(j,ncoeffs(a),s,c);
            end
        end
        hold on
        color = color_cell;
        ySmoothed = smoothdata(nanmean(data_plot,1));
        plot(x,ySmoothed,"Color",color{j,:},'LineWidth',2)
        hold on
    end

    % PLOT ERROR BARS FOR EACH BIN 
    for j = cats
        data_plot = zeros(num_subjs,col);
        for s = 1:num_subjs
            for c = 1:col
                data_plot(s,c) = betas_struct.with_intercept(j,ncoeffs(a),s,c);
            end
        end
        ySmoothed = smoothdata(nanmean(data_plot,1));
        color = cell2mat(color_cell);
        shadedErrorBar(x,ySmoothed,nanstd(data_plot,1)./sqrt(num_subjs),{'LineWidth',2,"Color",color(j,:)},1)
        hold on
    end

    % PLOT PERMUTATION TEST RESULTS
    disp_perm = 1;
    if disp_perm == 1
        ylim_axes = [ylim_lower(a),ylim_upper(a)];
        [pval_pos] = create_pvalpos(ylim_axes); % get position for p-value
        plot(x(find(perm.mask(ncoeffs(a),:) == 1)), 0.095*ones(1, length(find(perm.mask(ncoeffs(a),:) == 1))), '.', 'color', ...
            [119, 119, 119]./255, 'markersize', 4);
    end
    text(mean(x(perm.mask(ncoeffs(a),:) == 1)),pval_pos + 0.095 ,"\itp\rm = 0.002","FontSize",7,"FontName",'Arial',"VerticalAlignment","bottom","HorizontalAlignment","center")
    
    % ADJUST FIGURE PROPERTIES
    adjust_figprops(axes_new(a),'Arial',7,0.5)
    xlim([-300,2700])
    ylim([ylim_lower(a),ylim_upper(a)])
    xline(0,'--')
    yline(0,'--')
    xlabel('Time since feedback (ms)')
    ylabel(ylabel_strings(:,a))
end

l = legend('High BS uncertainty','Low BS uncertainty','Location','best','EdgeColor', ...
    'none','AutoUpdate','off','FontSize',7,'FontName','Arial','Color','none');
l.ItemTokenSize = [7 7];

%% ADD SUBPLOT LABELS

ax1_pos = axes_new(a).Position;
adjust_x = -0.06; % adjusted x-position for subplot label
adjust_y = ax1_pos(4)+0.09; % adjusted y-position for subplot label
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

%% SAVE AS PNG

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'binnedreg_full2.png', '-dpng', '-r600') 