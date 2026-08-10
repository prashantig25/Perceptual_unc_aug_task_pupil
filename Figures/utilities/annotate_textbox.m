function annotate_textbox(gca, position, content, font_name, font_size,...
    horz_align, vert_align, bg_color, face_alpha, edge_color, varargin)
    % function annotate_textbox adds a textbox and customises it in a figure.
    %
    %   INPUT:
    %       gca: Current axes
    %       position: Textbox position [left, bottom, width, height]
    %       content: Text string or image
    %       font_name: Font for string
    %       font_size: Font size
    %       horz_align: Horizontal alignment
    %       vert_align: Vertical alignment
    %       bg_color: Background color
    %       face_alpha: Alpha of bg_color
    %       edge_color: Color for box edge
    %       varargin{1}: Line width
    %       varargin{2}: Line style
    %
    %   Return:
    %       None
    
    hold(gca, 'on');
    
    % Draw background border box
    box1 = rectangle('Parent', gca, 'Position', position, 'EdgeColor', edge_color);
    if strcmpi(bg_color, 'none')
        box1.FaceColor = 'none';
    else
        box1.FaceColor = [validatecolor(bg_color), face_alpha];
    end
    
    % Line style
    if ~isempty(varargin)
        box1.LineWidth = varargin{1};
        box1.LineStyle = varargin{2};
    end
    
    % Check for images vs text cells
    is_image = false;
    is_text_cell = false;
    img_cells = {};
    text_cells = {};
    
    if iscell(content)
        if all(cellfun(@(c) (ischar(c) || isstring(c)) && exist(c, 'file') == 2, content))
            img_cells = content;
            is_image = true;
        elseif all(cellfun(@(c) ischar(c) || isstring(c), content))
            text_cells = content;
            is_text_cell = true;
        end
    elseif ischar(content) || isstring(content)
        if exist(content, 'file') == 2
            img_cells = {content};
            is_image = true;
        end
    end
    
    % Extract base box metrics
    box_left = position(1);
    box_bottom = position(2);
    box_width = position(3);
    box_height = position(4);
    
    % If image:
    if is_image
        parent_fig = ancestor(gca, 'figure');
        num_imgs = length(img_cells);
    
        % Keep image axis transparent ('none') so the rectangle's background color shows through
        if num_imgs == 1
            img_ax1 = axes(parent_fig, 'Units', 'pixels', 'Color', 'none', 'XTick', [], 'YTick', []); imshow(img_cells{1}, 'Parent', img_ax1); img_axes = {img_ax1};
        elseif num_imgs == 2
            img_ax1 = axes(parent_fig, 'Units', 'pixels', 'Color', 'none', 'XTick', [], 'YTick', []); imshow(img_cells{1}, 'Parent', img_ax1);
            img_ax2 = axes(parent_fig, 'Units', 'pixels', 'Color', 'none', 'XTick', [], 'YTick', []); imshow(img_cells{2}, 'Parent', img_ax2);
            img_axes = {img_ax1, img_ax2};
        end
        update_positions = @(src, event) reposition_images(gca, position, img_axes); update_positions([], []);
        if isempty(parent_fig.SizeChangedFcn)
            parent_fig.SizeChangedFcn = update_positions;
        else
            old_callback = parent_fig.SizeChangedFcn; parent_fig.SizeChangedFcn = @(src, event) execute_multiple_callbacks(old_callback, update_positions, src, event);
        end
    
        % If 2 text strings:
    elseif is_text_cell && length(text_cells) == 2
        half_width = box_width / 2;
        y_center   = box_bottom + (box_height / 2);
    
        % We calculate the text center offsets to mirror the 10% image padding gap
        img_pad_offset = (half_width - box_height) / 2;
        text_center_1  = box_left + img_pad_offset + (box_height / 2);
        text_center_2  = box_left + half_width + img_pad_offset + (box_height / 2);
    
        % Left sub-text
        t1 = text(text_center_1, y_center, text_cells{1}, 'Parent', gca);
        set(t1, 'Units', 'data', 'FontName', font_name, 'FontSize', font_size, ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    
        % Right sub-text
        t2 = text(text_center_2, y_center, text_cells{2}, 'Parent', gca);
        set(t2, 'Units', 'data', 'FontName', font_name, 'FontSize', font_size, ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    
        % If 1 text string:
    elseif ~isempty(content)
        x_center = box_left + box_width/2;
        y_center = box_bottom + box_height/2;
        text1 = text(x_center, y_center, content, 'Parent', gca);
        set(text1, 'Units', 'data', 'FontName', font_name, 'FontSize', font_size, ...
            'HorizontalAlignment', horz_align, 'VerticalAlignment', vert_align);
    end
    set(gca, 'YDir', 'normal');
    end
    
    %% HELPER FUNCTIONS
    
    function reposition_images(main_ax, data_pos, img_axes)
    % REPOSITION_IMAGES Adjust image so that it does not overlap with box
    % borders
    %
    %   INPUT:
    %       main_ax: Current plot axis
    %       data_pos: Image data
    %       img_axes: Axes of images
    %   
    %   Return:
    %       None
    
    if ~isvalid(main_ax), return; end
    
    orig_units = main_ax.Units;
    main_ax.Units = 'pixels';
    ax_pixel_pos = main_ax.Position;
    main_ax.Units = orig_units;
    
    xl = xlim(main_ax);
    yl = ylim(main_ax);
    
    px_left   = ax_pixel_pos(1) + (data_pos(1) - xl(1)) / (xl(2) - xl(1)) * ax_pixel_pos(3);
    px_bottom = ax_pixel_pos(2) + (data_pos(2) - yl(1)) / (yl(2) - yl(1)) * ax_pixel_pos(4);
    px_width  = (data_pos(3) / (xl(2) - xl(1))) * ax_pixel_pos(3);
    px_height = (data_pos(4) / (yl(2) - yl(1))) * ax_pixel_pos(4);
    
    % 0.10 means 10% of the box height will be used as empty border spacing around the image
    pad_fraction = 0.10;
    pixel_padding = px_height * pad_fraction;
    
    % Shrink the effective height used for the square calculation
    square_px = px_height - (2 * pixel_padding);
    
    % Number of images
    num_imgs = length(img_axes);
    
    % Position images correctly
    if num_imgs == 1 && isvalid(img_axes{1})
        x_offset = (px_width - square_px) / 2;
        img_axes{1}.Position = [px_left + x_offset, px_bottom + pixel_padding, square_px, square_px];
    
    elseif num_imgs == 2 && isvalid(img_axes{1}) && isvalid(img_axes{2})
        half_px_width = px_width / 2;
    
        % Calculate centered offsets while incorporating the bottom and side padding buffers
        x_offset_1 = (half_px_width - square_px) / 2;
        img_axes{1}.Position = [px_left + x_offset_1, px_bottom + pixel_padding, square_px, square_px];
    
        x_offset_2 = half_px_width + (half_px_width - square_px) / 2;
        img_axes{2}.Position = [px_left + x_offset_2, px_bottom + pixel_padding, square_px, square_px];
    end
    end
    
    function execute_multiple_callbacks(cb1, cb2, src, event)
    %EXECUTE_MULTIPLE_CALLBACKS Helpter function to update image position when
    %rescaling plot manually
    
    if ~isempty(cb1)
        if isa(cb1, 'function_handle')
            cb1(src, event);
        elseif iscell(cb1)
            feval(cb1{1}, src, event, cb1{2:end});
        end
    end
    if isa(cb2, 'function_handle')
        cb2(src, event);
    end
end