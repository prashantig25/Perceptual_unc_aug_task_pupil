function ls2 = double_pupil_IRF_ls(s1,s2,n1,n2,tmax1,tmax2,blink_resp,x)
%     whos params_array
%     whos x
%     whos blink_resp
    e = exp(1);
%     s1 = params_array(1);
%     s2 = params_array(2);
%     n1 = params_array(3);
%     n2 = params_array(4);
%     tmax1 = params_array(5);
%     tmax2 = params_array(6);
    kernel2 = s1 .* ((x.^n1) .* (e.^((-n1.*x)/tmax1))) + s2 .* ((x.^n2) .* (e.^((-n2.*x)/tmax2)));
    ls2 = sum((kernel2 - blink_resp).^2);
    %ls2 = kernel2 - blink_resp;
end
