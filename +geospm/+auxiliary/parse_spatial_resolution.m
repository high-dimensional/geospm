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

function [options] = parse_spatial_resolution(spatial_data, options)

    if ~isfield(options, 'min_location')
        options.min_location = floor(spatial_data.min_xyz);
    end
    
    if ~isfield(options, 'max_location')
        options.max_location = ceil(spatial_data.max_xyz);
    end
    
    if ~isfield(options, 'spatial_resolution')
        
        range = options.max_location - options.min_location;

        landscape_orientation = range(1) >= range(2);
        
        if isfield(options, 'spatial_resolution_x')
            if isfield(options, 'spatial_resolution_y')
                options.spatial_resolution = ...
                    [ceil(options.spatial_resolution_x) ...
                     ceil(options.spatial_resolution_y) ...
                     1];
            else
                range = range ./ range(1);
                
                options.spatial_resolution = ...
                    [ceil(options.spatial_resolution_x) ...
                     ceil(ceil(options.spatial_resolution_x) * range(2)) ...
                     1];
            end
        elseif isfield(options, 'spatial_resolution_y')
            range = range ./ range(2);

            options.spatial_resolution = ...
                [ceil(ceil(options.spatial_resolution_y) * range(1)) ...
                 ceil(options.spatial_resolution_y) ...
                 1];
        elseif isfield(options, 'spatial_resolution_min')
            
            if ~landscape_orientation
            
                range = range ./ range(1);
                
                options.spatial_resolution = ...
                    [ceil(options.spatial_resolution_min) ...
                     ceil(ceil(options.spatial_resolution_min) * range(2)) ...
                     1];
            else

                range = range ./ range(2);

                options.spatial_resolution = ...
                    [ceil(ceil(options.spatial_resolution_min) * range(1)) ...
                     ceil(options.spatial_resolution_min) ...
                     1];
            end
             
        else
            
            if ~isfield(options, 'spatial_resolution_max')
                options.spatial_resolution_max = 200;
            end
            
            if landscape_orientation
            
                range = range ./ range(1);
                
                options.spatial_resolution = ...
                    [ceil(options.spatial_resolution_max) ...
                     ceil(ceil(options.spatial_resolution_max) * range(2)) ...
                     1];
            else

                range = range ./ range(2);

                options.spatial_resolution = ...
                    [ceil(ceil(options.spatial_resolution_max) * range(1)) ...
                     ceil(options.spatial_resolution_max) ...
                     1];
            end
        end
    end
end
