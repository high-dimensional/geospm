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

classdef SpatialAnalysisStage < hdng.pipeline.Stage
    
    properties (GetAccess=public, SetAccess=immutable)
        analysis
        nth_stage
    end
    
    methods
        
        function obj = SpatialAnalysisStage(analysis)
            
            obj = obj@hdng.pipeline.Stage();
            
            obj.analysis = analysis;
            obj.analysis.add_stage(obj);
            obj.nth_stage = numel(obj.analysis.stages);
        end
        
        function [did_exist, binding] = get_requirement(obj, identifier)
            [did_exist, binding] = obj.binding_for(hdng.pipeline.Stage.REQUIREMENTS_CATEGORY, identifier);
        end
        
        function [did_exist, binding] = get_product(obj, identifier)
            [did_exist, binding] = obj.binding_for(hdng.pipeline.Stage.PRODUCTS_CATEGORY, identifier);
        end
        
        function [binding, options] = define_requirement(obj, identifier, options, varargin)
            
            if ~exist('options', 'var')
                options = struct();
            end
            
            [binding, options] = obj.define_binding(hdng.pipeline.Stage.REQUIREMENTS_CATEGORY, ...
                identifier, options, varargin{:});
        end
        
        function [binding, options] = define_product(obj, identifier, options, varargin)
            
            if ~exist('options', 'var')
                options = struct();
            end
            
            [binding, options] = obj.define_binding(hdng.pipeline.Stage.PRODUCTS_CATEGORY, ...
                identifier, options, varargin{:});
        end
        
    end
end
