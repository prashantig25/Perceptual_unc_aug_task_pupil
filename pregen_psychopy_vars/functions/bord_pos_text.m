function [bord_pos,bord_text]= bord_pos_text(num_trials,con,state_mu,pos)
    % BORD_POS_TEXT generates the position of red/green border and the word
    % LEFT/RIGHT for the question during slider phase

    % num_trials = number of trials in a block
    % con = contrast of block
    % state_mu = state of trial during slider phase in a block
    % pos = position on PsychoPy screen

    bord_pos = NaN(num_trials,1);
    bord_text = [];
% red/green border position around patch
    for i = 1:num_trials
        if con == 1
            if state_mu(i) == 1
                bord_pos(i) = -pos;
            else
                bord_pos(i) = pos;
            end
        else
            if state_mu(i) == 0
                bord_pos(i) = pos;
            else
                bord_pos(i) = -pos;
            end
        end
    end
    
    % red/green border text to indicate the patch for which participants should report the mu
    for i = 1:num_trials
        if bord_pos(i) < 0
            bord_text = [bord_text;"left"];
        elseif bord_pos(i) > 0
            bord_text = [bord_text;"right"];
        end
    end
end