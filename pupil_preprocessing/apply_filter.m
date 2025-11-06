function [high_pupil, low_pupil, band_pupil] = apply_filter(pupilcopy, sampling_rate, freqs)

    % function APPLY_FILTER apply high-pass, low-pass, and band-pass filters to pupil data
    %
    % INPUTS:
    %   pupilcopy: Array containing the pupil data
    %   sampling_rate: Sampling rate of the data in Hz
    %   freqs: Array containing cutoff frequencies for high-pass and low-pass filters
    %
    % OUTPUTS:
    %   high_pupil: High-pass filtered pupil data
    %   low_pupil: Low-pass filtered pupil data
    %   band_pupil: Band-pass filtered pupil data

    % High-pass filter
    [bfilt, afilt] = butter(3, freqs(1)/(sampling_rate/2), 'high');
    high_pupil = filtfilt(bfilt, afilt, pupilcopy);

    % Low-pass filter
    [bfilt, afilt] = butter(3, freqs(2)/(sampling_rate/2), 'low');
    low_pupil = filtfilt(bfilt, afilt, pupilcopy);

    % Band-pass filter (using the previously high-pass filtered data)
    band_pupil = filtfilt(bfilt, afilt, high_pupil);
end