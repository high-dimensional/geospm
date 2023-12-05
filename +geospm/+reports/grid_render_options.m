% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2021,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function options = grid_render_options(options)
    
    if ~exist('options', 'var')
        options = struct();
    end
    
    if ~isfield(options, 'origin')
        options.origin = [0, 0];
    end
    
    if ~isfield(options, 'cell_spacing')
        options.cell_spacing = [20, 20];
    end

    if ~isfield(options, 'per_row_column_labels')
        options.per_row_column_labels = false;
    end

    if ~isfield(options, 'magnification')
        options.magnification = 1;
    end

    if ~isfield(options, 'slice_name')
        options.slice_name = 'Unnamed Slice';
    end

    if ~isfield(options, 'collapse_empty_cells')
        options.collapse_empty_cells = false;
    end
end
