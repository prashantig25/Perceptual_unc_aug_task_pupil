function [data_base] = base_correction(data,baseline,n)

    % function BASE_CORRECTION baseline corrects using the subtractive
    % method.
    % 
    % INPUT:
    %   data: signal on which baseline correction is to be applied
    %   baseline: baseline signal to be used for the correction
    %   n: length of signal
    %
    % OUTPUT:
    %   data_base: baseline-corrected signal
    
    data_base = zeros(length(baseline),n);
    for i = 1:length(baseline)
        data_base(i,:) = data(i,:) - baseline(i);
    end
end