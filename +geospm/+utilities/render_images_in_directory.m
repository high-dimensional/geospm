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

function result = render_images_in_directory(directory, name_pattern, ...
                    output_directory, colour_map, render_settings)
    
    if ~exist('colour_map', 'var')
        %colour_map = hdng.colour_mapping.GenericColourMap.monochrome();
        colour_map = hdng.colour_mapping.GenericColourMap.twilight_27();
    end

    renderer = geospm.volumes.ColourMapping();
    renderer.colour_map = colour_map;

    if ~exist('render_settings', 'var')
        render_settings = geospm.volumes.RenderSettings();

        render_settings.formats = {'png'};
        render_settings.centre_pixels = true;
    end
    
    [file_paths, ~] = hdng.utilities.scan_files(directory, name_pattern);
    
    volume_set = geospm.volumes.VolumeSet();
    volume_set.file_paths = file_paths;

    result = geospm.utilities.render_images(volume_set, [], render_settings, output_directory, renderer);
end
