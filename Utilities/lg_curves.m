function lg_curves(x, mean_curves, sem_curves, colors_name, legend_names, title_name, ...
    xlabelname, ylabelname, fontsize, linewidth, fontname, legend_pos)
    % function lg_curves plots mean of data across participants, across trials in a block
    %
    % INPUT
    %   x: array containing trial numbers in a block for x-axis
    %   mean_curves: mean, across subjects, for each trial in a block
    %   sem_curves: SEM, across subjects, for each trial in a block
    %   colors_name: matrix with color RGB values for all curves
    %   legend_names: cell array with legend names for each curve
    %   title_name: cell array with title for plot
    %   xlabelname: cell array with label name of x-axis
    %   ylabelname: cell array with label name of y-axis
    %   fontsize: font size of the text
    %   linewidth: line width of the plot
    %   fontname: font of the text
    %   legend_pos: Optional legend position
    %
    % OUTPUT
    %   None
    
    % PLOT MEAN CURVES
    hold on
    hLines = []; % Pre-allocate an array to store the clean line handles
    for i = 1:height(mean_curves)
        hLines(i) = plot(x, mean_curves(i,:), "Color", colors_name(i,:));
    end
    
    % PLOT SHADED ERROR BARS FOR EACH CURVE
    for i = 1:height(mean_curves)
        shadedErrorBar(x,mean_curves(i,:),sem_curves(i,:),{'LineWidth', 2, 'Color',colors_name(i,:)}, 1)
    end

    % ADD/EDIT FIGURE PROPERTIES
    [lgd, hobjs] = legend(hLines, legend_names, "AutoUpdate", "off", 'Location', 'best',...
        'Box', 'off', 'Color', 'none', 'EdgeColor', 'none', 'FontSize', fontsize);

    % Check if legend position was provided
    if ~isempty(legend_pos)
        lgd.Position = legend_pos; 
    end

    % Thicker legend lines
    legLines = findobj(hobjs, 'type', 'line');
    set(legLines, 'LineWidth', 2.0);
    
    box off
    title(title_name)
    xlabel(xlabelname)
    ylabel(ylabelname)
    set(gca,'LineWidth',linewidth)
    set(gca,'fontname',fontname) 
    pl = gca;
    pl.FontSize = fontsize;
end