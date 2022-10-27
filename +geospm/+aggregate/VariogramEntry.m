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


classdef VariogramEntry < hdng.aggregate.FileAggregatorEntry
    
    properties
        final_data
        final_file
        
        covariogram_model
        empirical_covariogram
    end
    
    methods
        
        function obj = VariogramEntry(name, category, options)
            
            obj = obj@hdng.aggregate.FileAggregatorEntry(name, category, options);
            
            obj.final_data = [];
            obj.final_file = [];

            obj.covariogram_model = [];
            obj.empirical_covariogram = [];
        end

        function prepare(obj)
            
            obj.final_data = [];
            obj.final_file = [];
            
            obj.covariogram_model = [];
            obj.empirical_covariogram = [];
        end
        
        function gather_sample(obj, sample_file)
            
            if isempty(obj.covariogram_model)
                obj.from_files{end + 1} = sample_file;
                json_text = hdng.utilities.load_text(sample_file);
                json_struct = jsondecode(json_text);
                
                obj.covariogram_model = geospm.variograms.CovariogramModel.from_json(json_struct.covariogram_model);
                obj.empirical_covariogram = geospm.variograms.EmpiricalCovariogram.from_json(json_struct.empirical_covariogram);
            end
        end

        function finalise(obj) %#ok<MANU>
        end
        
        function process(obj, output_directory) %#ok<INUSD>
        end
    end
end

