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

function parameters = load_parameters(file_path)

    if exist(file_path, 'file')
        parameters = load(file_path, 'empirical', 'fitted', 'labels', 'models');
    else

        parameters = struct();

        parameters.empirical = struct();
        parameters.empirical.np = [];       % the number of point pairs for this estimate
        parameters.empirical.dist = [];     % the average distance of all point pairs considered for this estimate
        parameters.empirical.gamma = [];    % the actual sample variogram estimate
        parameters.empirical.dir_hor = [];  % horizontal direction
        parameters.empirical.dir_ver = [];  % vertical direction
        parameters.empirical.id = [];       % combined id pair

        parameters.fitted = struct();       
        parameters.fitted.label = [];
        parameters.fitted.model = [];

        parameters.fitted.psill = [];
        parameters.fitted.range = [];
        parameters.fitted.kappa = [];
        parameters.fitted.ang1 = [];
        parameters.fitted.ang2 = [];
        parameters.fitted.ang3 = [];
        parameters.fitted.anis1 = [];
        parameters.fitted.anis2 = [];

        parameters.labels = {};
        parameters.models = {};

        obj.log_diagnostic(...
            sprintf('Missing results file ''%s'' for level ''%s''.', file_name, level), ...
            'An empty results structure was created.');
    end
end
