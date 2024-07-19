function preprocessing_fun(subj_ids, num_sess, plot_steps, sampling_rate, freqs, downsample_rate, event_names, deconv_time, savedir)
%preprocssing_fun This function performs the preprocessing of pupillometry
% data
%
%   Input
%       subj_ids: Subject IDs
%       num_sess: Number of sessions
%       plot_steps: If you want to visualize results for each step
%       sampling_rate: Original sampling rate
%       freqs: Filter cutoffs [lo hi]
%       downsample_rate: Sampling rate after down-sampling
%       event_names: Event names (blinks, saccades)
%       deconv_time: Deconvolution time window [lo hi]
%       savedir: Directory for preprocessed data
%
%   Output
%       None

% Todo: Let's think about how we can put each step into a different
% function. The advantage is that we can then more easily test things with
% unit tests. And in principle, the pipeline would be more flexible as
% well.

% Compute number of subjects
num_subs = length(subj_ids);

% Compute number of samples after downsampling
sample_num = sampling_rate/downsample_rate;

% LOOP OVER PARTICIPANTS
for s = num_subs

    % LOOP OVER SESSIONS
    for ss = 1:num_sess(s)

        % Todo: This is also quite experiment specific, ensure that it works for
        % all data sets.
        % READ DAT AND ASC FILES
        % DAT FOR PUPIL SIZE AND GAZE COORDINATES
        % ASC FOR EVENTS, BLINKS, SACCADES
        if strcmp(subj_ids(s),'4672') == 1 % only for subj 4672 (read NOTES on top of script to understand)
            filename_dat = strcat(subj_ids{s},'_','m',num2str(ss),'.EDF_red','.DAT');
            filename_asc = strcat(subj_ids{s},'_','m',num2str(ss),'_red.asc');
        else
            %             filename_dat = strcat(subj_ids{s},'m',num2str(ss),'.EDF','.dat');
            %             filename_asc = strcat(subj_ids{s},'m',num2str(ss),'.asc');
            filename_dat = strcat(subj_ids{s},'.dat');%,'m',num2str(ss),'.EDF','.dat');
            filename_asc = strcat(subj_ids{s},'.asc');%(subj_ids{s},'m',num2str(ss),'.asc');
        end
        data = importdata(filename_dat); % read DAT file
        [asc] = read_eyelink_ascNK_AU(filename_asc); % read ASC file
        data_asc = asc2dat(asc); % convert asc to dat file
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
        blinksmp = data_asc.blinksmp; % get blink positions

        % MERGE BLINKS
        coalesce1 = 0.250; % merge 2 blinks into 1 if they are below this distance (in s) apart (default = 0.250)
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
        % todo: I don't understand the variable name: clarify
        padding1 = [-0.150 0.150]; % padding before/after EL-defined blinks for initial rough interpolation
        padblinksmp(:,1) = round(blinksmp(:,1) + padding1(1) * 1000);
        padblinksmp(:,2) = round(blinksmp(:,2) + padding1(2) * 1000);

        % AVOID INDEX OUTSIDE RANGE
        if any(padblinksmp(:) < 1)
            padblinksmp(padblinksmp < 1) = 1; % todo: deal with preallocation
        end

        % Todo: comment
        % todo: deal with preallocation
        if any(padblinksmp(:) > length(data_matched.pupil_diam))
            padblinksmp(padblinksmp > length(data_matched.pupil_diam)) = length(data_matched.pupil_diam);
        end

        % Convert all blinks to NaNs
        data_matched.pupil_diam(data_matched.pupil_diam == 0,1) = NaN;

        % CREATE COPIES
        pupilcopy = data_matched.pupil_diam;
        Xgazecopy = data_matched.eye_x;
        Ygazecopy = data_matched.eye_y;

        % INTERPOLATE
        [pupilcopy,~] = interp_nans(pupilcopy,padblinksmp); % pupil
        [Xgazecopy2,~] = interp_nans(Xgazecopy,padblinksmp); % x gaze coordinates
        [Ygazecopy2,~] = interp_nans(Ygazecopy,padblinksmp); % y gaze coordinates

        % MAKE SURE ALL NaNs have been dealt with
        assert(~any(isnan(pupilcopy)));
        assert(~any(pupilcopy == 0));

        % PLOT AFTER INTERPOLATION
        if plot_steps == 1
            plot(pupilcopy)
            hold on
            legend('before interpolation','after interpolation')
        end

        % FILTER
        % todo: more comments required: why 2 times hi-pass?
        % why is sampling_rate divided by 2
        fprintf('butterworth filtering...\n');
        [bfilt,afilt] = butter(3, freqs(1)/(sampling_rate/2), 'high'); % hi-pass
        high_pupil = filtfilt(bfilt,afilt, pupilcopy);
        [bfilt,afilt] = butter(3, freqs(2)/(sampling_rate/2)); % hi-pass
        low_pupil = filtfilt(bfilt,afilt, pupilcopy);
        band_pupil = filtfilt(bfilt,afilt, high_pupil);

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
        interval = 6; % time in seconds, after blinks/saccades for deconvolution
        deconv_freq = newsample_rate; % frequency

        % CHECK BLINKS/SACCADES ENDS THAT EXCEED THE DECONVOLUTION TIME
        % WINDOW (mostly after the last trial of the session)
        del_blinks = []; % empty array for blinks that need to be deleted
        blink_ends = round(blinksmp(:,2)/100);
        for h = 1:height(blink_ends)
            % check if timewindow after blink is beyond the number of
            % samples
            if blink_ends(h) + (interval*deconv_freq) > height(samp_pupil)
                del_blinks = [del_blinks; h];
            end
        end

        % Todo: comment
        del_sacc = []; % empty array for saccades that need to be deleted
        sacc_ends = round(data_asc.saccsmp(:,2)/100);
        for h = 1:height(sacc_ends)
            % check if timewindow after saccade is beyond the number of
            % samples
            if sacc_ends(h) + (interval*deconv_freq) > height(samp_pupil)
                del_sacc = [del_sacc; h];
            end
        end

        % SIMILARLY, REMOVE BLINKS/SACCADES THAT HAPPEN TOO EARLY ON IN THE
        % TASK (because MATLAB indexing starts from 1 and can't deal with
        % blink times less than 1)
        tp_blinks = blinksmp(:,2)/sampling_rate;
        if tp_blinks(1) < 1
            del_blinks = [del_blinks; 1]; % add to array of blinks that need to be deleted
        end
        tp_blinks(del_blinks,:) = [];
        blink_ends(del_blinks,:) = [];
        pupil = samp_pupil;
        tp_sacc = data_asc.saccsmp(:,2)/sampling_rate;
        if tp_blinks(1) < 1
            del_sacc = [del_sacc; 1]; % add to array of saccades that need to be deleted
        end
        tp_sacc(del_sacc,:) = [];

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

        % todo: is this used afterall
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
        % title(strcat('subject = ',subj_ids{s},{' '},'session = ',num2str(ss)))
        % saveas(gcf,strcat(subj_ids{s},' sess = ',num2str(ss),'_opt_params'),'fig')
        % saveas(gcf,strcat(subj_ids{s},' sess = ',num2str(ss),'_opt_params'),'png')
        %clear padblinksmp

        %%
        % x_values = linspace(0,deconv_time(end),deconv_time(end)*sampling_rate); % linspace(0,interval,interval*sample_rate)
        % blink_kernel = double_pupil_IRF(blink_result(1),blink_result(2),blink_result(3),blink_result(4),blink_result(5),blink_result(6),x_values);
        % sacc_kernel = double_pupil_IRF(sacc_result(1),sacc_result(2),sacc_result(3),sacc_result(4),sacc_result(5),sacc_result(6),x_values);

        % INITIALIZE VARS FOR CONVOLUTION
        blink_reg = zeros(1,length(pupil_og));
        blink_reg(blink_ends) = 1;
        sacc_reg = zeros(1,length(pupil_og));
        sacc_reg(sacc_ends) = 1;

        % PERFORM THE CONVOLUTION
        blink_reg_conv = conv(blink_reg, blink_kernel, 'full');
        sacc_reg_conv = conv(sacc_reg, sacc_kernel, 'full');

        % REMOVE THE PADDING
        blink_reg_conv = blink_reg_conv(1:end-(length(blink_kernel)-1));
        sacc_reg_conv = sacc_reg_conv(1:end-(length(sacc_kernel)-1));

        % GLM
        regs = vertcat(blink_reg_conv,sacc_reg_conv);
        design_matrix = transpose(regs);
        betas = ((inv(design_matrix'*design_matrix))*design_matrix')*band_pupil;
        betas_regs = [];
        for b = 1:length(betas)
            betas_regs = vertcat(betas_regs,betas(b).*regs(b,:)); % todo: deal with preallocation
        end
        explained = sum(betas_regs);

        % CLEAN PUPIL SIGNAL BY GETTING RID OF EXPLAINED
        % todo: check the above comment: explained what exactly?
        pupil_clean_bp = band_pupil - explained';
        pupil_clean_lp = pupil_clean_bp + (low_pupil - band_pupil);

        if plot_steps == 1
            figure
            hold on
            plot(band_pupil)
            hold on
            plot(pupil_clean_bp)
            hold on
            legend('bandpassed','blinks/saccades regressed out')
            box off
            %set(gcf,'Color','None')
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

        % Todo: implement safe_save function as suggested for behavioral
        % analyses
        if exist(savedir, 'dir')
            rmdir(savedir,'s')
            mkdir(savedir)
        else
            % Create the directory if it is non-existent
            mkdir(savedir)
        end

        filename = strcat(savedir,'\',subj_ids{s},'_main',num2str(ss),'.xlsx');
        writetable(data,filename);
        clear padblinksmp
    end
end

end