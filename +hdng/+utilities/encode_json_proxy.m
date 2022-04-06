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

function result = encode_json_proxy(argument)
%encode_json Encode argument as a JSON string.
%
    
    if isa(argument, 'hdng.experiments.Value')
        
        result = struct();
        result.content = argument.serialised;
        result.content_type = argument.type_identifier;
        result.content_digest = argument.digest;
        result.label = argument.label;
        
        return
    end
    
    if iscell(argument)
        
        result = cell(size(argument));
        
        for index=1:numel(argument)
            result{index} = hdng.utilities.encode_json_proxy(argument{index});
        end
        
        return
    end
    
    if isstruct(argument)
        
        result = struct();
        names = fieldnames(argument);
        
        for index=1:numel(names)
            key = names{index};
            result.(key) = hdng.utilities.encode_json_proxy(argument.(key));
        end
        
        return
    end
    
    if isa(argument, 'hdng.utilities.Dictionary')
        
        result = containers.Map('KeyType', 'char', 'ValueType', 'any');
        
        names = argument.keys();
        
        for index=1:numel(names)
            
            key = names{index};
            result(key) = hdng.utilities.encode_json_proxy(argument(key));
        end
        
        return
    end
    
    result = argument;
end
