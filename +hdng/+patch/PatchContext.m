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

classdef PatchContext < handle
    %PatchContext Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess=public, SetAccess=protected)
        patch
        diagnostics
    end
    
    properties
    end
    
    properties (Dependent, Transient)
        was_cancelled
    end
    
    properties (GetAccess=private, SetAccess=private)
        was_cancelled_
    end
    
    methods
        
        function obj = PatchContext(patch)
            obj.patch = patch;
            obj.diagnostics = {};
            obj.was_cancelled_ = false;
        end
        
        function result = get.was_cancelled(obj)
            result = obj.was_cancelled_;
        end
        
        function cancel(obj, diagnostic)
            
            if ~exist('diagnostic', 'var')
                diagnostic = hdng.patch.Diagnostic.error('Unspecified patch error.');
            end
            
            obj.was_cancelled_ = true;
            obj.diagnostics = [obj.diagnostics; {diagnostic}];
        end
    end
    
    methods (Access=protected)
    end
    
end
