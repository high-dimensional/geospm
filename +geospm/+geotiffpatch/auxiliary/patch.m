% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2022,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %



% This code was modified by GeoSPM to support alpha channels in
% geotiffs.

if ~isfield(TiffTags, 'Photometric'); return; end
if TiffTags.Photometric ~= Tiff.Photometric.RGB; return; end

condition = ndims(A) == 3 && any(size(A,3) == [3, 4]);
map.internal.assert(condition, 'map:geotiff:imageSizeNotRGB', ...
                               'PhotometricInterpretation');

%--------------------------------------------------------------------------
