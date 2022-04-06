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

classdef Variable < handle
    
    %Variable Defines a single element to be varied in a configuration.
    %   A variable can depend on other schedules, whose values will
    %   be provided when an iterator over all applicable settings
    %   in the schedule is requested.
    
    properties
        schedule
        identifier
        nth_variable
        description
        value_generator
        interactive
    end
    
    properties (Dependent, Transient)
        requirements
        required_by
        
        requirement_indices
    end
    
    properties (GetAccess=private, SetAccess=private)
        requirements_
        required_by_
    end
    
    methods
        
        function obj = Variable(schedule, identifier, value_generator, requirements, varargin)
            
            if ~exist('requirements', 'var')
                requirements = {};
            end
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            obj.schedule = schedule;
            obj.identifier = identifier;
            obj.nth_variable = obj.schedule.add_variable(obj);
            
            obj.description = [];
            obj.value_generator = value_generator;
            
            obj.requirements_ = {};
            obj.required_by_ = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            obj.requirements = requirements;
            
            obj.interactive = struct('default_display_mode', 'auto');
            
            if isfield(options, 'description')
                obj.description = options.description;
            end
            
            if isfield(options, 'interactive')
                obj.interactive = options.interactive;
            end
            
        end
        
        function result = get.requirements(obj)
            result = obj.access_requirements();
        end
        
        function result = get.required_by(obj)
            result = obj.access_required_by();
        end
        
        function set.requirements(obj, variables)
            obj.set_requirements(variables);
        end
        
        
        function result = get.requirement_indices(obj)
            result = obj.access_requirement_indices();
        end
    end
    
    methods (Access=protected)
        
        function result = access_requirements(obj)
            result = obj.requirements_;
        end
        
        function result = access_required_by(obj)
            result = values(obj.required_by_);
        end
        
        function set_requirements(obj, variables)
            
            for index=1:numel(obj.requirements_)
                
                requirement = obj.requirements_{index};
                
                if isKey(requirement.required_by_, obj.identifier)
                   remove(requirement.required_by_, obj.identifier);
                end
                
            end
            
            obj.requirements_ = cell(numel(variables), 1);
            obj.required_by_ = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            for index=1:numel(variables)
                
                requirement = variables{index};
                
                obj.requirements_{index} = requirement;
                requirement.required_by_(obj.identifier) = obj;
            end
        end
        
        function result = access_requirement_indices(obj)
            
            result = zeros(numel(obj.requirements_), 1);
            
            for index=1:numel(obj.requirements_)
                result(index) = obj.requirements_{index}.nth_variable;
            end
        end
        
    end
    
    methods (Static, Access=public)
    end
    
end
