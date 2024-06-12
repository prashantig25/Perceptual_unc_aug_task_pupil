classdef FIRdeconvolution_vars < handle
    properties
        signal = zeros(1,100);% pupil signal
        eventnames
        event_strings % should be empty, and then add string event times
        event_time = [1,2,3,4,5,6,8]; % timepoints for blinks and saccades
        event
        sample_frequency = 10
        deconvolution_interval = [0,6];
        deconvolution_frequency
        resampling_factor
        deconvolution_interval_size
        deconvolution_interval_timepoints
        signal_duration
        resampled_signal_size
        resampled_signal
        covariates
        durations
        number_of_event_types
        event_times_indices
        duration_indices
        interval = 6
    end
    methods
        function obj = FIRdeconvolution_vars
            if height(obj.signal) == 1
                obj.signal = obj.signal(:,ones(1,1));
            end
            if isempty(obj.event_strings) == 1
                obj.event_strings = zeros(height(obj.event_time),1);
                for h = 1:height(obj.event_time)
                    obj.event_strings(h,1) = string(obj.event_time(h));
                end
            end
                
            obj.event = struct('event_names',obj.event_strings,'event_time',obj.event_time);
            
%             obj.sample_frequency = sample_frequency;
            if isempty(obj.deconvolution_frequency)
                obj.deconvolution_frequency = obj.sample_frequency;
            else
                obj.deconvolution_frequency = deconvolution_frequency;
            end

            obj.resampling_factor = obj.sample_frequency/obj.deconvolution_frequency;
            obj.deconvolution_interval_size = round((obj.deconvolution_interval(2) - obj.deconvolution_interval(1)) * obj.deconvolution_frequency);
            %obj.deconvolution_interval_size = round((obj.deconvolution_interval(2) - obj.deconvolution_interval(1)) * 100);

%           self.deconvolution_interval_size = round((self.deconvolution_interval(2) - self.deconvolution_interval(1)) * self.deconvolution_frequency);
% if abs(round(obj.deconvolution_interval_size) - obj.deconvolution_interval_size) > eps
%                 fprintf('obj.deconvolution_interval_size, %3.6f should be integer. I don''t know why, but it''s neater.\n', obj.deconvolution_interval_size);
%             end
            obj.deconvolution_interval_size = int32(obj.deconvolution_interval_size);
            obj.deconvolution_interval_timepoints = linspace(obj.deconvolution_interval(1), obj.deconvolution_interval(2), obj.deconvolution_interval_size);
            
            % duration of signal in seconds and at deconvolution frequency
%             obj.signal_duration = size(obj.signal,1)/obj.sample_frequency;
%             obj.resampled_signal_size = double(int32(obj.signal_duration*obj.deconvolution_frequency));
%             obj.resampled_signal = resample(obj.signal, obj.resampled_signal_size, 1);

%             obj.covariates = struct(obj.event_strings(1),ones(length(obj.event_time(1))));
%             %obj.covariates = struct(obj.event_strings,'covariates',ones(length(obj.event_time),1));
%             obj.durations = struct('event_names',obj.event_strings,'covariates',ones(length(obj.event_strings),1)./obj.deconvolution_frequency);
            obj.number_of_event_types = 2;
            %obj.event_times_indices = struct('event_names',obj.event_strings,'event_time_indices',(obj.event_time + obj.deconvolution_interval(1))*obj.deconvolution_frequency);
            dura_indices = NaN(height(obj.eventnames),1);
            for ev = 1:height(obj.eventnames)
                dura_indices(ev,1) = obj.durations(ev)*obj.deconvolution_frequency;
            end
            obj.duration_indices = struct('event_names',obj.event_strings,'duration_indices',dura_indices);
%             self.event_times_indices = dict(zip(self.event_names, [((ev + self.deconvolution_interval[0])*self.deconvolution_frequency).astype(int) for ev in events]))
%             # convert the durations to samples/ indices also
%             self.duration_indices = dict(zip(self.event_names, [(self.durations[ev]*self.deconvolution_frequency).astype(int) for ev in self.event_names]))
              
        end

    end
end