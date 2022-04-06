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

function result = struct_to_name_value_sequence(S)
%serialise_struct Turns the fields of a struct into a sequence of name and value pairs.
%   Detailed explanation goes here
    
    
    names = fieldnames(S);
    result = cell(numel(names) * 2, 1);
    
    for i=1:numel(names)
        name = names{i};
        result{i * 2 - 1} = name;
        result{i * 2} = S.(name);
    end
    
    
end
