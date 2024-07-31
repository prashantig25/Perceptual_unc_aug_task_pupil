function y = down_sample(data,n)

    % function DOWN_SAMPLE downsamples the input data by a specified factor.
    %
    % INPUTS:
    %   data: Input data to be downsampled (vector or matrix).
    %   n: Downsampling factor. Every nth data point is retained.
    %
    % OUTPUT:
    %   y: Downsampled data (vector or matrix).

    y = downsample(data,n);
end