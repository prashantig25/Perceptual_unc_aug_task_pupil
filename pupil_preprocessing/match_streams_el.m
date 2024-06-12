function pupil_data = match_streams_el(pupil_data, events,event_per_trial, num_trial)
    
    % pupil_data = pupil data after conversion from arbitary units.
    % events = table with events data.
    % pupil_data = output table with events matched.
    pupil_data.serial_num(:,1) = 1:height(pupil_data); 
    % rows in the data table 
    start = ismember(pupil_data.time_stamp,events.time_stamp); 
    
    % identifies the index of rows when the trial has started
    trial_start = find(start(:,:)~=0); 
    
    for i = 1:length(trial_start)-1 
        % event_start for all samples to be changed to the x-position to match
        % the time point at which the trial started
        pupil_data.eventstart(trial_start(i):trial_start(i+1)-1,1) = trial_start(i); 
    end
    % for the last trial
    pupil_data.eventstart(trial_start(length(trial_start)):height(pupil_data),1) = trial_start(length(trial_start));

    % add event name
    for i = 1:length(trial_start)-1 
        % event_start for all samples to be changed to the x-position to match
        % the time point at which the trial started
        pupil_data.events(trial_start(i):trial_start(i+1)-1,1) = events.event(i); 
    end
    % for the last trial
    pupil_data.events(trial_start(length(trial_start)):height(pupil_data),1) = events.event(length(trial_start));
    
    % add event number
    % first trial
    x = 0;
    pupil_data.event_num(1) = x;
    % go through all the cells in the event start column
    for i = 1:height(pupil_data)-1
        if pupil_data.eventstart(i+1) == pupil_data.eventstart(i) % if the event start is the same
            % the event number remains the same
            pupil_data.event_num(i+1) = x;
        else
            % when it changes, the event number increases by 1
            pupil_data.event_num(i+1) = x+1;
            x = x +1;
        end
    end

    pupil_data(pupil_data.event_num == 0,:) = [];
    pupil_data(ismember(pupil_data.events, {'new_block'}) == 1,:) = [];
% 
%     % add trial number
    first_trial = 1;
    range = [first_trial:first_trial+event_per_trial-1];
    pupil_data.trial_num = rand(height(pupil_data),1);
    for t = 1:num_trial
        check = ismember(pupil_data.event_num,range);
        pupil_data.trial_num(check == 1) = repelem(t,height(pupil_data.trial_num(check == 1))).';
        first_trial = first_trial + event_per_trial;
        range = [first_trial:first_trial+event_per_trial-1];
    end

end