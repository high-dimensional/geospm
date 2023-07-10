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

classdef ExtractStructField < hdng.experiments.ValueGenerator
    %ExtractStructField Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        from
        field
        label_field
        description
    end
    
    methods
        
        function obj = ExtractStructField(varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'from')
                options.from = '';
            end

            if ~isfield(options, 'field')
                options.field = '';
            end

            if ~isfield(options, 'label_field')
                options.label_field = '';
            end

            if ~isfield(options, 'description')
                options.description = '';
            end
            
            obj = obj@hdng.experiments.ValueGenerator();
            obj.from = options.from;
            obj.field = options.field;
            obj.label_field = options.label_field;
            obj.description = options.description;
        end
        
    end
    
    methods (Access=protected)
        
        
        function result = create_iterator(obj, arguments)
            struct_value = arguments.(obj.from);
            field_value = struct_value.(obj.field);
            
            value_args = {field_value};
            
            if ~isempty(obj.label_field)
                value_args{end + 1} = struct_value.(obj.label_field);
            end
            
            value = hdng.experiments.Value.from(value_args{:});
            result = hdng.experiments.ValueListIterator({value});
        end
        
    end
    
    methods (Static, Access=private)
        
    end
    
end
