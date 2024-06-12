function ls1 = single_pupil_IRF_ls(s1,n1,tmax1,x_values,blink_resp)
    e = exp(1);
    model = s1 .* ((x_values.^n1) .* (e.^((-n1.*x_values)/tmax1)));
    %ls1 = sum((model - blink_resp).^2);
    ls1 = model - blink_resp;
end