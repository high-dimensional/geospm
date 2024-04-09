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

function [options] = parse_spatial_resolution(spatial_index, options)
    
    %{
    
    The specified options struct is expected to hold any of the
    following fields:

    min_location - min spatial coordinates of data
    default: floor(spatial_index.min_xyz)

    max_location - max spatial coordinates of data
    default: ceil(spatial_index.max_xyz)
	
	spatial_resolution - number of raster cells in the x, y and z
	directions for spatial data points inside the box
    defined by min_location and max_location.
	
	If 'spatial_resolution' is not specified it is computed
	by the following parameters:

	Either:
    
	At least one of spatial_resolution_x, spatial_resolution_y or 
    spatial_resolution_z is defined.
    
    If a resolution is defined for a dimension the ceil() of its value 
    is used. Otherwise, if its spatial extent as defined by min_location
    and max_location is non-zero, its resolution is derived by dividing
    its spatial extent by the smallest defined cell size. If its spatial 
    extent is zero, a resolution of 1 will be used.
    

    it is derived in proportion to the defined spatial resolution 
    via the box spanned by min_location and max_location.

	If the resolution of one direction is specified the other 
	resolution(s) are derived proportionally to the rectangle/box
	spanned by min_location and max_location
	

	Or one of:
	spatial_resolution_min - number of raster cells along the 
	shorter side of the rectangle/box spanned by min_location and 
	max_location
        
    spatial_resolution_max - number of raster cells along the
	longer side of the rectangle/box spanned by min_location and 
	max_location
	
	If no resolution value is specified, a default value of 200
	for spatial_resolution_max is assumed.
    %}

    if ~isfield(options, 'min_location')
        options.min_location = floor(spatial_index.min_xyz);
    end
    
    if ~isfield(options, 'max_location')
        options.max_location = ceil(spatial_index.max_xyz);
    end
    
    if ~isequal(size(options.min_location), [1, 2]) && ...
        ~isequal(size(options.min_location), [1, 3])
        error('parse_spatial_resolution(): min_location must be a 2 or 3-vector.')
    end
    
    if ~isequal(size(options.max_location), [1, 2]) && ...
        ~isequal(size(options.max_location), [1, 3])
        error('parse_spatial_resolution(): max_location must be a 2 or 3-vector.')
    end
    
    if isfield(options, 'spatial_resolution')
        
        if ~isequal(size(options.spatial_resolution), [1, 2]) && ...
        	~isequal(size(options.spatial_resolution), [1, 3])
            error('parse_spatial_resolution(): spatial_resolution must be a 2 or 3-vector.')
        end
        
        if size(options.spatial_resolution, 2) == 2
            options.spatial_resolution = [options.spatial_resolution, 1];
        end
        
        options.spatial_resolution = ceil(options.spatial_resolution);
        return
    end
    
    range = options.max_location - options.min_location;
    
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
    
    specified_resolution = [NaN NaN NaN];
          
    for i=1:numel(fields)
        
        if fields(i) == false
            continue
        end
        
        value = options.(field_names{i});
        
        if ~isnumeric(value)
            error('parse_spatial_resolution(): %s must numeric.', field_names{i});
        end
        
        if ~isequal(size(value), [1, 1])
            error('parse_spatial_resolution(): %s must be scalar.', field_names{i});
        end
        
        if isnan(value)
            error('parse_spatial_resolution(): %s is NaN.', field_names{i});
        end
        
        if value < 0
            error('parse_spatial_resolution(): %s is negative.', field_names{i});
        end
        
        if cast(cast(value, 'int64'), 'double') ~= cast(value, 'double')
            error('parse_spatial_resolution(): %s must be a whole number.', field_names{i});
        end
        
        specified_resolution(i) = ceil(cast(value, 'double'));
    end
    
    if all(fields)
        
        if isfield(options, 'spatial_resolution_min')
            warning('parse_spatial_resolution(): spatial_resolution_min specified but not used.');
        end
        
        if isfield(options, 'spatial_resolution_max')
            warning('parse_spatial_resolution(): spatial_resolution_max specified but not used.');
        end
        
        options.spatial_resolution = specified_resolution;
        return;
    end
    
    if any(fields)
        
        cell_size = range ./ specified_resolution;
        cell_size = min(cell_size(nonzero & field));  
        
        if isempty(cell_size)
            error('parse_spatial_resolution(): At least one of the specified resolutions requires a non-zero spatial extent.');
        end
        
    elseif isfield(options, 'spatial_resolution_min')
        
        cell_size = min(range(nonzero)) / options.spatial_resolution_min;
           
    else

        if ~isfield(options, 'spatial_resolution_max')
            options.spatial_resolution_max = 200;
        end
        
        cell_size = max(range) / options.spatial_resolution_max;
    end
        
    spatial_resolution = [1 1 1];
    spatial_resolution(nonzero & fields) = specified_resolution(nonzero & fields);

    computed_resolutions = range / cell_size;
    spatial_resolution(nonzero & ~fields) = computed_resolutions(nonzero & ~fields);

    options.spatial_resolution = spatial_resolution;
end
