function ls1 = single_pupil_IRF_ls(s1,n1,tmax1,x_values,blink_resp)

    % function SINGLE_PUPIL_IRF_LS calculates the residuals for a single 
    % pupil impulse response function (IRF) model.
    %
    % INPUTS:
    %   s1: Scaling factor for the kernel component.
    %   n1: Shape parameter for the kernel component.
    %   tmax1: Time to peak for the kernel component.
    %   x_values: Time vector over which the IRF is evaluated (vector).
    %   blink_resp: Observed blink response data (vector).
    %
    % OUTPUT:
    %   ls1: Residuals between the model prediction and the observed blink
    %         response (vector).

    e = exp(1);
    model = s1 .* ((x_values.^n1) .* (e.^((-n1.*x_values)/tmax1)));
    ls1 = model - blink_resp;
end