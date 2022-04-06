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

classdef WKTGeometry < matlab.mixin.Copyable
    %WKTGeometry Summary of this class goes here
    %   Detailed explanation goes here
    
    methods (Access=private)
    end
    
    methods (Static)
        
        function result = from_file(file_path)

            string = hdng.utilities.load_text(file_path);
            source = hdng.wkt.WKTSource;
            source.url = file_path;
            source.text = string;
            result = hdng.wkt.WKTGeometry.from_source(source);
        end
        
        function result = from_url(file_url)
            string = webread(file_url);
            source = hdng.wkt.WKTSource;
            source.url = file_url;
            source.text = string;
            result = hdng.wkt.WKTGeometry.from_source(source);
        end
        
        function result = from_chars(string)
            source = hdng.wkt.WKTSource;
            source.text = string;
            result = hdng.wkt.WKTGeometry.from_source(source);
        end
        
        function result = from_source(source)
            
            result = struct();
            
            parser = hdng.wkt.WKTParser;
            
            parser.allow_value_sequences = true;
            parser.allow_anonymous_values = true;
            parser.allow_additional_keywords = true;
            parser.allow_parenthesis_delimiters = true;
            parser.allow_bracket_delimiters = false;
            
            parse_result = parser.parse_chars(source.text);
            
            if ~isfield(parse_result, 'value' )
                result.errors = parse_result.errors;
                return
            end
            
            context = hdng.wkt.WKTAudit();
            
            context.handler.POINT = @hdng.wkt.WKTGeometry.build_point;
            context.handler.LINESTRING = @hdng.wkt.WKTGeometry.build_linestring;
            context.handler.POLYGON = @hdng.wkt.WKTGeometry.build_polygon;
            context.handler.MULTIPOINT = @hdng.wkt.WKTGeometry.build_multipoint;
            context.handler.MULTILINESTRING = @hdng.wkt.WKTGeometry.build_multilinestring;
            context.handler.MULTIPOLYGON = @hdng.wkt.WKTGeometry.build_multipolygon;
            context.handler.GEOMETRYCOLLECTION = @hdng.wkt.WKTGeometry.build_geometry_collection;
            
            
            [passed, result.value] = context.check_geometry(parse_result.value, parse_result.location);
            
            if ~passed
                result.errors = context.errors;
            else
                result.errors = [];
                result.source = source;
            end
        end
        
    end
    
    methods (Static, Access=private)
        
        function point = build_point_from(value, coordinates)
            
            if ~value.has_z && ~value.has_m
                point = hdng.geometry.Point.define(coordinates(1), coordinates(2));
            elseif ~value.has_z && value.has_m
                point = hdng.geometry.Point.define(coordinates(1), coordinates(2));
            elseif value.has_z && ~value.has_m
                point = hdng.geometry.Point.define(coordinates(1), coordinates(2), coordinates(3));
            else
                point = hdng.geometry.Point.define(coordinates(1), coordinates(2), coordinates(3));
            end
        end
        
        function build_point(context, value, ~, ~)
            
            if ~value.is_empty
                coordinates = context.result.anonymous_attributes{1};
                point = hdng.wkt.WKTGeometry.build_point_from(value, coordinates);
            else
                point = hdng.geometry.Collection.define('hdng.geometry.Point', 0, hdng.geometry.Vertices(), {}, @(index, vertices) []);
            end
            
            context.scope.add_named_attribute(value.keyword, point);
        end
        
        function [coordinates, m] = build_coordinates(points, value)
            
            N_points = numel(points);
            
            coordinates = zeros(N_points, value.N_dimensions, 'int64');
            
            for i=1:N_points
                point = points{i};
                if ~strcmp(class(point), class(coordinates))
                    coordinates = double(coordinates);
                end
                
                coordinates(i, :) = point;
            end
            
            if ~value.has_z && ~value.has_m
                m = [];
            elseif ~value.has_z && value.has_m
                m = coordinates(:, 3);
                coordinates = coordinates(:, 1:2);
            elseif value.has_z && ~value.has_m
                m = [];
            else
                m = coordinates(:, 4);
                coordinates = coordinates(:, 1:3);
            end
        end
        
        function [vertices, m] = build_vertices(points, value)
            [coordinates, m] = hdng.wkt.WKTGeometry.build_coordinates(points, value);
            vertices = hdng.geometry.Vertices.define(coordinates, 1);
        end
        
        function build_linestring(context, value, ~, ~)
            
            if ~value.is_empty
                [vertices, ~] = hdng.wkt.WKTGeometry.build_vertices(context.result.anonymous_attributes, value);
                linestring = hdng.geometry.Polyline.define(vertices);
            else
                linestring = hdng.geometry.Collection.define('hdng.geometry.Polyline', 0, hdng.geometry.Vertices(), {}, @(index, vertices) []);
            end
            
            context.scope.add_named_attribute(value.keyword, linestring);
        end
        
        function build_polygon(context, value, ~, ~)
            
            if ~value.is_empty
                N_rings = numel(context.result.named_attributes.LINESTRING.instances);
                
                for i=1:N_rings
                    rings{i} = context.result.named_attributes.LINESTRING.instances{i}.value; %#ok<AGROW>
                end
                
                [vertices, ring_offsets] = hdng.geometry.utilities.concat_vertices(rings);
                ring_offsets = hdng.geometry.Buffer.define(ring_offsets, 1);
                
                polygon = hdng.geometry.Polygon.define(vertices, ring_offsets);
            else
                polygon = hdng.geometry.Collection.define('hdng.geometry.Polygon', 0, hdng.geometry.Vertices(), {}, @(index, vertices) []);
            end
            
            context.scope.add_named_attribute(value.keyword, polygon);
        end
    end
    
end
