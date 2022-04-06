% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2021,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function result = decode_json_proxy(argument)
%decode_json Decode argument from JSON string.
%
    
    if isa(argument, 'containers.Map')
        
        
        if isKey(argument, 'content') && isKey(argument, 'content_type') && isKey(argument, 'content_digest') && isKey(argument, 'label')
            result = hdng.experiments.Value.load_from_proxy(argument);
            return;
        end
        
        result = containers.Map('KeyType', 'char', 'ValueType', 'any');
        
        names = argument.keys();
        
        for index=1:numel(names)
            
            key = names{index};
            result(key) = hdng.experiments.decode_json_proxy(argument(key));
        end
        
        return
    end
    
    if iscell(argument)
        
        result = cell(size(argument));
        
        for index=1:numel(argument)
            result{index} = hdng.experiments.decode_json_proxy(argument{index});
        end
        
        return
    end
    
    result = argument;
end
