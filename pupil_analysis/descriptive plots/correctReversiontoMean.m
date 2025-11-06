clc
clearvars

% INITIALISE STUFF

subj_ids = {'0806','3970','4300','4885','4954','907','2505','3985','4711',...
    '3376','4927','190','306','3391','5047','3922','659','421','3943',...
    '4225','4792','3952','4249','4672','4681','4738','3904','852','3337',...
    '3442','3571','4360','4522','4807','4943','594','379','4057','4813','601',...
    '3319','129','4684','3886','620','901','900'}; % subject IDs
num_sess = [1,1,1,1,1,1,1,1,1,1,1,2,2,1,1,1,1,1,1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]; % number of sessions
numSubjs = length(num_sess);
psuedobaseline_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript" + ...
    "/Perceptual_unc_aug_task_pupil-main/NatCommns Revisions/Reviewer 2/pupil/pupil signa" + ...
    "l/preprint pipeline/pseudobaseline for correction to reversion to mean new";
fb_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/" + ...
    "NatCommns Revisions/Reviewer 2/pupil/pupil signal/preprint pipeline/" + ...
    "fb for correction to reversion to mean new";
save_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/NatCommns Revisions/Reviewer 2/" + ...
    "pupil/pupil signal/preprint pipeline/corrected new";
fb_preprintbaseline_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript" + ...
    "/Perceptual_unc_aug_task_pupil-main/data/GB data peak corrected/" + ...
    "pupil/pupil signal/non-baseline corrected fb";
x_pseudo = linspace(-1800, 0, 180); % time window
x_fb = linspace(-300, 1500, 180); % time window

for n = 6:numSubjs
    figure(Position=[200,200,700,300],Visible="off")
    hold on

    % get 1800 ms of baseline pupil signal (depending on the timeseries of the
    % event + baseline acc to Mridha et al., 2021) before the event
    psuedobaseline = importdata(strcat(psuedobaseline_dir,filesep, subj_ids{n},".mat"));

    % get 1500 ms after event + 300 ms before event (the baseline we used in our preprint)
    fb = importdata(strcat(fb_dir,filesep,subj_ids{n},".mat"));

    mean_pseudobaseline = nanmean(psuedobaseline(:,1:30),2);
    edges = prctile(mean_pseudobaseline, linspace(0,100,9));
    bin_idx = discretize(mean_pseudobaseline, edges);

    for b = 1:length(unique(bin_idx))

        psuedobaseline_binned(b,:) = nanmean(psuedobaseline(bin_idx ==b, :));
        fb_binned(b,:) = nanmean(fb(bin_idx ==b, :));

    end

    nBins = length(unique(bin_idx));
    blues = [linspace(0.7, 0, nBins)', linspace(0.85, 0.2, nBins)', ones(nBins,1)]; % light to dark blue

    subplot(1,3,1)
    hold on
    for b = 1:nBins
        plot(x_pseudo, psuedobaseline_binned(b,:), 'Color', blues(b,:), 'LineWidth', 3)
    end
    plot(x_pseudo, nanmean(psuedobaseline_binned), 'Color', [0.8,0.5,0.7], 'LineWidth', 0.5)
    xlim([-1800,0])
    xlabel("Time (ms)")
    ylabel("Psuedo-baseline")
    xline(-1500)

    subplot(1,3,2)
    hold on
    for b = 1:nBins
        plot(x_fb, fb_binned(b,:), 'Color', blues(b,:), 'LineWidth', 3)
    end
    plot(x_fb, nanmean(fb_binned), 'Color', [0.8,0.5,0.7], 'LineWidth', 0.5)
    xlim([-300,1500])
    xlabel("Time (ms)")
    ylabel("fb locked (non-baseline corrected)")
    xline(0)

    % subtract the two
    correctedSignal = fb_binned - psuedobaseline_binned;

    subplot(1,3,3)
    hold on
    for b = 1:nBins
        plot(x_fb, correctedSignal(b,:), 'Color', blues(b,:), 'LineWidth', 3)
    end
    plot(x_fb, nanmean(correctedSignal), 'Color', [0.8,0.5,0.7], 'LineWidth', 5)
    xlim([-300,1500])
    xlabel("Time (ms)")
    ylabel("fb locked (corrected)")
    xline(0)

    % get our fb from preprint
    fb_preprint = importdata(strcat(fb_preprintbaseline_dir,filesep,subj_ids{n},".mat"));
    hold on
    plot(x_fb, nanmean(fb_preprint(:,1:180)), 'Color', [0.2,0.9,0.7], 'LineWidth', 5)

    % save
    % safe_saveall(strcat(save_dir,"\",subj_ids{n},".mat"),correctedSignal);
    saveas(gcf,subj_ids{n},'png')
end






