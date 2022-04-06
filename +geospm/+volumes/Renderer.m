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

classdef Renderer < handle
    
    %Renderer 
    %
    
    properties (GetAccess=public, SetAccess=private)
    end
    
    properties (GetAccess=public, SetAccess=public)
    end
    
    properties (Dependent, Transient)
    end
    
    
    properties (GetAccess=private, SetAccess=private)
        
    end
    
    methods
        
        function obj = Renderer()
        end
        
        function [files, metadata_per_file] = render(obj, context) %#ok<STOUT,INUSD>
            error('Renderer.render() must be implemented by a subclass.');
        end
    end
end
