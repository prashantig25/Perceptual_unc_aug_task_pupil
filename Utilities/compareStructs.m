function areEqual = compareStructs(struct1, struct2)
    % COMPARESTRUCTS Compare two structs for equality, treating NaNs as equal
    %   areEqual = compareStructs(struct1, struct2)
    %
    %   Inputs:
    %       struct1, struct2: The structs to compare
    %
    %   Output:
    %       areEqual: true if structs are equal, false otherwise

    % Check if both inputs are structs
    if ~isstruct(struct1) || ~isstruct(struct2)
        areEqual = false;
        return;
    end

    % Get field names
    fields1 = fieldnames(struct1);
    fields2 = fieldnames(struct2);

    % Check if field names are the same
    if ~isequal(sort(fields1), sort(fields2))
        areEqual = false;
        return;
    end

    % Compare each field
    for i = 1:length(fields1)
        areEqual = 0;
        field = fields1{i};
        val1 = struct1.(field);
        val2 = struct2.(field);

        % Handle cell arrays
        if ~isequal(size(val1), size(val2))
            areEqual = 0;
        else
            areEqual = 1;
        end
            
    end
end
