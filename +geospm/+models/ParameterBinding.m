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

classdef ParameterBinding < handle
    %ParameterBinding Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        generator
        role_index
        parameter_index
        arguments
        nth_binding
    end
    
    methods
        
        function obj = ParameterBinding(generator, role_index, parameter_index, arguments)
            
            if role_index < 1 || role_index > generator.N_roles
                error('ParameterBinding.ctor(): Invalid role index.');
            end
            
            if parameter_index < 1 || parameter_index > generator.N_parameters
                error('ParameterBinding.ctor(): Invalid parameter index.');
            end
            
            role = generator.roles{role_index};
            parameter = generator.parameters{parameter_index};
            
            if ~strcmp(parameter.type, role.type)
                error('ParameterBinding.ctor(): Parameter type incompatible with role.');
            end
            
            if ~isstruct(arguments)
                error('ParameterBinding.ctor(): Expected a struct of arguments.');
            end
            
            for i=1:numel(role.arguments)
                name = role.arguments{i};
                
                if ~isfield(arguments, name)
                    error(['ParameterBinding.ctor(): Missing argument ''' name '''']);
                end
            end
            
            obj.generator = generator;
            obj.role_index = role_index;
            obj.parameter_index = parameter_index;
            obj.arguments = arguments;
            obj.nth_binding = obj.generator.add_binding(obj);
        end
        
    end
    
    methods (Static, Access=public)
    end
    
    methods (Static, Access=private)
    end
    
end
