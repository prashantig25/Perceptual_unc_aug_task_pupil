function plotMeanLR(avg_ydataLR, sem_ydataLR, nbins, binnedDotsColor, yLabelText)
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

% Plot
hold on
errorbar(1:nbins, avg_ydataLR, sem_ydataLR, 'k', 'LineWidth', 1, 'LineStyle', 'none');
scatter(1:nbins, avg_ydataLR, 50, binnedDotsColor, 'filled', 'MarkerEdgeColor', 'k');
lsline

% Calculate correlation
x_data_b = 1:nbins;
y_data_b = avg_ydataLR(1:end)';
[rho_b, pval_b] = corrcoef(x_data_b', y_data_b');

xlabel('Contrast-difference bins');
ylabel(yLabelText);
if pval_b(1,2) < 0.001
    pval_str_b = "\itp\rm < 0.001";
else
    pval_str_b = "\itp\rm = " + num2str(round(pval_b(1,2),3));
end
title(strcat("\itr\rm =",{' '},num2str(round(rho_b(1,2),2)),{' '}) + newline + pval_str_b, ...
    'FontWeight','normal','Interpreter','tex');

hold off
set(gca,'FontName','Arial','FontSize',7,'LineWidth',0.5)
% ylim([0, 0.12])
end