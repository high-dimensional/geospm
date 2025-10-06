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

classdef Call < hdng.diagrams.DataTransform
    %Call Summary.  
    %   Detailed description 
    
    properties
        output_mode
        func
        call_mode
    end
    
    properties (Dependent, Transient)
    end
    
    properties (Access=private)
    end

    methods
        function obj = Call(output_mode, func, call_mode)

            if ~exist('output_mode', 'var')
                output_mode = 'records';
            end

            if ~exist('func', 'var')
                func = @(varargin) 0;
            end

            if ~exist('call_mode', 'var')
                call_mode = 'struct';
            end
            
            obj.output_mode = output_mode;
            obj.func = func;
            obj.call_mode = call_mode;
        end
        
        function result_scope = compute(obj, data_scope, base, parent, siblings) %#ok<INUSD>

            switch obj.call_mode

                case 'struct'
                    handler = obj.func;
                 
                case 'name_value_pairs'
                    handler = @(records) obj.call_with_name_value_pairs(records, false);
                
                case 'fields_ascending'
                    handler = @(records) obj.call_with_fields(records, false, true);
                
                case 'fields_descending'
                    handler = @(records) obj.call_with_fields(records, false, false);

                case 'record_array'
                    handler = obj.func;
                 
                case 'aggregate_name_value_pairs'
                    handler = @(records) obj.call_with_name_value_pairs(records, true);
                
                case 'aggregate_fields_ascending'
                    handler = @(records) obj.call_with_fields(records, true, true);
                
                case 'aggregate_fields_descending'
                    handler = @(records) obj.call_with_fields(records, true, false);
            
            
                otherwise
                    error('Call:UnknownCallMode', 'Unknown callmode: %s', obj.call_mode);
            end
            
            %{
            records = hdng.utilities.RecordTable();

            for index=1:data_scope.records.length
                record = data_scope.records.row(index);
                
                result = handler(record);
                records = records + hdng.utilities.RecordTable(result, 1);
            end
            %}

            records = handler(data_scope.records);
            
            attributes = data_scope.attributes;

            switch obj.output_mode
                case 'records'

                case 'attributes'
                    
                    for index=1:numel(records.fieldnames)
                        name = records.fieldnames{index};
                        attributes.(name) = records.fields.(name);
                    end

                    records = hdng.utilities.RecordTable();
                
                otherwise
                    error('Call:UnknownOutputMode', 'Unknown output mode: %s', obj.output_mode);
            end
            
            result_scope = hdng.diagrams.DataScope(data_scope.data_level, attributes, records);
        end
    end

    methods (Access=protected)
    
    end

    methods (Access=private)
        
        function result = call_with_name_value_pairs(obj, records, aggregate)
            
            if ~aggregate

                result = hdng.utilities.RecordTable;

                for index=1:records.length
                    record = records.row(index);
                    
                    record_result = obj.call_record_with_name_value_pairs(record);
                    result = result + hdng.utilities.RecordTable(record_result, 1);
                end
            else

                args = hdng.utilities.struct_to_name_value_sequence(records.fields);
                result = obj.func(args{:});
            end
        end
        
        function result = call_with_fields(obj, records, aggregate, ascending)

            if ~aggregate

                result = hdng.utilities.RecordTable;

                for index=1:records.length
                    record = records.row(index);
                    
                    record_result = obj.call_record_with_fields(record, ascending);
                    result = result + hdng.utilities.RecordTable(record_result, 1);
                end
            else
                sorted_names = sort(records.fieldnames);
    
                if ~ascending
                    sorted_names = sorted_names(numel(sorted_names):1);
                end
                
                args = cell(numel(sorted_names), 1);
    
                for index=1:numel(sorted_names)
                    name = sorted_names{index};
                    args{index} = records.fields.(name);
                end
    
                result = obj.func(args{:});
            end
        end

        function result = call_record_with_name_value_pairs(obj, record)
            args = hdng.utilities.struct_to_name_value_sequence(record);
            result = obj.func(args{:});
        end
        
        function result = call_record_with_fields(obj, record, ascending)

            sorted_names = sort(fieldnames(record));

            if ~ascending
                sorted_names = sorted_names(numel(sorted_names):1);
            end
            
            args = cell(numel(sorted_names), 1);

            for index=1:numel(sorted_names)
                name = sorted_names{index};
                args{index} = record.(name);
            end

            result = obj.func(args{:});
        end
    end
end
