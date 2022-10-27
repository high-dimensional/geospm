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

classdef Parameters < handle
    
    %Parameters Specifies all possible parameters to geospm.compute()
    %
    %   grid – a geospm.Grid that defines a transformation from point
    %          locations to raster locations
    %
    %   apply_density_mask - limit analysis to raster cells above a certain
    %                        sample density
    %   Default value is 'true'.
    %   
    %   density_mask_factor - The threshold for the sample density mask is
    %   derived from this value. It is roughly equivalent to the minimum 
    %   number of samples centred at a location (for a Gaussian smoothing 
    %   kernel). More accurately, the maximum value of the kernel for
    %   each smoothing level is multiplied by this number.
    %   Default value is 10.0.
    %
    %   thresholds - A cell array of threshold strings.
    %   Default value is { 'T[1, 2]: p<0.05 (FWE)' }, which specifies a 
    %   single two-sided per-voxel family-wise error of 5%. Cf.
    %   SignificanceTest for more information.
    %                                                                
    %   trace_thresholds - create shape files delineating significant areas
    %   Default value is 'true'.
    %                 
    %   smoothing_levels - a vector of smoothing diameters in the scale of
    %   the geographic coordinate system, otherwise in the scale of raster
    %   cells (pixels) if no coordinate system was specified.
    %                                 
    %   smoothing_levels_p_value - a probability value specifying the
    %   mass of the Gaussian smoothing kernel inside the diameters given
    %   by the smoothing_levels option.
    %                                       
    %   smoothing_method - the smoothing method to be used.
    %   Default value is 'default'.
    %                                       
    %   regression_add_intercept - indicates whether the regression should
    %   add an intercept term to the data. Default value is 'true'.
    %   
    %   add_georeference_to_images – indicates whether images are saved as
    %   georeferenced tiff files. Default value is 'true'.    
    %
    
    properties (Transient, Dependent)
        
        grid % default: []
        
        apply_density_mask % default: true
        density_mask_factor % default: []
        
        thresholds % default: A single two-sided t test at a significance level of 5% with family-wise error correction.
        trace_thresholds % default: true
        
        smoothing_levels % default: [5 10 15]
        smoothing_levels_p_value % default: 0.95
        smoothing_method % default: 'default'
        
        regression_add_intercept % default: true
        add_georeference_to_images % default: true
        
        report_generator % default: [] (used internally)
    end
    
    methods
        
        function result = get.grid(obj)
            result = obj.grid_;
        end
        
        function set.grid(obj, value)
            
            if isempty(value)
                error('Parameters.set.grid(): argument cannot be empty.');
            end
            
            if ~isa(value, 'geospm.Grid')
                error('Parameters.set.grid(): argument is not a geospm.Grid.');
            end
            
            obj.grid_ = value;
        end
        
        function result = get.apply_density_mask(obj)
            result = obj.apply_density_mask_;
        end
        
        function set.apply_density_mask(obj, value)
            
            if isempty(value)
                error('Parameters.set.apply_density_mask(): argument cannot be empty.');
            end
            
            if ~isa(value, 'logical')
                error('Parameters.set.apply_density_mask(): argument is not a logical value.');
            end
            
            obj.apply_density_mask_ = value;
        end
        
        function result = get.density_mask_factor(obj)
            result = obj.density_mask_factor_;
        end
        
        function set.density_mask_factor(obj, value)
            
            if ~isa(value, 'numeric')
                error('Parameters.set.density_mask_factor(): argument is not a numeric value.');
            end
            
            if value <= 0.0
                error('Parameters.set.density_mask_factor(): argument is not strictly positive.');
            end
            
            obj.density_mask_factor_ = cast(value, 'double');
        end
        
        function result = get.thresholds(obj)
            result = obj.thresholds_;
        end
        
        function set.thresholds(obj, value)
            
            if isempty(value)
                error('Parameters.set.thresholds(): argument cannot be empty.');
            end
            
            if ~isa(value, 'cell')
                error('Parameters.set.thresholds(): argument is not a cell array.');
            end
            
            if all(cellfun(@(x) isa(x, 'char'), value))
                % Check that each element can be parsed as a significance
                % test
                geospm.SignificanceTest.from_char(value);
                
            else % ~all(cellfun(@(x) isa(x, 'geospm.SignificanceTest'), value))
                error('Parameters.set.thresholds(): argument is not a cell array of char values or geospm.SignificanceTests.');
            end
            
            obj.thresholds_ = value;
        end
        
        function result = get.trace_thresholds(obj)
            result = obj.trace_thresholds_;
        end
        
        function set.trace_thresholds(obj, value)
            
            if isempty(value)
                error('Parameters.set.trace_thresholds(): argument cannot be empty.');
            end
            
            if ~isa(value, 'logical')
                error('Parameters.set.trace_thresholds(): argument is not a logical value.');
            end
            
            obj.trace_thresholds_ = value;
        end
        
        function result = get.smoothing_levels(obj)
            result = obj.smoothing_levels_;
        end
        
        function set.smoothing_levels(obj, value)
            
            if isempty(value)
                error('Parameters.set.smoothing_levels(): argument cannot be empty.');
            end
            
            if ~isa(value, 'numeric')
                error('Parameters.set.smoothing_levels(): argument is not a numeric value.');
            end
            
            obj.smoothing_levels_ = cast(value, 'double');
        end
        
        function result = get.smoothing_levels_p_value(obj)
            result = obj.smoothing_levels_p_value_;
        end
        
        function set.smoothing_levels_p_value(obj, value)
            
            if isempty(value)
                error('Parameters.set.smoothing_levels_p_value(): argument cannot be empty.');
            end
            
            if ~isa(value, 'numeric')
                error('Parameters.set.smoothing_levels_p_value(): argument is not a numeric value.');
            end
            
            obj.smoothing_levels_p_value_ = cast(value, 'double');
        end
        
        function result = get.smoothing_method(obj)
            result = obj.smoothing_method_;
        end
        
        function set.smoothing_method(obj, value)
            
            if isempty(value)
                error('Parameters.set.smoothing_method(): argument cannot be empty.');
            end
            
            if ~isa(value, 'char')
                error('Parameters.set.smoothing_method(): argument is not a char value.');
            end
            
            obj.smoothing_method_ = value;
        end
        
        function result = get.regression_add_intercept(obj)
            result = obj.regression_add_intercept_;
        end
        
        function set.regression_add_intercept(obj, value)
            
            if isempty(value)
                error('Parameters.set.regression_add_intercept(): argument cannot be empty.');
            end
            
            if ~isa(value, 'logical')
                error('Parameters.set.regression_add_intercept(): argument is not a logical value.');
            end
            
            obj.regression_add_intercept_ = value;
        end
        
        function result = get.add_georeference_to_images(obj)
            result = obj.add_georeference_to_images_;
        end
        
        function set.add_georeference_to_images(obj, value)
            
            if isempty(value)
                error('Parameters.set.add_georeference_to_images(): argument cannot be empty.');
            end
            
            if ~isa(value, 'logical')
                error('Parameters.set.add_georeference_to_images(): argument is not a logical value.');
            end
            
            obj.add_georeference_to_images_ = value;
        end
        
        function result = get.report_generator(obj)
            result = obj.report_generator_;
        end
        
        function set.report_generator(obj, value)
            
            if ~isa(value, 'hdng.documents.Generator')
                error('Parameters.set.report_generator(): argument is not a hdng.documents.Generator.');
            end
            
            obj.report_generator_ = value;
        end
        
        
        function obj = Parameters()
            
            obj.grid_ = [];
            
            obj.apply_density_mask_ = true;
            obj.density_mask_factor_ = 10.0;

            obj.thresholds_ = {'T[1,2]: p<0.05 (FWE)'};
            obj.trace_thresholds_ = true;

            obj.smoothing_levels_ = [5, 10, 15];
            obj.smoothing_levels_p_value_ = 0.95;
            obj.smoothing_method_ = 'default';

            obj.regression_add_intercept_ = true;
            obj.add_georeference_to_images_ = true;
            
            obj.report_generator_ = [];
        end
        
        function define_grid(obj, spatial_data, varargin)
            
            %{
                The grid is defined based on the extent of the data and 
                the desired spatial resolution.

                See geospm.auxiliary.parse_spatial_resolution() for
                a detailed description of supported name-value arguments.
            %}
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            obj.grid_ = geospm.Grid();
            
            options = geospm.auxiliary.parse_spatial_resolution(spatial_data, options);
            
            obj.grid_.span_frame( ...
                options.min_location, ...
                options.max_location, ...
                options.spatial_resolution);
        end
        
    end
   
    properties (GetAccess=private, SetAccess=private)
        
        grid_
        
        trace_thresholds_
        
        apply_density_mask_
        density_mask_factor_
        
        thresholds_
        
        smoothing_levels_
        smoothing_levels_p_value_
        smoothing_method_
        
        regression_add_intercept_
        add_georeference_to_images_
        
        report_generator_
    end
        
end
