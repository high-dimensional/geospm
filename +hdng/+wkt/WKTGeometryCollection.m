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

classdef WKTGeometryCollection < matlab.mixin.Copyable
    %WKTGeometryCollection Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name
        source
    end
    
    properties (Dependent, Transient)
        is_mixed
        element_type
        N_elements
        N_points
    end
    
    methods
        
        function obj = WKTGeometryCollection()
            obj.name = '';
            obj.source = hdng.wkt.WKTSource.empty;
        end
        
        function set.name(obj, value)
            
            if ~ischar(value)
                error('Expected char array value for ''name'' attribute.');
            end
            
            obj.name = value;
        end
         
        function set.source(obj, value)
            
            if ~isa(value, 'hdng.wkt.WKTSource')
                error('Expected WKTSource value for ''source'' attribute.');
            end
            
            obj.source = value;
        end
        
        function result = get.is_mixed(obj)
            result = obj.access_is_mixed();
        end
        
        function result = get.element_type(obj)
            result = obj.access_element_type();
        end
        
        function result = get.N_elements(obj)
            result = obj.access_N_elements();
        end
        
        function result = get.N_points(obj)
            result = obj.access_N_points();
        end
        
        function result = nth_element(~, index) %#ok<INUSD,STOUT>
            error('nth_element() must be implemented by a subclass.');
        end
    end
    
    methods (Access = protected)
        
        function result = access_is_mixed(~) %#ok<STOUT>
            error('access_is_mixed() must be implemented by a subclass.');
        end
        
        function result = access_element_type(~) %#ok<STOUT>
            error('access_element_type() must be implemented by a subclass.');
        end
        
        function result = access_N_elements(~) %#ok<STOUT>
            error('access_N_elements() must be implemented by a subclass.');
        end
        
        function result = access_N_points(~) %#ok<STOUT>
            error('access_N_points() must be implemented by a subclass.');
        end
        
    end
    
    methods (Static)
        
        function result = from_file(file_path)

            string = hdng.utilities.load_text(file_path);
            source = hdng.wkt.WKTSource;
            source.url = file_path;
            source.text = string;
            result = hdng.wkt.WKTGeometryCollection.from_source(source);
        end
        
        function result = from_url(file_url)
            string = webread(file_url);
            source = hdng.wkt.WKTSource;
            source.url = file_url;
            source.text = string;
            result = hdng.wkt.WKTGeometryCollection.from_source(source);
        end
        
        function result = from_chars(string)
            source = hdng.wkt.WKTSource;
            source.text = string;
            result = hdng.wkt.WKTGeometryCollection.from_source(source);
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
            
            context.handler.POINT = @hdng.wkt.WKTGeometryCollection.build_point;
            context.handler.LINESTRING = @hdng.wkt.WKTGeometryCollection.build_linestring;
            context.handler.POLYGON = @hdng.wkt.WKTGeometryCollection.build_polygon;
            context.handler.MULTIPOINT = @hdng.wkt.WKTGeometryCollection.build_multipoint;
            context.handler.MULTILINESTRING = @hdng.wkt.WKTGeometryCollection.build_multilinestring;
            context.handler.MULTIPOLYGON = @hdng.wkt.WKTGeometryCollection.build_multipolygon;
            context.handler.GEOMETRYCOLLECTION = @hdng.wkt.WKTGeometryCollection.build_geometry_collection;
            
            
            [passed, result.value] = context.check_geometry_collection(parse_result.value, parse_result.location);
            
            if ~passed
                result.errors = context.errors;
            else
                result.errors = [];
                result.value.source = source;
            end
        end
        
    end
    
    methods (Static, Access=private)
        
        function point = build_point_from(value, coordinates)
            
            if ~value.has_z && ~value.has_m
                point = hdng.wkt.WKTPoint(coordinates(1), coordinates(2), NaN, NaN);
            elseif ~value.has_z && value.has_m
                point = hdng.wkt.WKTPoint(coordinates(1), coordinates(2), NaN, coordinates(3));
            elseif value.has_z && ~value.has_m
                point = hdng.wkt.WKTPoint(coordinates(1), coordinates(2), coordinates(3), NaN);
            else
                point = hdng.wkt.WKTPoint(coordinates(1), coordinates(2), coordinates(3), coordinates(4));
            end
        end
        
        function build_point(context, value, ~, ~)
            
            if ~value.is_empty
                coordinates = context.result.anonymous_attributes{1};
                point = hdng.wkt.WKTGeometryCollection.build_point_from(value, coordinates);
            else
                point = hdng.wkt.GenericCollection(hdng.wkt.WKTPoint.empty);
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
        
        function build_linestring(context, value, ~, ~)
            
            if ~value.is_empty
                [coordinates, m] = hdng.wkt.WKTGeometryCollection.build_coordinates(context.result.anonymous_attributes, value);
                linestring = hdng.wkt.WKTLineString(coordinates, m);
            else
                linestring = hdng.wkt.GenericCollection(hdng.wkt.WKTLineString.empty);
            end
            
            context.scope.add_named_attribute(value.keyword, linestring);
        end
        
        function build_polygon(context, value, ~, ~)
            
            if ~value.is_empty
                N_rings = numel(context.result.named_attributes.LINESTRING.instances);
                rings = hdng.wkt.WKTLineString.empty;

                for i=1:N_rings
                    rings(i) = context.result.named_attributes.LINESTRING.instances{i}.value;
                end

                polygon = hdng.wkt.WKTPolygon(rings);
            else
                polygon = hdng.wkt.GenericCollection(hdng.wkt.WKTPolygon.empty);
            end
            
            context.scope.add_named_attribute(value.keyword, polygon);
        end
        
        function build_multipoint(context, value, ~, ~)
            
            if ~value.is_empty
                [coordinates, m] = hdng.wkt.WKTGeometryCollection.build_coordinates(context.result.anonymous_attributes, value);

                coordinates = [coordinates, m];

                elements = hdng.wkt.WKTPoint.empty;
                N_points = size(coordinates, 1);

                for i=1:N_points
                    elements(i) = hdng.wkt.WKTGeometryCollection.build_point_from(value, coordinates(i, :));
                end

                multipoints = hdng.wkt.GenericCollection(elements);
            else
                multipoints = hdng.wkt.GenericCollection(hdng.wkt.WKTPoint.empty);
            end
            
            context.scope.add_named_attribute(value.keyword, multipoints);
        end
        
        function build_multilinestring(context, value, ~, ~)
            
            if ~value.is_empty
                N_elements = numel(context.result.named_attributes.LINESTRING.instances);
                elements = hdng.wkt.WKTLineString.empty;

                for i=1:N_elements
                    elements(i) = context.result.named_attributes.LINESTRING.instances{i}.value;
                end

                multilinestring = hdng.wkt.GenericCollection(elements);
            else
                multilinestring = hdng.wkt.GenericCollection(hdng.wkt.WKTLineString.empty);
            end
            
            context.scope.add_named_attribute(value.keyword, multilinestring);
        end
            
        function build_multipolygon(context, value, ~, ~)
            
            if ~value.is_empty
                N_elements = numel(context.result.named_attributes.POLYGON.instances);
                elements = hdng.wkt.WKTPolygon.empty;

                for i=1:N_elements
                    elements(i) = context.result.named_attributes.POLYGON.instances{i}.value;
                end

                multipolygon = hdng.wkt.GenericCollection(elements);
            else
                multipolygon = hdng.wkt.GenericCollection(hdng.wkt.WKTPolygon.empty);
            end
            
            context.scope.add_named_attribute(value.keyword, multipolygon);
        end
        
        
        
        function build_geometry_collection(context, value, ~, ~)
            
            if ~value.is_empty
                
                elements = cell(context.result.count_named_attributes(), 1);
                
                primitives = fieldnames(context.result.named_attributes);
                
                for i=1:numel(primitives)
                    instances = context.result.named_attributes.(primitives{i}).instances;
                    
                    for j=1:numel(instances)
                        instance = instances{j};
                        elements{instance.position} = instance.value;
                    end
                end
                
                collection = hdng.wkt.GenericCollection(elements);
            else
                collection = hdng.wkt.GenericCollection(hdng.wkt.Primitive.empty);
            end
            
            context.scope.add_named_attribute(value.keyword, collection);
        end
        
        
    end
    
end
