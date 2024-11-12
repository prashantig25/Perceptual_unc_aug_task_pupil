function [pupil_bins,xgaze_bins,y_gaze_bins,data_bins]=get_binned_data(binned_accuracy,preds,r)
     if binned_accuracy
         pupil_bins=pupil_signal(preds.correct==r,:);
         xgaze_bins=xgaze_signal(preds.correct==r,:);
         y_gaze_bins=ygaze_signal(preds.correct==r,:);
         data_bins=behv_data(preds.correct==r,:);
     else
         pupil_bins=pupil_signal(preds.bin_columns==r,:);
         xgaze_bins=xgaze_signal(preds.bin_columns==r,:);
         y_gaze_bins=ygaze_signal(preds.bin_columns==r,:);
         data_bins=behv_data(preds.bin_columns==r,:);            
     end
end
