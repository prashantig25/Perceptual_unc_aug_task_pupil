%% 

params = struct();
params.s1 = struct('Value', -1, 'Min', -inf, 'Max', -1e-25);
params.s2 = struct('Value', 1, 'Min', 1e-25, 'Max', inf);
% params.s1 = struct('Value', -1, 'Min', -100, 'Max', -1e-25);
% params.s2 = struct('Value', 1, 'Min', 1e-25, 'Max', 100);
params.n1 = struct('Value', 10, 'Min', 9, 'Max', 11);
params.n2 = struct('Value', 10, 'Min', 8, 'Max', 12);
params.tmax1 = struct('Value', 0.9, 'Min', 0.5, 'Max', 1.5);
params.tmax2 = struct('Value', 2.5, 'Min', 1.5, 'Max', 4);

s1_0 = [params.s1.Min,params.s1.Max];
s2_0 = [params.s2.Min,params.s2.Max];
n1_0 = [params.n1.Min,params.n1.Max];
n2_0 = [params.n2.Min,params.n2.Max]; 
tmax1_0 = [params.tmax1.Min,params.tmax1.Max];
tmax2_0 = [params.tmax2.Min,params.tmax2.Max];
x = 1:60;
x_values = x.';

s1 = params.s1.Value;
s2 = params.s2.Value;
n1 = params.n1.Value;
n2 = params.n2.Value;
tmax1 = params.tmax1.Value;
tmax2 = params.tmax2.Value; 

% Define the function to be optimized
fun = @(y) double_pupil_IRF_ls(y(1), y(2), y(3), y(4), y(5), y(6), blink_response, x_values);

% Define the starting point for the optimization
y0 = [s1,s2,n1,n2,tmax1,tmax2];

% define range
% y0 = [linspace(params.s1.Min, params.s1.Max, 10)', linspace(params.s2.Min, params.s2.Max, 10)',...
%      linspace(params.n1.Min, params.n1.Max, 10)', linspace(params.n2.Min, params.n2.Max, 10)',...
%      linspace(params.tmax1.Min, params.tmax1.Max, 10)',linspace(params.tmax2.Min, params.tmax2.Max, 10)']; 

% Perform the optimization
blink_result = fminsearch(fun, y0);

blink_kernel = double_pupil_IRF(blink_result(1),blink_result(2),blink_result(3),blink_result(4), ...
    blink_result(5),blink_result(6),x_values);


% Define the function to be optimized
fun = @(y) double_pupil_IRF_ls(y(1), y(2), y(3), y(4), y(5), y(6), sacc_response, x_values);

% Define the starting point for the optimization
y0 = [s1,s2,n1,n2,tmax1,tmax2];

% Perform the optimization
sacc_result = fminsearch(fun, y0);

sacc_kernel = double_pupil_IRF(sacc_result(1),sacc_result(2),sacc_result(3),sacc_result(4), ...
    sacc_result(5),sacc_result(6),x_values);

figure
plot(blink_response,'r','LineStyle','-.')
hold on
plot(blink_kernel,'b')
hold on
plot(sacc_response,'r','LineStyle','-.')
hold on
plot(sacc_kernel,'b')

x_values = linspace(0,6,6*1000); % linspace(0,interval,interval*sample_rate)
blink_kernel = double_pupil_IRF(blink_result(1),blink_result(2),blink_result(3),blink_result(4),blink_result(5),blink_result(6),x_values);
sacc_kernel = double_pupil_IRF(sacc_result(1),sacc_result(2),sacc_result(3),sacc_result(4),sacc_result(5),sacc_result(6),x_values);

blink_reg = zeros(length(pupil),1);
blink_reg(blinksmp(:,2)) = 1;
blink_reg_conv = conv(blink_reg,blink_kernel,'same');

sacc_reg = zeros(length(pupil),1);
sacc_reg(data_asc.saccsmp(:,2)) = 1;
sacc_reg_conv = conv(sacc_reg,sacc_kernel,'same');

regs = [blink_reg_conv, sacc_reg_conv];

design_matrix = [regs(:)]';
betas = (design_matrix'*design_matrix)\inv*design_matrix'*pupil';
betas = betas(:);
explained = sum(bsxfun(@times, betas, regs),1);

pupil_clean_bp = pupil - explained;


%%
params = struct();
params.s1 = struct('Value', -1, 'Min', -inf, 'Max', -1e-25);
params.s2 = struct('Value', 1, 'Min', 1e-25, 'Max', inf);
params.n1 = struct('Value', 10, 'Min', 9, 'Max', 11);
params.n2 = struct('Value', 10, 'Min', 8, 'Max', 12);
params.tmax1 = struct('Value', 0.9, 'Min', 0.5, 'Max', 1.5);
params.tmax2 = struct('Value', 2.5, 'Min', 1.5, 'Max', 4);

s1_0 = [params.s1.Min,params.s1.Max];
s2_0 = [params.s2.Min,params.s2.Max];
n1_0 = [params.n1.Min,params.n1.Max];
n2_0 = [params.n2.Min,params.n2.Max];
tmax1_0 = [params.tmax1.Min,params.tmax1.Max];
tmax2_0 = [params.tmax2.Min,params.tmax2.Max];
x_values = x.';
x0 = [1,6];
br_0 = [2,7];

s1 = params.s1.Value;
s2 = params.s2.Value;
n1 = params.n1.Value;
n2 = params.n2.Value;
tmax1 = params.tmax1.Value;
tmax2 = params.tmax2.Value; 
y0 = [s1,s2,n1,n2,tmax1,tmax2];
blink_result = @(y)double_pupil_IRF(y(1),y(2),y(3),y(4),y(5),y(6),x_values,blink_response,y0);
%[blink_result, fval] = fminsearch(fun,y);


options = optimset(@fminsearch, 'SearchMethod', 'powell');


[blink_result, fval] = fminsearch(@(params_array)double_pupil_IRF_ls(s1,s2,n1,n2,tmax1,tmax2,blink_response,x.'),[s1,s2]);
% Compute the impulse response using the optimal parameters
blink_kernel = double_pupil_IRF(blink_result, x);

% Minimize the least-squares error for the sac response
sac_result = fminpowell(@(params)single_pupil_IRF_ls(params, x, sac_response), params, options);

% Compute the impulse response using the optimal parameters
sac_kernel = single_pupil_IRF(sac_result, x);

% # upsample:
x = linspace(0, interval, interval*sample_rate);
fit_kernels = fitkernels();
blink_kernel = fit_kernels.double_pupil_IRF();
sac_kernel = fit_kernels.double_pupil_IRF();

%regressors:
blink_tp;
sac_tp;
blink_reg = zeros(1,length(pupil)).';
sac_reg = zeros(1,length(pupil)).';
for l = 1:length(blink_tp)
    blink_reg(blink_tp(l,1):blink_tp(l,2)) = 1;
end
for l = 1:length(sac_tp)
    sac_reg(sac_tp(l,1):sac_tp(l,2)) = 1;
end
blink_reg_conv = conv(blink_reg, blink_kernel, 'same');
sac_reg_conv = conv(sac_reg, sac_kernel, 'same');
regs = [blink_reg_conv, sac_reg_conv];

% GLM:
design_matrix = vertcat(regs(:))';
betas = eye(design_matrix.'*design_matrix)*design_matrix.'*pupil_interpolated_bp(:);
explained_list = [];
for i = 1:length(betas)
    explained_list = vertcat(explained_list,betas(i)*regs(i));
end
explained = sum(explained_list);

% design_matrix = np.matrix(np.vstack([reg for reg in regs])).T
% betas = np.array(((design_matrix.T * design_matrix).I * design_matrix.T) * np.matrix(pupil_interpolated_bp).T).ravel()
% explained = np.sum(np.vstack([betas[i]*regs[i] for i in range(len(betas))]), axis=0)


% This code is performing a Generalized Linear Model (GLM) analysis on a 
% time series of pupil dilation data (pupil). It is using two types of regressors, 
% blink_reg_conv and sac_reg_conv, to explain the variance in the pupil dilation data.
% 
% The first step in this code is creating two binary time series, blink_reg and sac_reg, 
% that indicate the times of blink and saccade events respectively, by setting the values 
% corresponding to the blink and saccade events to 1 and the rest to 0.
% 
% blink_reg[blink_ends] = 1 creates an array of zeros of the same length as pupil, 
% and sets the values corresponding to the blink events to 1.
% sac_reg[sac_ends] = 1 creates an array of zeros of the same length as pupil, 
% and sets the values corresponding to the sac events to 1.
% 
% Then, the fftconvolve function is used to convolve the binary time series 
% with the impulse response functions (IRFs) of blinks and saccades, blink_kernel and sac_kernel respectively. 
% The mode argument is set to 'full' to ensure that the output has the same length as the input and then the convolved signals are truncated to the original length by slicing the last len(kernel)-1 elements.
% 
% blink_reg_conv = sp.signal.fftconvolve(blink_reg, blink_kernel, 'full')[:-(len(blink_kernel)-1)]
% sac_reg_conv = sp.signal.fftconvolve(sac_reg, sac_kernel, 'full')[:-(len(sac_kernel)-1)]
% 
% The two convolved time series are then stacked together in an array regs to form the design matrix of the GLM.
% regs = [blink_reg_conv, sac_reg_conv]
% 
% Next, the design matrix is multiplied by its transpose and the inverse of the product is taken, 
% and it is then multiplied by the transpose of the design matrix and the observed pupil dilation data to get the betas (regression coefficients) of the model.
% 
% betas = np.array(((design_matrix.T * design_matrix).I * design_matrix.T) * np.matrix(pupil_interpolated_bp).T).ravel()
% 
% Finally, the explained variance in the pupil dilation data is calculated 
% by multiplying the betas by the corresponding regressor time series and summing the results.
% explained = np.sum(np.vstack([betas[i]*regs[i] for i in range(len(betas))]), axis=0)
% 
% It's important to note that this code assumes that blink_ends, sac_ends, blink_kernel, 
% sac_kernel and pupil_interpolated_bp have been defined and calculated previously.