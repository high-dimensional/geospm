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

function result = wrap_text(string, break_words, width)
    
    if ~exist('break_words', 'var')
        break_words = false;
    end

    if ~exist('width', 'var')
        width = 72;
    end
    
    function result = combine(varargin)
        result = varargin;
    end

    expr = '(?<word>[^\s]+)|(?<space>[\s]+)';
    [starts, ends, tokens] = regexp(string, expr, 'start', 'end', 'names');
    
    words = ~cellfun(@isempty, combine(tokens.word));
    word_starts = starts(words);
    word_ends = ends(words);
    
    result = '';
    pos = 1;
    
    while pos < numel(string)
        limit = pos + width - 1;
        
        if limit > numel(string)
            limit = numel(string);
        end
        
        while ~break_words
            
            [index_or_zero, start_insert_at] = ...
                hdng.utilities.binary_search(word_starts, limit);

            if index_or_zero ~= 0
                % at the beginning of word
                limit = limit - 1;
                break;
            end

            [index_or_zero, end_insert_at] = ...
                hdng.utilities.binary_search(word_ends, limit);

            if index_or_zero ~= 0
                % at the end of word
                break;
            end

            if start_insert_at - 1 == end_insert_at
                
                start_insert_at = word_starts(start_insert_at - 1);
                
                % in the middle of word
                if start_insert_at >= pos + 2
                    limit = start_insert_at - 1;
                end
                
                break;
            end
            
            break;
        end
        
        fragment = string(pos:limit);
        
        [starts, ends] = regexp(fragment, '^ ', 'start', 'end');
        
        if ~isempty(starts)
            fragment = fragment(ends+1:end);
        end
        
        if isempty(result)
            result = fragment;
        else
            result = [result newline fragment]; %#ok<AGROW>
        end
        
        pos = limit + 1;
    end
end
