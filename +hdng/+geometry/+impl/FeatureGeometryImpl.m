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

classdef FeatureGeometryImpl < hdng.geometry.FeatureGeometry
    %FeatureGeometryImpl Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess = private, SetAccess = private)
        collection_
        crs_
    end
    
    methods
        
        function obj = FeatureGeometryImpl(collection, crs)
            obj = obj@hdng.geometry.FeatureGeometry();
            obj.collection_ = collection;
            obj.crs_ = crs;
        end
        
        
    end
    
    methods (Access = protected)
        
        function result = access_has_crs(obj)
            result = ~isempty(obj.crs_);
        end
        
        function result = access_crs(obj)
            result = obj.crs_;
        end
        
        function result = access_collection(obj)
            result = obj.collection_;
        end
    end
    
    methods (Static)
    end
end
