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

classdef RecordValueGroup < handle
    
    %RecordValueGroup Holds a collection of records that share the same value.
    %
    
    properties
        value
        records
        attachments
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = RecordValueGroup(value)
            obj.value = value;
            obj.records = {};
            obj.attachments = hdng.utilities.Dictionary();
        end
        
        function did_add = include_record(obj, record)
            
            did_add = true;
            
            for r_index=1:numel(obj.records)

                if record == obj.records{r_index}
                    did_add = false;
                    return
                end
            end

            obj.records = [obj.records, {record}];
        end
        
        function did_remove = exclude_record(obj, record)
            
            did_remove = false;

            for r_index=1:numel(obj.records)

                if record == obj.records{r_index}
                    did_remove = true;

                    obj.records(r_index) = [];
                    
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
