classdef TestPupilRegression < PupilRegression
    % Mock class for testing PupilRegression
    
    methods
        
        function [residuals_subj, predicted_subj] = processSubject(obj, i, ~)
            % Mock processSubject function for unit testing

            % Deterministic output
            residuals_subj = [0.1, 0.1, 0.1];         
            predicted_subj = [0.1, 0.2, 0.3];
            obj.betas_struct.with_intercept(:,:,i) = i;
            
        end
    end
end