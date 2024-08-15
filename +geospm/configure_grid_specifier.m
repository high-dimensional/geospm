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

function result = configure_grid_specifier(min_location, max_location, ...
    varargin)

    %{
        Creates a grid specifier struct for the span of coordinates
        from min_location to max_location, which can also be empty.
        
        The following name-value arguments are supported:
        
        -------------------------------------------------------------------
        
        -- General --
	    
	    spatial_resolution - number of raster cells in the x, y and z
	    directions for spatial data points inside the box
        defined by min_location and max_location.
	    
	    If 'spatial_resolution' is not specified it is computed
	    by the following parameters:
        
	        Either:
            
	        At least one of spatial_resolution_x, spatial_resolution_y or 
            spatial_resolution_z is defined.
	        
	        spatial_resolution_min - number of raster cells along the 
	        shorter side of the rectangle/box spanned by min_location and 
	        max_location
                
            spatial_resolution_max - number of raster cells along the
	        longer side of the rectangle/box spanned by min_location and 
	        max_location
	        
	        If no resolution value is specified, a default value of 200
	        for spatial_resolution_max is assumed.


        cell_marker_alignment = The relative alignment of markers within
        their cells, defaults to [0.5 0.5].
        
        cell_marker_scale – The relative size of cell markers, defaults to 
        [1, 1], the size of a cell.
        
        Also see geospm.auxiliary.parse_spatial_resolution().
    %}

    if ~isempty(min_location)
        if ~isequal(size(min_location), [1, 2]) && ...
            ~isequal(size(min_location), [1, 3])
            error('min_location must be a 2 or 3-vector.');
        end
    end

    if ~isempty(max_location)
        if ~isequal(size(max_location), [1, 2]) && ...
            ~isequal(size(max_location), [1, 3])
            error('max_location must be a 2 or 3-vector.');
        end
    end
    
    options = hdng.utilities.parse_struct_from_varargin(varargin{:});
    
    result = struct();
    
    result.min_location = min_location;
    result.max_location = max_location;

    if isfield(options, 'spatial_resolution')

        if ~isequal(size(options.spatial_resolution), [1, 2]) && ...
        	~isequal(size(options.spatial_resolution), [1, 3])
            error('spatial_resolution must be a 2 or 3-vector.')
        end
        
        if size(options.spatial_resolution, 2) == 2
            options.spatial_resolution = [options.spatial_resolution, 1];
        end
        
        result.spatial_resolution = options.spatial_resolution;
    else
        
        % spatial_resolution undefined, see if we can compute a
        % spatial resolution from the provided fields.

        range = max_location - min_location;

        if isempty(range)
            range = [1, 1, 1];
        end
        
        [~, validated_options] = geospm.auxiliary.compute_spatial_resolution(range, options);
        
        tmp = fieldnames(validated_options);

        for i=1:numel(tmp)
            result.(tmp{i}) = validated_options.(tmp{i});
        end
    end

    if isfield(options, 'cell_marker_alignment')
        if ~isnumeric(options.cell_marker_alignment)
            error('cell_marker_alignment must be numeric');
        end

        if ~isequal(size(options.cell_marker_alignment), [1, 2])
            error('cell_marker_alignment must be a 2-vector.');
        end

        result.cell_marker_alignment = cast(options.cell_marker_alignment, 'double');
    else
        result.cell_marker_alignment = [0.5, 0.5];
    end

    if isfield(options, 'cell_marker_scale')
        if ~isnumeric(options.cell_marker_scale)
            error('cell_marker_scale must be numeric');
        end

        if ~isequal(size(options.cell_marker_scale), [1, 2])
            error('cell_marker_scale must be a 2-vector.');
        end
        
        result.cell_marker_scale = cast(options.cell_marker_scale, 'double');
    else
        result.cell_marker_scale = [1, 1];
    end
end
