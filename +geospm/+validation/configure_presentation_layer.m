% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2020,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function [result, options] = configure_presentation_layer(varargin)
    
    % category:   {overlay, underlay}
    % blend_mode: {normal, multiply}
    
    options = hdng.utilities.parse_struct_from_varargin(varargin{:});

    if ~isfield(options, 'type')
        error('geospm.validation.configure_presentation_layer() is missing an type argument.');
    end

    if ~isfield(options, 'identifier')
        error('geospm.validation.configure_presentation_layer() is missing an identifier argument.');
    end

    if ~isfield(options, 'category')
        options.category = 'overlay';
    end
    
    if ~isfield(options, 'blend_mode')
        options.blend_mode = 'normal';
    end
    
    result = struct();
    
    result.type = options.type;
    result.identifier = options.identifier;
    result.category = options.category;
    result.blend_mode = options.blend_mode;
end

