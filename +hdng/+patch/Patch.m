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

classdef Patch < handle
    %Patch Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
        impl
    end
    
    properties (Dependent, Transient)
        
        path
        patch_file_path
    end
    
    properties (GetAccess = private, SetAccess = private)
        path_
    end
    
    methods (Static)
        
        function identifier = get_default_implementation()
            identifier = hdng.patch.Patch.handle_implementations('getdefault');
        end
        
        
        function set_default_implementation(identifier)
            hdng.patch.Patch.handle_implementations('setdefault', identifier);
        end
        
        function register_implementation(identifier, cls)
            hdng.patch.Patch.handle_implementations('register', identifier, cls);
        end
        
        function deregister_implementation(identifier)
            hdng.patch.Patch.handle_implementations('deregister', identifier);
        end
        
        function result = lookup_implementation(identifier, default)
            
            if ~exist('default', 'var')
                default = [];
            end
            
            result = hdng.patch.Patch.handle_implementations('lookup', identifier, default);
        end
    end
    
    methods (Static, Access=private)
        
        function result = handle_implementations(action, varargin)
            
            persistent default_implementation;
            persistent implementations;
            
            result = [];
            
            switch action
                
                case 'getdefault'
                    
                    if isempty(default_implementation)
                        default_implementation = 'builtin.1';
                        hdng.patch.Patch.register_implementation(default_implementation, @hdng.patch.PatchV1);
                    end
                    
                    result = default_implementation;
                    
                case 'setdefault'
                    
                    default_implementation = varargin{1};
                
                case 'register'
                    
                    if isempty(implementations)
                        implementations = containers.Map('KeyType', 'char', 'ValueType', 'any');
                    end
                    
                    implementations(varargin{1}) = varargin{2};
                    
                case 'deregister'
                    
                    if isempty(implementations)
                        return;
                    end
                    
                    if ~isKey(implementations, varargin{1})
                        return;
                    end
                    
                    implementations.remove(varargin{1});
                    
                case 'lookup'
                    
                    
                    if isempty(implementations) || ~isKey(implementations, varargin{1})
                        result = varargin{2};
                        return;
                    end
                    
                    result = implementations(varargin{1});
                    
                otherwise
                    
                    error('Patch.handle_implementations(): Unknown action %s', action);
            end
            
        end
        
    end
    
    methods
        
        function obj = Patch(path, patch_impl)
            
            if ~exist('patch_impl', 'var')
                patch_impl = hdng.patch.Patch.get_default_implementation();
            end
            
            obj.path_ = path;

            if ~isempty(obj.path_)

                [dirstatus, dirmsg] = mkdir(obj.path_);
                if dirstatus ~= 1; error(dirmsg); end
                
                try
                    patch_impl = strip(hdng.utilities.load_text(obj.patch_file_path));
                    
                catch ME
                    if ~strcmp(ME.identifier, 'MATLAB:FileIO:InvalidFid')
                        rethrow(ME);
                    end
                    
                    if isempty(hdng.patch.Patch.lookup_implementation(patch_impl))
                        error('Patch.ctor(): Unknown patch class %s.', patch_impl);
                    end
                    
                    hdng.utilities.save_text([patch_impl newline], obj.patch_file_path);
                end
            end
            
            impl = hdng.patch.Patch.lookup_implementation(patch_impl);
            
            if isempty(impl)
                error('Patch.ctor(): Unknown patch class %s.', patch_impl);
            end
            
            obj.impl = impl(obj.path_);
        end
        
        function result = get.path(obj)
            result = obj.access_path();
        end
        
        function result = get.patch_file_path(obj)
            result = obj.access_patch_file_path();
        end
        
        function load(obj)
            obj.impl.load(obj);
        end
        
        function save(obj)
            obj.impl.save(obj);
        end
        
        function apply(obj)
            obj.impl.apply(obj);
        end
    end
    
    methods (Access = protected)
        
        function result = access_path(obj)
            result = obj.path_;
        end
        
        
        function result = access_patch_file_path(obj)
            result = fullfile(obj.path_, 'patch');
        end
    end
end
