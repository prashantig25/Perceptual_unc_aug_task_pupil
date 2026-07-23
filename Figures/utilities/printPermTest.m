function printPermTest(perm, xaxis, coeff, pval_position, pval_sign, pval_text_dist, font_size, font_name, two_sided)
%PRINTPERMTEST This function plots the significant cluster and p-value for
%the pupil data
%
%   Input
%       perm: Permutation-test results
%       xaxis: Plot x-axis
%       coeff: Coefficient of interest
%       pval_position: p-value y-position
%       pval_sign: Whether p-value is above or below the significance line
%       pval_text_dist: Distance to significance line
%       font_size: Font size
%       font_name: Font name
%       two_sided: Optional one- vs. two-sided (default: two-sided)

% Manage optional permutation test input
if ~exist('two_sided', 'var') || isempty(two_sided)
    two_sided = true;
end

% Plot mask of significant cluster(s)
if two_sided
    plot(xaxis(find(perm.mask(coeff,:) == 1)), pval_position*ones(1, length(find(perm.mask(coeff,:) == 1))), '.', 'color', ...
        [119, 119, 119]./255, 'markersize', 4);
else
    plot(xaxis(find(perm.prob(coeff,:) < 0.05)), pval_position*ones(1, length(find(perm.prob(coeff,:) < 0.05))), '.', 'color', ...
        [119, 119, 119]./255, 'markersize', 4);
end

% Extract p-value
p_val = min(unique(perm.prob(coeff, perm.prob(coeff,:) < 0.05)));

% Place text under consideration of the axes limits for normalized
% positioning
y_limits = ylim;
y_norm = (pval_position - y_limits(1)) / (y_limits(2) - y_limits(1));
x_limits = xlim;
x_pos = mean(xaxis(perm.prob(coeff, :) < 0.05));
x_norm = (x_pos - x_limits(1)) / (x_limits(2) - x_limits(1));
if p_val < 0.001
    text(x_norm, y_norm + pval_sign * pval_text_dist, "\itp\rm < 0.001","FontSize", font_size, "FontName", font_name, "VerticalAlignment","middle", "HorizontalAlignment", "center", "Units", "normalized"); %
elseif p_val < 0.05
    text(x_norm, y_norm + pval_sign * pval_text_dist, strcat("\itp\rm = ", num2str(round(p_val, 3))), "FontSize", font_size, "FontName", font_name, "VerticalAlignment", "middle", "HorizontalAlignment", "center",  "Units", "normalized");
end
end