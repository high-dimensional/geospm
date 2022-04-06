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

classdef ParameterRole < handle
    %ParameterRole Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    properties (SetAccess=private)
        generator
        identifier
        type
        arguments
        min_bindings
        max_bindings
        description
        check
        listener
        nth_role
    end
    
    methods
        
        function obj = ParameterRole(generator, identifier, type, arguments, min_bindings, max_bindings, description, check, listener)
            
            if numel(identifier) == 0
                error('ParameterRole.ctor(): Expected non-empty identifier.');
            end
            
            
            if ~iscell(arguments)
                error('ParameterRole.ctor(): Expected a cell array of argument names.');
            end
            
            for i=1:numel(arguments)
                arg = arguments{i};
                
                if ~ischar(arg)
                    error('GeneratorRole.ctor(): Argument names must be specified as char vectors.');
                end
            end
            
            if ~exist('description', 'var')
                description = '';
            end
            
            if ~exist('check', 'var')
                check = @(generator, bindings) struct('passed', true, 'diagnostic', '');
            end
            
            if ~exist('listener', 'var')
                listener = @(generator, bindings, added, removed) [];
            end
            
            obj.generator = generator;
            obj.identifier = identifier;
            obj.type = type;
            obj.arguments = arguments;
            obj.min_bindings = min_bindings;
            obj.max_bindings = max_bindings;
            obj.description = description;
            obj.check = check;
            obj.listener = listener;
            obj.nth_role = obj.generator.add_role(obj);
        end
        
    end
    
    methods (Static, Access=public)
    end
    
    methods (Static, Access=private)
    end
    
end
