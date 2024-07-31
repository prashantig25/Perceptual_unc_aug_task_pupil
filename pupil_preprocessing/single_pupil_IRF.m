function model = single_pupil_IRF(s1,n1,tmax1,x_values)

    % function SINGLE_PUPIL_IRF generates a single pupil impulse response 
    % function (IRF) model.
    %
    % INPUTS:
    %   s1: Scaling factor for the kernel component.
    %   n1: Shape parameter for the kernel component.
    %   tmax1: Time to peak for the kernel component.
    %   x_values: Time vector over which the IRF is evaluated (vector).
    %
    % OUTPUT:
    %   model: Calculated IRF values over the input time vector x_values (vector).

    e = exp(1);
    model = s1 .* ((x_values.^n1) .* (e.^((-n1.*x_values)/tmax1)));
end