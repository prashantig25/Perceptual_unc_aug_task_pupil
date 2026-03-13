function [table_data] = conv2table(data)

    % function conv2table converts data array to a table.

    % INPUTS:
        % data: input variable with data array

    % OUTPUTS:
        % table_data: converted data in the table format
    
    table_data = array2table(data,"VariableNames",{'time_stamp','eye_x','eye_y','pupil_diam'});
end