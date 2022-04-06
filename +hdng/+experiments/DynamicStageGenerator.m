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

classdef DynamicStageGenerator < hdng.experiments.StageGenerator
    
    %DynamicStageGenerator Encapsulates a method of generating stages in a study.
    %
    
    properties
        attachments
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
        callback
    end
    
    methods
        
        function obj = DynamicStageGenerator(study, callback)
            
            obj = obj@hdng.experiments.StageGenerator(study);
            obj.callback = callback;
            obj.attachments = struct();
        end
        
        function [is_valid, stage] = next(obj)
            [is_valid, stage] = obj.callback(obj);
        end
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
    
end
