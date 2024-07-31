function [tp_blinks, tp_sacc, blink_ends, pupil] = check_blinks_saccades(samp_pupil, interval, ...
    deconv_freq, blink_ends, sacc_ends,tp_blinks,tp_sacc)

    % function CHECK_BLINKS_SACCADES check and remove blinks and saccades 
    % that exceed the deconvolution time window or occur too early.
    %
    % Inputs:
    %   blinksmp: Array containing blink positions
    %   data_asc: Struct containing saccade positions (saccsmp)
    %   samp_pupil: Sampled pupil data
    %   interval: Interval for deconvolution
    %   deconv_freq: Deconvolution frequency
    %   sampling_rate: Sampling rate of the data in Hz
    %
    % Outputs:
    %   tp_blinks: Cleaned blink times
    %   tp_sacc: Cleaned saccade times
    %   blink_ends: Cleaned blink end times
    %   pupil: Sampled pupil data after cleaning

    % CHECK BLINKS/SACCADES ENDS THAT EXCEED THE DECONVOLUTION TIME WINDOW
    del_blinks = []; % empty array for blinks that need to be deleted
    for h = 1:length(blink_ends)
        % check if time window after blink is beyond the number of samples
        if blink_ends(h) + (interval * deconv_freq) > length(samp_pupil)
            del_blinks = [del_blinks; h];
        end
    end

    del_sacc = []; % empty array for saccades that need to be deleted
    for h = 1:length(sacc_ends)
        % check if time window after saccade is beyond the number of samples
        if sacc_ends(h) + (interval * deconv_freq) > length(samp_pupil)
            del_sacc = [del_sacc; h];
        end
    end

    % SIMILARLY, REMOVE BLINKS/SACCADES THAT HAPPEN TOO EARLY ON IN THE TASK
    if tp_blinks(1) < 1 
        del_blinks = [del_blinks; 1]; % add to array of blinks that need to be deleted
    end

    % REMOVE THE BLINKS THAT NEED TO BE DELETED
    tp_blinks(del_blinks, :) = [];
    blink_ends(del_blinks, :) = [];

    % HANDLE SACCADES
    if tp_sacc(1) < 1
        del_sacc = [del_sacc; 1]; % add to array of saccades that need to be deleted
    end

    % DELETE SACCADES
    tp_sacc(del_sacc, :) = [];

    % CLEANED DATA
    pupil = samp_pupil;
end
