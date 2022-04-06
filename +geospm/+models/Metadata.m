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

classdef Metadata < handle
    %Metadata Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        generator
        seed
        transform
        
        metadata_per_parameter
    end
    
    methods
        
        function obj = Metadata(generator, seed, transform)
            obj.generator = generator;
            obj.seed = seed;
            obj.transform = transform;
            obj.metadata_per_parameter = cell(0, 1);
        end
        
        function result = get_parameter_metadata(obj, parameter_index, default)
            
            if ~exist('default', 'var')
                default = struct();
            end
            
            N = numel(obj.metadata_per_parameter);
            
            if N < parameter_index
                result = default;
                return;
            end
            
            result = obj.metadata_per_parameter{parameter_index};
        end
        
        function set_parameter_metadata(obj, parameter_index, metadata)
            
            N = numel(obj.metadata_per_parameter);
            
            if N < parameter_index
                tmp = cell(obj.generator.N_parameters, 1);
                tmp(1:N) = obj.metadata_per_parameter;
                obj.metadata_per_parameter = tmp;
            end
            
            obj.metadata_per_parameter{parameter_index} = metadata;
        end
    end
    
    methods (Static, Access=private)
    end
    
end
