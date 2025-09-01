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

classdef DelegateCall < hdng.diagrams.DataTransform
    %DelegateCall Summary.  
    %   Detailed description 
    
    properties
        output_mode
        delegate
    end
    
    properties (Dependent, Transient)
    end
    
    properties (Access=private)
    end

    methods
        function obj = DelegateCall(output_mode, delegate)

            if ~exist('output_mode', 'var')
                output_mode = 'records';
            end
            
            if ~exist('delegate', 'var')
                delegate = @(varargin) 0;
            end
            
            obj.output_mode = output_mode;
            obj.delegate = delegate;
        end
        
        function result_scope = compute(obj, data_scope, base, parent, siblings)
            
            result_scope = data_scope;

            if isempty(obj.delegate)
                return;
            end

            result = obj.delegate(data_scope, base, parent, siblings);
            records = hdng.utilities.RecordTable(result, 1);
            
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
        
        function result = call_with_name_value_pairs(obj, record)
            args = hdng.utilities.struct_to_name_value_sequence(record);
            result = obj.func(args{:});
        end
        
        function result = call_with_fields(obj, record, ascending)

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
