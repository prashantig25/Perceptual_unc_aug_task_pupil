function model = single_pupil_IRF(s1,n1,tmax1,x_values)
    e = exp(1);
    model = s1 .* ((x_values.^n1) .* (e.^((-n1.*x_values)/tmax1)));
end