% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2021,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %


classdef FileAggregatorGroup < handle
    
    properties
        name
        mode
        entries
        options
    end
    
    methods
        
        function obj = FileAggregatorGroup(name, mode, options)
            
            obj.name = name;
            obj.mode = mode;
            
            obj.entries = {};
            obj.options = options;
        end
        
        function prepare(obj) %#ok<MANU>
        end
        
        function gather_entry(obj, entry) %#ok<INUSD>
        end
        
        function gather_group(obj, group) %#ok<INUSD>
        end
        
        function finalise(obj) %#ok<MANU>
        end
        
        function process(obj, output_directory) %#ok<INUSD>
        end
        
        function output_path = make_output_path(obj, output_directory)
            output_path = fullfile(output_directory, obj.name);
        end
    end
end

