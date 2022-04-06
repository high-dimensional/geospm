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

function result = parse_struct_from_varargin(varargin)
%parse_struct_from_varargin Parses a sequence of Name, Value pairs into a struct.
%   Detailed explanation goes here
    
    if bitand(numel(varargin), 1)
        error(['parse_struct_from_varargin(): Number of ' ...
               'variable arguments must be a multiple of two.']);
    end
    
    result = struct();
    
    for i=1:2:numel(varargin)
        name = varargin{i};
        value = varargin{i + 1};
        result.(name) = value;
    end
end
