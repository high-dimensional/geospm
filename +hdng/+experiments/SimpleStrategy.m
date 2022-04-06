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

classdef SimpleStrategy < hdng.experiments.Strategy
    
    %SimpleStrategy .
    % 
    
    properties
        schedule
        evaluator
        stage_identifier
        prefix
    end
     
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = SimpleStrategy()
            
            obj = obj@hdng.experiments.Strategy();
            
            obj.schedule = hdng.experiments.Schedule.empty;
            obj.evaluator = hdng.experiments.Evaluator.empty;
            obj.stage_identifier = '1';
            obj.prefix = '';
        end
        
        function result = iterate_stages(obj, study)
            
            callback = @(iterator) obj.next_stage(iterator);
            
            result = hdng.experiments.DynamicStageGenerator(study, callback);
            result.attachments.is_done = false;
        end
        
        function [is_valid, stage] = next_stage(obj, iterator)
            
            is_valid = false;
            stage = hdng.experiments.Stage.empty;
            
            if isempty(obj.schedule)
                return
            end
            
            if isempty(obj.evaluator)
                return
            end
            
            if iterator.attachments.is_done
                return
            end
            
            is_valid = true;
            stage = hdng.experiments.Stage(obj.stage_identifier);
            stage.schedule = obj.schedule;
            stage.evaluator = obj.evaluator;
            stage.prefix = obj.prefix;
            
            iterator.attachments.is_done = true;
        end
        
        
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
    
end
