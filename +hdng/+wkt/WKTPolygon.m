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

classdef WKTPolygon < hdng.wkt.Primitive
    %WKTPolygon Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Dependent, Transient)
        
        N_rings
        N_holes
        
        rings
        holes
    end
    
    properties (GetAccess=private, SetAccess=private)
        rings_
        N_points_
    end
    
    methods
        
        function obj = WKTPolygon(rings)
            
            obj = obj@hdng.wkt.Primitive();
            
            if ~isa(rings, 'hdng.wkt.WKTLineString')
                error('Expected array of WKTLineStrings for rings argument.');
            end
            
            for i=2:numel(rings)
                ring = rings(i);
                
                if ring.has_m ~= rings(1).has_m
                    error('Rings have inconsistent measurement dimension.');
                end
                
                if ring.has_z ~= rings(1).has_z
                    error('Rings have inconsistent spatial dimensions.');
                end
            end
            
            obj.rings_ = rings;
            obj.N_points_ = [];
        end
        
        function result = get.N_rings(obj)
            result = numel(obj.rings_);
        end
        
        function result = get.N_holes(obj)
            result = obj.N_rings;
            if result > 0
                result = result - 1;
            end
        end
        
        function result = get.rings(obj)
            result = obj.rings_;
        end
        
        function result = get.holes(obj)
            if obj.N_holes > 0
                result = obj.rings_(2:end);
            else
                result = hdng.wkt.WKTLineString.empty;
            end
        end
        
        function result = nth_ring(obj, index)
            result = obj.rings_(index);
        end
        
        function result = nth_hole(obj, index)
            result = obj.rings_(1 + index);
        end
    end
    
    
    methods (Access = protected)
        
        function result = access_N_points(obj)
            if isempty(obj.N_points_)
                obj.N_points_ = 0;
                
                for i=1:obj.N_rings
                    ring = obj.nth_ring(i);
                    obj.N_points_ = obj.N_points_ + ring.N_points;
                end
            end
            
            result = obj.N_points_;
        end
    end
    
    methods (Static)
        function result = select_handler_method(handler)
            result = @(primitive) handler.handle_polygons(primitive);
        end
    end
end
