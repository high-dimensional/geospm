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

classdef StageGenerator < handle
    
    %StageGenerator Encapsulates a method of generating stages in a study.
    %
    
    properties
        study
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = StageGenerator(study)
            obj.study = study;
        end
        
        function [is_valid, stage] = next(obj) %#ok<STOUT,MANU>
            error('StageGenerator.next() must be implemented by a subclass.');
        end
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
    
end
