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

classdef ModelVariograms < geospm.validation.scores.SPMRegressionScore
    %ModelVariograms 
    %   
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = ModelVariograms()
            obj = obj@geospm.validation.scores.SPMRegressionScore();
            
            attribute = obj.result_attributes.define('model_variograms');
            attribute.description = 'Model Variograms';
        end
    end
    
    methods (Access=protected)
        
        function compute_for_spm_regression(obj, spm_regression, extra_variables, evaluation, mode) %#ok<INUSL>
            
            results = evaluation.results;
            
            only_if_missing = strcmp(mode, hdng.experiments.Score.COMPUTE_IF_MISSING);
            
            if only_if_missing && results.holds_key('model_variagrams')
                return
            end
            
            expression_data_path = fullfile(spm_regression.directory, [spm_regression.expression_data_name '.csv']);
            
            variogram_parameters = obj.estimate_variograms(spm_regression, expression_data_path, {'Exp', 'Gau', 'Mat'});
            results('model_variograms') = hdng.experiments.Value.from(variogram_parameters); %#ok<NASGU>
        end
        
        
        function results = load_variograms(~, path)
            results = load(path, 'metadata', 'variograms');
        end
        
        function [model, psill, range] = locate_variogram_columns(~, cells)
            
            model = 0;
            psill = 0;
            range = 0;
            
            for index=1:size(cells, 2)
                value = cells{1, index};
                
                if strcmp(value, 'model')
                    model = index;
                    continue;
                end
                
                if strcmp(value, 'psill')
                    psill = index;
                    continue;
                end
                
                if strcmp(value, 'range')
                    range = index;
                    continue;
                end
            end
        end
        
        function result = extract_variogram_parameters(obj, variogram_function, variogram_container)
            
            result = hdng.utilities.Dictionary();
            names = fieldnames(variogram_container.variograms);
            
            for index=1:numel(names)
                name = names{index};
                table = variogram_container.variograms.(name);
                
                [model, psill, range] = obj.locate_variogram_columns(table);
                
                for row=2:size(table, 1)
                    model_type = table{row, model};
                    
                    if ~strcmp(model_type, variogram_function)
                        continue;
                    end
                    
                    psill_value = str2double(table{row, psill});
                    range_value = str2double(table{row, range});
                    
                    parameters = hdng.utilities.Dictionary();
                    parameters('psill') = psill_value;
                    parameters('range') = range_value;
                    
                    result(name) = parameters;
                    
                    break;
                    
                end
            end
        end
        
        function result = estimate_variograms(obj, spm_regression, data_path, variogram_functions)
            
            result = hdng.utilities.Dictionary();
            
            r_interface = geospm.validation.SpatialExperiment.create_r_interface();
            
            output_directory = fullfile(spm_regression.directory, 'variograms');
            
            [dirstatus, dirmsg] = mkdir(output_directory);
            if dirstatus ~= 1; error(dirmsg); end
            
            for index=1:numel(variogram_functions)
                
                variogram_function = variogram_functions{index};

                variogram_directory = fullfile(output_directory, variogram_function);

                [dirstatus, dirmsg] = mkdir(variogram_directory);
                if dirstatus ~= 1; error(dirmsg); end
                
                arguments = {
                    'variograms', ...
                    '-o', variogram_directory, ...
                    '-s', '1', ...
                    '-t', '1', ...
                    '-m', num2str(spm_regression.model.spatial_resolution(1), '%d'), ...
                    '-n', num2str(spm_regression.model.spatial_resolution(2), '%d'), ...
                    '-c', variogram_function, ...
                    };

                
                %if ~isempty(max_distance)
                %    arguments{end + 1} = '-d'; %#ok<AGROW>
                %    arguments{end + 1} = num2str(max_distance, '%d'); %#ok<AGROW>
                %end

                arguments{end + 1} = data_path; %#ok<AGROW>

                r_interface.call(arguments{:});
                
                file_name = [spm_regression.expression_data_name '_variograms.mat'];
                variogram_container = obj.load_variograms(fullfile(variogram_directory, file_name));
                
                parameters = obj.extract_variogram_parameters(variogram_function, variogram_container);
                result(variogram_function) = parameters;
            end
        end
        
    end
end
