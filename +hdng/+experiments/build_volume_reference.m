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

function result = build_volume_reference(scalars_path, image_path, slice_names, source_ref)
    
    if ~exist('slice_names', 'var')
        slice_names = [];
    end
    if ~exist('source_ref', 'var')
        source_ref = '';
    end
    
    result = hdng.experiments.VolumeReference();
    
    if ~isempty(scalars_path)
        result.scalars = hdng.experiments.ImageReference(scalars_path, source_ref);
    else
        result.scalars = [];
    end
    
    if ~isempty(image_path)
        result.image = hdng.experiments.ImageReference(image_path, source_ref);
    else
        result.image = [];
    end
    
    result.slice_names = slice_names;
end
