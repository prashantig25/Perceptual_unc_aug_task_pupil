function kernel2 = double_pupil_IRF(s1,s2,n1,n2,tmax1,tmax2,x)

    % function double_pupil_IRF computes the double pupil impulse 
    % response function (IRF).
    %
    % INPUTS:
    %   s1,s2,n1,n2,tmax1,tmax2: set of parameters
    %   x: deconvolution time interval
    %
    % OUTPUT:
    %   kernel2: double pupil impulse response function

    e = exp(1);
    kernel2 = s1 .* ((x.^n1) .* (e.^((-n1.*x)/tmax1))) + s2 .* ((x.^n2) .* (e.^((-n2.*x)/tmax2)));
end
