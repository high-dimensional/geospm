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

function [result, options] = configure_image_field_presentation_layer(varargin)
    
    [result, options] = geospm.validation.configure_presentation_layer(varargin{:}, 'type', 'image-field');

    if ~isfield(options, 'record_path')
        error('geospm.validation.configure_image_field_presentation_layer() is missing a record_path argument.');
    end
    if ~isfield(options, 'property_path')
        error('geospm.validation.configure_image_field_presentation_layer() is missing a property_path argument.');
    end
    
    result.record_path = options.record_path;
    result.property_path = options.property_path;
end
