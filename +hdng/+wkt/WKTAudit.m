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

classdef WKTAudit < handle
    %WKTAudit Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        errors
        handler
        result
    end
    
    properties (Dependent)
        scope
    end
    
    properties (GetAccess=private,SetAccess=private)
        scope_stack
    end
    
    methods
        
        function obj = WKTAudit()
            
            obj.errors = cell(0,1);
            obj.handler = struct();
            obj.scope_stack = cell(0,1);
            obj.result = cell(0,1);
        end
        
        function scope = get.scope(obj)
            scope = obj.scope_stack{size(obj.scope_stack, 1),1};
        end
        
        function set.scope(obj, value)
            obj.scope_stack{size(obj.scope_stack, 1),1} = value;
        end
    end
    
    methods
        
        function enter_scope(obj)
            obj.scope_stack{end + 1, 1} = hdng.wkt.WKTAuditScope;
        end
        
        function result = leave_scope(obj)
            result = obj.scope;
            obj.scope_stack(end) = [];
        end
    end
    
    methods

        function define_error(obj, message, location)

            error=struct();
            error.string = message;
            error.line_number = location(1);
            error.position = location(2);

            obj.errors{end + 1} = error;
        end


        function passed = check_string(obj, value, location)

            if ~ischar(value)
                passed = false;
                obj.define_error('Expected string value.', location);
                return;
            end

            passed = true;
            obj.scope.add_anonymous_attribute(value);
        end

        function passed = check_number(obj, value, location)

            if ~isnumeric(value)
                passed = false;
                obj.define_error('Expected number value.', location);
                return;
            end

            passed = true;
            obj.scope.add_anonymous_attribute(value);
        end
        
        function passed = check_vector(obj, value, location, k)

            if ~isnumeric(value)
                passed = false;
                obj.define_error('Expected numeric vector value.', location);
                return;
            end

            if numel(value) ~= k
                passed = false;
                obj.define_error(['Expected ' num2str(k, '%d') '-vector value.'], location);
                return;
            end
            
            passed = true;
            obj.scope.add_anonymous_attribute(value);
        end

        function passed = check_value(obj, value, location)

            if ~isnumeric(value)
                passed = false;
                obj.define_error('Expected value.', location);
                return;
            end

            passed = true;
            obj.scope.add_anonymous_attribute(value);
        end


        function passed = check_keyword_value(obj, value, location)

            passed = isstruct(value) ...
                     && isfield(value, 'keyword') ...
                     && isfield(value, 'attributes') ...
                     && isfield(value, 'locations') ...
                     && size(value.attributes, 1) == 0;

            if ~passed
                obj.define_error('Expected keyword value.', location);
                return;
            end
        end

        function passed = check_keyword_struct(obj, value, location)

            passed = isstruct(value) ...
                     && isfield(value, 'keyword') ...
                     && isfield(value, 'attributes') ...
                     && isfield(value, 'locations');

            if ~passed
                obj.define_error('Expected keyword value.', location);
                return;
            end
        end


        function passed = check_bearing(obj, value, location)

            passed = obj.check_keyword_value(value, location);
            
            if ~passed
                obj.define_error('Expected WKTBearing value.', location);
                return;
            end
            
            if wkt_strcmp(value.keyword, 'NORTH')
                passed = true;
                obj.scope.add_anonymous_attribute(hdng.wkt.WKTBearing.NORTH);
                return;
            end
            
            if wkt_strcmp(value.keyword, 'SOUTH')
                passed = true;
                obj.scope.add_anonymous_attribute(hdng.wkt.WKTBearing.SOUTH);
                return;
            end
            
            if wkt_strcmp(value.keyword, 'EAST')
                passed = true;
                obj.scope.add_anonymous_attribute(hdng.wkt.WKTBearing.EAST);
                return;
            end
            
            if wkt_strcmp(value.keyword, 'WEST')
                passed = true;
                obj.scope.add_anonymous_attribute(hdng.wkt.WKTBearing.WEST);
                return;
            end
            
            if wkt_strcmp(value.keyword, 'UP')
                passed = true;
                obj.scope.add_anonymous_attribute(hdng.wkt.WKTBearing.UP);
                return;
            end
            
            if wkt_strcmp(value.keyword, 'DOWN')
                passed = true;
                obj.scope.add_anonymous_attribute(hdng.wkt.WKTBearing.DOWN);
                return;
            end
            
            if wkt_strcmp(value.keyword, 'OTHER')
                passed = true;
                obj.scope.add_anonymous_attribute(hdng.wkt.WKTBearing.OTHER);
                return;
            end
            
            obj.define_error('Expected WKTBearing value.', location);
        end

        function passed = check_longitude(obj, value, location)

            if ~isnumeric(value)
                passed = false;
                obj.define_error('Expected longitude value.', location);
                return;
            end

            passed = true;
            obj.scope.add_anonymous_attribute(value);
        end


        function passed = check_semi_major_axis(obj, value, location)

            if ~isnumeric(value)
                passed = false;
                obj.define_error('Expected semi-major axis value.', location);
                return;
            end

            passed = true;
            obj.scope.add_anonymous_attribute(value);
        end


        function passed = check_inverse_flattening(obj, value, location)

            if ~isnumeric(value)
                passed = false;
                obj.define_error('Expected inverse flattening value.', location);
                return;
            end

            passed = true;
            obj.scope.add_anonymous_attribute(value);
        end

        function passed = check_conversion_factor(obj, value, location)

            if ~isnumeric(value)
                passed = false;
                obj.define_error('Expected conversion factor value.', location);
                return;
            end

            passed = true;
            obj.scope.add_anonymous_attribute(value);
        end


        function passed = run_wkt_attribute_check(obj, value, location, index, is_optional, handler)

            if index > size(value.attributes, 1)

                if is_optional
                    passed = true;
                    return
                end

                passed = false;
                obj.define_error(sprintf('Missing expected attribute %s in %s', char(handler), value.keyword), location);
                return
            end

            handler_passed = handler(obj, value.attributes{index}, value.locations{index});
            
            if ~handler_passed && ~is_optional
                passed = false;
                obj.define_error(sprintf('Missing expected attribute %s in %s', char(handler), value.keyword), location);
                return
            end

            passed = true;
        end

        function [passed, checks] = run_wkt_attribute_checks(obj, value, location, index, checks)

            passed = true;

            remaining_checks = checks;
            completed_checks = cell(0,1);
            
            % Iterate over attributes one by one
            
            while index <= size(value.attributes,1) + 1

                % Determine what checks can still be run,
                % and remove checks that are no longer applicable
                
                applicable_checks = cell(0,1);

                for j=1:size(remaining_checks, 1)

                    check = remaining_checks{j, 1};

                    if check.occ < check.max_occ || check.max_occ == 0
                        applicable_checks{end + 1, 1} = check; %#ok<AGROW>
                    else
                        completed_checks{end + 1, 1} = check; %#ok<AGROW>
                    end
                end

                remaining_checks = applicable_checks;
                
                % Stop if there a no more attributes to be checked
                
                if index == size(value.attributes,1) + 1
                    break
                end

                handler_passed = false;

                % Cycle over remaining checks, stopping at the first check
                % that passes
                
                for j=1:size(remaining_checks, 1)

                    check = remaining_checks{j, 1};

                    handler_passed = check.handler(obj, value.attributes{index}, value.locations{index});

                    if handler_passed
                        
                       check.occ = check.occ + 1;
                       check.occ_indices{end + 1, 1} = index;
                       remaining_checks{j, 1} = check;
                       break
                    end
                end

                % If no check passed we have an error condition:
                % Either there are more attributes than expected
                % or the attribute is not expected.
                
                if ~handler_passed
                    passed = false;

                    if size(remaining_checks, 1) == 0
                        obj.define_error(sprintf('%s contains more attributes than expected.', value.keyword), location);
                    else
                        if isstruct(value.attributes{index})
                            attribute_value = value.attributes{index}.keyword;
                        else
                            attribute_value = char(value.attributes{index});
                        end
                        
                        obj.define_error(sprintf('Attribute ''%s'' is not in the list of expected attributes.', attribute_value), value.locations{index});
                    end
                    return;
                end

                index = index + 1;
            end
            
            % Finally, make sure that each check occured the
            % minimum (or exact) number of times required.
            
            checks = [completed_checks; remaining_checks];

            for j=1:size(checks, 1)

                check = checks{j, 1};

                if check.occ < check.min_occ && (check.occ ~= 0 || ~check.occ_is_optional)
                    passed = false;
                    obj.define_error(sprintf('Missing at least one %s attribute in %s', char(check.handler), char(value)), location);
                end
                
                if ~isempty(check.exact_occ)
                    if sum(ismember([check.occ], check.exact_occ)) == 0
                        passed = false;
                        obj.define_error(sprintf('Only a certain number of %s attribute in %s are permitted: [...]', char(check.handler), char(value)), location);
                    end
                end
            end
        end


        function [passed, result] = check_coordinate_system(obj, value, location)

            result = hdng.wkt.WKTCoordinateSystem.empty;
            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end
            
            guard = hdng.wkt.WKTAuditScopeGuard(obj);
            
            while true
                if wkt_strcmp(value.keyword, 'PROJCS')
                    passed = obj.check_projected_cs(value, location);
                    break;
                end

                if wkt_strcmp(value.keyword, 'GEOGCS')
                    passed = obj.check_geographic_cs(value, location);
                    break;
                end

                if wkt_strcmp(value.keyword, 'GEOCCS')
                    passed = obj.check_geocentric_cs(value, location);
                    break;
                end
                
                break;
            end
            
            if ~passed
                obj.define_error(sprintf('Unknown coordinate systems ''%s''', value.keyword), location);
                return
            end
            
            result = obj.scope.get_nth_named_attribute(value.keyword, 1, result);
            delete(guard);
        end


        function passed = check_projected_cs(obj, value, location)

            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end

            passed = wkt_strcmp(value.keyword, 'PROJCS');

            if ~passed
                return
            end
            
            guard = hdng.wkt.WKTAuditScopeGuard(obj);

            passed = obj.run_wkt_attribute_check(value, location, 1, false, @check_string);

            if ~passed
                return
            end

            checks = cell(0,1);

            checks{end + 1, 1} = wkt_attribute_check(1, 1, false, @check_geographic_cs);
            checks{end + 1, 1} = wkt_attribute_check(1, 1, false, @check_projection);
            checks{end + 1, 1} = wkt_attribute_check(0, 0, true,  @check_parameter);
            checks{end + 1, 1} = wkt_attribute_check(1, 1, false, @check_linear_unit);
            checks{end + 1, 1} = wkt_attribute_check(2, 2, true,  @check_axis);
            checks{end + 1, 1} = wkt_attribute_check(0, 1, true,  @check_authority);

            [passed, checks] = obj.run_wkt_attribute_checks(value, location, 2, checks);

            obj.result = obj.scope;
            delete(guard);
            
            if passed && isfield(obj.handler, value.keyword)
                obj.handler.(value.keyword)(obj, value, location, checks);
            end
        end


        function passed = check_geographic_cs(obj, value, location)

            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end

            passed = wkt_strcmp(value.keyword, 'GEOGCS');

            if ~passed
                return
            end
            
            guard = hdng.wkt.WKTAuditScopeGuard(obj);
            
            passed = obj.run_wkt_attribute_check(value, location, 1, false, @check_string);

            if ~passed
                return
            end

            checks = cell(0,1);

            checks{end + 1, 1} = wkt_attribute_check(1, 1, false, @check_datum);
            checks{end + 1, 1} = wkt_attribute_check(1, 1, false, @check_prime_meridian);
            checks{end + 1, 1} = wkt_attribute_check(1, 1, false, @check_angular_unit);
            checks{end + 1, 1} = wkt_attribute_check(2, 2, true,  @check_axis);
            checks{end + 1, 1} = wkt_attribute_check(0, 1, true,  @check_authority);

            [passed, checks] = obj.run_wkt_attribute_checks(value, location, 2, checks);

            obj.result = obj.scope;
            delete(guard);
            
            if passed && isfield(obj.handler, value.keyword)
                obj.handler.(value.keyword)(obj, value, location, checks);
            end
        end


        function passed = check_projection(obj, value, location)

            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end

            passed = wkt_strcmp(value.keyword, 'PROJECTION');

            if ~passed
                return
            end

            guard = hdng.wkt.WKTAuditScopeGuard(obj);
            
            passed = obj.run_wkt_attribute_check(value, location, 1, false, @check_string);

            if ~passed
                return
            end

            checks = cell(0,1);

            checks{end + 1, 1} = wkt_attribute_check(0, 1, true,  @check_authority);

            [passed, checks] = obj.run_wkt_attribute_checks(value, location, 2, checks);

            obj.result = obj.scope;
            delete(guard);
            
            if passed && isfield(obj.handler, value.keyword)
                obj.handler.(value.keyword)(obj, value, location, checks);
            end
        end


        function passed = check_parameter(obj, value, location)

            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end

            passed = wkt_strcmp(value.keyword, 'PARAMETER');

            if ~passed
                return
            end
            
            guard = hdng.wkt.WKTAuditScopeGuard(obj);

            passed = obj.run_wkt_attribute_check(value, location, 1, false, @check_string);

            if ~passed
                return
            end

            checks = cell(0,1);

            checks{end + 1, 1} = wkt_attribute_check(1, 1, false,  @check_value);

            [passed, checks] = obj.run_wkt_attribute_checks(value, location, 2, checks);

            obj.result = obj.scope;
            delete(guard);
            
            if passed && isfield(obj.handler, value.keyword)
                obj.handler.(value.keyword)(obj, value, location, checks);
            end
        end


        function passed = check_linear_unit(obj, value, location)

            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end

            passed = wkt_strcmp(value.keyword, 'UNIT');

            if ~passed
                return
            end
            
            guard = hdng.wkt.WKTAuditScopeGuard(obj);

            passed = obj.run_wkt_attribute_check(value, location, 1, false, @check_string);

            if ~passed
                return
            end

            checks = cell(0,1);

            checks{end + 1, 1} = wkt_attribute_check(1, 1, false,  @check_conversion_factor);
            checks{end + 1, 1} = wkt_attribute_check(0, 1, true,  @check_authority);

            [passed, checks] = obj.run_wkt_attribute_checks(value, location, 2, checks);

            obj.result = obj.scope;
            delete(guard);
            
            if passed && isfield(obj.handler, value.keyword)
                obj.handler.(value.keyword)(obj, value, location, checks);
            end
        end



        function passed = check_angular_unit(obj, value, location)

            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end

            passed = wkt_strcmp(value.keyword, 'UNIT');

            if ~passed
                return
            end

            guard = hdng.wkt.WKTAuditScopeGuard(obj);
            
            passed = obj.run_wkt_attribute_check(value, location, 1, false, @check_string);

            if ~passed
                return
            end

            checks = cell(0,1);

            checks{end + 1, 1} = wkt_attribute_check(1, 1, false,  @check_conversion_factor);
            checks{end + 1, 1} = wkt_attribute_check(0, 1, true,  @check_authority);

            [passed, checks] = obj.run_wkt_attribute_checks(value, location, 2, checks);

            obj.result = obj.scope;
            delete(guard);
            
            if passed && isfield(obj.handler, value.keyword)
                obj.handler.(value.keyword)(obj, value, location, checks);
            end
        end


        function passed = check_axis(obj, value, location)


            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end

            passed = wkt_strcmp(value.keyword, 'AXIS');

            if ~passed
                return
            end

            guard = hdng.wkt.WKTAuditScopeGuard(obj);
            
            passed = obj.run_wkt_attribute_check(value, location, 1, false, @check_string);

            if ~passed
                return
            end

            checks = cell(0,1);

            checks{end + 1, 1} = wkt_attribute_check(1, 1, false,  @check_bearing);

            [passed, checks] = obj.run_wkt_attribute_checks(value, location, 2, checks);

            obj.result = obj.scope;
            delete(guard);
            
            if passed && isfield(obj.handler, value.keyword)
                obj.handler.(value.keyword)(obj, value, location, checks);
            end
        end


        function passed = check_authority(obj, value, location)

            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end

            passed = wkt_strcmp(value.keyword, 'AUTHORITY');

            if ~passed
                return
            end

            guard = hdng.wkt.WKTAuditScopeGuard(obj);
            
            passed = obj.run_wkt_attribute_check(value, location, 1, false, @check_string);

            if ~passed
                return
            end

            checks = cell(0,1);

            checks{end + 1, 1} = wkt_attribute_check(1, 1, false,  @check_string);

            [passed, checks] = obj.run_wkt_attribute_checks(value, location, 2, checks);

            obj.result = obj.scope;
            delete(guard);
            
            if passed && isfield(obj.handler, value.keyword)
                obj.handler.(value.keyword)(obj, value, location, checks);
            end
        end


        function passed = check_datum(obj, value, location)

            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end

            passed = wkt_strcmp(value.keyword, 'DATUM');

            if ~passed
                return
            end
            
            guard = hdng.wkt.WKTAuditScopeGuard(obj);
            
            passed = obj.run_wkt_attribute_check(value, location, 1, false, @check_string);

            if ~passed
                return
            end

            checks = cell(0,1);

            checks{end + 1, 1} = wkt_attribute_check(1, 1, false, @check_spheroid);
            checks{end + 1, 1} = wkt_attribute_check(0, 1, true,  @check_to_wgs84);
            checks{end + 1, 1} = wkt_attribute_check(0, 1, true,  @check_authority);

            [passed, checks] = obj.run_wkt_attribute_checks(value, location, 2, checks);

            obj.result = obj.scope;
            delete(guard);
            
            if passed && isfield(obj.handler, value.keyword)
                obj.handler.(value.keyword)(obj, value, location, checks);
            end
        end


        function passed = check_prime_meridian(obj, value, location)

            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end

            passed = wkt_strcmp(value.keyword, 'PRIMEM');

            if ~passed
                return
            end

            guard = hdng.wkt.WKTAuditScopeGuard(obj);
            
            passed = obj.run_wkt_attribute_check(value, location, 1, false, @check_string);

            if ~passed
                return
            end

            checks = cell(0,1);

            checks{end + 1, 1} = wkt_attribute_check(1, 1, false, @check_longitude);
            checks{end + 1, 1} = wkt_attribute_check(0, 1, true,  @check_authority);

            [passed, checks] = obj.run_wkt_attribute_checks(value, location, 2, checks);

            obj.result = obj.scope;
            delete(guard);
            
            if passed && isfield(obj.handler, value.keyword)
                obj.handler.(value.keyword)(obj, value, location, checks);
            end
        end


        function passed = check_spheroid(obj, value, location)

            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end

            passed = wkt_strcmp(value.keyword, 'SPHEROID');

            if ~passed
                return
            end

            guard = hdng.wkt.WKTAuditScopeGuard(obj);
            
            passed = obj.run_wkt_attribute_check(value, location, 1, false, @check_string);

            if ~passed
                return
            end

            checks = cell(0,1);

            checks{end + 1, 1} = wkt_attribute_check(1, 1, false, @check_semi_major_axis);
            checks{end + 1, 1} = wkt_attribute_check(1, 1, false, @check_inverse_flattening);
            checks{end + 1, 1} = wkt_attribute_check(0, 1, true,  @check_authority);

            [passed, checks] = obj.run_wkt_attribute_checks(value, location, 2, checks);

            obj.result = obj.scope;
            delete(guard);
            
            if passed && isfield(obj.handler, value.keyword)
                obj.handler.(value.keyword)(obj, value, location, checks);
            end
        end


        function passed = check_to_wgs84(obj, value, location)

            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end

            passed = wkt_strcmp(value.keyword, 'TOWGS84');

            if ~passed
                return
            end

            guard = hdng.wkt.WKTAuditScopeGuard(obj);
            
            checks = cell(0,1);

            checks{end + 1, 1} = wkt_exact_attribute_check([3, 6, 7], false, @check_number);

            [passed, checks] = obj.run_wkt_attribute_checks(value, location, 2, checks);

            obj.result = obj.scope;
            delete(guard);
            
            if passed && isfield(obj.handler, value.keyword)
                obj.handler.(value.keyword)(obj, value, location, checks);
            end
        end
        
        
        function [passed, result] = check_geometry_collection(obj, value, location, is_nested_call)

            if ~exist('is_nested_call', 'var')
                is_nested_call = false;
            end
            
            result = hdng.wkt.WKTGeometryCollection.empty;
            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end
            
            if ~is_nested_call
                guard = hdng.wkt.WKTAuditScopeGuard(obj);
            end
            
            while true
                
                if wkt_strcmp(value.keyword, 'POINT')
                    passed = obj.check_point(value, location);
                    break;
                end

                if wkt_strcmp(value.keyword, 'LINESTRING')
                    passed = obj.check_linestring(value, location);
                    break;
                end

                if wkt_strcmp(value.keyword, 'POLYGON')
                    passed = obj.check_polygon(value, location);
                    break;
                end

                if wkt_strcmp(value.keyword, 'MULTIPOINT')
                    passed = obj.check_multipoint(value, location);
                    break;
                end

                if wkt_strcmp(value.keyword, 'MULTILINESTRING')
                    passed = obj.check_multilinestring(value, location);
                    break;
                end

                if wkt_strcmp(value.keyword, 'MULTIPOLYGON')
                    passed = obj.check_multipolygon(value, location);
                    break;
                end
                
                if ~is_nested_call && wkt_strcmp(value.keyword, 'GEOMETRYCOLLECTION')
                    passed = obj.check_geometrycollection(value, location);
                    break;
                end
                
                break;
            end
            
            if ~passed
                obj.define_error(sprintf('Unknown geometry ''%s''', value.keyword), location);
                return
            end
            
            if ~is_nested_call
                result = obj.scope.get_nth_named_attribute(value.keyword, 1, result);
                delete(guard);
            end
        end
        
        function [passed, result] = check_geometry(obj, value, location, is_nested_call)

            if ~exist('is_nested_call', 'var')
                is_nested_call = false;
            end
            
            result = hdng.wkt.WKTGeometry.empty;
            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end
            
            if ~is_nested_call
                guard = hdng.wkt.WKTAuditScopeGuard(obj);
            end
            
            while true
                
                if wkt_strcmp(value.keyword, 'POINT')
                    passed = obj.check_point(value, location);
                    break;
                end

                if wkt_strcmp(value.keyword, 'LINESTRING')
                    passed = obj.check_linestring(value, location);
                    break;
                end

                if wkt_strcmp(value.keyword, 'POLYGON')
                    passed = obj.check_polygon(value, location);
                    break;
                end

                if wkt_strcmp(value.keyword, 'MULTIPOINT')
                    passed = obj.check_multipoint(value, location);
                    break;
                end

                if wkt_strcmp(value.keyword, 'MULTILINESTRING')
                    passed = obj.check_multilinestring(value, location);
                    break;
                end

                if wkt_strcmp(value.keyword, 'MULTIPOLYGON')
                    passed = obj.check_multipolygon(value, location);
                    break;
                end
                
                if ~is_nested_call && wkt_strcmp(value.keyword, 'GEOMETRYCOLLECTION')
                    passed = obj.check_geometrycollection(value, location);
                    break;
                end
                
                break;
            end
            
            if ~passed
                obj.define_error(sprintf('Unknown geometry ''%s''', value.keyword), location);
                return
            end
            
            if ~is_nested_call
                result = obj.scope.get_nth_named_attribute(value.keyword, 1, result);
                delete(guard);
            end
        end
        
        function [passed, N_dimensions, has_z, has_m, is_empty] = check_n_dimensions(~, value, ~)
            
            N_dimensions = 2;
            has_z = false;
            has_m = false;
            is_empty = false;
            
            N_keywords = numel(value.additional_keywords);
            passed = N_keywords < 3;
            
            if ~passed || N_keywords == 0
                return
            end
            
            has_z = wkt_strcmp(value.additional_keywords{1}, 'Z') ...
                        || wkt_strcmp(value.additional_keywords{1}, 'ZM');
            
            has_m = wkt_strcmp(value.additional_keywords{1}, 'M') ...
                        || wkt_strcmp(value.additional_keywords{1}, 'ZM');
            
            N_dimensions = 2 + cast(has_z, 'double') + cast(has_m, 'double');
            
            if N_keywords == 1
                if has_z || has_m
                    return
                end
                
                empty_index = 1;
            else
                if ~has_z && ~has_m
                    passed = false;
                    return
                end
                
                empty_index = 2;
            end
            
            if ~wkt_strcmp(value.additional_keywords{empty_index}, 'EMPTY')
                passed = false;
                return;
            end
            
            is_empty = true;

            if numel(value.attributes) ~= 0
                passed = false;
                return;
            end
        end
        
        
        function passed = check_point(obj, value, location)

            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end

            passed = wkt_strcmp(value.keyword, 'POINT');

            if ~passed
                return
            end
            
            [passed, value.N_dimensions, value.has_z, value.has_m, value.is_empty] = obj.check_n_dimensions(value, location);
            
            if ~passed
                return
            end
            
            guard = hdng.wkt.WKTAuditScopeGuard(obj);
            
            if ~value.is_empty
                passed = obj.run_wkt_attribute_check(value, location, 1, false, ...
                            @(obj, raw_value, location) obj.check_vector(raw_value, location, value.N_dimensions));
            end
            
            if ~passed
                return
            end
            
            checks = cell(0,1);
            obj.result = obj.scope;
            delete(guard);
            
            if passed && isfield(obj.handler, value.keyword)
                obj.handler.(value.keyword)(obj, value, location, checks);
            end
        end
        
        function passed = check_point_list_as(obj, value, location, keyword, metadata)
            
            
            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end
            
            value.keyword = keyword;
            value.keyword_as_specified = '';
            value.N_dimensions = metadata.N_dimensions;
            value.has_z = metadata.has_z;
            value.has_m = metadata.has_m;
            value.is_empty = metadata.is_empty;
            
            guard = hdng.wkt.WKTAuditScopeGuard(obj);
            
            checks = cell(0,1);

            checks{end + 1, 1} = wkt_attribute_check(1, Inf, false, ...
                        @(obj, raw_value, location) obj.check_vector(raw_value, location, value.N_dimensions));

            [passed, checks] = obj.run_wkt_attribute_checks(value, location, 1, checks);
            
            obj.result = obj.scope;
            delete(guard);
            
            if passed && isfield(obj.handler, value.keyword)
                obj.handler.(value.keyword)(obj, value, location, checks);
            end
            
        end
                
        function passed = check_linestring(obj, value, location)
            
            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end
            
            passed = wkt_strcmp(value.keyword, 'LINESTRING');

            if ~passed
                return
            end
            
            [passed, value.N_dimensions, value.has_z, value.has_m, value.is_empty] = obj.check_n_dimensions(value, location);
            
            if ~passed
                return
            end
            
            if ~value.is_empty
                passed = obj.check_point_list_as(value, location, value.keyword, value);

                if ~passed
                    return
                end
            else
                if passed && isfield(obj.handler, value.keyword)
                    obj.handler.(value.keyword)(obj, value, location, {});
                end
            end
        end
        
        function passed = check_polygon(obj, value, location, is_anonymous, metadata)
            
            if ~exist('is_anonymous', 'var')
                is_anonymous = false;
            end
            
            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end
            
            if ~is_anonymous
                passed = wkt_strcmp(value.keyword, 'POLYGON');
            else
                passed = numel(value.keyword) == 0;
                value.keyword = 'POLYGON';
            end            

            if ~passed
                return
            end
            
            [passed, value.N_dimensions, value.has_z, value.has_m, value.is_empty] = obj.check_n_dimensions(value, location);

            if ~passed
                return
            end

            if exist('metadata', 'var')
                
                value.N_dimensions = metadata.N_dimensions;
                value.has_z = metadata.has_z;
                value.has_m = metadata.has_m;
            end
            
            if ~value.is_empty
                guard = hdng.wkt.WKTAuditScopeGuard(obj);

                checks = cell(0,1);

                checks{end + 1, 1} = wkt_attribute_check(1, Inf, false, ...
                            @(obj, raw_value, location) obj.check_point_list_as(raw_value, location, 'LINESTRING', value));

                [passed, checks] = obj.run_wkt_attribute_checks(value, location, 1, checks);

                obj.result = obj.scope;
                delete(guard);
            else
                checks = cell(0,1);
            end
            
            if passed && isfield(obj.handler, value.keyword)
                obj.handler.(value.keyword)(obj, value, location, checks);
            end
        end
        
       
        function passed = check_multipoint(obj, value, location)
         
            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end
            
            passed = wkt_strcmp(value.keyword, 'MULTIPOINT');

            if ~passed
                return
            end
            
            [passed, value.N_dimensions, value.has_z, value.has_m, value.is_empty] = obj.check_n_dimensions(value, location);
            
            if ~passed
                return
            end
            
            if ~value.is_empty
                passed = obj.check_point_list_as(value, location, value.keyword, value);

                if ~passed
                    return
                end
            else
                if passed && isfield(obj.handler, value.keyword)
                    checks = cell(0,1);
                    obj.handler.(value.keyword)(obj, value, location, checks);
                end
            end
        end
        
        function passed = check_multilinestring(obj, value, location)

            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end

            passed = wkt_strcmp(value.keyword, 'MULTILINESTRING');

            if ~passed
                return
            end
            
            [passed, value.N_dimensions, value.has_z, value.has_m, value.is_empty] = obj.check_n_dimensions(value, location);
            
            if ~passed
                return
            end
            
            if ~value.is_empty
                guard = hdng.wkt.WKTAuditScopeGuard(obj);

                checks = cell(0,1);

                checks{end + 1, 1} = wkt_attribute_check(1, Inf, false, ...
                            @(obj, raw_value, location) obj.check_point_list_as(raw_value, location, 'LINESTRING', value));

                [passed, checks] = obj.run_wkt_attribute_checks(value, location, 1, checks);

                obj.result = obj.scope;
                delete(guard);
            else
                checks = cell(0,1);
            end
            
            if passed && isfield(obj.handler, value.keyword)
                obj.handler.(value.keyword)(obj, value, location, checks);
            end
        end
        
        function passed = check_multipolygon(obj, value, location)

            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end

            passed = wkt_strcmp(value.keyword, 'MULTIPOLYGON');

            if ~passed
                return
            end
            
            [passed, value.N_dimensions, value.has_z, value.has_m, value.is_empty] = obj.check_n_dimensions(value, location);
            
            if ~passed
                return
            end
            
            if ~value.is_empty
                guard = hdng.wkt.WKTAuditScopeGuard(obj);

                checks = cell(0,1);

                checks{end + 1, 1} = wkt_attribute_check(1, Inf, false, ...
                            @(obj, raw_value, location) obj.check_polygon(raw_value, location, true, value));

                [passed, checks] = obj.run_wkt_attribute_checks(value, location, 1, checks);

                obj.result = obj.scope;
                delete(guard);
            else
                checks = cell(0,1);
            end
            
            if passed && isfield(obj.handler, value.keyword)
                obj.handler.(value.keyword)(obj, value, location, checks);
            end
        end
        
        function passed = check_geometrycollection(obj, value, location)

            passed = obj.check_keyword_struct(value, location);

            if ~passed
                return
            end

            passed = wkt_strcmp(value.keyword, 'GEOMETRYCOLLECTION');

            if ~passed
                return
            end
            
            [passed, value.N_dimensions, value.has_z, value.has_m, value.is_empty] = obj.check_n_dimensions(value, location);
            
            if ~passed
                return
            end
            
            if value.has_z || value.has_m
                passed = false;
                return
            end
            
            if ~value.is_empty
                guard = hdng.wkt.WKTAuditScopeGuard(obj);

                checks = cell(0,1);

                checks{end + 1, 1} = wkt_attribute_check(1, Inf, false, ...
                            @(obj, value, location) obj.check_geometry(value, location, true));

                [passed, checks] = obj.run_wkt_attribute_checks(value, location, 1, checks);

                obj.result = obj.scope;
                delete(guard);
            else
                checks = cell(0,1);
            end
            
            if passed && isfield(obj.handler, value.keyword)
                obj.handler.(value.keyword)(obj, value, location, checks);
            end
        end
    end
end



function [descriptor] = wkt_attribute_check(min_occ, max_occ, occ_optional, handler)

    descriptor = struct();
    descriptor.occ = cast(0, 'int64');
    descriptor.min_occ = min_occ;
    descriptor.max_occ = max_occ;
    descriptor.exact_occ = [];
    descriptor.occ_is_optional = occ_optional;
    descriptor.handler = handler;
    descriptor.occ_indices = cell(0,1);
end


function [descriptor] = wkt_exact_attribute_check(exact_occ, occ_optional, handler)

    descriptor = struct();
    descriptor.occ = cast(0, 'int64');
    descriptor.min_occ = 0;
    descriptor.max_occ = 0;
    descriptor.exact_occ = exact_occ;
    descriptor.occ_is_optional = occ_optional;
    descriptor.handler = handler;
    descriptor.occ_indices = cell(0,1);
end

function result = wkt_strcmp(left, right)
    result = strcmpi(left, right);
end
