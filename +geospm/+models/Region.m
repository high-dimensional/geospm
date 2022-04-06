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

classdef Region < handle
    %Region Summary
    %   Detailed explanation goes here
    
    properties
    end
    
    properties (SetAccess=private)
        map
        nth_region
        arguments
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Region(map, varargin)
            obj.map = map;
            obj.nth_region = map.add_region(obj);
            obj.arguments = varargin;
        end
        
        function result = load_parameter_dependencies(obj)
            result = obj.select_parameters(obj.arguments{:});
        end
        
        
        function result = select_parameters(~, varargin)
            
            N = numel(varargin);
            result = cell(N, 1);
            index = 0;
            
            for i=1:N
                
                setting = varargin{i};
                
                if iscell(setting)
                    
                    for k=1:numel(setting)
                        
                        value = setting{k};
                        
                        if isa(value, 'geospm.models.Parameter')
                            index = index + 1;
                            result{index} = value;
                        end
                    end
                    
                end
                
                if isa(setting, 'geospm.models.Parameter')
                    index = index + 1;
                    result{index} = setting;
                end
            end
            
            result = result(1:index);
        end
        
        function result = load_values(~, varargin)
            
            N = numel(varargin);
            result = cell(N, 1);
            
            for i=1:N
                
                setting = varargin{i};
                
                if iscell(setting)
                    
                    setting_result = zeros(size(setting));
                    
                    for k=1:numel(setting)
                        
                        value = setting{k};
                        
                        if isa(value, 'geospm.models.Control')
                            setting_result(k) = value.value;
                        elseif isa(value, 'geospm.models.Expression')
                            setting_result(k) = value.value;
                        else
                            setting_result(k) = value;
                        end
                    end
                    
                    result{i} = setting_result;
                    
                elseif isa(setting, 'geospm.models.Control')
                    result{i} = setting.value;
                elseif isa(setting, 'geospm.models.Expression')
                    result{i} = setting.value;
                else
                    result{i} = setting;
                end
            end
        end
        
        function render_impl(obj, model, raster_context, varargin) %#ok<INUSD>
            error('Region.render_impl() must be implemented by a subclass.');
        end
        
        function render(obj, model, raster_context)
            argument_values = obj.load_values(obj.arguments{:});
            obj.render_impl(model, raster_context, argument_values{:});
        end
    end
    
    methods (Static, Access=public)
        
        
        function result = builtin_regions()
            
            persistent BUILTIN_REGIONS;
            
            if isempty(BUILTIN_REGIONS)
            
                where = mfilename('fullpath');
                [base_dir, ~, ~] = fileparts(where);
                regions_dir = fullfile(base_dir, '+regions');

                result = what(regions_dir);
                    
                BUILTIN_REGIONS = containers.Map('KeyType', 'char','ValueType', 'any');
                
                for i=1:numel(result.m)
                    class_file = fullfile(regions_dir, result.m{i});
                    [~, class_name, ~] = fileparts(class_file);
                    class_type = ['geospm.models.regions.' class_name];

                    if exist(class_type, 'class')
                        identifier = join(lower(hdng.utilities.split_camelcase(class_name)), '_');
                        identifier = identifier{1};
                        BUILTIN_REGIONS(identifier) = str2func(class_type);
                    end
                end
            end
            
            result = BUILTIN_REGIONS;
        end
        
        
    end
    
end
