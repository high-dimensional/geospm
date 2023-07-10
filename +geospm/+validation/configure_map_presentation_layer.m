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

function [result, options] = configure_map_presentation_layer(varargin)
    
    [result, options] = geospm.validation.configure_presentation_layer(varargin{:}, 'type', 'map');

    if ~isfield(options, 'service_identifier')
        options.service_identifier = 'default';
    end
    
    if ~isfield(options, 'layers')
        options.layers = 'all';
    end
    
    if ~isfield(options, 'pixel_density')
        options.pixel_density = 1.0;
    end
    
    result.service_identifier = options.service_identifier;
    result.layers = options.layers;
    result.pixel_density = options.pixel_density;
end
