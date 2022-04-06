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

classdef Score < handle
    %Score Represents a way of computing a score for an experiment.
    %   A score computes or modifies one or more result fields in an evaluation.
    
    properties (Constant)
        COMPUTE_ALWAYS = 'always'
        COMPUTE_IF_MISSING = 'missing'
    end
    
    properties
        result_attributes
        description
    end
    
    methods
        
        function obj = Score()
            obj.result_attributes = hdng.experiments.RecordAttributeMap();
        end
        
        function compute(obj, evaluation, mode) %#ok<INUSD>
        	error('Score.compute() must be implemented by a subclass.');
        end
        
    end
    
    methods (Access=protected)
        
        function result = only_if_missing(obj, mode) %#ok<INUSL>
            result = strcmp(mode, hdng.experiments.Score.COMPUTE_IF_MISSING);
        end
        
        function holds = contains_all_result_attributes(obj, results)
            
            holds = false;
            
            for index=1:numel(obj.result_attributes.names)
                name = obj.result_attributes.names{index};
                
                if ~results.holds_key(name)
                    return;
                end
            end
            
            holds = true;
        end
        
        function result = should_compute(obj, mode, results)
            result = ~obj.only_if_missing(mode) || ~obj.contains_all_result_attributes(results);
        end
        
    end
    
    methods (Static, Access=public)
        
        function result = create(type, varargin)
            
            if ~hdng.utilities.issubclass(type, 'hdng.experiments.Score')
                error('Score.create(): %s is not derived from hdng.experiments.Score.', type);
            end
            
            ctor = str2func(type);
            result = ctor(varargin{:});
        end
        
    end
    
end
