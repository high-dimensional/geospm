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

classdef Fractal < matlab.mixin.Copyable
    %Fractal Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
        name
        description
        generator
        parameters
    end
    
    properties (Constant)
        REGISTRY_LIST = 1
        REGISTRY_ADD = 2
        REGISTRY_GET = 3
    end
    
    methods (Static, Access=public)
        
        function [did_exist, result] = for_name(name)
            
            result = hdng.fractals.Fractal.registry(hdng.fractals.Fractal.REGISTRY_GET, name);
            did_exist = ~isempty(result);
        end
    end
    
    methods (Static, Access=private)
        
        function result = registry(action, varargin)
            
            result = [];
            
            persistent registry_struct;
            
            if isempty(registry_struct)
                registry_struct = containers.Map('KeyType', 'char','ValueType', 'any');
                registry_struct(num2str(hdng.fractals.Fractals.Zero, '%d')) = [];
            end
            
            switch action
                
                case hdng.fractals.Fractal.REGISTRY_LIST

                    result = registry_struct.values();
                    
                case hdng.fractals.Fractal.REGISTRY_ADD
                    
                    fractal = varargin{1};
                    registry_struct(fractal.name) = fractal;
                    
                case hdng.fractals.Fractal.REGISTRY_GET
                    
                    name = varargin{1};
                    
                    if isKey(registry_struct, name)
                        result = registry_struct(name);
                    end
            end
        end
        
    end
    
    methods
        
        function obj = Fractal(name, generator, parameters, description)
            
           if ~exist('parameters', 'var')
                parameters = cell(0,1);
            end
            
            if ~exist('description', 'var')
                description = '';
            end
            
            obj.name = name;
            obj.generator = generator;
            
            obj.parameters = parameters;
            obj.description = description;
            
            hdng.fractals.Fractal.registry(hdng.fractals.Fractal.REGISTRY_ADD, obj);
        end
        
        function result = default_parameters(obj)
            
            result = struct();
            
            for i=1:numel(obj.parameters)
                p = obj.parameters{i};
                result.(p.identifier) = p.default_value;
            end
        end
        
        
        function arguments = regularise_arguments(obj, arguments)
            
            defaults = obj.default_parameters();
            names = fieldnames(defaults);
            
            for i=1:size(names, 1)
               f = names{i};
               if ~isfield(arguments, f)
                   arguments.(f) = defaults.(f);
               end
            end
            
        end
        
        function graphic = generate(obj, arguments)
            
            if ~exist('arguments', 'var')
                arguments = struct();
            end
            
            arguments = obj.regularise_arguments(arguments);
            graphic = obj.generator.render(obj, arguments);
        end
        
        function graphic = show(obj, arguments)
            
            if ~exist('arguments', 'var')
                arguments = struct();
            end
            
            graphic = obj.generate(arguments);
            graphic.show();
        end
        
    end
end
