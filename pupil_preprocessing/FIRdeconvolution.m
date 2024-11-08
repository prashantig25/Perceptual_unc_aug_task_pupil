classdef FIRdeconvolution < FIRdeconvolution_vars
% FIRdeconvolution contains all the required functions to implement the
% deconvolution analysis on pupil signal.
    
    properties
        design_matrix % design matrix for regression
        betas % estimated betas 
        residuals % residuals after regressing out blink and saccad related activity
        betas_per_event_type % betas estimated for each event
        prediction % predicted pupil signal
    end
    methods 

        function gen_diff_vars(obj)
            % function gen_diff_vars initializes vars and computes
            % resampled pupil signal.
            %
            % obj: current object

            obj.signal_duration = size(obj.signal,2)/obj.sample_frequency;
            obj.resampled_signal_size = double(int32(obj.signal_duration*obj.deconvolution_frequency));
            obj.resampled_signal = resample(obj.signal, obj.resampled_signal_size,size(obj.signal, 2));
        end

        function gen_covariates(obj)
            % function gen_covariates initializes variable to store
            % covariates for the event string.
            %
            % obj: current object

            obj.covariates = struct();
            for i = 1:length(obj.event_strings)
                obj.covariates.(obj.event_strings{i}) = ones(length(obj.event_time{i}),1);
            end
        end

        function gen_durations(obj)
            % function gen_durations initializes variable to store
            % durations for the event string.
            %
            % obj: current object

            obj.durations = struct();
            for i = 1:length(obj.event_strings)
                obj.durations.(obj.event_strings{i}) = ones(length(obj.event_time{i}),1)/obj.deconvolution_frequency;
            end
        end

        function gen_event_times_indices(obj)
            % function gen_event_times_indices initializes variable to store
            % the indices for the events.
            %           
            % obj: current object

            obj.event_times_indices = struct();
            for i = 1:length(obj.event_strings)
                obj.event_times_indices.(obj.event_strings{i}) = round((obj.event_time{i}+obj.deconvolution_interval(1))*obj.deconvolution_frequency);
            end
        end

        function [regressors_for_event]=create_event_regressors(obj,event_times_indices,covariates,durations)
            % function gen_event_times_indices initializes variable to store
            % the indices for the events.
            %
            % obj: current object
            % event_times_indices: event times and their indices
            % covariates: covariates for the regression
            % durations: duration for the deconvolution

            durations = round(durations*obj.deconvolution_frequency);
            mean_duration = mean(durations);
            regressors_for_event = zeros(obj.deconvolution_interval_size, obj.resampled_signal_size);
            for c = 1:length(covariates)
                cov = covariates(c);
                eti = event_times_indices(c);
                this_event_design_matrix = (eye(obj.deconvolution_interval_size) * cov);
                over_duration_dm = this_event_design_matrix;
                if durations(c) > 1
                    new_over_duration_dm = [];
                    for d = 1:durations(c)-1
                        over_duration_dm(d:end,:) = over_duration_dm(d:end,:) + this_event_design_matrix(1:end-d+1,:);
                    end
                    over_duration_dm = over_duration_dm/mean_duration;
                end
                    regressors_for_event(:,eti:eti+double(obj.deconvolution_interval_size-1)) = ...
                    regressors_for_event(:,eti:eti+double(obj.deconvolution_interval_size-1)) + over_duration_dm;
            end
        end

        function create_design_matrix(obj)
            % function create_design_matrix creates design matrix with
            % blink and saccades indices to be regressed out.
            %
            % obj: current object

            obj.design_matrix = zeros(int32(obj.number_of_event_types*obj.deconvolution_interval_size), ...
                obj.resampled_signal_size);
        
            covariates = fieldnames(obj.covariates);
            for i = 1:length(covariates)
                covariate = covariates{i};
                indices = int32(i*obj.deconvolution_interval_size : (i+1)*obj.deconvolution_interval_size - 1);
                which_event_time_indices = covariate;
                obj.design_matrix(indices,:) = obj.create_event_regressors(obj.event_times_indices.(which_event_time_indices), ...
                    obj.covariates.(covariate), obj.durations.(which_event_time_indices));
            end
        end

        function regress(obj)
            % function regress run the regression to regress out blink and 
            % saccade related activity.
            %
            % obj: current object

            [obj.betas, residuals_sum]= lsqr(obj.design_matrix.',obj.resampled_signal.');
            obj.predict_from_design_matrix();
            obj.residuals = obj.resampled_signal - obj.prediction;
        end

        function betas_for_event_type = betas_for_covariates(obj,covariate)
            % function betas_for_event_type get betas for each of the
            % predictors.
            %
            % obj: current object

            this_covariate_index = find(strcmp(fieldnames(obj.covariates),covariate));
            [betas_for_event_type] = obj.betas(this_covariate_index*obj.deconvolution_interval_size:((this_covariate_index+1) ...
                *obj.deconvolution_interval_size-1),:);
        end

        function betas_for_events(obj)
            % function betas_for_events get betas for all the
            % predictors.
            %
            % obj: current object

            obj.betas_per_event_type = zeros(length(obj.covariates), obj.deconvolution_interval_size, ...
                size(obj.resampled_signal,1));
            covariates = fieldnames(obj.covariates);
            for i = 1:length(covariates)
                covariate = covariates{i};
                obj.betas_per_event_type(i,:) = obj.betas_for_covariates(covariate).';
            end
        end

        function predict_from_design_matrix(obj)
            % function predict_from_design_matrix computes posterior curves
            % using betas estimated for blink and saccade related activity.
            %
            % obj: current object

            obj.prediction = obj.betas' * obj.design_matrix;
        end
            
        end
    end
