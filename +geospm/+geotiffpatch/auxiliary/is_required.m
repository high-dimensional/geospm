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

function result = is_required(patch)

    result = false;

    [parent_directory, ~, ~] = fileparts(mfilename('fullpath'));
    
    crs_identifier = 'EPSG:27700';

    N_samples = 4;
    image = zeros(64, 64, N_samples, 'uint8');
    
    tags = struct();
    tags.('Compression') = Tiff.Compression.LZW;
    
    if N_samples == 4 || N_samples == 2
        tags.('ExtraSamples') = Tiff.ExtraSamples.AssociatedAlpha;
    end

    if N_samples == 4 || N_samples == 3
        tags.('Photometric') = Tiff.Photometric.RGB;
    else
        tags.('Photometric') = Tiff.Photometric.MinBlack;
    end

    extra_arguments = {...
        'TiffTags', tags};

    if ~isempty(crs_identifier)
        extra_arguments{end + 1} = 'CoordRefSysCode';
        extra_arguments{end + 1} = crs_identifier;
    end
    
    R = [0 1; 1 0; 0 0];
    file_path = fullfile(parent_directory, 'tmp');
    
    try
        geotiffwrite(file_path, image, R, extra_arguments{:});
    catch
        result = true;
    end
    
    if ~result
        hdng.utilities.delete(false, file_path);
    end
end
