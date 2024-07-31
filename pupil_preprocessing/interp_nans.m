function [p_out,p_nans] = interp_nans(p_in,badsmps)

    % function INTERP_NANS innterpolates NaN values in the input data 
    % within specified blink windows.
    %
    % INPUTS:
    %   p_in: Input data vector containing pupil measurements.
    %   badsmps: Matrix specifying blink windows, where each row contains
    %             start and end indices of a blink window (size Nx2).
    %
    % OUTPUT:
    %   p_out: Output data vector with NaN values interpolated and extrapolated.
    %   p_nans: Indices of NaN values in the input data vector after setting
    %            NaNs within blink windows.
    
    % REPLACE BLINKS WITH NaNs
    for b = 1:size(badsmps,1),
        p_in(badsmps(b,1):badsmps(b,2)) = NaN;
    end
    
    % STORE INDICES OF NaNs
    p_nans = find(isnan(p_in));
    
    % INTERPOLATE
    p_in(isnan(p_in)) = interp1(find(~isnan(p_in)), ...
        p_in(~isnan(p_in)), find(isnan(p_in)), 'linear');
    
    % EXTERPOLATE ENDS
    p_in(isnan(p_in)) = interp1(find(~isnan(p_in)), ...
        p_in(~isnan(p_in)), find(isnan(p_in)), 'nearest', 'extrap');
    
    % STORE OUTPUT
    p_out = p_in;
end