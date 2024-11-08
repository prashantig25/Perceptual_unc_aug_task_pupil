classdef FIRdeconvolution_vars < handle
% FIRdeconvolution_vars class specifies and generates parameters for the deconvolution analysis.

    properties
        signal = zeros(1,100);% pupil signal
        eventnames % event names
        event_strings % should be empty, and then add string event times
        event_time = [1,2,3,4,5,6,8]; % timepoints for blinks and saccades
        event
        sample_frequency = 10 % sampling frequency
        deconvolution_interval = [0,6]; % deconvolution interval
        deconvolution_frequency % sampling frequency for deconvolution
        resampling_factor % sampling frequency for resampling after deconvolution
        deconvolution_interval_size % size of deconvolution interval
        deconvolution_interval_timepoints % timepoints within the deconvolution interval
        signal_duration % signal duration
        resampled_signal_size % size of signal after resampling
        resampled_signal % resampled signal
        covariates % covariates
        durations % duration
        number_of_event_types % number of events
        event_times_indices % events 
        duration_indices % duration indices array
        interval = 6 % deconvolution interval
    end
    methods
        function obj = FIRdeconvolution_vars

            % INITIALIZE VARS

            % variable to store pupil signal
            if height(obj.signal) == 1
                obj.signal = obj.signal(:,ones(1,1));
            end

            % event name strings
            if isempty(obj.event_strings) == 1
                obj.event_strings = zeros(height(obj.event_time),1);
                for h = 1:height(obj.event_time)
                    obj.event_strings(h,1) = string(obj.event_time(h));
                end
            end           
            obj.event = struct('event_names',obj.event_strings,'event_time',obj.event_time);

            % deconvolution frequency, indices and interval
            if isempty(obj.deconvolution_frequency)
                obj.deconvolution_frequency = obj.sample_frequency;
            else
                obj.deconvolution_frequency = deconvolution_frequency;
            end
            obj.resampling_factor = obj.sample_frequency/obj.deconvolution_frequency;
            obj.deconvolution_interval_size = round((obj.deconvolution_interval(2) - obj.deconvolution_interval(1)) * obj.deconvolution_frequency);
            obj.deconvolution_interval_size = int32(obj.deconvolution_interval_size);
            obj.deconvolution_interval_timepoints = linspace(obj.deconvolution_interval(1), obj.deconvolution_interval(2), obj.deconvolution_interval_size);       
            obj.number_of_event_types = 2;
            dura_indices = NaN(height(obj.eventnames),1);
            for ev = 1:height(obj.eventnames)
                dura_indices(ev,1) = obj.durations(ev)*obj.deconvolution_frequency;
            end
            obj.duration_indices = struct('event_names',obj.event_strings,'duration_indices',dura_indices);
        end

    end
end