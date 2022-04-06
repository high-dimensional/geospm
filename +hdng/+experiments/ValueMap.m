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

classdef ValueMap < handle
    
    %ValueMap .
    %
    
    properties
    end
    
    properties (Dependent, Transient)
        is_empty
        length
        values
    end
    
    properties (GetAccess=private, SetAccess=private)
        values_
    end
    
    methods
        
        function obj = ValueMap()
            obj.values_ = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end
        
        function result = get.length(obj)
            result = length(obj.values_); %#ok<CPROP>
        end
        
        function result = get.is_empty(obj)
            result = length(obj.values_) == 0; %#ok<ISMT,CPROP>
        end
        
        function result = get.values(obj)
            
            result = {};
            value_keys = keys(obj.values_);
            
            for index=1:numel(value_keys)
                
                key = value_keys{index};
                entry = obj.values_(key);
                result = [result; entry.values]; %#ok<AGROW>
            end
        end
        
        function [did_contain, attachment] = get(obj, value)
            
            if ~isa(value, 'hdng.experiments.Value')
                error('ValueMap.get() expects a hdng.experiments.Value as value but got: %s', class(value));
            end
            
            did_contain = false;
            attachment = [];
            
            key = value.digest;
            
            if ~isKey(obj.values_, key)
                return
            end
            
            entry = obj.values_(key);
            
            [did_contain, attachment] = entry.get(value);
        end
        
        function set(obj, value, attachment)
            
            if ~isa(value, 'hdng.experiments.Value')
                error('ValueMap.set() expects a hdng.experiments.Value as value but got: %s', class(value));
            end
            
            key = value.digest;
            
            if ~isKey(obj.values_, key)
                entry = hdng.experiments.ValueMapEntry(key);
                obj.values_(key) = entry;
            else
                entry = obj.values_(key);
            end
            
            entry.set(value, attachment)
        end
        
        function [did_contain, attachment] = remove(obj, value)
            
            if ~isa(value, 'hdng.experiments.Value')
                error('ValueMap.remove() expects a hdng.experiments.Value as value but got: %s', class(value));
            end
            
            did_contain = false;
            attachment = [];
            
            key = value.digest;
            
            if ~isKey(obj.values_, key)
                return
            end
            
            entry = obj.values_(key);
            
            [did_contain, attachment] = entry.remove(value);
            
            if numel(entry.attachments_by_value) == 0
                remove(obj.values_, key);
            end
        end
    end
    
    methods (Static, Access=protected)
    end
end
