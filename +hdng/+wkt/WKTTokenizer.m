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

classdef WKTTokenizer < hdng.parsing.RegexpTokenizer
    %WKTTOKENIZER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        
        function obj = WKTTokenizer()
            
            obj = obj@hdng.parsing.RegexpTokenizer();
            obj.token_expr = ...
                '(?<linebreak>(\r\n|\r|\n))|(?<wsp>\s+)|(?<keyword>[A-Za-z][A-Za-z0-9]*)|(?<real>(-?[0-9]+\.?[0-9]*E[0-9]+|\.[0-9]+E[0-9]+|\-?[0-9]+\.[0-9]+|\.[0-9]+))|(?<integer>\-?[0-9]+)|(?<string>"([^"\\]|\\.)+")|(?<lp>\()|(?<rp>\))|(?<lb>\[)|(?<rb>\])|(?<comma>\,)';
            
            value_converters = struct();
            value_converters.string = @convert_string_value;
            value_converters.integer = @convert_integer_value;
            value_converters.real = @convert_real_value;
            
            obj.value_converters = value_converters;
            obj.linebreak_token = 'linebreak';
            obj.whitespace_token = 'wsp';
        end
        
    end
    
end

function [value] = convert_string_value(value)
    value=value(2:end-1);
    value=regexprep(value, '\\(.)', '$1');
end

function [value] = convert_integer_value(value)
    value=cast(str2double(value), 'int64');
end

function [value] = convert_real_value(value)
    value=str2double(value);
end
