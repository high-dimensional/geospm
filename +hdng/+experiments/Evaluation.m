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

classdef Evaluation < handle
    
    %Evaluation .
    %
    
    properties
        
        configuration
        directory
        
        canonical_base_path
        source_ref
        
        results
        
        start_time
        stop_time
    end
    
    properties (SetAccess = public)
        attachments % a struct for holding arbitrary shared values
    end
    
    properties (Dependent, Transient)
        directory_name
        directory_path
        
        duration
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = Evaluation()
            obj.configuration = hdng.experiments.Configuration.empty;
            obj.directory = '';
            obj.canonical_base_path = obj.directory;
            obj.source_ref = '';
            obj.results = hdng.utilities.Dictionary();
            obj.start_time = datetime.empty;
            obj.stop_time = datetime.empty;
            obj.attachments = struct();
        end
        
        function result = get.directory_name(obj)
            [~, name, ext] = fileparts(obj.directory);
            result = [name, ext];
        end
        
        function result = get.directory_path(obj)
            [result, ~, ~] = fileparts(obj.directory);
        end
        
        function result = get.duration(obj)
            result = obj.stop_time - obj.start_time;
        end
        
        function result = canonical_path(obj, local_path)
            
            prefix = obj.canonical_base_path;
            
            if startsWith(local_path, prefix)
                result = local_path(numel(prefix)+numel(filesep)+1:end);
            else
                result = local_path;
            end
        end
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
    
end
