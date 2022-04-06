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

classdef Map < geospm.models.Parameter
    %Map Summary
    %   Detailed explanation goes here
    
    properties
    end
    
    properties (SetAccess=private)
        regions
        dimensions
        nth_map
    end
    
    properties (Dependent, Transient)
        N_regions
    end
    
    methods
        
        function obj = Map(generator, name, dimensions, varargin)
            obj = obj@geospm.models.Parameter(generator, name, 'map', varargin{:});
            
            obj.regions = cell(0, 1);
            obj.dimensions = dimensions;
            obj.nth_map = generator.add_map(obj);
        end
        
        function result = load_dependencies(obj)
            
            parameters_by_index = containers.Map('KeyType', 'int64','ValueType', 'any');
            
            for i=1:obj.N_regions
                region = obj.regions{i};
                
                parameters = region.load_parameter_dependencies();
                
                for j=1:numel(parameters)
                    p = parameters{j};
                    parameters_by_index(p.nth_parameter) = p;
                end
            end
            
            result = parameters_by_index.values();
        end

        function result = get.N_regions(obj)
            result = numel(obj.regions);
        end
        
        function nth_region = add_region(obj, region)
            obj.regions{end + 1} = region;
            nth_region = numel(obj.regions);
        end
        
        function result = define(obj, region_type, varargin)
            
            builtins = geospm.models.Region.builtin_regions();
            
            if ~isKey(builtins, region_type)
                error(['Map.define(): Unknown builtin region type: ' region_type]);
            end
            
            ctor = builtins(region_type);
            result = ctor(obj, varargin{:});
        end
        
        function compute(obj, model, metadata)
            
            render_context = hdng.rasters.RasterContext([model.spatial_resolution obj.dimensions]);
            
            render_context.save();
            render_context.apply_transform(metadata.transform);
            
            for i=obj.N_regions:-1:1
                region = obj.regions{i};
                render_context.save();
                
                region.render(model, render_context);
                render_context.restore();
            end
            
            render_context.restore();
            
            result = struct();
            result.quantity = geospm.models.quantities.DiscreteQuantity(model, obj.name, render_context.canvas);
            metadata.set_parameter_metadata(obj.nth_parameter, result);
            
            if ~isempty(obj.generator.debug_path)
                
                debug_path = obj.generator.debug_path();
                
                [dirstatus, dirmsg] = mkdir(debug_path);
                if dirstatus ~= 1; error(dirmsg); end
                
                path = fullfile(debug_path, obj.name);

                d = prod(obj.dimensions);
                d = d(end);

                for i=1:d
                    s = zeros([obj.dimensions, 1], 'logical');
                    s(i) = 1;
                    render_context.save_canvas_as_png([path '_c' num2str(i, '%d')], '', s, true);
                end
            end
        end
    end
    
    methods (Static, Access=public)
        
    end
    
end
