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

classdef Pivot < hdng.diagrams.DataTransform
    %Pivot Summary.  
    %   Detailed description 
    
    properties
        header_field
        format_header_values
        match_header_values
        row_label_column
        merge_identical_columns
    end
    
    properties (Dependent, Transient)
    end
    
    properties (Access=private)
    end

    methods
        function obj = Pivot(header_field, format_header_values,...
                match_header_values, row_label_column, merge_identical_columns)

            if ~exist('format_header_values', 'var')
                format_header_values = [];
            end

            if ~exist('match_header_values', 'var')
                match_header_values = {};
            end
         
            if ~exist('row_label_column', 'var')
                row_label_column = [];
            end

            if ~exist('merge_identical_columns', 'var')
                merge_identical_columns = false;
            end

            obj@hdng.diagrams.DataTransform();

            obj.header_field = header_field;
            obj.format_header_values = format_header_values;
            obj.match_header_values = match_header_values;
            obj.row_label_column = row_label_column;
            obj.merge_identical_columns = merge_identical_columns;
        end
        
        function result_scope = compute(obj, data_scope, base, parent, siblings) %#ok<INUSD>
            
            records = data_scope.records.pivot(...
                obj.header_field, ...
                obj.format_header_values, ...
                obj.match_header_values, ...
                obj.row_label_column, ...
                obj.merge_identical_columns ...
            );
            
            result_scope = hdng.diagrams.DataScope(data_scope.data_level, data_scope.attributes, records);
        end
    end

    methods (Access=protected)
    
    end
end
