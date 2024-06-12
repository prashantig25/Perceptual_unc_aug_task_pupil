function [pupil_data] = conv2table(data)

    % convert arbitary pupil size obtained from Eye-link to mm.
    % data = array with pupil data in arbitary units.
    % art_diam = diameter of artificial pupil size (usually 3.5 mm).
    % arbit_size = arbitary pupil diameter of the artificial eye (usually
    % 1473).
    % pupil_mm = converted pupil diameter in mm
    
%     scaling_factor = art_diam/sqrt(arbit_size);
%     pupil_mm = zeros(length(data(:,4)),1);
%     pupil = data(:,4);
%     for i = 1:length(pupil)
%         data_mm = sqrt(pupil(i))*scaling_factor;
%         pupil_mm(i) = data_mm;
%     end
%     data(:,4) = pupil_mm;
    pupil_data = array2table(data,"VariableNames",{'time_stamp','eye_x','eye_y','pupil_diam'});
end