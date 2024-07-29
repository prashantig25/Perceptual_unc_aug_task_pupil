%% GET RELEVANT BEHAVIOURAL DATA FROM PSYCHOPY FILES
clc
clearvars

%%%% DON'T CHANGE SUBJECT IDs and NUM_SESS
% INITIALISE VARS
subj_ids = {'0806','3970','4300','4885','4954','907','2505','3985','4711',...
    '3376','4927','190','306','3391','5047','3922','659','421','3943',...
    '4225','4792','3952','4249','4672','4681','4738','3904','852','3337',...
    '3442','3571','4360','4522','4807','4943','594','379','4057','4813',...
    '601','3319','129','4684','3886','620','901','900'};
num_sess = [1,1,1,1,1,1,1,1,1,1,1,2,2,1,1,1,1,1,1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
total_blocks = 8; % total number of blocks in the task
task_name = '_main';
format = '.xlsx';
behv_dir = 'C:\Users\prash\Nextcloud\Thesis_laptop\Semester 6\pupil_data\pre_preprocessed\behv\with_missed_trials';
save_dir = "C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\data_space\behavior\preprocessed";

num_subjs = length(subj_ids); % number of subjects
data_subj = []; % empty array for each subjects data
data_all = []; % empty array for all participants' data
num_trials = 20; % number of trials

% LOOP OVER ALL SUBJECTS
for n = 1:num_subjs
    
    missed_trials_all = [];
    sess_trials = [];

    % LOOP OVER NUMBER OF SESSIONS FOR THAT PARTICIPANT
    for j = 1:num_sess(n)
        filename = strcat(behv_dir,'\',subj_ids{n},task_name,num2str(j),format); % filename
        if strcmp(subj_ids{n},'4672') == 1
            filename = strcat(behv_dir,'\',subj_ids{n},'_','main',num2str(j),'_red.xlsx');
        end

        data = readtable(filename); % read file
        if num_sess(n) == 2
            sess_trials = [sess_trials;height(data)];
        end
            % ADD NECCESARY VARS
            data.diff = data.con_left-data.con_right; % calculate contrast difference
            if j ~= 4 % if it is not practice block, delete trials where participant hasn't responded
                missed_trials = []; % initialize array for index of missed trials
                for i = 1:height(data)
                    if strcmp(data.choice_keys(i,:),"None")==1 % check if participant has not responded
                        missed_trials = [missed_trials;i];
                    end
                end
                if num_sess(n) > 1
                    if j == 2
                        missed_trials_all = [missed_trials_all;missed_trials+sess_trials(1)];
                    else
                        missed_trials_all = [missed_trials_all;missed_trials];
                    end
                end
                data(missed_trials,:) = []; % delete such trials
            end

            % CONVERT KEYPRESS TO a = 0 or a = 1
            for i = 1:height(data)
                if strcmp(data.choice_keys(i,1), "left")
                    data.choice(i,1) = 0;
                else
                    data.choice(i,1) = 1;
                end
            end
    
            % GET ECONOMIC PERFORMANCE ON EACH TRIAL
            for i = 1:height(data)
                % for low contrast block, state and action must be same for the
                % choice to be more rewarding
                if data.contrast(i) == 1 && data.state(i) == 0 || data.contrast(i) == 0 && data.state(i) == 1
                    if data.choice(i) == 1
                        data.eco_perf(i) = 1;
                    else
                        data.eco_perf(i) = 0;
                    end
                % for high contrast block, state and action must NOT be same for the
                % choice to be more rewarding
                elseif data.contrast(i) == 0 && data.state(i) == 0 || data.contrast(i) == 1 && data.state(i) == 1
                    if data.choice(i) == 0
                        data.eco_perf(i) = 1;
                    else
                        data.eco_perf(i) = 0;
                    end
                end
            end

        data.congruent = data.congruence;
        not_trials = []; % initialize array for index of missed trials
        for i = 1:height(data)
            if strcmp(num2str(data.row_id(i)),'NaN') == 1
                not_trials = [not_trials;i];
            end
        end
        data(not_trials,:) = []; % delete such trials

        % GET SLIDER RESPONSE FOR CONGRUENT AND INCONGRUENT TRIALS
        for i = 1:height(data)
            if data.congruent(i) == 1
                data.mu_congruence(i) = data.slider_respond_response(i);
            else
                data.mu_congruence(i) = 100 - data.slider_respond_response(i);
            end
        end
        data.mu_congruence = data.mu_congruence./100;
        data.mu = data.slider_respond_response./100;
       
        % ADD TRIAL NUMBERS FOR EACH BLOCK
        t = 0;
        for i = 1:height(data)
            if t > 19
                t = 1;
            else
                t = t + 1;
            end
            data.trial_num(i) = t;
        end

        % CODE CONDITIONS NUMERICALLY
        for i = 1:height(data)
            if strcmp(data.condition_name(i),'mixed_s0') == 1 || strcmp(data.condition_name(i),'mixed_s1') == 1
                data.condition(i) = 1;
            end
        end

        % GET DATA FROM ALL THE RELEVANT COLUMNS
        data_new = table(data.participant,data.condition,data.contrast, ...
            data.state,data.action,data.condiff,data.con_left,data.con_right,data.congruent, data.state_mu,...
            data.slider_respond_response,data.choice,data.diff,data.choice_keys, ...
            data.mu,data.eco_perf,data.trial_num, data.bord_pos,data.bord_text,data.choice_rt,data.choice_corr, ...
            'VariableNames',{'id','condition','contrast', ...
            'state','action','con_diff','contrast_left','contrast_right','congruence','state_mu',...
            'slider','choice','rel_diff','choice_keys','mu','ecoperf','trial','bord_pos','bord_text','rt','correct'});

        data_subj = [data_subj;data_new];
    end

    total_blocks = height(data_subj)./num_trials;
    % ADD BLOCK NUMBERS
    blocks = zeros(total_blocks*num_trials,1); % initialise array for block number 
    c = 1;
    for b = 1:total_blocks
        blocks(c:b*num_trials,1) = repelem(b,num_trials,1); % repeat block numbers for all trials
        c = c+num_trials;
    end
    data_subj.blocks = blocks; % add to table

    % SAVE FILE
    save_file = strcat(save_dir,'\',num2str(subj_ids{n}),'.xlsx');
    safe_saveall(save_file,data_subj);
    data_all = [data_all; data_subj];
    data_subj = [];
end