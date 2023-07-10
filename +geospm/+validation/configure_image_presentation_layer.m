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

function [result, options] = configure_image_presentation_layer(varargin)
    
    [result, options] = geospm.validation.configure_presentation_layer(varargin{:}, 'type', 'image-file');

    if ~isfield(options, 'path')
        error('geospm.validation.configure_file_layer_source() is missing an path argument.');
    end
    
    result.path = options.path;
end
