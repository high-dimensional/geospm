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

function [serialised_value, type_identifier] = as_serialised_value_and_type(content)
    %as_serialised_value_and_type Serialises a content value
    
    if isa(content, 'char')
        serialised_value = content;
        type_identifier = 'builtin.str';
        return
    end
    
    if isa(content, 'hdng.experiments.Value')
        serialised_value = content.serialised;
        type_identifier = content.type_identifier;
        return
    end
    
    if isa(content, 'logical')
        if numel(content) == 1
            serialised_value = content;
            type_identifier = 'builtin.bool';
            return
        else
            content = num2cell(content);
        end
    end
    
    if isinteger(content)
        if numel(content) == 1
            serialised_value = content;
            type_identifier = 'builtin.int';
            return
        else
            content = num2cell(content);
        end
    end
    
    if isfloat(content)
        if numel(content) == 1
            
            if isinf(content)
                if content > 0
                    serialised_value = 'Infinity';
                else
                    serialised_value = '-Infinity';
                end
                
                type_identifier = 'builtin.float.symbolic';
                return
            end
            
            if isnan(content)
                serialised_value = 'NaN';
                type_identifier = 'builtin.float.symbolic';
                return
            end
            
            serialised_value = content;
            type_identifier = 'builtin.float';
            return
        else
            content = num2cell(content);
        end
    end
    
    if iscell(content)
        
        inner_size = size(content);
        D = numel(inner_size);
        
        if D > 1 && inner_size(1) > 1 && inner_size(2) > 1
            inner_size = inner_size(2:end);
            serialised_value = cell(size(content, 1), 1);

            for index=1:numel(serialised_value)
                element = content(index, :);
                
                if D > 2
                    element = reshape(element, inner_size);
                end
                
                value = hdng.experiments.Value.from(element);
                serialised_value{index} = value.as_map();
            end
        else
            serialised_value = cell(numel(content), 1);

            for index=1:numel(serialised_value)
                element = content{index};
                value = hdng.experiments.Value.from(element);
                serialised_value{index} = value.as_map();
            end
        end
        
        type_identifier = 'builtin.list';
        return
    end
    
    if isstruct(content)
        
        serialised_value = containers.Map('KeyType', 'char', 'ValueType', 'any');
        
        keys = fieldnames(content);
        
        for index=1:numel(keys)
            key = keys{index};
            element = content.(key);
            value = hdng.experiments.Value.from(element);
            serialised_value(key) = value.as_map();
        end
        
        type_identifier = 'builtin.struct';
        return
    end
    
    if isa(content, 'hdng.utilities.Dictionary')
        
        serialised_value = containers.Map('KeyType', 'char', 'ValueType', 'any');
        keys = content.keys();
        
        for index=1:numel(keys)
            key = keys{index};
            element = content(key);
            value = hdng.experiments.Value.from(element);
            serialised_value(key) = value.as_map();
        end
        
        type_identifier = 'builtin.dict';
        return
    end
    
    if isa(content, 'hdng.experiments.ValueContent')
        [serialised_value, type_identifier] = content.as_serialised_value_and_type();
        return
    end
    
    serialised_value = class(content);
    type_identifier = 'builtin.missing';
    
    %error('ValueSerialisationError. Value content type is unsupported: %s', class(content));
end

function handle_multidimensional_array(content)
    
    inner_size = size(content);
    D = numel(inner_size);

    if D > 1 && inner_size(2) > 1
        inner_size = inner_size(2:end);
        serialised_value = cell(size(content, 1), 1);

        for index=1:numel(serialised_value)
            element = content(index, :);

            if D > 2
                element = reshape(element, inner_size);
            end

            value = hdng.experiments.Value.from(element);
            serialised_value{index} = value.as_map();
        end
    else
        serialised_value = cell(numel(content), 1);

        for index=1:numel(serialised_value)
            element = content{index};
            value = hdng.experiments.Value.from(element);
            serialised_value{index} = value.as_map();
        end
    end
end
