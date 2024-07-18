function residual = remove_rt_effects(pupil,rt)

    % NOTE: code is based on Urai et al., 2017
    %
    % function REMOVE_RT_EFFECTS removes trial-by-trial variations in pupil
    % signal caused by very slow/long RTs
    %
    % INPUT:
    %   pupil: signal from which RT needs to be regressed
    %   rt: reaction-times
    %
    % OUTPUT:
    %   residual: pupil signal after regressing out RTs
    
    % normalise rt
    rt_norm = rt/norm(rt);

    % subtract dot product from pupil (formula: y' = y - (y.'r)r)
    residual = pupil - (pupil'*rt_norm)*rt_norm;
end