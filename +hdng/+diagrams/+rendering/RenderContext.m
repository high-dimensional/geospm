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

classdef RenderContext < handle
    %RenderContext Summary.
    %   Detailed description 
    
    properties
        resource_manager
        resources
        renderer

        view_box

        directory
        file_name
        target_scope
    end

    properties (SetAccess=private)
        base_directory
        saved_target_proxies
    end
    
    properties (Dependent, Transient)
        current_scope
        file_path
        target
        binary_target
        text_target
    end
    
    properties (Access=private)
        scope_ctors
        scope_ctors_by_type
        scopes
    end

    methods

        function result = get.current_scope(obj)
            result = obj.scopes{end};
        end
        
        function result = get.file_path(obj)
            result = fullfile(obj.directory, obj.file_name);
        end

        function result = get.target(obj)
            result = struct();

            if isempty(obj.target_scope)
                return;
            end
            
            result = obj.target_scope.target_proxy.fragments;
        end

        %{
        function set.target(obj, value)

            if isempty(obj.target_scope)
                return;
            end
            
            obj.target_scope.target_proxy.fragments = value;
        end
        %}
        
        function set.binary_target(obj, value)
            if isempty(obj.target_scope)
                return;
            end

            obj.target_scope.write_bytes(value);
        end
        
        function set.text_target(obj, value)
            if isempty(obj.target_scope)
                return;
            end
            
            obj.target_scope.write_text(value);
        end

        function obj = RenderContext(varargin)

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'resource_manager')
                options.resource_manager = hdng.resources.ResourceManager();
            end
            
            if ~isfield(options, 'resources')
                options.resources = hdng.utilities.Dictionary();
            end

            if ~isfield(options, 'renderer')
                options.renderer = [];
            end

            if ~isfield(options, 'scope_ctors')
                options.scope_ctors = {
                    'directory'; @hdng.diagrams.rendering.DirectoryScope;
                    'file'; @hdng.diagrams.rendering.FileScope;
                    'page'; @hdng.diagrams.rendering.PageScope;
                    'target'; @hdng.diagrams.rendering.TargetScope;
                };
            end

            if ~isfield(options, 'base_directory')
                options.base_directory = char(hdng.utilities.timestamp());
            end

            if ~isfield(options, 'directory')
                options.directory = options.base_directory;
            end

            if ~isfield(options, 'file_name')
                options.file_name = 'diagram';
            end

            if ~isfield(options, 'view_box')
                options.view_box = [0, 0, 3740, 3740];
            end
            
            obj.resource_manager = options.resource_manager;
            obj.resources = options.resources;
            obj.renderer = options.renderer;

            obj.view_box = options.view_box;

            obj.scope_ctors = options.scope_ctors;
            obj.scope_ctors_by_type = ...
                hdng.utilities.parse_struct_from_varargin(obj.scope_ctors{:});
            
            obj.scopes = {};
            obj.target_scope = [];

            obj.base_directory = options.base_directory;
            obj.directory = options.directory;
            obj.file_name = options.file_name;

            obj.saved_target_proxies = hdng.utilities.Dictionary();
        end

        function enter_scope(obj, type, name, varargin)
            
            if ~isfield(obj.scope_ctors_by_type, type)
                error('RenderContext:UnknownScopeType', 'Could not enter unknown scope type %s', type);
            end
            
            scope_ctor = obj.scope_ctors_by_type.(type);
            scope = scope_ctor('name', name, 'renderer', obj.renderer, varargin{:});

            scope.enter(obj);

            obj.scopes{end + 1} = scope;
        end
        
        function exit_scope(obj)
            scope = obj.current_scope;
            scope.exit(obj);
            
            obj.scopes = obj.scopes(1:end - 1);
        end
    end
end
