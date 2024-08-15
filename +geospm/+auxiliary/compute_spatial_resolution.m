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

function [spatial_resolution, validated_options] = compute_spatial_resolution( ...
    coordinate_span, options)
    
    %{

    Computes a spatial resolution vector from the given coordinate span 
    (specified as a 2 or 3-vector) and one or more optional fields:
    
    Either:
    
	At least one of spatial_resolution_x, spatial_resolution_y or 
    spatial_resolution_z is defined.
    
    If a resolution is defined for a dimension, the ceil() of its value 
    is used. Otherwise, if its spatial extent as defined by coordinate_span
    is non-zero, its resolution is derived by dividing its spatial extent 
    by the smallest defined cell dimension. If its spatial extent is zero, 
    a resolution of 1 will be used.
    
	If the resolution for at least one dimension is specified the other 
	resolution(s) are derived proportionally to coordinate_span.
	
	Or one of:
    
	spatial_resolution_min - number of raster cells along the 
	shorter side of the rectangle/box spanned by min_location and 
	max_location
        
    spatial_resolution_max - number of raster cells along the
	longer side of the rectangle/box spanned by min_location and 
	max_location
	
    Otherwise:

	If no resolution value is specified, a default value of 200
	for spatial_resolution_max is assumed and the spatial resolution is
    computed accordingly.
    
    %}
    
    range = coordinate_span;
    
    if size(range, 2) == 2
        range = [range 0];
    end
    
    nonzero = range > 0.0;
    
    field_names = {'spatial_resolution_x', ...
                   'spatial_resolution_y', ...
                   'spatial_resolution_z'};
    
    fields = [isfield(options, field_names{1}), ...
              isfield(options, field_names{2}), ...
              isfield(options, field_names{3})];

    empty = zeros(1, 3, 'logical');
    
    specified_resolution = [NaN NaN NaN];
          
    for i=1:numel(fields)
        
        if fields(i) == false
            continue
        end
        
        value = options.(field_names{i});
        
        if isempty(value)
            % Ignore for now, we catch empty values below.

            fields(i) = false;
            empty(i) = true;

            continue;
        end

        if ~isnumeric(value)
            error('%s must numeric.', field_names{i});
        end
        
        if ~isequal(size(value), [1, 1])
            error('%s must be scalar.', field_names{i});
        end
        
        if isnan(value)
            error('%s is NaN.', field_names{i});
        end
        
        if value < 0
            error('%s is negative.', field_names{i});
        end
        
        if cast(cast(value, 'int64'), 'double') ~= cast(value, 'double')
            error('%s must be a whole number.', field_names{i});
        end
        
        specified_resolution(i) = ceil(cast(value, 'double'));
    end
    
    if all(empty)
        error('All the specified x, y, z resolutions are empty.');
    end

    if any(empty)

        if sum(empty) == 1
            warning('%s is specified but empty.', field_names{empty});
        end
        
        defined_names = join(field_names(empty), ', ');

        warning('%s are specified but empty', defined_names);
    end

    validated_options = struct();
    
    if all(fields)
        
        if isfield(options, 'spatial_resolution_min')
            warning('spatial_resolution_min specified but not used.');
        end
        
        if isfield(options, 'spatial_resolution_max')
            warning('spatial_resolution_max specified but not used.');
        end
        
        validated_options.spatial_resolution_x = options.spatial_resolution_x;
        validated_options.spatial_resolution_y = options.spatial_resolution_y;
        validated_options.spatial_resolution_z = options.spatial_resolution_z;

        spatial_resolution = specified_resolution;

        return;
    end
    
    if any(fields)
        
        cell_size = range ./ specified_resolution;
        cell_size = min(cell_size(nonzero & fields));  
        
        if isempty(cell_size)
            error('At least one of the specified x, y, z resolutions requires a non-zero spatial extent.');
        end

        tmp = field_names(nonzero & fields);

        for i=1:numel(tmp)
            validated_options.(tmp{i}) = options.(tmp{i});
        end
        
    elseif isfield(options, 'spatial_resolution_min')
        
        cell_size = min(range(nonzero)) / options.spatial_resolution_min;

        validated_options.spatial_resolution_min = options.spatial_resolution_min;
           
    else

        if ~isfield(options, 'spatial_resolution_max')
            options.spatial_resolution_max = 200;
        else
            validated_options.spatial_resolution_max = options.spatial_resolution_max;
        end

        cell_size = max(range) / options.spatial_resolution_max;
    end
        
    spatial_resolution = [1 1 1];
    spatial_resolution(nonzero & fields) = specified_resolution(nonzero & fields);

    computed_resolutions = range / cell_size;
    spatial_resolution(nonzero & ~fields) = computed_resolutions(nonzero & ~fields);
end
