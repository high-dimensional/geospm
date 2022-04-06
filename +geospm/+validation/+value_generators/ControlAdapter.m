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

classdef ControlAdapter < hdng.experiments.ValueGenerator
    %ControlAdapter Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        control_identifier
        iterator_ctor
        ctor_arguments
        extra_requirements
    end
    
    methods
        
        function obj = ControlAdapter(control_identifier, iterator_type, extra_requirements, varargin)
            
            obj = obj@hdng.experiments.ValueGenerator();
            obj.control_identifier = control_identifier;
            
            obj.extra_requirements = extra_requirements;
            
            ctor_arguments = varargin;
            
            if exist('iterator_type', 'var')
                
                builtins = geospm.validation.value_generators.ControlAdapter.builtin_iterators();

                if ~isKey(builtins, iterator_type)
                    error(['ControlSchedule.ctor(): Unknown builtin iterator type: ' iterator_type]);
                end

                obj.iterator_ctor = builtins(iterator_type);
            else
                obj.iterator_ctor = str2func('geospm.validation.value_generators.ControlIterator');
            end
            
            obj.ctor_arguments = ctor_arguments;
        end
    end
    
    methods (Access=protected)
        
        function result = create_iterator(obj, arguments)
            
            generator_context = arguments.generator;
            generator = generator_context.generator;
            [control, does_exist] = generator.get_parameter_by_identifier(obj.control_identifier);
            
            if ~does_exist || ~strcmp(control.type, 'control')
                
                warning(['ControlAdapter.create_iterator(): Control ''' obj.control_identifier ''' missing in generator.']);
                
                value = struct();
                value.control = [];
                value.identifier = obj.control_identifier;
                
                value = hdng.experiments.Value.from(value, obj.control_identifier, missing, 'builtin.missing');
                result = hdng.experiments.ValueListIterator({value});
                return;
            end
            
            final_arguments = cell(numel(obj.extra_requirements), 1);
            
            for index=1:numel(obj.extra_requirements)
                argument = obj.extra_requirements{index};
                final_arguments{index} = arguments.(argument);
            end
            
            final_arguments = [final_arguments, obj.ctor_arguments];
            
            result= obj.iterator_ctor(obj, control, final_arguments{:});
        end
    end
    
    methods (Static, Access=private)
        
        
        function result = builtin_iterators()
            
            persistent BUILTIN_ITERATORS;
            
            if isempty(BUILTIN_ITERATORS)
            
                where = mfilename('fullpath');
                [base_dir, ~, ~] = fileparts(where);

                result = what(base_dir);
                    
                BUILTIN_ITERATORS = containers.Map('KeyType', 'char','ValueType', 'any');
                
                for i=1:numel(result.m)
                    class_file = fullfile(base_dir, result.m{i});
                    [~, class_name, ~] = fileparts(class_file);
                    class_type = ['geospm.validation.value_generators.' class_name];

                    if ~exist(class_type, 'class')
                        continue;
                    end
                    
                    mc = meta.class.fromName(class_type);
                    is_iterator = false;
                    
                    for j=1:numel(mc.SuperclassList)
                        sc = mc.SuperclassList(j);
                        
                        if strcmp(sc.Name, 'geospm.validation.value_generators.ControlIterator')
                            is_iterator = true;
                            break;
                        end
                    end
                    
                    if is_iterator
                        class_name = replace(class_name, 'ControlIterator', '');
                        BUILTIN_ITERATORS(lower(class_name)) = str2func(class_type);
                    end
                end
            end
            
            result = BUILTIN_ITERATORS;
        end
        
    end
    
end
