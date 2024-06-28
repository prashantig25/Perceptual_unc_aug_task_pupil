classdef FIRdeconvolution < FIRdeconvolution_vars
   % todo: this need documentation and cleaning
    
    properties
        design_matrix
        betas
        residuals
        betas_per_event_type
        prediction
    end
    methods 
%         obj.signal_duration = size(obj.signal,1)/obj.sample_frequency;
%         obj.resampled_signal_size = double(int32(obj.signal_duration*obj.deconvolution_frequency));
%         obj.resampled_signal = resample(obj.signal, obj.resampled_signal_size, 1);
        function gen_diff_vars(obj)

%             self.signal_duration = self.signal.shape[-1] / self.sample_frequency
%             self.resampled_signal_size = int(self.signal_duration*self.deconvolution_frequency)
%             self.resampled_signal = scipy.signal.resample(self.signal, self.resampled_signal_size, axis = -1)

            obj.signal_duration = size(obj.signal,2)/obj.sample_frequency;
            obj.resampled_signal_size = double(int32(obj.signal_duration*obj.deconvolution_frequency));
            obj.resampled_signal = resample(obj.signal, obj.resampled_signal_size,size(obj.signal, 2));
        end
        function gen_covariates(obj)
            obj.covariates = struct();
            for i = 1:length(obj.event_strings)
                obj.covariates.(obj.event_strings{i}) = ones(length(obj.event_time{i}),1);
            end
        end
        function gen_durations(obj)
            obj.durations = struct();
            for i = 1:length(obj.event_strings)
                obj.durations.(obj.event_strings{i}) = ones(length(obj.event_time{i}),1)/obj.deconvolution_frequency;
            end
        end
        function gen_event_times_indices(obj)
            % [((ev + self.deconvolution_interval[0])*self.deconvolution_frequency).astype(int) for ev in events]))
            obj.event_times_indices = struct();
            for i = 1:length(obj.event_strings)
                %obj.event_times_indices.(obj.event_strings{i}) = (obj.event_time{i}+obj.deconvolution_interval(1))*obj.deconvolution_frequency;
                obj.event_times_indices.(obj.event_strings{i}) = round((obj.event_time{i}+obj.deconvolution_interval(1))*obj.deconvolution_frequency);
                %obj.event_times_indices.(obj.event_strings{i}) = round((obj.event_time{i}+obj.deconvolution_interval(1))*100);
            end
        end
        function [regressors_for_event]=create_event_regressors(obj,event_times_indices,covariates,durations)
%             covariates = ones(size(obj.event_times_indices));
%             durations = ones(size(obj.event_times_indices));
            durations = round(durations*obj.deconvolution_frequency);
            mean_duration = mean(durations);
            regressors_for_event = zeros(obj.deconvolution_interval_size, obj.resampled_signal_size);
            for c = 1:length(covariates)
                cov = covariates(c);
                eti = event_times_indices(c);
%                 this_event_design_matrix = (diag(ones(obj.deconvolution_interval_size)) * cov);
                this_event_design_matrix = (eye(obj.deconvolution_interval_size) * cov);
                over_duration_dm = this_event_design_matrix;
                if durations(c) > 1
                    new_over_duration_dm = [];
                    for d = 1:durations(c)-1
                        %over_durations_dm[d:] += this_event_design_matrix[:-d]
                        %over_durations_dm(d:end,:) = over_durations_dm(d:end,:) + this_event_design_matrix(1:end-d,:)
                        over_duration_dm(d:end,:) = over_duration_dm(d:end,:) + this_event_design_matrix(1:end-d+1,:);
%                         new_over_duration_dm = [new_over_duration_dm; over_duration_dm(d,:) + this_event_design_matrix(:,end-d)];
                    end
                    over_duration_dm = over_duration_dm/mean_duration;
                end
%                 regressors_for_event = []; 
                %for e = 1:height(event_times_indices)
                    regressors_for_event(:,eti:eti+double(obj.deconvolution_interval_size-1)) = ...
                    regressors_for_event(:,eti:eti+double(obj.deconvolution_interval_size-1)) + over_duration_dm;
                    %regressors_for_event = [regressors_for_event,e:double(e+obj.deconvolution_interval_size) + over_duration_dm];
                %end
                
            end
        end
%             function create_design_matrix(obj)
%                 %self.design_matrix = np.zeros((int(self.number_of_event_types*self.deconvolution_interval_size), self.resampled_signal_size))
%                 
%                 obj.design_matrix = zeros(int32(obj.number_of_event_types*obj.deconvolution_interval_size),obj.resampled_signal_size);
%                 covariate_keys = fieldnames(obj.covariates);
%                 for i = 1:length(fieldnames(obj.covariates))
%                     covariate = covariate_keys{i};
%                     %indices = np.arange(i*self.deconvolution_interval_size,(i+1)*self.deconvolution_interval_size, dtype = int)
%                     indices = [i*obj.deconvolution_interval_size:(i+1)*obj.deconvolution_interval_size-1];
%                 
% %                 which_event_time_indices = covariate
% %                 self.design_matrix[indices] = self.create_event_regressors( self.event_times_indices[which_event_time_indices], 
% %                                                                             self.covariates[covariate], 
% %                                                                             self.durations[which_event_time_indices])
%                 which_event_time_indices = covariate;
%                 event_times_indices = obj.event_times_indices.(which_event_time_indices);
%                 covariates = obj.covariates.(covariate);
%                 durations = obj.durations.(which_event_time_indices);
%                 [reg_for_event] = obj.create_event_regressors(event_times_indices,covariates,durations);
%                 obj.design_matrix(double(indices)) = reg_for_event;
%                 
%                 end
%             end
        function create_design_matrix(obj)
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
                [obj.betas, residuals_sum]= lsqr(obj.design_matrix.',obj.resampled_signal.');
                %obj.residuals = obj.resampled_signal - obj.predict_from_design_matrix();
                obj.predict_from_design_matrix();
                obj.residuals = obj.resampled_signal - obj.prediction;
            end
            function betas_for_event_type = betas_for_covariates(obj,covariate)
                this_covariate_index = find(strcmp(fieldnames(obj.covariates),covariate));
%                 [betas_for_event_type] = obj.betas(this_covariate_index*obj.deconvolution_interval_size+1:(this_covariate_index+1)* ...
%                     obj.deconvolution_interval_size);
                [betas_for_event_type] = obj.betas(this_covariate_index*obj.deconvolution_interval_size:((this_covariate_index+1) ...
                    *obj.deconvolution_interval_size-1),:);
                %self.betas[int(this_covariate_index*self.deconvolution_interval_size):int((this_covariate_index+1)*self.deconvolution_interval_size)]
            end
            function betas_for_events(obj)
%                 obj.betas_per_event_type = zeros(length(obj.covariates), obj.deconvolution_interval_size, obj.resampled_signal.shape(1));
                obj.betas_per_event_type = zeros(length(obj.covariates), obj.deconvolution_interval_size, ...
                    size(obj.resampled_signal,1));
                %self.betas_per_event_type = np.zeros((len(self.covariates), self.deconvolution_interval_size, self.resampled_signal.shape[0]))
                covariates = fieldnames(obj.covariates);
                for i = 1:length(covariates)
                    covariate = covariates{i};
                    obj.betas_per_event_type(i,:) = obj.betas_for_covariates(covariate).';
                end
%                 for i = 1:height(fieldnames(obj.covariates))
%                     obj.betas_per_event_type(i) = obj.betas_for_covariates(i);
%                 end
            end
            function predict_from_design_matrix(obj)
                %prediction = dot(obj.betas, obj.design_matrix);
                obj.prediction = obj.betas' * obj.design_matrix;
            end
            
        end
    end
