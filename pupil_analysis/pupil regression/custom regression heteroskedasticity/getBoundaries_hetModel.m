%% Script: Calculate Symmetric Parameter Bounds for Heterogeneous Models
% This script computes symmetric min/max bounds for parameter estimates
% from three different modeling approaches: linear interpolation, cubic
% spline, and deconvolution. Bounds are set to ±width × max_absolute_value
% for each coefficient.

%% Initialize Workspace
clc         % Clear command window
clearvars   % Clear all variables from workspace

%% Configuration
width = 3;              % Scaling factor for bounds (±width × max_abs_value)
ncoeffs = 1:10;        % Coefficient indices to process

%% Process Linear Interpolation Model
fprintf('Processing Linear Interpolation parameters...\n');
betas_struct = importdata("param_estimates_hetero_noZeroPE_linearInt.mat");
[minCoeff, maxCoeff] = calculateSymmetricBounds(betas_struct, ncoeffs, width);

% Save results
safe_saveall("minHetParams_linearIntabs.mat", minCoeff);
safe_saveall("maxHetParams_linearIntabs.mat", maxCoeff);

%% Process Cubic Spline Model
fprintf('Processing Cubic Spline parameters...\n');
betas_struct = importdata("param_estimates_hetero_noZeroPE_cubicSplineNew.mat");
[minCoeff, maxCoeff] = calculateSymmetricBounds(betas_struct, ncoeffs, width);

% Save results
safe_saveall("minHetParams_CSabs.mat", minCoeff);
safe_saveall("maxHetParams_CSabs.mat", maxCoeff);

%% Process Deconvolution Model
fprintf('Processing Deconvolution parameters...\n');
betas_struct = importdata("param_estimates_hetero_noZeroPE_deconvolution.mat");
[minCoeff, maxCoeff] = calculateSymmetricBounds(betas_struct, ncoeffs, width);

% Save results
safe_saveall("minHetParams_deconvolutionabs.mat", minCoeff);
safe_saveall("maxHetParams_deconvolutionabs.mat", maxCoeff);

fprintf('All bounds calculated and saved successfully.\n');

%% Helper Function: Calculate Symmetric Bounds
function [minCoeff, maxCoeff] = calculateSymmetricBounds(betas_struct, ncoeffs, width)
    % CALCULATESYMMETRICBOUNDS Compute symmetric min/max bounds for coefficients
    %
    % Inputs:
    %   betas_struct - Parameter estimates array (subjects × coeffs × bins)
    %   ncoeffs      - Vector of coefficient indices to process
    %   width        - Scaling factor for bounds
    %
    % Outputs:
    %   minCoeff     - Minimum bounds for each coefficient
    %   maxCoeff     - Maximum bounds for each coefficient
    
    % Preallocate output arrays
    minCoeff = NaN(length(ncoeffs), 1);
    maxCoeff = NaN(length(ncoeffs), 1);
    
    % Loop through each coefficient
    for a = 1:length(ncoeffs)
        coeff_idx = ncoeffs(a);
        
        % Extract data for current coefficient across all subjects and bins
        data_plot = squeeze(betas_struct(:, coeff_idx, :));
        
        % Find the maximum absolute value across all entries
        max_abs_val = max(abs(data_plot(:)));
        
        % Create symmetric bounds: ±width × max_abs_value
        minCoeff(a) = round(-width * max_abs_val);
        maxCoeff(a) = round(width * max_abs_val);
    end
end