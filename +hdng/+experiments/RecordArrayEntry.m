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

classdef RecordArrayEntry < handle
    
    %RecordArrayEntry Holds a collection of records that share the same key.
    %
    
    properties
        key
        records
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = RecordArrayEntry(key)
            obj.key = key;
            obj.records = {};
        end
        
        function result = contains_record(obj, record)
            
            result = false;
            
            for index=1:numel(obj.records)
                if record == obj.records{index}
                    result = true;
                    return
                end
            end
        end
        
        function did_add = include_record(obj, record)
            
            did_add = true;
            
            for index=1:numel(obj.records)
                if record == obj.records{index}
                    did_add = false;
                    return
                end
            end
            
            obj.records = [obj.records; {record}];
        end
        
        function did_remove = exclude_record(obj, record)
            
            did_remove = false;
            
            for index=1:numel(obj.records)
                if record == obj.records{index}
                    did_remove = true;
                    obj.records(index) = [];
                    
                    if isempty(obj.records)
                        obj.records = {};
                    end
                    
                    return
                end
            end
            
        end
    end
    
    methods (Static, Access=protected)

    end
end
