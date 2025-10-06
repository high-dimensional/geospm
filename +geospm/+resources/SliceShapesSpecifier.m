% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2019,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef SliceShapesSpecifier < handle
    %SliceShapesSpecifier Summary.
    %   Detailed description 
    
    properties

        origin
        span
        resolution

        shape_paths
        slice_map
        source_ref

        shape_selector
    end

    properties (Dependent, Transient)
        slice_names
    end
    
    methods
        
        function obj = SliceShapesSpecifier()
            
            obj.origin = [];
            obj.span = [];
            obj.resolution = [];

            obj.source_ref = '';
            obj.slice_map = hdng.experiments.SliceMap(0);
            obj.shape_paths = [];

            obj.shape_selector = [];
        end

        function result = get.slice_names(obj)
            result = obj.slice_map.slice_names;
        end
        
        function set.slice_names(obj, values)
            obj.slice_map = hdng.experiments.SliceMap(values);
        end

    end
end
