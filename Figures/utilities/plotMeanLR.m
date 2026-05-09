function [rho, pval] = plotMeanLR(avg_ydataLR, sem_ydataLR, nbins, binnedDotsColor, yLabelText)
% PLOTMEANLR Plots the mean learning rate across N bins.
%
%   Can be used for agent and subjects.
%
%   INPUT:
%    avg_ydataLR: Mean learning rates
%    sem_ydataLR: SEM learning rates
%    nbins: Number of bins
%    binnedDotsColor: Color for plotting
%    yLabelText: Text for y-axis
%
%   OUTPUT:
%    rho: Correlation coefficient
%    pval: p-value of correlation

% Plot
hold on
errorbar(1:nbins, avg_ydataLR, sem_ydataLR, 'k', 'LineWidth', 1, 'LineStyle', 'none');
scatter(1:nbins, avg_ydataLR, 50, binnedDotsColor, 'filled', 'MarkerEdgeColor', 'k');
lsline

% Calculate correlation
x_data = (1:nbins)';
y_data = avg_ydataLR(1:end);
[rho,pval] = corr(x_data,y_data, 'rows', 'pairwise');

xlabel('Contrast-difference bins');
ylabel(yLabelText);
if pval < 0.001
    pval_str_b = "\itp\rm < 0.001";
else
    pval_str_b = "\itp\rm = " + num2str(round(pval,3));
end
title(strcat("\itr\rm =",{' '},num2str(round(rho,2)),{' '}) + newline + pval_str_b, ...
    'FontWeight','normal','Interpreter','tex');

hold off
set(gca,'FontName','Arial','FontSize',7,'LineWidth',0.5)
end