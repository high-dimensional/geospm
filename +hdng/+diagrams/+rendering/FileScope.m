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

classdef FileScope < hdng.diagrams.rendering.TargetScope
    %FileScope Summary.
    %   Detailed description 
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    properties (Access=private)
        saved_file_name
        style_definitions
        file_handle
    end

    methods
        
        function obj = FileScope(varargin)

            obj@hdng.diagrams.rendering.TargetScope(varargin{:});

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'file_handle_parameters')
                options.file_handle_parameters = {};
            end

            if ~isfield(options, 'style_definitions')
                options.style_definitions = {};
            end

            obj.saved_file_name = '';
            obj.file_handle = hdng.diagrams.rendering.FileHandle(...
                options.file_handle_parameters{:});

            obj.style_definitions = options.style_definitions;
            obj.target_proxy.delegate = obj.file_handle;
        end
        
        function enter(obj, context)
            enter@hdng.diagrams.rendering.TargetScope(obj, context);

            if isempty(context.directory)
                error('No working directory defined in render context.');
            end

            obj.saved_file_name = context.file_name;
            context.file_name = obj.name;

            obj.file_handle.file_path = fullfile(context.directory, context.file_name);
        end
        
        function exit(obj, context)
            
            if ~isempty(obj.style_definitions)
                context.renderer.render_style_definitions(obj.style_definitions, context);
            end
            
            exit@hdng.diagrams.rendering.TargetScope(obj, context);

            context.file_name = obj.saved_file_name;

            obj.file_handle.close();
        end
        
        function write_bytes(obj, output)
            obj.file_handle.write_bytes(output);
        end

        function write_text(obj, output)
            obj.file_handle.write_text(output);
        end
    end
end
