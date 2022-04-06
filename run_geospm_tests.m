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

function results = run_geospm_tests()
    
    [geospm_dir, ~, ~] = fileparts(mfilename('fullpath'));

    suites = [];
    
    %{
    %suite = matlab.unittest.TestSuite.fromFolder(base_dir, 'IncludingSubfolders', true);
    suite = [];
    
    if ~isempty(suite)
        suites = [suites suite];
    end
    %}
    
    listing = what(geospm_dir);

    for i=1:numel(listing.packages)
        
        suite = matlab.unittest.TestSuite.fromPackage(...
            listing.packages{i}, 'IncludingSubpackages', true);
        
        if ~isempty(suite)
            suites = [suites suite]; %#ok<AGROW>
        end
    end

    results = run(suites);
end
