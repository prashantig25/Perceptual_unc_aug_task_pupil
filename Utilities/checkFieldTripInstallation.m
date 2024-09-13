function checkFieldTripInstallation()
    % Check if FieldTrip is installed and on the MATLAB path
    if ~exist('ft_defaults', 'file')
        error('FieldTrip:NotInstalled', ...
              ['FieldTrip toolbox is not installed or not on the MATLAB path.\n' ...
               'Please install FieldTrip and add it to your MATLAB path using:\n' ...
               'addpath(''path/to/fieldtrip'');\n' ...
               'ft_defaults;']);
    end
    
    % Attempt to run ft_defaults to ensure FieldTrip is properly initialized
    try
        ft_defaults;
    catch ME
        error('FieldTrip:InitializationError', ...
              ['FieldTrip is installed but could not be initialized.\n' ...
               'Error message: %s'], ME.message);
    end
    
    % Check FieldTrip version (optional)
    [ftVer, ftPath] = ft_version;
    fprintf('FieldTrip is installed and initialized.\n');
    fprintf('Version: %s\n', ftVer);
    fprintf('Path: %s\n', ftPath);
end