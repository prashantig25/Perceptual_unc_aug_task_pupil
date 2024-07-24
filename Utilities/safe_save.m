function safe_save(filename, newData)

    % function SAFE_SAVE is a custom replacement for MATLAB's save function
    % to ensure that data does not get saved unexpectedlt.
    % INPUTS:
    %   filename: input string with filename
    %   newData: input data that needs to be saved

    % CHECK IF FILE ALREADY EXISTS
    if isfile(filename)
        oldData = load(filename);
        if isequal(newData, oldData)
            disp('Data is consistent. No need to save.');
        else

            % FOR DIFFERENT DATA, CREATE A NEW FILENAME
            [path, name, ext] = fileparts(filename);
            timestamp = datestr(now, 'yymmdd');
            newFilename = strcat(name, "_", timestamp, ext);
            
            % SAVE WITH NEW FILENAME
            save(fullfile(path,newFilename), 'newData');
            disp(['Data is different. Saved with a new filename: ' newFilename]);
        end
    else
        save(filename, '-struct', 'newData');
        disp(['File does not exist. Saved data to: ' filename]);
    end
end