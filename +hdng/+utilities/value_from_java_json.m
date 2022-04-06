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

function result = value_from_java_json(value)
    
    if isa(value, 'jdk.nashorn.api.scripting.ScriptObjectMirror')
        
        result = hdng.utilities.OrderedMap('KeyType', 'char', 'ValueType', 'any');
        entries = value.entrySet().toArray();
        
        for index=1:entries.length

            entry = entries(index);
            entry_key = entry.getKey();
            entry_value = entry.getValue();

            if ~ischar(entry_key)
                error('value_from_java_json(): Map keys must be of type char.');
            end
            
            if isempty(entry_value)
                string = entry.toString();
                
                if endsWith(string, '=null')
                    entry_value = missing;
                end
            end
            
            result(entry_key) = hdng.utilities.value_from_java_json(entry_value);
        end

    elseif isa(value, 'jdk.nashorn.internal.runtime.JSONListAdapter')
        
        string = char(value.toString());
        
        if startsWith(string, '[')
            string = string(2:end);
        end
        
        if endsWith(string, ']')
            string = string(1:end - 1);
        end
        
        parts = split(string, ',');
        value = value.toArray();
        result = cell(value.length, 1);
        
        for index=1:value.length
            element = value(index);
            part = parts{index};
            
            if isempty(element) && strcmp(part, 'null')
                result{index} = missing;
            else
                result{index} = hdng.utilities.value_from_java_json(element);
            end
        end
    else
        result = value;
    end
end
