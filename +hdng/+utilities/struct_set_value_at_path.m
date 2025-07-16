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

function [root] = struct_set_value_at_path(root, path, value)

    components = split(path, '.');
    
    assignments = {root};

    for index=1:numel(components)
        
        component = components{index};

        scope = assignments{index};

        if ~isfield(scope, component)
            scope.(component) = struct();
        end
        
        assignments{index + 1} = scope.(component);
    end

    assignments{end} = value;

    for index=numel(components):-1:1
        
        component = components{index};

        assignments{index}.(component) = assignments{index + 1};
    end
    
    root = assignments{1};
end
