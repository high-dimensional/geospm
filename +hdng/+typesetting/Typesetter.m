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

classdef Typesetter < handle
    
    %Typesetter 
    %
    
    properties (GetAccess=public, SetAccess=private)
    end
    
    properties (GetAccess=public, SetAccess=public)
    end
    
    properties (Dependent, Transient)
        units

        context
    end
    
    properties (GetAccess=private, SetAccess=private)
        context_
    end
    
    methods
        
        function obj = Typesetter()
            
            obj.context_ = hdng.typesetting.TypesettingContext();
        end
        
        function result = get.context(obj)
            result = obj.context_;
        end

        function result = get.units(obj)
            result = obj.context_.units;
        end

        function set.units(obj, value)
            obj.context_.units = value;
        end

        function [lines, shift] = layout(obj, tokens, max_width, alignment)
            
            if ~exist('alignment', 'var')
                alignment = 'start';
            end

            function line = start_alignment(line, ~)
                line.x = 0;
            end

            function line = center_alignment(line, max_width)
                line.x = max_width / 2 - line.width / 2;
            end

            function line = end_alignment(line, max_width)
                line.x = max_width - line.width;
            end

            switch alignment
                case 'start'
                    alignment = @start_alignment;
                case 'centered'
                    alignment = @center_alignment;
                case 'end'
                    alignment = @end_alignment;
                otherwise
                    error('Typesetter.layout(): Unknown alignment %s.', alignment);
            end
            
            fragments = struct.empty;

            for t=1:numel(tokens)
                token = tokens(t);
                
                obj.context_.update(token.style);
                [width, height] = obj.context_.measure(token.text);

                fragments = [fragments; hdng.one_struct('token', token, 'width', width, 'height', height)]; %#ok<AGROW>
            end
            
            lines = hdng.one_struct('width', 0, 'height', 0, 'x', 0, 'y', 0, 'fragments', struct.empty);
            
            for f=1:numel(fragments)

                line = lines(end);
                fragment = fragments(f);
                
                width = line.width + fragment.width;

                if width > max_width && numel(line.fragments) > 0
                    % break line

                    y = line.y + line.height;

                    line = hdng.one_struct('width', fragment.width, 'height', fragment.height, 'x', 0, 'y', y, 'fragments', fragment);
                    lines = [lines; line]; %#ok<AGROW>
                else
                    line.fragments = [line.fragments; fragment];
                    line.width = width;
                    line.height = max([line.height fragment.height]);
                end
                
                lines(end) = line;
            end
            
            function line = clean_fragment(line, index)

                if strcmp(line.fragments(index).token.text, ' ')
                    frag_width = line.fragments(index).width;
                    line.width = line.width - frag_width;
                    line.fragments = [line.fragments(1:index - 1) line.fragments(index + 1:end)];
                end
            end

            for l=1:numel(lines)
                line = lines(l);
                
                line = clean_fragment(line, numel(line.fragments));
                line = clean_fragment(line, 1);
                
                lines(l) = alignment(line, max_width);
            end

            x = cell(numel(lines), 1);
            [x{:}] = lines.x;
            x = cell2mat(x);
            shift_x = min(x);

            for l=1:numel(lines)
                line = lines(l);
                line.x = line.x - shift_x;
                lines(l) = line;
            end

            shift = [shift_x, 0];
        end

        function result = layout_svg(obj, tokens, max_width, alignment)

            if ~exist('alignment', 'var')
                alignment = 'start';
            end
            
            result = '';

            origin = [0, 0];
            
            ignore_change = true;
            text_style = [];

            [lines, shift] = obj.layout(tokens, max_width, alignment);
            
            implied_x = origin(1) + shift(1);
            implied_y = origin(2) + shift(2);

            for l=1:numel(lines)
                line = lines(l);

                pos = origin + shift + [line.x, line.y];
                nesting_level = 0;

                for f=1:numel(line.fragments)
                    fragment = line.fragments(f);

                    [output, nesting_level] = obj.fragment_as_svg_tspan(f, fragment, pos, implied_x, implied_y, ignore_change, nesting_level);
                    result = [result output]; %#ok<AGROW>
                    
                    if ignore_change
                        text_style = obj.context_.style;
                        ignore_change = false;
                    end

                    pos(1) = pos(1) + fragment.width;
                    implied_x = pos(1);
                    implied_y = pos(2);
                end

                while nesting_level > 0
                    result = [result '</tspan>']; %#ok<AGROW>
                    nesting_level = nesting_level - 1;
                end
            end

            if ~isempty(text_style)
                obj.context_.update(text_style);
                text_attributes = [' ' obj.context_.to_svg_attributes()];
            else
                text_attributes = '';
            end
            
            result = sprintf('<text%s x="%g" y="%g">%s</text>', text_attributes, origin(1) + shift(1), origin(2) + shift(2), result);
        end
    end
    
    methods (Access=protected)

        function result = compute_advance(~, coord, pos, implied, absolute)
            result = '';

            if pos ~= implied

                delta = pos - implied;
                
                if delta < 0 || absolute
                   result = sprintf('%s="%g"', coord, pos);
                else
                    result = sprintf('d%s="%g"', coord, delta);
                end
            end
        end

        function [output, nesting_level] = fragment_as_svg_tspan(obj, index_in_line, fragment, pos, implied_x, implied_y, ignore_change, nesting_level)
            
            did_change = ~ignore_change & obj.context_.update(fragment.token.style);
            
            extra_attributes = '';

            if did_change
                extra_attributes = [' ' obj.context_.to_svg_attributes(true)];
            end

            position = join({obj.compute_advance('x', pos(1), implied_x, false), ...
                             obj.compute_advance('y', pos(2), implied_y, false)}, ' ');

            position = position{1};
            
            if strcmp(position, ' ')
                position = '';
            else
                position = [' ' position];
            end

            if did_change || ~isempty(position)

                close_tag = '';
    
                if nesting_level ~= 0
                    close_tag = '</tspan>';
                    nesting_level = nesting_level - 1;
                end

                output = sprintf('%s<tspan%s%s>%s', ...
                    close_tag, position, extra_attributes, fragment.token.text);

                nesting_level = nesting_level + 1;
            else
                output = fragment.token.text;
            end
        end

    end
    
    methods (Access=public, Static)
    end
end
