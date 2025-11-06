% figure1 creates a hypothesis illustration figure.

clc
clearvars

% INITIALISE VARS

font_name = 'Arial'; % font name
font_size = 7; % font size
horz_align = 'center'; % horizontal alignment for text
vert_align = 'middle'; % vertical alignment for text
line_width = 0.5; % linewidth for axes
linewidth_arrow = 0.5; % linewidth for arrows
linewidth_line = 2; % linewidth for plotted lines
headlength_arrow = 5; % headlength for arrows
[~,high_PU,mid_PU,low_PU,color_screen,~,~,~,~,~,gray_dots,light_gray,~,~,...
    ~,dots_edges,~,~,gray_arrow] = colors_rgb(); % colors

% VARS FOR LRs PLOT

colors_pu_all = [low_PU; high_PU; gray_arrow(1,1:3); gray_arrow(1,1:3)]; % colors for low and high perceptual uncertainty data
pe_vals = linspace(-1,1,10); % prediction error range
neg_up = [-0.5,-0.15,-0.325,-0.325]; % negative updates
pos_up = [0.5,0.15,0.325,0.325]; % positive updates

condiffbin = importdata("condiff_pebin2.mat"); % pupil regression
num_subjs = 47; % number of subjects
col = 300; % number of timepoints
%% INITIALISE TILE LAYOUT

f1 = figure;
set(gcf,'Visible','on','Position',[200,200,400,200])
t = tiledlayout(1,2);
ax2 = nexttile(2);
ax3 = nexttile(1);
t.TileSpacing = 'compact';
t.Padding = 'compact';
 
%% ADD ARROWS

ar1 = annotation('arrow','LineWidth',linewidth_arrow,'HeadLength',headlength_arrow,'Color','k','HeadWidth',10);
ar1.X = [0.47 0.54];
ar1.Y = [0.49,0.49];

ar1 = annotation('arrow','LineWidth',linewidth_arrow,'HeadLength',headlength_arrow,'Color',low_PU,'HeadWidth',10);
ar1.X = [0.7 0.7];
ar1.Y = [0.58,0.77];

ar1 = annotation('arrow','LineWidth',linewidth_arrow,'HeadLength',headlength_arrow,'Color',high_PU,'HeadWidth',10);
ar1.X = [0.7 0.7];
ar1.Y = [0.49,0.3];

% sgtitle('H1:Pupil-linked arousal encodes uncertainty-weighted prediction errors','FontName','Arial','FontSize',9)

%% PLOT LEARNING RATES

% POSITION CHANGE

position_change = [0.025,0.03,-0.05,-0.05];%[0.1,0.1,-0.1,-0.15]; % change in position % use this if LR is subplot a
new_pos = change_position(ax3,position_change);
ax3_new = axes('Units', 'Normalized', 'Position', new_pos);
box(ax3_new, 'on');
delete(ax3);

% PLOT

hold on
plot(pe_vals,repelem(0,1,10),'LineStyle','--','Color','k','LineWidth',0.5)
hold on
plot(pe_vals,pe_vals,'LineStyle','--','Color','k','LineWidth',0.5)
hold on
plot(pe_vals,pe_vals,'LineStyle','none','Color','k','LineWidth',0.5)
% for i = [1:3]
%     hold on
%     plot(pe_vals,linspace(neg_up(i),pos_up(i),10),'LineStyle','-','Color', ...
%         colors_pu_all(i,:),'LineWidth',linewidth_line)
% end

hold on
plot(pe_vals,linspace(neg_up(1),pos_up(1),10),'LineStyle','-','Color', ...
    colors_pu_all(1,:),'LineWidth',linewidth_line)
hold on
plot(pe_vals,linspace(neg_up(2),pos_up(2),10),'LineStyle','-','Color', ...
    colors_pu_all(2,:),'LineWidth',linewidth_line)
hold on
plot(pe_vals,linspace(neg_up(3),pos_up(3),10),'LineStyle','none','Color', ...
    colors_pu_all(3,:),'LineWidth',linewidth_line)
hold on
plot(pe_vals,linspace(neg_up(4),pos_up(4),10),'LineStyle','-','Color', ...
    colors_pu_all(4,:),'LineWidth',linewidth_line)

% ADJUST FIGURE PROPERTIES

xlim_vals = [-1 1];
ylim_vals = [-1 1];
adjust_figprops(ax3_new,font_name,font_size,line_width,xlim_vals,ylim_vals)
ylabel('Update')
xlabel({'Prediction error (PE)'})
% l1 = legend('','','Low state uncertainty','Classic RL account','','Location','best','Color','none', ...
%     'EdgeColor','none','AutoUpdate','off','FontSize',7);
% l1.ItemTokenSize = [7, 7];

% Create legend with a header for uncertainty-aware account
l1 = legend( ...
    '', ...  % dummy for header
    '',...
    'u',...
    'Low state uncertainty trials', ...
    'High state uncertainty trials', ...
    'u',...
    'All trials', ...
    'Location','best', ...
    'Color','none', ...
    'EdgeColor','none', ...
    'AutoUpdate','off', ...
    'FontSize',7);

% Reduce marker size in legend
l1.ItemTokenSize = [7, 7];
box off

% Now set the header text manually
l1.String{1} = '\bfUncertainty-weighted RL account'; % bold header
l1.String{4} = '\bfClassic RL account'; % bold header

box off

% ADD ROTATED TEXT BOXES

ypos = [0.71,-0.07,0.5,0.55,0.45]; % position on y-axis
xpos = [0.8,0.8,0.1,0.1,0.1]; % position on x-axis
rotate = [45.5, 0, 0, 90, 90]; % degree of rotation
allstrings = {'LR = 1','LR = 0','','Up-regulation','Down-regulation'};
num_strings = 2;
for n = 1:num_strings
    txt = text(xpos(n),ypos(n),allstrings{1,n});
    txt.Parent = ax3_new;
    txt.FontSize = font_size;
    txt.FontWeight = 'normal';
    txt.Rotation = rotate(n);
    txt.LineStyle = '-';
    txt.FontName = font_name;
    txt.HorizontalAlignment = horz_align;
end

%% PLOT PU modulated PUPIL

% POSITION CHANGE

position_change = [0.09,0.03,-0.05,-0.05];% change in position and use this if arousal is subplot b 
new_pos = change_position(ax2,position_change);
ax2_new = axes('Units', 'Normalized', 'Position', new_pos);
box(ax2_new, 'on');
delete(ax2);

% USE BETAS TO PLOT AS ILLUSTRATION BUT MAKE IT CARTOONISH USING SMOOTH

xaxis = linspace(-300,2700,250); % x-axis values
highPU_pupil = nanmean(smoothdata(condiffbin.pebin1(:,1:250),2,"gaussian")); % high perceptual uncertainty
midPU_pupil = nanmean(smoothdata(condiffbin.pebin1(:,1:250),2,"gaussian"))*0.66; % mid perceptual uncertainty
lowPU_pupil = nanmean(smoothdata(condiffbin.pebin1(:,1:250),2,"gaussian"))*0.3; % low perceptual uncertatinty

highPU_pupil(1,highPU_pupil < 0) = 0;
midPU_pupil(1,midPU_pupil < 0) = 0;
lowhPU_pupil(1,lowPU_pupil < 0) = 0;

% PLOT

hold on
plot(xaxis,highPU_pupil,'LineWidth',2,'Color',low_PU)
hold on
plot(xaxis,midPU_pupil,'LineWidth',2,'Color',gray_arrow)
hold on
plot(xaxis,lowPU_pupil,'LineWidth',2,'Color',high_PU)

% l1 = legend('','PE Signal','','Location','best','Color','none', ...
%     'EdgeColor','none','AutoUpdate','off','FontSize',7);
% l1.ItemTokenSize = [7, 7];

hold on
box off
xlabel('Time')
ylabel('Arousal')
xlim([-300,2700])
ylim([-0.005,0.4])
xticks([]); % Remove x-axis ticks
yticks([]); % Remove x-axis ticks
title('PE Encoding in Arousal Signal','FontWeight','normal')
adjust_figprops(ax2_new,font_name,font_size,0.5);
hold on

% ADD ROTATED TEXT BOXES

ypos = [0.71,-0.07,0.208,0.25,0.1]; % position on y-axis
xpos = [0.8,0.8,120,25,25]; % position on x-axis
rotate = [45.5, 0, 0, 90, 90]; % degree of rotation
allstrings = {'LR = 1','LR = 0','','Up-regulation','Down-regulation'};
num_strings = 5;
for n = 3%:num_strings
    txt = text(xpos(n),ypos(n),allstrings{1,n});
    txt.Parent = ax2_new;
    txt.FontSize = font_size-0.3;
    txt.FontWeight = 'normal';
    txt.Rotation = rotate(n);
    txt.LineStyle = '-';
    txt.FontName = font_name;
    txt.HorizontalAlignment = horz_align;
end

%% SUBPLOT LABELS

ax1_pos = ax3_new.Position;
adjust_x = -0.09; % adjust x-position of subplot label
adjust_y = ax1_pos(4) + 0.04; % adjust y-position of subplot label
[label_x,label_y] = change_plotlabel(ax3_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'a','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

[label_x,label_y] = change_plotlabel(ax2_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'b','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

%% SAVE FIGURE

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'hypothesis7.png', '-dpng', '-r600') 
