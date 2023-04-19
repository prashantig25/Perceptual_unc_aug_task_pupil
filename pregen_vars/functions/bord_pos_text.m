function [bord_pos, bord_text]= bord_pos_text(num_trials, con, state_mu, pos, cong)
    % BORD_POS_TEXT generates the position of red/green border and the word
    % LEFT/RIGHT for the question during slider phase
    % INPUT:
    	% num_trials = number of trials in a block
    	% con = contrast of block
    	% state_mu = state of trial during slider phase in a block
    	% pos = position on PsychoPy screen
     	% cong = congruence of a block
     % OUTPUT:
     	% bord_pos = position of red/green on the screen for PsychoPy
      	% bord_text = string indicating which patch they need to report the mu

    bord_pos = NaN(num_trials,1);
    bord_text = [];
    
	% BORDER POSITION DEPENDING ON CONTRAST OF A BLOCK
	for i = 1:num_trials
        if con(1) == 1
            if state_mu(i) == 1
                bord_pos(i) = -pos;
            else
                bord_pos(i) = pos;
            end
        else
            if state_mu(i) == 0
                bord_pos(i) = -pos;
            else
                bord_pos(i) = pos;
            end
        end
    end

	% BORDER POSITION DEPENDING ON CONGRUENCE OF A BLOCK
    for i = 1:num_trials
        if cong(1) == 0
                bord_pos(i) = -1*bord_pos(i);
        end
    end
    
    % BORDER TEXT DEPENDING ON THE POSITION OF BORDER ON SCREEN
    for i = 1:num_trials
        if bord_pos(i) < 0
            bord_text = [bord_text;"left"];
        elseif bord_pos(i) > 0
            bord_text = [bord_text;"right"];
        end
    end
end