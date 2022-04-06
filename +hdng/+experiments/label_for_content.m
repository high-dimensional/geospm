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

function result = label_for_content(content, add_string_quotes)
%label_for_content Derives a label from a value
    
    if ~exist('add_string_quotes', 'var')
        add_string_quotes = false;
    end

    if isa(content, 'hdng.experiments.Value')
        result = content.label;
        return
    end
    
    if isa(content, 'char')
        result = content;
        return
    end
    
    if isa(content, 'logical')
        if numel(content) == 1
            if content == true
                result = 'true';
            else
                result = 'false';
            end
            return
        else
            content = num2cell(content);
        end
    end
    
    if isinteger(content)
        if numel(content) == 1
            result = num2str(content);
            return
        else
            content = num2cell(content);
        end
    end
    
    if isfloat(content)
        if numel(content) == 1
            if isa(content, 'single')
                result = num2str(content, 6);
            elseif isa(content, 'double')
                result = num2str(content, 10);
            end

            return
        else
            content = num2cell(content);
        end
    end
    
    if iscell(content)
        
        result = '{';
        
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

                if index == 1
                    delimiter = '';
                else
                    delimiter = ',';
                end
                
                result = [result sprintf('%s%s', delimiter, hdng.experiments.label_for_content(element, true))]; %#ok<AGROW>
            end
        else
            serialised_value = cell(numel(content), 1);

            for index=1:numel(serialised_value)
                element = content{index};
                
                if index == 1
                    delimiter = '';
                else
                    delimiter = ',';
                end
                
                result = [result sprintf('%s%s', delimiter, hdng.experiments.label_for_content(element, true))]; %#ok<AGROW>
            end
        end
        
        result = [result '}'];
        return;
    end
    
    if isstruct(content)
        
        result = '{';
        
        names = fieldnames(content);
        
        for index=1:numel(names)
            
            if index == 1
                delimiter = '';
            else
                delimiter = ',';
            end
            
            key = names{index};
            result = [result sprintf('%s%s=%s', delimiter, key, hdng.experiments.label_for_content(content.(key), true))]; %#ok<AGROW>
        end
        
        result = [result '}'];
        return
    end
    
    if isa(content, 'hdng.utilities.Dictionary')
        
        result = '{';
        
        names = content.keys();
        
        for index=1:numel(names)
            
            if index == 1
                delimiter = '';
            else
                delimiter = ',';
            end
            
            key = names{index};
            result = [result sprintf('%s%s=%s', delimiter, key, hdng.experiments.label_for_content(content(key), true))]; %#ok<AGROW>
        end
        
        result = [result '}'];
        return
    end
    
    if isa(content, 'hdng.experiments.ValueContent')
        result = content.label_for_content();
        return
    end
    
    try
        result = char(content);
    catch
        result = class(content);
    end
    
    if add_string_quotes
        result = ["'" result "'"];
    end
end
