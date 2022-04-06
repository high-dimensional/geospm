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

classdef SpatialCRSImpl < hdng.SpatialCRS
    %SpatialCRSImpl Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess = private, SetAccess = private)
        authority_name_
        authority_issued_identifier_
        wkt_
    end
    
    methods
        
        function obj = SpatialCRSImpl(authority_name, authority_issued_identifier, wkt)
            obj = obj@hdng.SpatialCRS();
            
            obj.authority_name_ = authority_name;
            obj.authority_issued_identifier_ = authority_issued_identifier;
            obj.wkt_ = wkt;
        end
    end
    
    methods (Access = protected)
        
        function result = access_authority_name(obj)
            result = obj.authority_name_;
        end
        
        function result = access_authority_issued_identifier(obj)
            result = obj.authority_issued_identifier_;
        end
        
        function result = access_type(obj)
            
            if isa(obj.wkt_, 'hdng.wkt.GeographicCoordinateSystem')
                result = hdng.SpatialCRS.GEOGRAPHIC_TYPE;
            elseif isa(obj.wkt_, 'hdng.wkt.GeocentricCoordinateSystem')
                result = hdng.SpatialCRS.GEOCENTRIC_TYPE;
            elseif isa(obj.wkt_, 'hdng.wkt.ProjectedCoordinateSystem')
                result = hdng.SpatialCRS.PROJECTED_TYPE;
            else
                result = hdng.SpatialCRS.UNKNOWN_TYPE;
            end
        end
        
        function result = access_wkt(obj)
            result = obj.wkt_;
        end
        
        function result = access_description(obj)
            result = obj.wkt_.name;
        end
    end
end
