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

classdef Domain < handle
    %Domain A ordered group of variables of interest.
    %
    
    properties (SetAccess=private)
        variables
    end
    
    properties (Dependent, Transient)
        N_variables
        joint_dimensions
        variable_names
    end
    
    properties (GetAccess=private, SetAccess=private)
        variables_by_name
    end
    
    methods
        
        function obj = Domain()
            
            obj.variables = cell(0, 1);
            obj.variables_by_name = containers.Map('KeyType', 'char','ValueType', 'any');
        end
        
        function result = get.joint_dimensions(obj)
            result = ones(1, obj.N_variables) * 2;
        end
        
        function result = get.N_variables(obj)
            result = numel(obj.variables);
        end
        
        function result = get.variable_names(obj)
            result = cell(obj.N_variables, 1);
            
            for i=1:obj.N_variables
                result{i} = obj.variables{i}.name;
            end
        end
        
        function nth_variable = add_variable(obj, variable)
            obj.variables{end + 1} = variable;
            nth_variable = numel(obj.variables);
            obj.variables_by_name(variable.name) = variable;
        end
        
        function result = contains_variable_for_name(obj, name)
            result = isKey(obj.variables_by_name, name);
        end
        
        function [result, value] = variable_for_name(obj, name, default_value)
            
            if ~exist('default_value', 'var')
                default_value = [];
            end
            
            if ~isKey(obj.variables_by_name, name)
                result = false;
                value = default_value;
            else
                result = true;
                value = obj.variables_by_name(name);
            end
        end
        
        function index_or_zero = index_for_variable_name(obj, name)
            
            if ~isKey(obj.variables_by_name, name)
                index_or_zero = 0;
                return
            end
            
            index_or_zero = obj.variables_by_name(name).nth_variable;
        end
        
        function result = char(obj)
            result = ['{' join(obj.variable_names, ', ') '}'];
        end
    end
    
    methods (Static, Access=private)
    end
    
end
