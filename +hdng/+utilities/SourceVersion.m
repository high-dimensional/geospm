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

classdef SourceVersion < handle
    %SourceVersion Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = private)
        search_path
        commit_directory
        
        path
        
        date
        build_number
        hash
        release
        
        string
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = SourceVersion(search_path)
            
            if ~exist('search_path', 'var')
                where = mfilename('fullpath');
                [search_path, ~, ~] = fileparts(where);
            end
            
            obj.search_path = search_path;
            obj.load();
        end
    end
    
    methods (Static)
    end
    
    methods (Access = protected)
        
        function load(obj)
            
            obj.path = [];
            obj.commit_directory = [];
            
            active_path = obj.search_path;
                
            while ~isempty(active_path)
                obj.commit_directory = fullfile(active_path, 'commit');
                
                if exist(obj.commit_directory, 'dir')
                    obj.path = active_path;
                    break;
                end
                
                [new_active_path, ~, ~] = fileparts(active_path);
                
                if strcmp(new_active_path, active_path)
                    obj.commit_directory = [];
                    return
                end
                
                active_path = new_active_path;
            end
            
            
            hash_path = fullfile(obj.commit_directory, 'hash');
            date_path = fullfile(obj.commit_directory, 'date');
            build_number_path = fullfile(obj.commit_directory, 'number');
            release_path = fullfile(obj.commit_directory, 'release');
            string_path = fullfile(obj.commit_directory, 'string');
            
            if exist(hash_path, 'file') ~= 0
                obj.hash = strip(hdng.utilities.load_text(hash_path));
            else
                obj.hash = '';
            end
            
            if exist(date_path, 'file') ~= 0
                obj.date = strip(hdng.utilities.load_text(date_path));
            else
                obj.date = '';
            end
            
            if exist(build_number_path, 'file') ~= 0
                obj.build_number = strip(hdng.utilities.load_text(build_number_path));
            else
                obj.build_number = '';
            end
            
            if exist(release_path, 'file') ~= 0
                obj.release = strip(hdng.utilities.load_text(release_path));
            else
                obj.release = '';
            end
            
            if exist(string_path, 'file') ~= 0
                obj.string = strip(hdng.utilities.load_text(string_path));
            else
                obj.string = '';
            end
        end
        
    end
    
end
