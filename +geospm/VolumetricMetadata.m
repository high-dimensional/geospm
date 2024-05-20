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

classdef VolumetricMetadata < handle
    %VolumetricMetadata Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = public)
        min_xyz
        max_xyz
    end
    
    methods
        
        function obj = VolumetricMetadata()
            
            %Construct a VolumetricMetadata object.

            obj.min_xyz = [];
            obj.max_xyz = [];
        end

        function result = as_json_struct(obj, varargin)

            result = struct();
            result.ctor = 'geospm.VolumetricMetadata';

            result.min_xyz = obj.min_xyz;
            result.max_xyz = obj.max_xyz;
        end
        
        function write_as_json(obj, filepath, varargin)
            %Writes a JSON representation of this VolumetricMetadata object to a file.
            % The range of possible name-value arguments is documented for
            % the as_json_struct() method.
            
            json = obj.as_json_struct(varargin{:});
            
            [dir, name, ext] = fileparts(filepath);
            
            if ~strcmpi(ext, '.json')
                filepath = fullfile(dir, [name, '.json']);
            end
            
            json = jsonencode(json);
            hdng.utilities.save_text(json, filepath);
        end
    end
    
    methods (Static)

        function result = from_json_struct_impl(specifier)
            
            if ~isfield(specifier, 'min_xyz') || ~isnumeric(specifier.min_xyz)
                error('Missing ''min_xyz'' field in json struct or ''min_xyz'' field is not numeric.');
            end

            if ~isfield(specifier, 'max_xyz') || ~isnumeric(specifier.max_xyz)
                error('Missing ''max_xyz'' field in json struct or ''max_xyz'' field is not numeric.');
            end
            
            result = geospm.VolumetricMetadata();

            result.min_xyz = specifier.min_xyz;
            result.max_xyz = specifier.max_xyz;
        end

        function result = from_json_struct(specifier)
            
            ctor = str2func([specifier.ctor '.from_json_struct_impl']);
            result = ctor(specifier);
        end

        function result = from_json_file(path, varargin)
                
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'create_if_missing')
                options.create_if_missing = true;
            end
            
            if ~exist(path, 'file')
                result = geospm.VolumetricMetadata();
                return;
            end

            specifier = hdng.utilities.load_json(path);

            ctor = str2func([specifier.ctor '.from_json_struct_impl']);
            result = ctor(varargin{:});
        end
        
    end
end
