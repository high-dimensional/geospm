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

classdef ValueMapEntry < handle
    
    %ValueMapEntry Holds a collection of records that share the same key.
    %
    
    properties
        key
        attachments_by_value
    end
    
    properties (Dependent, Transient)
        values
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = ValueMapEntry(key)
            obj.key = key;
            obj.attachments_by_value = {};
        end
        
        function result = attachments_for_value(obj, value)
            
            result = hdng.utilities.Dictionary.empty;
            
            for index=1:numel(obj.attachments_by_value)
                
                entry = obj.attachments_by_value{index};
                
                if ~(value == entry.value)
                    continue
                end
                
                result = entry.attachments;
                return
            end
        end
        
        function result = get.values(obj)
            
            result = cell(numel(obj.attachments_by_value), 1);
            
            for index=1:numel(obj.attachments_by_value)
                
                entry = obj.attachments_by_value{index};
                result{index} = entry.value;
            end
            
        end
        
        function [did_contain, attachment] = get(obj, value)
            
            did_contain = false;
            attachment = [];
            
            for index=1:numel(obj.attachments_by_value)
                
                entry = obj.attachments_by_value{index};
                
                if ~(value == entry.value)
                    continue
                end
                
                did_contain = true;
                attachment = entry.attachment;
                return
            end
        end
        
        function set(obj, value, attachment)
            
            for index=1:numel(obj.attachments_by_value)
                
                entry = obj.attachments_by_value{index};
                
                if ~(value == entry.value)
                    continue
                end
                
                entry.attachment = attachment;
                return
                
            end
            
            entry = struct();
            entry.value = value;
            entry.attachment = attachment;
            
            obj.attachments_by_value = [obj.attachments_by_value, entry];
        end
        
        function [did_remove, attachment] = remove(obj, value)
            
            did_remove = false;
            attachment = [];
            
            for index=1:numel(obj.attachments_by_value)
                
                entry = obj.attachments_by_value{index};
                
                if ~(value == entry.value)
                    continue
                end
                
                did_remove = true;
                attachment = entry.attachment;
                
                obj.attachments_by_value = [obj.attachments_by_value(1:index - 1), obj.attachments_by_value(index + 1:end)];
                return
            end
        end
    end
    
    methods (Static, Access=protected)

    end
end
