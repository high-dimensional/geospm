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

function [value] = struct_get_value_at_path(root, path, default_value)

    raise_exception = false;

    if ~exist('default_value', 'var')
        raise_exception = true;
    end

    components = split(path, '.');
    
    assignments = {root};

    for index=1:numel(components)
        
        component = components{index};

        scope = assignments{index};

        if ~isfield(scope, component)
            if raise_exception
                msg = join(components(1:index), '.');
                ME = MException('hdng_utilities_struct_get_value_at_path:missing_field', ...
                        'No field at %s.', msg{1});
                throw(ME);
            else
                value = default_value;
                return;
            end
        end
        
        assignments{index + 1} = scope.(component);
    end

    value = assignments{end};
end
