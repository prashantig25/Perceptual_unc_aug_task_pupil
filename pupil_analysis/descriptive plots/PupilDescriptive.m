classdef PupilDescriptive
    %PUPILDESCRIPTIVE Descriptive pupil analyses
    %
    % Shared properties and methods for descriptive analyses of pupil data
    % including average curves and condition differences

    properties

        num_sess % number of sessions for each participant
        subj_ids % cell array with subject IDs
        behv_dir % directory to get behavioral data
        preproc_dir % directory to get preprocessed data
        regress_rt % whether RT to be regressed from pupil signal
        time_base % duration of baseline
        pre_duration % pre-event duration
        base_duration % duration of baseline

    end

    methods
        function obj = PupilDescriptive()
            %PUPILDESCRIPTIVE Construct an instance of the PupilDescriptive class

            obj.num_sess = nan;
            obj.subj_ids = nan;
            obj.behv_dir = nan;
            obj.preproc_dir = nan;
            obj.regress_rt = false;
            obj.time_base = nan;
            obj.pre_duration = nan;
            obj.base_duration = nan;
        end

        function [pupil, sliderOnset] = run_PupilSignal(obj, subjNum, time_pupil, event_name,...
                baseline, main)
            % RUN_PUPILSIGNAL Gets event-specific pupil signal for each of the
            % specified events.
            %
            % INPUT:
            %   subNum: Subject number
            %   time_pupil: Duration of pupil signal
            %   event_name: Event name for which signal is being extracted
            %   baseline: Type of baseline: "trial-specific, "event-specific" or "no baseline"
            %   main: If using preprocessed signal from the main analysis
            %
            % OUPUT:
            %   pupil: Pupil signal
            %   sliderOnset: XXXX

            % Load behavioral data
            behvData = obj.loadBehavioralData(subjNum);

            % Number of trials
            nTrials = length(behvData.condition);

            % Missed trials
            missedtrials = ~isnan(behvData.rt);
            behvData(missedtrials == 0,:) = []; % remove missed trials

            % Load pupil data
            pupilData = obj.loadPupilData(subjNum);

            % Todo: rethink this, feels dangerous?
            % and integrate deconvolution pipeline.
            if main == 1
                pupilData.pupil_zsc = pupilData.pupil_cleaned;
            end

            % GET EVENT-LOCKED PUPIL SIGNAL
            [pupil_event, base_event, sliderOnset] = obj.get_pupil_event(time_pupil, event_name, ...
                pupilData, baseline);

            % BASELINE CORRECTION

            % Perform the baseline correction, if required
            if baseline == "no correction"
                pupil = pupil_event;
            elseif any(baseline == ["event-specific", "trial-specific"])

                % Initialise array to store mean of baseline pupil
                base_event_mean = zeros(nTrials,1);

                % Extract baseline for each trial
                for i = 1:nTrials
                    base_event_mean(i) = mean(base_event(i,:));
                end
                pupil = base_correction(pupil_event, base_event_mean, time_pupil); 

            else
                error('Variable "baseline" is undefined. Please initialize properly before running this script.');
            end

            % Remove pupil response of missed trials
            pupil(missedtrials == 0,:) = [];

            % todo: used at all?
            if obj.regress_rt == 1 % regress out RT
                for c = 1:col
                    pupil(:,c) = remove_rt_effects(pupil(:,c),log(behvData.rt));
                end
            end
        end

        function [pupil_event, base_event, sliderOnset] = get_pupil_event(obj, time_pupil, ...
                event_name, pupilData, trial_base)
            % GET_PUPIL_EVENT Returns non-baseline-corrected pupil
            % response for an event or full trial. It also returns the baseline signal for an
            % event or full trial.
            %
            % INPUT:
            %   time_pupil: Duration for each event
            %   event_name: Specified event name (choice, response, feedback, full)
            %   data: Preprocessed pupil data
            %   trial_list: List of trials
            %   trial_base: Get trial-specific baseline
            %
            % OUTPUT:
            %   pupil_event: Pupil response for an event/trial
            %   base_event: Baseline response
            %   sliderOnset: Slider onset

            trialList = unique(pupilData.trial);
            nTrials = max(trialList);

            % Initialize variables
            pupil_event = NaN(nTrials,time_pupil); % pupil data
            base_event = zeros(nTrials, obj.time_base); % baseline pupil data

            % Event-name numbers
            trial_start = 1;
            patches_start = 2;
            instructed_delay_start = 3;
            response_start = 4;
            delay_start = 5;
            feedback_start = 6;
            delay1_start = 7;
            slider_start = 8;

            % STORE EVENT NAMES AS NUMBERS
            pupilData.event_code = zeros(height(pupilData), 1);  % Pre-allocate the event_code column
            pupilData.event_code(pupilData.events == "trial_start") = trial_start;
            pupilData.event_code(pupilData.events == "patches_start") = patches_start;
            pupilData.event_code(pupilData.events == "instructed_delay_start") = instructed_delay_start;
            pupilData.event_code(pupilData.events == "response_start") = response_start;
            pupilData.event_code(pupilData.events == "delay_start") = delay_start;
            pupilData.event_code(pupilData.events == "feedback_start") = feedback_start;
            pupilData.event_code(pupilData.events == "delay1_start") = delay1_start;
            pupilData.event_code(pupilData.events == "slider_start") = slider_start;
            sliderOnset = NaN(nTrials,1);

            % LOOP OVER NUMBER OF TRIALS
            for j = 1:nTrials

                % USE EVENT CODE TO GET PREPROCESSED DATA
                % ---------------------------------------

                % Pre-patch locked
                pupil_patch_base = pupilData.pupil_zsc(and(pupilData.event_code == trial_start, pupilData.trial == trialList(j)));

                % Patch locked
                pupil_patch = pupilData.pupil_zsc(and(pupilData.event_code == patches_start, pupilData.trial == trialList(j)));

                % Instructed-delay locked
                pupil_inst_delay = pupilData.pupil_zsc(and(pupilData.event_code == instructed_delay_start, pupilData.trial == trialList(j)));

                % Go-cue locked
                pupil_resp = pupilData.pupil_zsc(and(pupilData.event_code == response_start, pupilData.trial == trialList(j)));

                % Feedback locked
                pupil_fb = pupilData.pupil_zsc(and(pupilData.event_code == feedback_start, pupilData.trial == trialList(j)));

                % Pre-feedback-delay locked
                pupil_delay = pupilData.pupil_zsc(and(pupilData.event_code == delay_start, pupilData.trial == trialList(j)));

                % Post-feeback-delay locked
                pupil_delay1 = pupilData.pupil_zsc(and(pupilData.event_code == delay1_start, pupilData.trial == trialList(j)));

                % Slider locked
                pupil_slider = pupilData.pupil_zsc(and(pupilData.event_code == slider_start, pupilData.trial == trialList(j)));

                % Choice locked
                if event_name == "choice"

                    % Choice- and patch-locked time course
                    pupil_patch_event = [pupil_patch; pupil_inst_delay; pupil_resp; pupil_delay];

                    % Get pre-patch pupil signal
                    % todo: didn't we use +1 after pre_duration below?
                    pupil_pre_patch = pupil_patch_base(end-obj.pre_duration:end);

                    % Add pre-patch to patch-locked time course
                    pupil_patch_event = [pupil_pre_patch; pupil_patch_event];

                    % Get signal for time window of interest
                    pupil_event(j,:) = pupil_patch_event(1:time_pupil);

                    % Get baseline signal
                    % todo: okay, here's the +1
                    pupil_base_patch = pupil_patch_base(end-(obj.pre_duration+obj.base_duration+1):end-(obj.pre_duration+1));

                    % Store event-specific baseline
                    %if trial_base == 0
                    if trial_base == "event-specific"
                        base_event(j,:) = pupil_base_patch;
                    end

                    % Response-locked
                elseif event_name == "response"

                    % Response-locked time course
                    pupil_resp_event = [pupil_resp; pupil_delay; pupil_fb; pupil_delay1; pupil_slider];

                    % Get pre-response pupil signal
                    pupil_pre_resp = [pupil_patch_base; pupil_patch; pupil_inst_delay];

                    % Baseline for response phase
                    pupil_base_resp = pupil_pre_resp(end-(obj.pre_duration+obj.base_duration+1):end-(obj.pre_duration+1));

                    % todo: why shorter now?
                    pupil_pre_resp = pupil_pre_resp(end-obj.pre_duration:end);

                    % Response event
                    pupil_resp_event = pupil_resp_event(1:time_pupil);

                    % Add pre-response time window
                    pupil_resp_event = [pupil_pre_resp; pupil_resp_event(1:end-30)]; % todo: be careful! manual!! and why?

                    % Store result
                    pupil_event(j,:) = pupil_resp_event;

                    % Store event-specific baseline
                    %if trial_base == 0
                    if trial_base == "event-specific"
                        base_event(j,:) = pupil_base_resp;
                    end

                    % Feedback locked
                elseif event_name == "feedback"

                    % Feedback-locked time course
                    pupil_fb_event = [pupil_fb; pupil_delay1; pupil_slider];

                    % Slider onset
                    sliderOnset(j,:) = length(pupil_fb) + length(pupil_delay1);

                    % Pre-feedback time course
                    pupil_pre_fb = [pupil_resp; pupil_delay];

                    % Baseline for feedback phase
                    % why the +1?
                    pupil_base_fb = pupil_pre_fb(end-(obj.pre_duration+obj.base_duration+1):end-(obj.pre_duration+1));

                    % Take interval length of interest
                    pupil_pre_fb = pupil_pre_fb(end-obj.pre_duration:end);

                    % Post-feedback time course
                    % pupil_post_fb = [pupil_delay1; pupil_slider];

                    % Add pre-feedback to feedback-locked time course
                    pupil_fb_event = [pupil_pre_fb; pupil_fb_event];

                    % Select final time course
                    if length(pupil_fb_event) < time_pupil
                        pupil_event(j, 1:length(pupil_fb_event)) = pupil_fb_event;
                    else
                        pupil_event(j, 1:time_pupil) = pupil_fb_event(1:time_pupil);
                    end

                    % Store event-specific baseline
                    if trial_base == "event-specific"
                        base_event(j,:) = pupil_base_fb;
                    end

                elseif event_name == "tonic_prefb"

                    % Response-locked pupil response
                    pupil_pre_fb = [pupil_resp; pupil_delay];

                    % Extract tonic time window of interest
                    pupil_pre_fb = pupil_pre_fb(end-time_pupil:end);
                    pupil_event(j,:) = pupil_pre_fb(1:time_pupil);

                end

                % GET TRIAL-SPECIFIC BASELINE
                pupil_base_patch = pupil_patch_base(end-obj.base_duration:end);
                if trial_base == "trial-specific"
                    base_event(j,:) = pupil_base_patch;
                end
            end
        end


        function behvData = loadBehavioralData(obj, subj_idx)
            % Load behavioral data from Excel files for a specific subject
            % Concatenates data across multiple experimental sessions
            %
            % INPUT:
            %   subj_idx: Index of subject to load data for
            %
            % OUTPUT:
            %   behv_data: Table containing all behavioral data for the subject

            behvData = [];

            % Loop through all sessions for this subject
            for j = 1:obj.num_sess(subj_idx)

                % Construct filename (special case for subject 4672)
                filename = fullfile(obj.behv_dir, [obj.subj_ids{subj_idx}, '_main', num2str(j), '.xlsx']);
                if strcmp(obj.subj_ids{subj_idx}, '4672')
                    filename = fullfile(obj.behv_dir, [obj.subj_ids{subj_idx}, '_main', num2str(j), '_red.xlsx']);
                end

                % Load session data and extract relevant columns
                data_run = readtable(filename, 'VariableNamingRule', 'preserve');
                % rt = table(data_run.choice_rt, 'VariableNames', {'rt'});
                rt = table(data_run.('choice.rt'), 'VariableNames', {'rt'});
                % slider = table(data_run.slider_respond_response, 'VariableNames', {'slider'});
                slider = table(data_run.('slider_respond.response'), 'VariableNames', {'slider'});
                data_run = [data_run(:, 1:16), rt, slider];

                % Concatenate with previous sessions
                behvData = [behvData; data_run];
            end
        end

        function pupilData = loadPupilData(obj, subj_idx)
            %LOADPUPILDATA Loas the pupl data
            %
            % INPUT:
            %   subj_idx: Subject IDs
            %
            % OUTPUT:
            %   pupilData: Loaded subject data

            % GET PUPIL DATA FROM DIFFERENT SESSIONS
            pupilData = [];
            for j = 1:obj.num_sess(subj_idx)
                filename = strcat(obj.preproc_dir,filesep,obj.subj_ids{subj_idx},'_main',num2str(j),'.xlsx');
                data_run = readtable(filename);
                pupilData = [pupilData; data_run];
            end
        end
    end
end