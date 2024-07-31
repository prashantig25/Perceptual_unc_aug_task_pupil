function [pupilcopy, Xgazecopy2, Ygazecopy2, blinksmp] = process_blinks(data_asc, data_matched, sampling_rate, coalesce1, padding1)

    % function PROCESS_BLINKS process and interpolate blinks in eye-tracking data
    % 
    % INPUTS:
    %   data_asc: Struct containing blink positions (blinksmp)
    %   data_matched: Struct containing pupil diameter and gaze coordinates
    %   sampling_rate: Sampling rate of the data in Hz
    %   coalesce1: maximum distance in seconds to be considered before merging
    %   adjacent blinks into 1
    %   padding1: duration before and after a blink for padding
    %
    % OUTPUTS:
    %   pupilcopy: Interpolated pupil diameter
    %   Xgazecopy2: Interpolated x gaze coordinates
    %   Ygazecopy2: Interpolated y gaze coordinates

    blinksmp = data_asc.blinksmp; % get blink positions

    % MERGE BLINKS
    if ~isempty(blinksmp)
        cblinksmp = blinksmp(1,:);
        for b = 1:size(blinksmp,1)-1
            if blinksmp(b+1,1) - cblinksmp(end,2) < coalesce1 * sampling_rate
                cblinksmp(end,2) = blinksmp(b+1,2);
            else
                cblinksmp(end+1,:) = blinksmp(b+1,:); % todo: deal with preallocation
            end
        end
        blinksmp = cblinksmp;
        clear cblinksmp
    end

    % PAD THE BLINKS
    padblinksmp(:,1) = round(blinksmp(:,1) + padding1(1) * sampling_rate);
    padblinksmp(:,2) = round(blinksmp(:,2) + padding1(2) * sampling_rate);

    % AVOID INDEX OUTSIDE RANGE
    if any(padblinksmp(:) < 1)
        padblinksmp(padblinksmp < 1) = 1; % todo: deal with preallocation
    end

    if any(padblinksmp(:) > length(data_matched.pupil_diam))
        padblinksmp(padblinksmp > length(data_matched.pupil_diam)) = length(data_matched.pupil_diam);
    end

    % CONVERT ALL MISSING SAMPLES TO NaNs
    data_matched.pupil_diam(data_matched.pupil_diam == 0,1) = NaN;

    % CREATE COPIES
    pupilcopy = data_matched.pupil_diam;
    Xgazecopy = data_matched.eye_x;
    Ygazecopy = data_matched.eye_y;

    % INTERPOLATE
    [pupilcopy,~] = interp_nans(pupilcopy, padblinksmp); % pupil
    [Xgazecopy2,~] = interp_nans(Xgazecopy, padblinksmp); % x gaze coordinates
    [Ygazecopy2,~] = interp_nans(Ygazecopy, padblinksmp); % y gaze coordinates

    % MAKE SURE ALL NaNs have been dealt with
    assert(~any(isnan(pupilcopy)));
    assert(~any(pupilcopy == 0));
end