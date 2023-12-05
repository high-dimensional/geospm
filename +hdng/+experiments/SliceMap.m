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

classdef SliceMap < handle
    %SliceMap Summary.
    %   Detailed description 
    
    properties
        slice_names
        slice_index_by_name
    end
    
    methods
        
        function obj = SliceMap(slice_names_or_number)
            obj.slice_names = {};
            obj.slice_index_by_name = hdng.utilities.Dictionary();
            
            if isnumeric(slice_names_or_number)
                for index=1:slice_names_or_number
                    slice_label = fprintf('Slice %d', index);
                    obj.slice_names{end + 1} = slice_label;
                end
            else
                obj.slice_names = slice_names_or_number;
            end

            for index=1:numel(obj.slice_names)
                slice_name = obj.slice_names{index};
                obj.slice_index_by_name(slice_name) = index;
            end
        end
        
        function result = index_for_name(obj, slice_name, default_value)
            
            if ~exist('default_value', 'var')
                default_value = 1;
            end

            result = default_value;

            if ~obj.slice_index_by_name.holds_key(slice_name)
                return
            end

            result = obj.slice_index_by_name(slice_name);
        end

        function result = name_for_index(obj, index)
            safe_index = floor(min([index, numel(obj.slice_names) - 1]));
            result = obj.slice_names{safe_index};
        end
    end
    
    methods (Static)
    end
end
