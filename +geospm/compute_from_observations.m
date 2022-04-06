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

function compute_from_observations(directory, observations, x, y, z, ...
            varargin)
    
    %{
        Convenience method to geospm.compute().
        Creates a SpatialData instance from a matrix of observations and
        column vectors x, y and z of corresponding locations. z can be 
        specified as [], which means the spatial data is purely 
        2-dimensional.
        
        All name-value options understood by geospm.compute() can also
        be passed to this function. In addition, the coordinate reference
        system of the data can be specified via 'crs'. The value
        corresponding to 'crs' can either be a char specifier such as
        'EPSG:27700' (the Ordnance Survey grid) or a SpatialCRS object.
    %}
    
    if ~exist('z', 'var')
        z = [];
    end
    
    options = hdng.utilities.parse_struct_from_varargin(varargin{:});
    
    if ~isfield(options, 'crs')
        options.crs = hdng.SpatialCRS.empty;
    end
    
    data = geospm.SpatialData(x, y, z, observations, options.crs);
    
    options = rmfield(options, 'crs');
    
    varargin = hdng.utilities.struct_to_name_value_sequence(options);
    
    geospm.compute(directory, data, true, varargin{:});
end
