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

classdef VolumeSpecifier < handle
    %ImageSpecifier Summary.
    %   Detailed description 
    
    properties
        image
        slice_map
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = VolumeSpecifier(varargin)

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'image')
                options.image = hdng.resources.ImageSpecifier();
            end

            if ~isfield(options, 'slice_map')
                options.slice_map = hdng.experiments.SliceMap(0);
            end
            
            obj.image = options.image;
            obj.slice_map = options.slice_map;
        end
    end
end
