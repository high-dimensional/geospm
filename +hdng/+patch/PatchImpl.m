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

classdef PatchImpl < handle
    %PatchImpl Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
        path
        metadata
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = PatchImpl()
        end
        
        function result = get.path(obj)
            result = obj.access_path();
        end
        
        function result = get.metadata(obj)
            result = obj.access_metadata();
        end
        
        function load(obj, patch) %#ok<INUSD>
            error('PatchImpl.load() must be implemented by a subclass.');
        end
        
        function save(obj, patch) %#ok<INUSD>
            error('PatchImpl.save() must be implemented by a subclass.');
        end
        
        function apply(obj, patch) %#ok<INUSD>
            error('PatchImpl.apply() must be implemented by a subclass.');
        end
    end
    
    methods (Access=protected)
        
        function result = access_path(~) %#ok<STOUT>
            error('PatchImpl.access_path() must be implemented by a subclass.');
        end
        
        function result = access_metadata(~) %#ok<STOUT>
            error('PatchImpl.access_metadata() must be implemented by a subclass.');
        end
        
        
    end
end
