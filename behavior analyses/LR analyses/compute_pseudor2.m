clc
clearvars
signed = 1; % if partial R2 to be calculated for signed model
save_csv = 1; % if stat to be saved as CSV file for overleaf MS
if signed == 1
    SSE_best = importdata("SSE_signed.mat"); % SSE for best model
    SSE_baseline = importdata("SSEsigned_baseline.mat"); % SSE for baseline model
    partialR2_csv = "partialR2_signed.csv";
    mdl_name = {'signed'};
else
    SSE_best = importdata("SSE_abs.mat");
    SSE_baseline = importdata("SSE_baseline.mat");
    partialR2_csv = "partialR2_abs.csv";
    mdl_name = {'abs'};
end
num_subjs = 47;
col = 300;
%%

partial_rsq_Wpupil = NaN(num_subjs,col);
partial_rsq = compute_partialrsqSSE(SSE_baseline,SSE_best); % using SSE

safe_saveall("partialR2_signed.mat",partial_rsq)
statTbl = table(mdl_name,round(mean(partial_rsq),2),'VariableNames',{'name','partial_R2'});
safe_saveall(partialR2_csv,statTbl);
