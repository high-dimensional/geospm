% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2019,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef WKTTest < matlab.unittest.TestCase
 
    properties
    end
 
    methods(TestMethodSetup)
        
        function initialise(~)
        end
        
    end
 
    methods(TestMethodTeardown)
    end
 
    methods
    end
    
    methods(Test)
        
        function [result] = test_crs_from_file(~)

            [directory, ~, ~] = fileparts(mfilename('fullpath'));
            file_path = fullfile(directory, 'test_crs.wkt');
            result = hdng.wkt.WKTCoordinateSystem.from_file(file_path);
        end
        
        function [result] = test_crs_from_web(~)

            source1 = @(code) strcat('https://spatialreference.org/ref/epsg/', code, '/ogcwkt/');
            source2 = @(code) strcat('https://epsg.io/', code, '.wkt?download');
            
            codes = [27700, 26191, 23030];
            sources = {source1, source2};
            
            for i=1:numel(codes)
                code = num2str(codes(i), '%d');
                
                for j=1:numel(sources)
                    
                    source = sources{j};
                    url = source(code);
                    
                    fprintf('Retrieving CRS %s from %s...\n', code, url);
                    
                    result = hdng.wkt.WKTCoordinateSystem.from_url(url);
                end
            end
        end        
    end
end
