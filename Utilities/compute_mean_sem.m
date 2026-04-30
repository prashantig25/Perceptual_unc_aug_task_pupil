function [mean_data, sem_data] = compute_mean_sem(data)
    % compute_mean_sem computes mean and standard error of mean of
    % a dataset.
    %
    % INPUT:
    %   data: dataset 
    %
    % OUTPUT:
    %   mean_data: mean of data
    %   sem_data: standard error of mean of data
    % 

    mean_data = mean(data,"omitnan");
    sem_data = std(data,"omitnan")./sqrt(length(data));
end