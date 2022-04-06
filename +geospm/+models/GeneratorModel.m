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

classdef GeneratorModel < handle
    %GeneratorModel Defines a generator.
    %   Detailed explanation goes here
    
    properties (GetAccess=public, SetAccess=protected)
        options
    end
    
    properties (Dependent, Transient)
        variable_names
        spatial_resolution
    end
    
    methods
        
        function obj = GeneratorModel(options, varargin)
            obj.options = hdng.utilities.parse_options_argument(options, varargin{:});
        end
        
        function result = get.variable_names(obj)
            result = obj.access_variable_names();
            result = result(:);
        end
        
        function result = get.spatial_resolution(obj)
            result = obj.access_spatial_resolution();
        end
        
        function domain = create_domain(obj)
            domain = geospm.models.Domain();
            
            names = obj.variable_names;
            
            for index=1:numel(names)
                name = names{index};
                geospm.models.Variable(domain, name);
            end
        end
        
        function configure_generator(obj, generator) %#ok<INUSD>
            error('GeneratorModel.configure_generator() must be implemented by a subclass.');
        end
    end
    
    methods (Access=protected)
       
        function [result] = access_variable_names(~) %#ok<STOUT>
            error('GeneratorModel.access_variable_names() must be implemented by a subclass.');
        end
        
        function [result] = access_spatial_resolution(~) %#ok<STOUT>
            error('GeneratorModel.access_spatial_resolution() must be implemented by a subclass.');
        end
        
    end
    
    methods (Static, Access=private)
    end
    
end
