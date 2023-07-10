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

classdef Evaluator < handle
    
    %Evaluator Encapsulates a method of generating stages in a study.
    %
    
    properties
        configuration_attributes
        result_attributes
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = Evaluator()
            obj.configuration_attributes = hdng.experiments.RecordAttributeMap();
            obj.result_attributes = hdng.experiments.RecordAttributeMap();
        end
        
        function apply(obj, evaluation, options)  %#ok<INUSD>
            error('Evaluator.apply() must be implemented by a subclass.');
        end
    end
    
    methods (Access=protected)
        
        function result = now(~)
            result = datetime('now', 'TimeZone', 'local', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        end
        
    end
    
    methods (Static, Access=public)
    end
    
end
