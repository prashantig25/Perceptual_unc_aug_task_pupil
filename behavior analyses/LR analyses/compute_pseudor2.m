clc
clearvars

% Define model configurations as a struct array
models(1).name       = 'abs';
models(1).SSE_best   = "SSE_abs.mat";
models(1).SSE_base   = "SSE_baseline.mat";
models(1).csv_out    = "partialR2_abs.csv";
models(1).mat_out    = "partialR2_abs.mat";

models(2).name       = 'signed';
models(2).SSE_best   = "SSE_signed.mat";
models(2).SSE_base   = "SSEsigned_baseline.mat";
models(2).csv_out    = "partialR2_signed.csv";
models(2).mat_out    = "partialR2_signed.mat";

subj_ids  = importdata("subj_ids.mat");
num_sess  = importdata("num_sess.mat");
numSubjs  = length(num_sess);
col       = 300;

%% Loop over both model types
for m = 1:length(models)

    SSE_best     = importdata(models(m).SSE_best);
    SSE_baseline = importdata(models(m).SSE_base);

    partial_rsq_Wpupil = NaN(numSubjs, col);

    partial_rsq = compute_partialrsqSSE(SSE_baseline, SSE_best);

    safe_saveall(models(m).mat_out, partial_rsq);

    statTbl = table({models(m).name}, round(mean(partial_rsq), 2), ...
                    'VariableNames', {'name', 'partial_R2'});

    safe_saveall(models(m).csv_out, statTbl);

end