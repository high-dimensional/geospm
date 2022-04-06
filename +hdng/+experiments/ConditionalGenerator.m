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

classdef ConditionalGenerator < hdng.experiments.ValueGenerator
    
    %ConditionalGenerator Provides an iterator over a list of values.
    %
    
    properties
        requirement
        requirement_test
        missing_label
        value_generator
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = ConditionalGenerator()
            obj = obj@hdng.experiments.ValueGenerator();
            obj.requirement = '';
            obj.requirement_test = @(value) false;
            obj.missing_label = '';
            obj.value_generator = hdng.experiments.ValueGenerator.empty;
        end
        
    end
    
    methods (Access=protected)
        
        function result = create_iterator(obj, arguments)
            
            requirement_value = arguments.(obj.requirement);
            
            if obj.requirement_test(requirement_value)
                result = obj.value_generator.create_iterator(struct());
            else
                result = hdng.experiments.ValueListIterator({hdng.experiments.SkipValue()});
            end
            
        end
    end
    
    methods (Static, Access=public)
        
        function generator = from(varargin)
            generator = hdng.experiments.ValueList();
            generator.values = cell(numel(varargin), 1);
            
            for index=1:numel(varargin)
                
                value = varargin{index};
                
                if ~isa(value, 'hdng.experiments.Value')
                    value = hdng.experiments.Value.from(value);
                end
                
                generator.values{index} = value;
            end
        end
    end
    
end
