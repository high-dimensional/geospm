% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2021,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function result = render_images(image_set, alpha_set, render_settings, directory, renderer)

    result = hdng.utilities.Dictionary();
    result('volumes') = hdng.experiments.Value.from(image_set.file_paths);
    
    context = geospm.volumes.RenderContext();
    context.render_settings = render_settings;

    context.image_volumes = image_set;
    context.alpha_volumes = alpha_set;
    context.output_directory = directory;

    image_paths = renderer.render(context);

    for index=1:numel(image_paths)
        paths = image_paths{index};
        image_paths(index) = paths(1);
    end

    result('images') = hdng.experiments.Value.from(image_paths);

    result = hdng.experiments.Value.from(result);
end
