function [pupil_clean_bp, pupil_clean_lp] = perform_convolutionGLM(blink_reg, blink_kernel, sacc_reg, sacc_kernel, band_pupil, low_pupil)
    
    % function PERFORM_CONVOLUTIONGLM perform convolution and GLM to clean pupil signals
    %
    % INPUTS:
    %   blink_reg: Blink regressor
    %   blink_kernel: Blink kernel for convolution
    %   sacc_reg: Saccade regressor
    %   sacc_kernel: Saccade kernel for convolution
    %   band_pupil: Band-pass filtered pupil data
    %   low_pupil: Low-pass filtered pupil data
    %
    % OUTPUT:
    %   pupil_clean_bp: Cleaned pupil signal after band-pass filtering
    %   pupil_clean_lp: Cleaned pupil signal after low-pass filtering

    % PERFORM THE CONVOLUTION
    blink_reg_conv = conv(blink_reg, blink_kernel, 'full');
    sacc_reg_conv = conv(sacc_reg, sacc_kernel, 'full');
    
    % REMOVE THE PADDING
    blink_reg_conv = blink_reg_conv(1:end-(length(blink_kernel)-1));
    sacc_reg_conv = sacc_reg_conv(1:end-(length(sacc_kernel)-1));
    
    % GLM
    regs = vertcat(blink_reg_conv, sacc_reg_conv);
    design_matrix = transpose(regs);
    betas = ((inv(design_matrix'*design_matrix))*design_matrix')*band_pupil;
    betas_regs = [];
    for b = 1:length(betas)
        betas_regs = vertcat(betas_regs, betas(b) .* regs(b,:));
    end
    explained = sum(betas_regs);
    
    % CLEAN PUPIL SIGNAL BY GETTING RID OF EXPLAINED
    pupil_clean_bp = band_pupil - explained';
    pupil_clean_lp = pupil_clean_bp + (low_pupil - band_pupil);
end
