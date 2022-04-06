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

function variable_value_list = read_variables(...
            variable_value_list, ...
            interface, ...
            interface_value_map)

    names = fieldnames(interface);
    
    for i=1:numel(names)

        name = names{i};

        if ~isfield(interface_value_map, name)
            continue
        end
        
        variable = interface.(name);
        variable_value_list{variable.nth_variable} = interface_value_map.(name);
    end
end
