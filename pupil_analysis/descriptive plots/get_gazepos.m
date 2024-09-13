function [xgaze_event,ygaze_event]= get_gazepos(time_pupil,xgaze_event,ygaze_event, ...
    event_name,num_trials,data,trial_list,pre_duration)

        % funtion GET_GAZEPOS returns gaze position
        % response for an event/
        %
        % INPUT:
        %   time_pupil: duration for each event
        %   xgaze_event: initialised cell array to store x-gaze position
        %   ygaze_event: initialised cell array to store y-gaze response
        %   event_name: specified event name (choice,response,feedback,full)
        %   num_trials: number of trials
        %   data: preprocessed pupil data
        %   trial_list: list of trials
        %   pre_duration: duration for pre-event signal
        %
        % OUTPUT:
        %   xgaze_event: cell array with x-gaze position
        %   ygaze_event: cell array with y-gaze position

        % STORE EVENT NAMES AS NUMBER
        data.event_code = zeros(height(data), 1);  % Pre-allocate the event_code column
        data.event_code(strcmp(data.events, 'trial_start')) = 1;
        data.event_code(strcmp(data.events, 'instructed_delay_start')) = 3;
        data.event_code(strcmp(data.events, 'patches_start')) = 2;
        data.event_code(strcmp(data.events, 'response_start')) = 4;
        data.event_code(strcmp(data.events, 'feedback_start')) = 6;
        data.event_code(strcmp(data.events, 'slider_start')) = 8;
        data.event_code(strcmp(data.events, 'delay_start')) = 5;
        data.event_code(strcmp(data.events, 'delay1_start')) = 7;

        % LOOP OVER NUMBER OF TRIALS
        for j = 1:num_trials

            % USE EVENT CODE TO GET PREPROCESSED DATA
            xgaze_patch = data.xgaze(and(data.event_code == 2,data.trial == trial_list(j))); % patch locked
            xgaze_resp = data.xgaze(and(data.event_code == 4,data.trial == trial_list(j))); % go cue locked
            xgaze_fb = data.xgaze(and(data.event_code == 6,data.trial == trial_list(j))); % feedback locked
            xgaze_inst_delay = data.xgaze(and(data.event_code == 3,data.trial == trial_list(j))); % instructed delay locked
            xgaze_slider = data.xgaze(and(data.event_code == 8,data.trial == trial_list(j))); % slider locked
            xgaze_delay = data.xgaze(and(data.event_code == 5,data.trial == trial_list(j))); % pre-fb delay locked
            xgaze_delay1 = data.xgaze(and(data.event_code == 7,data.trial == trial_list(j))); % post-fb delay locked
            xgaze_patch_base = data.xgaze(and(data.event_code == 1,data.trial == trial_list(j))); % pre-patch locked

            ygaze_patch = data.ygaze(and(data.event_code == 2,data.trial == trial_list(j))); % patch locked
            ygaze_resp = data.ygaze(and(data.event_code == 4,data.trial == trial_list(j))); % go cue locked
            ygaze_fb = data.ygaze(and(data.event_code == 6,data.trial == trial_list(j))); % feedback locked
            ygaze_inst_delay = data.ygaze(and(data.event_code == 3,data.trial == trial_list(j))); % instructed delay locked
            ygaze_slider = data.ygaze(and(data.event_code == 8,data.trial == trial_list(j))); % slider locked
            ygaze_delay = data.ygaze(and(data.event_code == 5,data.trial == trial_list(j))); % pre-fb delay locked
            ygaze_delay1 = data.ygaze(and(data.event_code == 7,data.trial == trial_list(j))); % post-fb delay locked
            ygaze_patch_base = data.ygaze(and(data.event_code == 1,data.trial == trial_list(j))); % pre-patch locked

            if strcmp(event_name,'choice') == 1
                xgaze_patch_event = [xgaze_patch;xgaze_inst_delay;xgaze_resp;xgaze_delay;]; % multiple trial events post patch
                xgaze_pre_patch = xgaze_patch_base(end-pre_duration:end); % get pre-patch pupil signal
                xgaze_patch_event = [xgaze_pre_patch;xgaze_patch_event]; % combine pre- and post- signal
                xgaze_event(j,:) = xgaze_patch_event(1:time_pupil); % get signal for a specific duration

                ygaze_patch_event = [ygaze_patch;ygaze_inst_delay;ygaze_resp;ygaze_delay;]; % multiple trial events post patch
                ygaze_pre_patch = ygaze_patch_base(end-pre_duration:end); % get pre-patch pupil signal
                ygaze_patch_event = [ygaze_pre_patch;ygaze_patch_event]; % combine pre- and post- signal
                ygaze_event(j,:) = ygaze_patch_event(1:time_pupil); % get signal for a specific duration
            elseif strcmp(event_name,'response') == 1 % response-locked
                xgaze_resp_event = [xgaze_resp;xgaze_delay;xgaze_fb;xgaze_delay1;xgaze_slider];
                xgaze_pre_resp = [xgaze_patch_base;xgaze_patch;xgaze_inst_delay;];
                xgaze_pre_resp = xgaze_pre_resp(end-pre_duration:end);
                xgaze_resp_event = xgaze_resp_event(1:time_pupil);
                xgaze_resp_event = [xgaze_pre_resp; xgaze_resp_event(1:end-30)];
                xgaze_event(j,:) = xgaze_resp_event;

                ygaze_resp_event = [ygaze_resp;ygaze_delay;ygaze_fb;ygaze_delay1;ygaze_slider];
                ygaze_pre_resp = [ygaze_patch_base;ygaze_patch;ygaze_inst_delay;];
                ygaze_pre_resp = ygaze_pre_resp(end-pre_duration:end);
                ygaze_resp_event = ygaze_resp_event(1:time_pupil);
                ygaze_resp_event = [ygaze_pre_resp; ygaze_resp_event(1:end-30)];
                ygaze_event(j,:) = ygaze_resp_event;
            elseif strcmp(event_name,'feedback') == 1 % feedback locked
                xgaze_fb_event = [xgaze_fb;xgaze_delay1;xgaze_slider]; %(1:140)
                xgaze_pre_fb = [xgaze_resp;xgaze_delay];
                xgaze_pre_fb = xgaze_pre_fb(end-pre_duration:end);
                xgaze_post_fb = [xgaze_delay1;xgaze_slider;];
                xgaze_fb_event = [xgaze_pre_fb;xgaze_fb_event];
                if length(xgaze_fb_event) < time_pupil
                    xgaze_event(j,1:length(xgaze_fb_event)) = xgaze_fb_event;
                else
                    xgaze_event(j,1:1000) = xgaze_fb_event(1:time_pupil);
                end 

                ygaze_fb_event = [ygaze_fb;ygaze_delay1;ygaze_slider]; %(1:140)
                ygaze_pre_fb = [ygaze_resp;ygaze_delay];
                ygaze_pre_fb = ygaze_pre_fb(end-pre_duration:end);
                ygaze_post_fb = [ygaze_delay1;ygaze_slider;];
                ygaze_fb_event = [ygaze_pre_fb;ygaze_fb_event];
                if length(ygaze_fb_event) < time_pupil
                    ygaze_event(j,1:length(ygaze_fb_event)) = ygaze_fb_event;
                else
                    ygaze_event(j,1:1000) = ygaze_fb_event(1:time_pupil);
                end 
            end
        end
end