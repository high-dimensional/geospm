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

classdef WKTCoordinateSystem < handle
    %WKTCOORDINATESYSTEM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name
        authority
        source
    end
    
    methods
        
        function obj = WKTCoordinateSystem()
            obj.name = '';
            obj.authority = hdng.wkt.WKTAuthority.empty;
            obj.source = hdng.wkt.WKTSource.empty;
        end
       
        function set.name(obj, value)
            
            if ~ischar(value)
                error('Expected char array value for ''name'' attribute.');
            end
            
            obj.name = value;
        end
        
        function set.authority(obj, value)
            
            if ~isa(value, 'hdng.wkt.WKTAuthority')
                error('Expected WKTAuthority value for ''authority'' attribute.');
            end
            
            obj.authority = value;
        end
         
        function set.source(obj, value)
            
            if ~isa(value, 'hdng.wkt.WKTSource')
                error('Expected WKTSource value for ''source'' attribute.');
            end
            
            obj.source = value;
        end
        
        function result = format_as_text(obj)
            
            while true

                if isempty(obj.source)
                    break;
                end
                
                result = obj.source.text;
                
                if numel(result) == 0
                    break;
                end
                
                return;
            end
            
            error('WKTCoordinateSystem.format_as_text() must be implemented by a subclass.');
        end
    end
    
    methods (Static)
        
        function result = from_file(file_path)

            string = hdng.utilities.load_text(file_path);
            source = hdng.wkt.WKTSource;
            source.url = file_path;
            source.text = string;
            result = hdng.wkt.WKTCoordinateSystem.from_source(source);
        end
        
        function result = from_url(file_url)
            string = webread(file_url);
            source = hdng.wkt.WKTSource;
            source.url = file_url;
            source.text = string;
            result = hdng.wkt.WKTCoordinateSystem.from_source(source);
        end
        
        function result = from_chars(string)
            source = hdng.wkt.WKTSource;
            source.text = string;
            result = hdng.wkt.WKTCoordinateSystem.from_source(source);
        end
        
        function result = from_source(source)
            
            result = struct();
            
            parser = hdng.wkt.WKTParser;
            
            parser.allow_value_sequences = false;
            parser.allow_anonymous_values = false;
            parser.allow_additional_keywords = false;
            parser.allow_parenthesis_delimiters = true;
            parser.allow_bracket_delimiters = true;
            
            parse_result = parser.parse_chars(source.text);
            
            if ~isfield(parse_result, 'value' )
                result.errors = parse_result.errors;
                return
            end
            
            context = hdng.wkt.WKTAudit();
            context.handler.PROJCS = @hdng.wkt.WKTCoordinateSystem.build_projected_cs;
            context.handler.GEOGCS = @hdng.wkt.WKTCoordinateSystem.build_geographic_cs;
            context.handler.GEOCCS = @hdng.wkt.WKTCoordinateSystem.build_geocentric_cs;
            context.handler.TOWGS84 = @hdng.wkt.WKTCoordinateSystem.build_towgs84;
            context.handler.DATUM = @hdng.wkt.WKTCoordinateSystem.build_datum;
            context.handler.PROJECTION = @hdng.wkt.WKTCoordinateSystem.build_projection;
            context.handler.PARAMETER = @hdng.wkt.WKTCoordinateSystem.build_parameter;
            context.handler.SPHEROID = @hdng.wkt.WKTCoordinateSystem.build_spheroid;
            context.handler.PRIMEM = @hdng.wkt.WKTCoordinateSystem.build_prime_meridian;
            context.handler.UNIT = @hdng.wkt.WKTCoordinateSystem.build_unit;
            context.handler.AUTHORITY = @hdng.wkt.WKTCoordinateSystem.build_authority;
            context.handler.AXIS = @hdng.wkt.WKTCoordinateSystem.build_axis;
            
            [passed, result.value] = context.check_coordinate_system(parse_result.value, parse_result.location);
            
            if ~passed
                result.errors = context.errors;
            else
                result.errors = [];
                result.value.source = source;
            end
        end
        
    end
    
    methods (Static, Access=private)
        
        % function build_xyz(context, value, location, checks)
        
        function build_authority(context, value, ~, ~)
            
            authority = hdng.wkt.WKTAuthority(...
                           context.result.anonymous_attributes{1}, ...
                           context.result.anonymous_attributes{2});
                       
            context.scope.add_named_attribute(value.keyword, authority);
        end
        
        function build_axis(context, value, ~, ~)
            
            axis = hdng.wkt.WKTAxis(...
                           context.result.anonymous_attributes{1}, ...
                           context.result.anonymous_attributes{2});
            
            context.scope.add_named_attribute(value.keyword, axis);
        end
        
        function build_unit(context, value, ~, ~)
            
            authority = context.result.get_nth_named_attribute(...
                            'AUTHORITY', 1, hdng.wkt.WKTAuthority.empty);

            unit = hdng.wkt.WKTUnit(...
                           context.result.anonymous_attributes{1}, ...
                           context.result.anonymous_attributes{2}, ...
                           authority);
                       
            context.scope.add_named_attribute(value.keyword, unit);
        end
        
        function build_prime_meridian(context, value, ~, ~)
            
            authority = context.result.get_nth_named_attribute(...
                            'AUTHORITY', 1, hdng.wkt.WKTAuthority.empty);
            
            prime_meridian = hdng.wkt.WKTPrimeMeridian(...
                                context.result.anonymous_attributes{1}, ...
                                context.result.anonymous_attributes{2}, ...
                                authority);
                            
            context.scope.add_named_attribute(value.keyword, prime_meridian);
        end
        
        function build_spheroid(context, value, ~, ~)
            
            authority = context.result.get_nth_named_attribute(...
                            'AUTHORITY', 1, hdng.wkt.WKTAuthority.empty);
            
            spheroid = hdng.wkt.WKTSpheroid(...
                            context.result.anonymous_attributes{1}, ...
                            context.result.anonymous_attributes{2}, ...
                            context.result.anonymous_attributes{3}, ...
                            authority);
                            
            context.scope.add_named_attribute(value.keyword, spheroid);
        end
        
        function build_parameter(context, value, ~, ~)
            
            parameter = hdng.wkt.WKTParameter(...
                            context.result.anonymous_attributes{1}, ...
                            context.result.anonymous_attributes{2} );
                        
            context.scope.add_named_attribute(value.keyword, parameter);
        end
        
        function build_projection(context, value, ~, ~)
            
            authority = context.result.get_nth_named_attribute(...
                            'AUTHORITY', 1, hdng.wkt.WKTAuthority.empty);
            
            projection = hdng.wkt.WKTProjection(...
                                context.result.anonymous_attributes{1}, ...
                                authority);
                            
            context.scope.add_named_attribute(value.keyword, projection);
        end
        
        function build_datum(context, value, ~, ~)
            
            datum = hdng.wkt.WKTDatum();
            datum.name = context.result.anonymous_attributes{1};
           
            datum.spheroid = context.result.get_nth_named_attribute(...
                                'SPHEROID', 1, hdng.wkt.WKTSpheroid.empty);
            datum.towgs84 = context.result.get_nth_named_attribute(...
                                'TOWGS84', 1, hdng.wkt.WKTWGS84Transformation.empty);
            datum.authority = context.result.get_nth_named_attribute(...
                                'AUTHORITY', 1, hdng.wkt.WKTAuthority.empty);
            
            context.scope.add_named_attribute(value.keyword, datum);
        end
        
        function build_towgs84(context, value, ~, ~)
            
            t = hdng.wkt.WKTWGS84Transformation();
            
            t.dx = context.result.anonymous_attributes{1};
            t.dy = context.result.anonymous_attributes{2};
            t.dz = context.result.anonymous_attributes{3};
            
            if size(context.result.anonymous_attributes, 1) >= 6
                t.ex = context.result.anonymous_attributes{4};
                t.ey = context.result.anonymous_attributes{5};
                t.ez = context.result.anonymous_attributes{6};
            end
            
            if size(context.result.anonymous_attributes, 1) >= 7
                t.ppm = context.result.anonymous_attributes{7};
            end
            
            context.scope.add_named_attribute(value.keyword, t);
        end
        
        function build_geocentric_cs(context, value, ~, ~)
            
            cs = hdng.wkt.GeocentricCoordinateSystem;
            cs.name = context.result.anonymous_attributes{1};
            
            cs.datum = context.result.get_nth_named_attribute('DATUM', 1, cs.datum);
            cs.prime_meridian = context.result.get_nth_named_attribute('PRIMEM', 1, cs.prime_meridian);
            cs.linear_unit = context.result.get_nth_named_attribute('UNIT', 1, cs.linear_unit);
            
            cs.x_axis = context.result.get_nth_named_attribute('AXIS', 1, cs.x_axis);
            cs.y_axis = context.result.get_nth_named_attribute('AXIS', 2, cs.y_axis);
            cs.z_axis = context.result.get_nth_named_attribute('AXIS', 3, cs.z_axis);
            cs.authority = context.result.get_nth_named_attribute('AUTHORITY', 1, cs.authority);
            
            context.scope.add_named_attribute(value.keyword, cs);
        end
        
        function build_geographic_cs(context, value, ~, ~)
            
            cs = hdng.wkt.GeographicCoordinateSystem;
            
            cs.name = context.result.anonymous_attributes{1};
            
            cs.datum = context.result.get_nth_named_attribute('DATUM', 1, cs.datum);
            cs.prime_meridian = context.result.get_nth_named_attribute('PRIMEM', 1, cs.prime_meridian);
            cs.angular_unit = context.result.get_nth_named_attribute('UNIT', 1, cs.angular_unit);
            cs.linear_unit = context.result.get_nth_named_attribute('UNIT', 2, cs.linear_unit);
            cs.lon_axis = context.result.get_nth_named_attribute('AXIS', 1, cs.lon_axis);
            cs.lat_axis = context.result.get_nth_named_attribute('AXIS', 2, cs.lat_axis);
            cs.authority = context.result.get_nth_named_attribute('AUTHORITY', 1, cs.authority);
            
            context.scope.add_named_attribute(value.keyword, cs);
        end
        
        function build_projected_cs(context, value, ~, ~)
            
            cs = hdng.wkt.ProjectedCoordinateSystem;
            
            cs.name = context.result.anonymous_attributes{1};
            
            cs.geographic_coordinate_system = ...
                context.result.get_nth_named_attribute('GEOGCS', 1, ...
                    cs.geographic_coordinate_system);
            
                
            cs.projection = context.result.get_nth_named_attribute('PROJECTION', 1, cs.projection);
            
            n_parameters = context.result.size_of_named_attribute('PARAMETER');
            
            for index=1:n_parameters
                
                parameter = context.result.get_nth_named_attribute(...
                                'PARAMETER', index, hdng.wkt.WKTParameter.empty);
                cs.add_parameter(parameter);
            end
            
            cs.linear_unit = context.result.get_nth_named_attribute('UNIT', 1, cs.linear_unit);
            
            cs.x_axis = context.result.get_nth_named_attribute('AXIS', 1, cs.x_axis);
            cs.y_axis = context.result.get_nth_named_attribute('AXIS', 2, cs.y_axis);
            
            cs.authority = context.result.get_nth_named_attribute('AUTHORITY', 1, cs.authority);
            
            context.scope.add_named_attribute(value.keyword, cs);
        end
        
    end
    
end
