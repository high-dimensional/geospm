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

classdef NameCombinations < hdng.experiments.ValueGenerator
    
    %NameCombinations Provides an iterator over a list of values.
    %
    
    properties
        exclude_names
        choose_k
        variable_names_requirement
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = NameCombinations()
            obj = obj@hdng.experiments.ValueGenerator();
            obj.exclude_names = {};
            obj.choose_k = 2;
            obj.variable_names_requirement = 'names';
        end
        
    end
    
    methods (Access=protected)
        
        function result = create_iterator(obj, arguments)
            
            exclusion_map = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            for index=1:numel(obj.exclude_names)
                exclusion_map(obj.exclude_names{index}) = true;
            end
            
            unfiltered_variable_names = arguments.(obj.variable_names_requirement);
            variable_names = cell(numel(unfiltered_variable_names), 1);
            N = 0;
            
            for index=1:numel(unfiltered_variable_names)
                
                name = unfiltered_variable_names{index};
                
                if isKey(exclusion_map, name)
                    continue
                end
                
                N = N + 1;
                
                variable_names{N} = name;
            end
            
            variable_names = variable_names(1:N);
            result = hdng.experiments.NameCombinationsIterator(variable_names, obj.choose_k);
        end
    end
    
    methods (Static, Access=public)
        
        function generator = from(varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            generator = hdng.experiments.NameCombinations();
            
            if isfield(options, 'exclude_names')
                generator.exclude_names = options.exclude_names;
            end
            if isfield(options, 'choose_k')
                generator.choose_k = options.choose_k;
            end
            if isfield(options, 'variable_names_requirement')
                generator.variable_names_requirement = options.variable_names_requirement;
            end
        end
    end
    
end
