function [pupil_event,base_event]= get_pupil_event(time_pupil,pupil_event,base_event, ...
    event_name,num_trials,data,trial_list,trial_base,pre_duration,base_duration)

        % funtion GET_PUPIL_EVENT returns non-baseline corrected pupil
        % response for an event or full trial and baseline signal for an
        % event or full trial.
        %
        % INPUT:
        %   time_pupil: duration for each event
        %   pupil_event: initialised cell array to store pupil response
        %   base_event: initialised cell array to store pupil response
        %   event_name: specified event name (choice,response,feedback,full)
        %   num_trials: number of trials
        %   data: preprocessed pupil data
        %   trial_list: list of trials
        %   trial_base: get trial-specific baseline
        %   pre_duration: duration for pre-event signal
        %   base_duration: duration for baseline
        %
        % OUTPUT:
        %   pupil_event: cell array with pupil response for an event/trial
        %   base_event: cell array with baseline response

        % STORE EVENT NAMES AS NUMBERS
        for i = 1:height(data)
            if strcmp(data.events(i),'trial_start')
                data.event_code(i) = 1;
            elseif strcmp(data.events(i),'instructed_delay_start')
                    data.event_code(i) = 3;
            elseif strcmp(data.events(i),'patches_start')
                  data.event_code(i) = 2;
            elseif strcmp(data.events(i),'response_start')
                data.event_code(i) = 4;
            elseif strcmp(data.events(i),'feedback_start')
                data.event_code(i) = 6;
            elseif strcmp(data.events(i),'slider_start')
            data.event_code(i) = 8;
            elseif strcmp(data.events(i),'delay_start')
                data.event_code(i) = 5;
            elseif strcmp(data.events(i),'delay1_start')
                data.event_code(i) = 7;
            end
        end

        % LOOP OVER NUMBER OF TRIALS
        for j = 1:num_trials

            % USE EVENT CODE TO GET PREPROCESSED DATA
            pupil_patch = data.pupil_zsc(and(data.event_code == 2,data.trial == trial_list(j))); % patch locked
            pupil_resp = data.pupil_zsc(and(data.event_code == 4,data.trial == trial_list(j))); % go cue locked
            pupil_fb = data.pupil_zsc(and(data.event_code == 6,data.trial == trial_list(j))); % feedback locked
            pupil_inst_delay = data.pupil_zsc(and(data.event_code == 3,data.trial == trial_list(j))); % instructed delay locked
            pupil_slider = data.pupil_zsc(and(data.event_code == 8,data.trial == trial_list(j))); % slider locked
            pupil_delay = data.pupil_zsc(and(data.event_code == 5,data.trial == trial_list(j))); % pre-fb delay locked
            pupil_delay1 = data.pupil_zsc(and(data.event_code == 7,data.trial == trial_list(j))); % post-fb delay locked
            pupil_patch_base = data.pupil_zsc(and(data.event_code == 1,data.trial == trial_list(j))); % pre-patch locked

            if strcmp(event_name,'choice') == 1
                pupil_patch_event = [pupil_patch;pupil_inst_delay;pupil_resp;pupil_delay;]; % multiple trial events post patch
                pupil_pre_patch = pupil_patch_base(end-pre_duration:end); % get pre-patch pupil signal
                pupil_patch_event = [pupil_pre_patch;pupil_patch_event]; % combine pre- and post- signal
                pupil_event(j,:) = pupil_patch_event(1:time_pupil); % get signal for a specific duration
                pupil_base_patch = pupil_patch_base(end-(pre_duration+base_duration):end-pre_duration+1); % get baseline signal
                if trial_base == 0 % store event-specific baseline
                    base_event(j,:) = pupil_base_patch;
                end
            elseif strcmp(event_name,'response') == 1 % response-locked
                pupil_resp_event = [pupil_resp;pupil_delay;pupil_fb;pupil_delay1;pupil_slider];
                pupil_pre_resp = [pupil_patch_base;pupil_patch;pupil_inst_delay;];
                pupil_base_resp = pupil_pre_resp(end-(pre_duration+base_duration):end-pre_duration+1);
                pupil_pre_resp = pupil_pre_resp(end-pre_duration:end);
                pupil_resp_event = pupil_resp_event(1:time_pupil);
                pupil_resp_event = [pupil_pre_resp; pupil_resp_event(1:end-30)];
                pupil_event(j,:) = pupil_resp_event;
                if trial_base == 0
                    base_event(j,:) = pupil_base_resp;
                end
            elseif strcmp(event_name,'full') == 1 % full trial
                pupil_pre_patch = pupil_patch_base(end-pre_duration:end);
                pupil_full = [pupil_pre_patch;pupil_patch;pupil_inst_delay;pupil_resp;pupil_delay;];
                pupil_event(j,:) = pupil_full(1:time_pupil);
                pupil_base_patch = pupil_patch_base(end-(pre_duration+base_duration):end-pre_duration+1);
                if trial_base == 0
                    base_event(j,:) = pupil_base_patch;
                end
            elseif strcmp(event_name,'feedback') == 1 % feedback locked
                pupil_fb_event = [pupil_fb;pupil_delay1;pupil_slider]; %(1:140)
                pupil_pre_fb = [pupil_resp;pupil_delay];
                pupil_base_fb = pupil_pre_fb(end-(pre_duration+base_duration+1):end-(pre_duration+1));
                pupil_pre_fb = pupil_pre_fb(end-pre_duration:end);
                pupil_post_fb = [pupil_delay1;pupil_slider;];
                pupil_fb_event = [pupil_pre_fb;pupil_fb_event];
                if length(pupil_fb_event) < time_pupil
                    pupil_event(j,1:length(pupil_fb_event)) = pupil_fb_event;
                else
                    pupil_event(j,1:1000) = pupil_fb_event(1:time_pupil);
                end 
                if trial_base == 0
                    base_event(j,:) = pupil_base_fb;
                end
            elseif strcmp(event_name,'tonic_prefb') == 1
                pupil_pre_fb = [pupil_resp;pupil_delay];
                pupil_pre_fb = pupil_pre_fb(end-200:end);
                pupil_event(j,:) = pupil_pre_fb(1:time_pupil);
            end

            % GET TRIAL-SPECIFIC BASELINE
            pupil_base_patch = pupil_patch_base(end-base_duration:end);
            if trial_base == 1
                base_event(j,:) = pupil_base_patch;
            end
        end
end