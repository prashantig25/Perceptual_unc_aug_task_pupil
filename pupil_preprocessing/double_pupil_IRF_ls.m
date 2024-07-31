function ls2 = double_pupil_IRF_ls(s1,s2,n1,n2,tmax1,tmax2,blink_resp,x)

    % function DOUBLE_PUPIL_IRF_LS computes the least squares error 
    % between a double pupil impulse response function (IRF) model and 
    % observed blink response data. The model consists of two  
    % kernels parameterized by s1, s2, n1, n2, tmax1, and tmax2. 
    % The function returns the sum of squared differences between the model 
    % prediction and the actual blink response.
    %
    % INPUTS:
    %   s1: Scaling factor for the first kernel component.
    %   s2: Scaling factor for the second kernel component.
    %   n1: Shape parameter for the first kernel component.
    %   n2: Shape parameter for the second kernel component.
    %   tmax1: Time to peak for the first kernel component.
    %   tmax2: Time to peak for the second kernel component.
    %   blink_resp: Observed blink response data (vector).
    %   x: Time vector over which the IRF is evaluated (vector).
    %
    % OUTPUT:
    %   ls2: Least squares error between the model prediction and the observed
    %   blink response.

    e = exp(1);
    kernel2 = s1 .* ((x.^n1) .* (e.^((-n1.*x)/tmax1))) + s2 .* ((x.^n2) .* (e.^((-n2.*x)/tmax2)));
    ls2 = sum((kernel2 - blink_resp).^2);
end
