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

classdef RInterface < handle
    %RInterface Helper for running R scripts.
    %   Detailed description to follow here.
    
    properties (Constant)
    end
    
    properties
        commands
    end
    
    methods
        
        function obj = RInterface(directory_path)
            obj.commands = hdng.r_support.RInterface.commands_in_directory(directory_path);
        end
        
        function call(obj, command_id, varargin)
            
            if ~isKey(obj.commands, command_id)
                error(['RInterface.format_call(): Unknown command: ' command_id]);
            end
            
            command = obj.commands(command_id);
            command = ['"' command '"'];
            
            command = obj.format_call(command, varargin{:});
            system(command);
        end
        
        function result = format_call(~, command, varargin)
            
            argument_str = ' ';
            
            for i=1:numel(varargin)
                
                if ischar(varargin{i})
                    argument = varargin{i};
                    
                    if any(isspace(argument))
                        argument = ['"' argument '"']; %#ok<AGROW>
                    end
                else
                    argument = char(varargin{i});
                end
                
                argument_str = [argument_str argument ' ']; %#ok<AGROW>
            end
            
            if endsWith(argument_str, ' ') ~= 0
                argument_str = argument_str(1:end - 1);
            end
            
            result = [command argument_str];
        end
        
        
    end
    
    methods (Static, Access=public)
                
        function [commands, directories] = commands_in_directory(directory_path)
            
            %{
            where = mfilename('fullpath');
            [base_dir, ~, ~] = fileparts(where);
            r_command_dir = fullfile(base_dir, '+experiments');
            %}
            
            directories = cell(0,1);
            commands = containers.Map('KeyType', 'char', 'ValueType', 'any');
            listing = dir(directory_path);

            shebang1 = ['#!/usr/local/bin/Rscript' newline];
            shebang2 = ['#!/usr/bin/Rscript' newline];
            
            for i=1:size(listing, 1)
                
                entry = listing(i);
                file_path = fullfile(entry.folder, entry.name);
                
                if entry.isdir
                    directories{end + 1} = file_path; %#ok<AGROW>
                    continue;
                end
                
                if ~endsWith(entry.name, '.r')
                    continue;
                end
                
                h = fopen(file_path, "r", "n", "UTF-8");
                text = fread(h, '*char')';
                fclose(h);
                
                if ~startsWith(text, shebang1, 'IgnoreCase', true) && ...
                    ~startsWith(text, shebang2, 'IgnoreCase', true)
                    continue;
                end
                
                [~, command_name, ~] = fileparts(file_path);
                
                commands(lower(command_name)) = file_path;
            end
            
            
        end
        
        
    end
    
end
