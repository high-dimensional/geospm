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

classdef SpatialAnalysis < hdng.pipeline.Pipeline
    %SpatialAnalysis Runs computations on a spatial configuration.
    
    methods
        
        function obj = SpatialAnalysis(options, varargin)
            %Creates a new SpatialAnalysis object for a SpatialData
            %object.
            %
            % options - A structure of options. 
            % varargin - An arbitrary number of Name, Value pairs specifying
            % additional options.
            %
            % Example (1)
            %
            % spatial_data = geospm.SpatialData(...);
            % options = struct('precision', 'single');
            % computation = geospm.SpatialAnalysis(spatial_data, options);
            %
            % Example (2)
            %
            % computation = geospm.SpatialAnalysis(spatial_data, [],
            % 'precision', 'single');
            %
            % Example (3)
            %
            % computation = geospm.SpatialAnalysis(spatial_data, default_options,
            % 'precision', 'single');
            %
            % The following options are currently defined:
            %
            %  diagnostics - A structure holding diagnostics settings.
            %
            %  diagnostics.active - A global on/off switch for all
            %  diagnostic settings (default boolean value is false);
            %
            %  diagnostics.sample_volumes - A structure specifying
            %  diagnostics for the sample volumes to be generated for
            %  the data.
            %
            %  diagnostics.sample_volumes.write_files - Indicates whether
            %  the volume synthesized for each observation should be
            %  written to disk (default false).
            %
            %  diagnostics.sample_volumes.overwrite_existing_files - 
            %  Indicates whether volumes already saved on disk should be 
            %  overwritten (default false).
            %
            
            if ~exist('options', 'var') || isempty(options)
                options = struct();
            end
            
            additional_options = hdng.utilities.parse_struct_from_varargin(varargin{:});
           
            names = fieldnames(additional_options);
            
            for i=1:numel(names)
                name = names{i};
                options.(name) = additional_options.(name);
            end
            
            if ~isfield(options, 'diagnostics')
                options.diagnostics = struct();
            end
            
            if ~isfield(options.diagnostics, 'active')
                options.diagnostics.active = false;
            end
            
            if ~isfield(options.diagnostics, 'sample_volumes')
                options.diagnostics.sample_volumes = struct();
            end
            
            if ~isfield(options.diagnostics.sample_volumes, 'write_files')
                options.diagnostics.sample_volumes.write_files = false;
            end
            
            if ~isfield(options.diagnostics.sample_volumes, 'overwrite_existing_files')
                options.diagnostics.sample_volumes.overwrite_existing_files = false;
            end
            
            obj = obj@hdng.pipeline.Pipeline(options);
        end
        
        function [did_exist, binding] = get_requirement(obj, identifier)
            [did_exist, binding] = obj.binding_for(hdng.pipeline.Stage.REQUIREMENTS_CATEGORY, identifier);
        end
        
        function [did_exist, binding] = get_product(obj, identifier)
            [did_exist, binding] = obj.binding_for(hdng.pipeline.Stage.PRODUCTS_CATEGORY, identifier);
        end
        
        function [binding, options] = define_requirement(obj, identifier, options, varargin)
            
            if ~exist('options', 'var')
                options = struct();
            end
            
            [binding, options] = obj.define_binding(hdng.pipeline.Stage.REQUIREMENTS_CATEGORY, ...
                identifier, options, varargin{:});
        end
        
        function [binding, options] = define_product(obj, identifier, options, varargin)
            
            if ~exist('options', 'var')
                options = struct();
            end
            
            [binding, options] = obj.define_binding(hdng.pipeline.Stage.PRODUCTS_CATEGORY, ...
                identifier, options, varargin{:});
        end
    end
    
    methods (Access = private)
        
        function result = now(~)
            result = datetime('now', 'TimeZone', 'local', 'Format', 'yyyy_MM_dd_HH_mm_ss');
        end
    end
    
end
