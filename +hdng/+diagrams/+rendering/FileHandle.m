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

classdef FileHandle < hdng.diagrams.rendering.Target
    %FileHandle Summary.
    %   Detailed description 
    
    properties
        file_path
    end

    properties (Dependent, Transient)
    end

    properties (SetAccess=private)
        file_mode
        file_handle
        file_encoding
        make_directories
    end

    methods
        
        function obj = FileHandle(varargin)

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'file_path')
                options.file_path = '';
            end

            if ~isfield(options, 'file_mode')
                options.file_mode = 'create';
            end
            
            obj.file_path = options.file_path;
            obj.file_mode = options.file_mode;
            obj.file_handle = [];
            obj.file_encoding = 'UTF-8';
            obj.make_directories = true;
        end
        
        function write_bytes(obj, output)
            obj.assert();
            fwrite(obj.file_handle, output);
        end

        function write_text(obj, output)
            obj.assert();
            fwrite(obj.file_handle, output, 'char');
        end
        
        function assert(obj)
            
            if ~isempty(obj.file_handle)
                return;
            end

            switch obj.file_mode
                case 'create'
                    mode_impl = 'w';
                
                case 'append'
                    mode_impl = 'a';
        
                otherwise
                    error('Unknown file mode ''%s''', mode);
            end
            
            if obj.make_directories
                [directory, ~, ~] = fileparts(obj.file_path);
            
                [status, msg] = mkdir(directory);
                
                if status ~= 1
                    error('assert_file_handle(): %s', msg);
                end
            end
            
            obj.file_handle = fopen(obj.file_path, mode_impl, 'n', ...
                obj.file_encoding);
        end
        
        function close(obj)

            if isempty(obj.file_handle)
                return;
            end
            
            fclose(obj.file_handle);
            obj.file_handle = [];
        end
    end
end
