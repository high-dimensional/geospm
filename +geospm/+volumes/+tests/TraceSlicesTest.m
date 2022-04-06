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

classdef TraceSlicesTest < matlab.unittest.TestCase
 
    properties
        bw_volume
    end
 
    methods(TestMethodSetup)
        
        function initialise(obj)
            self_path = mfilename('fullpath');
            [directory, ~, ~] = fileparts(self_path);
            
            file_path = fullfile(directory, 'trace_volume_test.nii');
            V = spm_vol(file_path);
            obj.bw_volume = spm_read_vols(V);
        end
        
    end
 
    methods(TestMethodTeardown)
    end
 
    methods
    end
    
    methods(Test)
        
        function test_trace_slices(obj)
            
            result = geospm.volumes.trace_slices(obj.bw_volume);
            
        end
        
    end
end
