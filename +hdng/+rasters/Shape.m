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

classdef Shape < handle
    %Shape Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
        type
    end
    
    properties
        geometry
        style
    end
    
    methods
        function obj = Shape(type, geometry, style)
            
            obj.type = type;
            obj.geometry = struct();
            obj.style = style;
            
            switch lower(type)
                
                case 'polygon'

                    if ~isfield(geometry, 'x')
                        geometry.x = 0;
                    end
                    
                    if ~isfield(geometry, 'y')
                        geometry.y = 0;
                    end
                    
                    if ~isfield(geometry, 'points')
                        error('No points specified for polygon shape in Shape');
                    end
                    
                case 'ellipse'
                    
                    if ~isfield(geometry, 'x')
                        geometry.x = 0;
                    end
                    
                    if ~isfield(geometry, 'y')
                        geometry.y = 0;
                    end
                    
                    if ~isfield(geometry, 'radiusX')
                        geometry.radiusX = 1.0;
                    end
                    
                    if ~isfield(geometry, 'radiusY')
                        geometry.radiusY = 1.0;
                    end
                    
                case 'rect'
                    
                    if ~isfield(geometry, 'x')
                        geometry.x = 0;
                    end
                    
                    if ~isfield(geometry, 'y')
                        geometry.y = 0;
                    end
                    
                    if ~isfield(geometry, 'width')
                        geometry.width = 1.0;
                    end
                    
                    if ~isfield(geometry, 'height')
                        geometry.height = 1.0;
                    end
                
                case 'layer'
                    
                    
                    
                otherwise
                    error('Unknown type for Shape');
            end
            
            obj.geometry = geometry;
        end
        
        function draw(obj, raster_context)
            
            switch lower(obj.type)
                
                case 'polygon'
                    obj.style.draw_polygon(raster_context, obj.geometry.x + obj.geometry.points(:,1), obj.geometry.y + obj.geometry.points(:,1));
                    
                case 'ellipse'
                    obj.style.draw_ellipse(raster_context, obj.geometry.x, obj.geometry.y, obj.geometry.radiusX, obj.geometry.radiusY);
                    
                case 'rect'
                    obj.style.draw_rect(raster_context, obj.geometry.x, obj.geometry.y, obj.geometry.width, obj.geometry.height);
                
                case 'layer'
                    obj.style.draw_rect(raster_context, 0, 0, raster_context.width, raster_context.height);
                    
                otherwise
                    
            end
        end
        
    end
    
    methods (Static)
        
        function result = polygon(x, y, points, style)
            result = hdng.rasters.Shape('polygon', struct('x', x, 'y', y, 'points', points), style);
        end
        
        function result = rect(x, y, width, height, style)
            result = hdng.rasters.Shape('rect', struct('x', x, 'y', y, 'width', width, 'height', height), style);
        end
        
        function result = layer(style)
            result = hdng.rasters.Shape('layer', struct(), style);
        end
        
        function result = ellipse(x, y, radiusX, radiusY, style)
            result = hdng.rasters.Shape('ellipse', struct('x', x, 'y', y, 'radiusX', radiusX, 'radiusY', radiusY), style);
        end
    end
end
