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

classdef Expression < geospm.models.Parameter
    %Expression Summary
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
        arguments
        func
        nth_expression
        value
    end
    
    properties (Transient, Dependent)
    end
    
    methods
        
        function obj = Expression(generator, name, varargin)
            
            if ~ischar(name)
                varargin = [{name} varargin];
                name = '';
                
                for i=1:numel(varargin) - 1
                    arg = varargin{i};
                    
                    if isa(arg, 'geospm.models.Parameter')
                        name = [name, ', ', arg.name]; %#ok<AGROW>
                    elseif isnumeric(arg)
                        name = [name, ', ', num2str(arg, '%f')]; %#ok<AGROW>
                    else
                        name = [name, ', ', arg]; %#ok<AGROW>
                    end
                end
                
                name = ['expr(' name(3:end) ')'];
            end
            
            obj = obj@geospm.models.Parameter(generator, name, 'expression');
            
            if nargin < 1
                error('Expression.ctor(): Expects a function.');
            end
            
            obj.arguments = varargin(1:end - 1);
            obj.func = varargin{end};
            obj.nth_expression = obj.generator.add_expression(obj);
        end
        
        function result = load_dependencies(obj)
            result = obj.arguments(:);
        end
        
        function result = load_values(~, varargin)
            
            N = numel(varargin);
            result = cell(N, 1);
            
            for i=1:N
                
                setting = varargin{i};
                
                if isa(setting, 'geospm.models.Control')
                    result{i} = setting.value;
                elseif isa(setting, 'geospm.models.Expression')
                    result{i} = setting.value;
                else
                    result{i} = setting;
                end
            end
        end
        
        function compute(obj, model, ~)
            values = obj.load_values(obj.arguments{:});
            obj.value = obj.func(model, values{:});
        end
    end
    
    methods (Static, Access=private)
    end
    
end
