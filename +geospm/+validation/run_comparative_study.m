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

function study_path = run_comparative_study(varargin)

    options = hdng.utilities.parse_struct_from_varargin(varargin{:});
    
    if ~isfield(options, 'n_samples')
        options.n_samples = {1500 2000 2500};
    end
    
    if ~isfield(options, 'method')
        options.method = {'SPM', 'Kriging'};
    end
    
    if ~isfield(options, 'spatial_data_specifier')
        options.spatial_data_specifier = {struct('file_path', '')};
    end
    
    if ~isfield(options, 'extra_variables')
        options.extra_variables = {};
    end
    
    if ~isfield(options, 'evaluator')
        options.evaluator = geospm.validation.DataEvaluator();
        options.evaluator.run_mode = geospm.validation.SpatialExperiment.REGULAR_MODE;
    end
    
    n_samples = struct();
    n_samples.identifier = 'n_samples';
    n_samples.requirements = {};
    n_samples.value_generator = hdng.experiments.ValueList.from(options.n_samples{:});
    n_samples.description = 'Number of Samples';
    
    method = struct();
    method.identifier = 'method';
    method.requirements = {};
    method.value_generator = hdng.experiments.ValueList.from(options.method{:});
    method.description = 'Method';
    
    spatial_data_specifier = struct();
    spatial_data_specifier.identifier = 'spatial_data_specifier';
    spatial_data_specifier.requirements = {};
    spatial_data_specifier.value_generator = hdng.experiments.ValueList.from(options.spatial_data_specifier{:});
    spatial_data_specifier.description = 'Spatial Data Specifier';
    
    options.extra_variables = [{n_samples method spatial_data_specifier}, ...
                                options.extra_variables];
    
    options = rmfield(options, 'n_samples');
    options = rmfield(options, 'method');
    options = rmfield(options, 'spatial_data_specifier');
    
    arguments = hdng.utilities.struct_to_name_value_sequence(options);
    study_path = geospm.validation.run_study(arguments{:});
end
