function [data] = events_trialnums(data,events,event_per_trial,num_trial)

    % function EVENTS_TRIALNUMS returns pre-processed data with event names
    % and trial numbers.
    % 
    % INPUT:
    %   data: preprocessed data
    %   events: table with event relate information from EL file
    %   event_per_trial: number of unique events in a trial
    %   num_trial: number of trials within a recording session
    %
    % OUTPUT:
    %   data: preprocessed data with event names and trial numbers

    % MATCH EVENT NAMES WITH EVENT STARTING TIME
    event_indices = find(data.time_stamp > events.time_stamp(1) & data.time_stamp < events.time_stamp(2));
    for v = 1:height(events)
        if v < height(events) % for all events except the last one
            event_indices = find(data.time_stamp >= events.time_stamp(v) & data.time_stamp < events.time_stamp(v+1));
            data.events(event_indices) = events.event(v);
        elseif v == height(events) % last event
            event_indices = find(data.time_stamp >= events.time_stamp(v));
            data.events(event_indices) = events.event(v);
        end
    end
    beforetask_indices = find(data.time_stamp < events.time_stamp(1)); 
    data(beforetask_indices,:) = []; % remove samples before task starts
    
    % ADD EVENT NUMBER
    event_num = 1;
    data.event_num(1) = event_num;
    % go through all the cells in the event start column
    for i = 1:height(data)-1
        if strcmp(data.events(i+1),data.events(i)) == 1 % if the event start is the same
            % the event number remains the same
            data.event_num(i+1) = event_num;
        else
            % when it changes, the event number increases by 1
            data.event_num(i+1) = event_num+1;
            event_num = event_num +1;
        end
    end
    
    data(data.event_num == 0,:) = [];
    data(ismember(data.events, {'new_block'}) == 1,:) = [];
    
    % ADD TRIAL NUMBER
    first_trial = 1;
    range = [first_trial:event_per_trial]; % array of events in a trial
    data.trial_num = rand(height(data),1); % initialise column
    for t = 1:num_trial % for each trial
        check = ismember(data.event_num,range);
        data.trial_num(check == 1) = repelem(t,height(data.trial_num(check == 1))).';
        first_trial = first_trial + event_per_trial; % next trial
        range = [first_trial:first_trial+event_per_trial];
    end
end