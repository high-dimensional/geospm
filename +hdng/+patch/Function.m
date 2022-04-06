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

classdef Function < hdng.patch.Fragment
    %Function Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess=public, SetAccess=private)
        name
    end
    
    properties
        
        header_range
        body_range
    end
    
    properties (Dependent, Transient)
        
        
        arguments
        argument_index
        
        return_values
        return_value_index
        
        header_text
        body_text
    end
    
    properties (GetAccess=private, SetAccess=private)
        arguments_
        argument_index_
        return_values_
        return_value_index_
    end
    
    methods
        
        function obj = Function(range_in_file, name)
            
            obj = obj@hdng.patch.Fragment(range_in_file);
            
            obj.name = name;
            
            obj.arguments_ = {};
            obj.argument_index_ = [];
            
            obj.return_values_ = {};
            obj.return_value_index_ = [];
            
            obj.header_range = [];
            obj.body_range = [];
        end
        
        function result = get.arguments(obj)
            result = obj.arguments_;
        end
        
        function result = get.return_values(obj)
            result = obj.return_values_;
        end
        
        function set.arguments(obj, value)
            obj.arguments_ = value;
            obj.argument_index_ = [];
        end
        
        function set.return_values(obj, value)
            obj.return_values_ = value;
            obj.return_value_index_ = [];
        end
        
        function result = get.argument_index(obj)
            if ~isempty(obj.arguments_) && isempty(obj.argument_index_)
                
                obj.argument_index_ = struct();
                
                for i=1:numel(obj.arguments_)
                    obj.argument_index_.(obj.arguments_{i}) = true;
                end
            end
            
            result = obj.argument_index_;
        end
        
        function result = get.return_value_index(obj)
            if ~isempty(obj.return_values_) && isempty(obj.return_value_index_)
                
                obj.return_value_index_ = struct();
                
                for i=1:numel(obj.return_values_)
                    obj.return_value_index_.(obj.return_values_{i}) = true;
                end
            end
            
            result = obj.return_value_index_;
        end
        
        
        function result = get.header_text(obj)
            result = obj.text(obj.header_range(1):obj.header_range(2));
        end
        
        function result = get.body_text(obj)
            result = obj.text(obj.body_range(1):obj.body_range(2));
        end
        
        function set.header_text(obj, value)
            
            svd_body_text = obj.body_text;
            obj.body_range = obj.body_range - obj.header_range(2) + numel(value) + 1;
            obj.header_range = [1, numel(value)];
            obj.text = [value svd_body_text];
        end
        
        function set.body_text(obj, value)
            
            svd_header_text = obj.header_text;
            obj.body_range = [1, numel(value)] + numel(svd_header_text);
            obj.text = [svd_header_text value];
        end
        
        function [matched, unmatched] = match_arguments(obj, values)
            
            matched = {};
            unmatched = {};
            match_index = obj.argument_index;
            
            for i=1:numel(values)
                if isfield(match_index, values{i})
                    matched = [matched; values{i}]; %#ok<AGROW>
                else
                    unmatched = [unmatched; values{i}]; %#ok<AGROW>
                end
            end
        end
        
        function [matched, unmatched] = match_return_values(obj, values)
            
            matched = {};
            unmatched = {};
            match_index = obj.return_value_index;
            
            for i=1:numel(values)
                if isfield(match_index, values{i})
                    matched = [matched; values{i}]; %#ok<AGROW>
                else
                    unmatched = [unmatched; values{i}]; %#ok<AGROW>
                end
            end
        end
    end
    
    methods (Access=protected)
        
        function result = access_type(~)
            result = 'function';
        end
        
    end
end
