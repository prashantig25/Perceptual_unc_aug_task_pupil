function preprocessing_fun(subj_ids, num_sess, plot_steps, sampling_rate, freqs, downsample_rate, ...
    event_names, deconv_time, savedir, asc_dir, dat_dir, save_dirASC, using_DAT)

        % function PREPROCESS_FUNCTION performs the preprocessing of pupillometry
        % data collected using EyeLink
        %
        % INPUT
        %   subj_ids: Subject IDs
        %   num_sess: Number of sessions
        %   plot_steps: If you want to visualize results for each step
        %   sampling_rate: Original sampling rate
        %   freqs: Filter cutoffs [lo hi]
        %   downsample_rate: Sampling rate after down-sampling
        %   event_names: Event names (blinks, saccades)
        %   deconv_time: Deconvolution time window [lo hi]
        %   savedir: Directory for preprocessed data
        %   using_DAT: use already saved DAT files

    sample_num = sampling_rate/downsample_rate;
    num_subs = length(subj_ids);
    
    % LOOP OVER PARTICIPANTS
    for s = 1:num_subs
    
        % LOOP OVER SESSIONS
        for ss = 1:num_sess(s)
    
            % READ DAT AND ASC FILES
            % DAT FOR PUPIL SIZE AND GAZE COORDINATES
            % ASC FOR EVENTS, BLINKS, SACCADES
            if strcmp(subj_ids(s),'4672') == 1 % only for subj 4672 (read NOTES on top of script to understand)
                filename_dat = strcat(dat_dir, filesep, subj_ids{s},'_','m',num2str(ss),'.EDF_red','.DAT');
                filename_asc = strcat(asc_dir, filesep, subj_ids{s},'_','m',num2str(ss),'_red.asc');
            else
                filename_dat = strcat(dat_dir, filesep, subj_ids{s},'m',num2str(ss),'.EDF','.dat');
                filename_asc = strcat(asc_dir, filesep, subj_ids{s},'m',num2str(ss),'.asc');
            end
            data = importdata(filename_dat); % read DAT file
            if using_DAT == 0
                [asc] = read_eyelink_ascNK_AU(filename_asc); % read ASC file
                data_asc = asc2dat(asc); % convert asc to dat file
                safe_saveall(strcat(save_dirASC, filesep,subj_ids{s},'_DAT',num2str(ss),".mat"),data_asc);
            else
                filename_ascDAT = strcat(save_dirASC, filesep, subj_ids{s},'_DAT',num2str(ss),'.mat');
                data_asc = importdata(filename_ascDAT); % read DAT file
            end
            events = data_asc.event; % get events information from the DAT file
    
            % CONVERT TO TABLE
            fprintf('converting to table...\n');
            [data_table] = conv2table(data);
            data_matched = data_table;
            pupil_og = data_matched.pupil_diam;
    
            % PLOT OG PUPIL SIZE
            if plot_steps == 1
                figure
                hold on
                plot(pupil_og)
                hold on
                title('Original pupil size')
            end
    
            % BLINK INTERPOLATION
            fprintf('blink correction step 1...\n');
            coalesce1 = 0.250;
            padding1 = [-0.150 0.150];
            [pupilcopy, Xgazecopy2, Ygazecopy2, blinksmp] = process_blinks(data_asc, data_matched, sampling_rate, coalesce1, padding1);
    
            % PLOT AFTER INTERPOLATION
            if plot_steps == 1
                plot(pupilcopy)
                hold on
                legend('before interpolation','after interpolation')
            end

            % PEAK CORRECTION
            fprintf('peak correction...\n');
            assert(~any(isnan(pupilcopy)));
            win             = hanning(11);
            pupildatsmooth  = filter2(win.',pupilcopy,'same');

            % IDENTIFY PEAKS
            pupildiff   = diff(pupildatsmooth) - mean(diff(pupildatsmooth)) / std(diff(pupildatsmooth));
            [peaks, loc]    = findpeaks(abs(pupildiff), 'minpeakheight', 3*std(pupildiff), 'minpeakdistance', 0.5*1000);
            
            if ~isempty(peaks),
                % convert peaks into blinksmp
                newblinksmp = nan(length(peaks), 2);
                for p = 1:length(peaks),
                    newblinksmp(p, 1) = loc(p) - 2*padding1(2) * sampling_rate; % peak detected will be eye-opening again
                    newblinksmp(p, 2) = loc(p) + padding1(2) * sampling_rate;
                end
                
                % merge 2 blinks into 1 if they are < 250 ms together (coalesce)
                coalesce = 0.250;
                for b = 1:size(newblinksmp, 1)-1,
                    if newblinksmp(b+1, 1) - newblinksmp(b, 2) < coalesce * sampling_rate,
                        newblinksmp(b, 2) = newblinksmp(b+1, 2);
                        newblinksmp(b+1, :) = nan;
                    end
                end
                % remove those duplicates
                newblinksmp(isnan(nanmean(newblinksmp, 2)), :) = [];
                
                % make sure none are outside of the data range
                newblinksmp(newblinksmp < 1) = 1;
                newblinksmp(newblinksmp > length(pupilcopy)) = length(pupilcopy) -1;
                
                % make the pupil NaN at those points
                for b = 1:size(newblinksmp,1),
                    pupilcopy(newblinksmp(b,1):newblinksmp(b,2)) = NaN;
                end
                
                pupilcopy1 = pupilcopy;
                % interpolate linearly
                pupilcopy(isnan(pupilcopy)) = interp1(find(~isnan(pupilcopy)), ...
                    pupilcopy(~isnan(pupilcopy)), find(isnan(pupilcopy)), 'linear');

                % extrapolate ends
                pupilcopy(isnan(pupilcopy)) = interp1(find(~isnan(pupilcopy)), ...
                    pupilcopy(~isnan(pupilcopy)), find(isnan(pupilcopy)), 'nearest', 'extrap');
            else
                newblinksmp = [];
            end

            % FILTER
            fprintf('butterworth filtering...\n');
            [~, low_pupil, band_pupil] = apply_filter(pupilcopy, sampling_rate, freqs);
    
            % PLOT AFTER FILTERING
            if plot_steps == 1
                figure
                hold on
                plot(low_pupil)
                hold on
                plot(band_pupil)
                hold on
                legend('low pass','band pass')
                box off
                title('Filtered')
            end
    
            % DOWN SAMPLE
            newsample_rate = sampling_rate/downsample_rate;
            fprintf('downsampling data...\n');
            samp_pupil = decimate(band_pupil,downsample_rate,1);
    
            % PREPARE FOR DECONVOLUTION
            fprintf('performing deconvolution...\n');
            interval = 6; % time in seconds, after blinks/saccades for deconvolution
            deconv_freq = newsample_rate; % frequency
    
            % CHECK BLINKS/SACCADES ENDS THAT EXCEED THE DECONVOLUTION TIME
            % WINDOW (mostly after the last trial of the session)
    
            del_blinks = []; % empty array for blinks that need to be deleted
            blink_ends = round(blinksmp(:,2)/100);
            del_sacc = []; % empty array for saccades that need to be deleted
            sacc_ends = round(data_asc.saccsmp(:,2)/100);

            % SIMILARLY, REMOVE BLINKS/SACCADES THAT HAPPEN TOO EARLY ON IN THE
            % TASK (because MATLAB indexing starts from 1 and can't deal with
            % blink times less than 1)
            tp_blinks = blinksmp(:,2)/sampling_rate;
            tp_blinks(del_blinks,:) = [];
            blink_ends(del_blinks,:) = [];
            pupil = samp_pupil;
            tp_sacc = data_asc.saccsmp(:,2)/sampling_rate;
            tp_sacc(del_sacc,:) = [];
    
            [tp_blinks, tp_sacc, blink_ends, pupil, sacc_ends] = check_blinks_saccades(samp_pupil, interval, ...
                deconv_freq, blink_ends, sacc_ends,tp_blinks,tp_sacc);
    
            % INITIALISE VARS FOR DECONVOLUTION
            events_list = {[tp_blinks],[tp_sacc]}; % array with blink and saccade end times
    
            % INTIALISE DECONVOLUTION CLASS
            FIR = FIRdeconvolution();
            FIR.signal = pupil.'; % pupil signal that needs to be deconvolved
            FIR.event_time = events_list; % blink/saccades end array
            FIR.event_strings = event_names; % event names to be used for deconvolution
            FIR.deconvolution_interval = deconv_time; % time window
    
            % INITIALISE DIFFERENT VARIABLES FOR DECONVOLUTION
            FIR.gen_diff_vars();
            FIR.gen_covariates();
            FIR.gen_durations();
            FIR.gen_event_times_indices();
            FIR.create_design_matrix();
    
            % GET BETAS
            FIR.regress();
            FIR.betas_for_events();
            blink_response = reshape(FIR.betas_per_event_type(1,:), [], 1);
            sacc_response = reshape(FIR.betas_per_event_type(2,:), [], 1);
    
            % BASELINE
            blink_response = blink_response - mean(blink_response(1));
            sacc_response = sacc_response - mean(blink_response(1));
    
            % PLOT AFTER DECONVOLUTION
            if plot_steps == 1
                x = linspace(0, deconv_time(end), length(blink_response));
                figure
                plot(x,blink_response,'Color','r','LineWidth',2)
                hold on
                plot(x,sacc_response,'Color','b','LineWidth',2)
                legend('Blink response','Saccade response')
                xlabel('Time from event')
                ylabel('Pupil size')
                box off
                title('Fitting to blink responses')
            end
    
            A = [];
            b = [];
            Aeq = [];
            beq = [];
    
            % CREATE A SET OF PARAMETERS
            params = struct();
            params.s1 = struct('Value', -1, 'Min', -inf, 'Max', -1e-25);
            params.s2 = struct('Value', 1, 'Min', 1e-25, 'Max', inf);
            params.n1 = struct('Value', 10, 'Min', 9, 'Max', 11);
            params.n2 = struct('Value', 10, 'Min', 8, 'Max', 12);
            params.tmax1 = struct('Value', 0.9, 'Min', 0.5, 'Max', 1.5);
            params.tmax2 = struct('Value', 2.5, 'Min', 1.5, 'Max', 4);
    
            s1_0 = [params.s1.Min,params.s1.Max];
            s2_0 = [params.s2.Min,params.s2.Max];
            n1_0 = [params.n1.Min,params.n1.Max];
            n2_0 = [params.n2.Min,params.n2.Max];
            tmax1_0 = [params.tmax1.Min,params.tmax1.Max];
            tmax2_0 = [params.tmax2.Min,params.tmax2.Max];
            x = linspace(0,6,length(blink_response));
            x_values = x.';
            s1 = params.s1.Value;
            s2 = params.s2.Value;
            n1 = params.n1.Value;
            n2 = params.n2.Value;
            tmax1 = params.tmax1.Value;
            tmax2 = params.tmax2.Value;
    
            % DEFINE FUNCTIONS THAT NEED TO BE OPTIMIZED
            fun_blink = @(y) double_pupil_IRF_ls(y(1), y(2), y(3), y(4), y(5), y(6), blink_response, x_values);
            fun_sacc = @(y) double_pupil_IRF_ls(y(1), y(2), y(3), y(4), y(5), y(6), sacc_response, x_values);
    
            % INITIALIZE VARS FOR PARAMETER ESTIMATION
            y0 = [s1,s2,n1,n2,tmax1,tmax2]; % starting point for optimization
            lb = [params.s1.Min, params.s2.Min, params.n1.Min, params.n2.Min, params.tmax1.Min, params.tmax2.Min];
            ub = [params.s1.Max, params.s2.Max, params.n1.Max, params.n2.Max, params.tmax1.Max, params.tmax2.Max];
            options = optimoptions('fmincon','Display','iter', 'Algorithm', 'interior-point');
    
            % PERFORM THE OPTIMIZATION
            blink_result = fmincon(fun_blink,y0,A,b,Aeq,beq,lb,ub,[],options);
            sacc_result = fmincon(fun_sacc,y0,A,b,Aeq,beq,lb,ub,[],options);
    
            % FIT PARAMETERS
            blink_kernel = double_pupil_IRF(blink_result(1),blink_result(2),blink_result(3),blink_result(4), ...
                blink_result(5),blink_result(6),x_values);
            sacc_kernel = double_pupil_IRF(sacc_result(1),sacc_result(2),sacc_result(3),sacc_result(4), ...
                sacc_result(5),sacc_result(6),x_values);
    
            % PLOT FIT BLINK/SACCADE RESPONSE
            if plot_steps == 1
                x = linspace(0, 6, length(blink_response));
                hold on
                plot(x,blink_kernel,'Color','r','LineWidth',2,'LineStyle','-.')
                hold on
                plot(x,sacc_kernel,'Color','b','LineStyle','-.','LineWidth',2)
                hold on
                legend('Blink response','Saccade response','Blink fit','Saccade fit')
            end
            x = linspace(0,interval,interval*sampling_rate);
            x_values = x.';
            blink_kernel = double_pupil_IRF(blink_result(1),blink_result(2),blink_result(3),blink_result(4), ...
                blink_result(5),blink_result(6),x_values);
            sacc_kernel = double_pupil_IRF(sacc_result(1),sacc_result(2),sacc_result(3),sacc_result(4), ...
                sacc_result(5),sacc_result(6),x_values);
    
            % INITIALIZE VARS FOR CONVOLUTION
            blink_reg = zeros(1,length(pupil_og));
            blink_reg(blinksmp(:,2)) = 1;
            sacc_reg = zeros(1,length(pupil_og));
            sacc_reg(data_asc.saccsmp(:,2)) = 1;

            blinkIRFup = blink_kernel;
            saccIRFup = sacc_kernel;

            % PERFORM THE CONVOLUTION
            [pupil_clean_bp, pupil_clean_lp] = perform_convolutionGLM(blink_reg, blinkIRFup, sacc_reg, saccIRFup, band_pupil, low_pupil);
    
            if plot_steps == 1
                figure
                hold on
                plot(band_pupil)
                hold on
                plot(pupil_clean_bp)
                hold on
                legend('bandpassed','blinks/saccades regressed out')
                box off
                set(gcf,'Color','None')
                title('Subtracted explained (blinks/saccades) from signal')
    
                figure
                plot(pupilcopy)
                hold on
                plot(pupil_clean_lp)
                hold on
                legend('bandpassed','blinks/saccades regressed out')
                box off
                title('After adding slow drift')
            end
            clear padblinksmp
            data_matched.pupil_cleaned = pupil_clean_lp;
            data_matched.xgaze = Xgazecopy2;
            data_matched.ygaze = Ygazecopy2;
    
            % ZSCORE
            fprintf('zscore normalising...\n');
            data_matched.pupil_zsc = zscore(data_matched.pupil_cleaned);
    
            % DOWNSAMPLE
            fprintf('downsampling data...\n');
            data = down_sample(data_matched,sample_num);
    
            % SAVE
            filename = strcat(savedir,filesep,subj_ids{s},'_main',num2str(ss),'_resampled_peak.xlsx');
            safe_saveall(filename,data);
            clear padblinksmp
            clear newblinksmp
        end
    end
end
