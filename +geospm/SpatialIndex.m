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

classdef SpatialIndex < geospm.BaseSpatialIndex
    %SpatialIndex A spatial index stores coordinates grouped
    % into segments.
    %
    
    properties (GetAccess = private, SetAccess = private)
        
        x_
        y_
        z_

        extra_data_

        segment_sizes_

        segment_index_
        segment_offsets_

        x_min_
        x_max_
        
        y_min_
        y_max_
        
        z_min_
        z_max_
        
        centroid_xyz_
    end
    
    methods
        
        function obj = SpatialIndex(x, y, z, segment_sizes, crs, extra_data)
            %Construct a SpatialIndex object from x, y and z vectors and an
            %optional CRS.
            % x ? x locations
            % y ? y locations
            % z ? z locations or empty
            % segment_sizes ?  
            % crs ? coordinate reference system or empty
            
            if ~exist('crs', 'var')
                crs = hdng.SpatialCRS.empty;
            end
            
            if ~exist('extra_data', 'var')
                extra_data = [];
            end
            
            if ~ismatrix(x) || size(x, 2) ~= 1
                error('''x'' is not a numeric value; specify ''x'' as a N x 1 matrix');
            end
            
            if ~ismatrix(y) || size(y, 2) ~= 1
                error('''y'' is not a numeric value; specify ''y'' as a N x 1 matrix');
            end
            
            if ~ismatrix(z)
                error('''z'' is not a numeric value; specify ''z'' as a N x 1 matrix or []');
            end
            
            if size(x, 1) ~= size(y, 1)
                error('The number of elements in ''x'' (=%d) and ''y'' (=%d) do not match; specify both ''x'' and ''y'' as a N x 1 matrix', size(x,1), size(y,1));
            end
            
            if isempty(z)
                z = zeros(size(x));
            end
            
            if size(z, 2) ~= 1
                error('''z'' is not a numeric value; specify ''z'' as a N x 1 matrix or []');
            end
            
            if size(x, 1) ~= size(z, 1)
                error('The number of elements in ''x'' (=%d) and ''z'' (=%d) do not match; specify ''x'', ''y'' and ''z'' each as a N x 1 matrix', size(x,1), size(z,1));
            end

            if isempty(segment_sizes)
                segment_sizes = ones(size(x, 1), 1);
            end
            

            if ~isempty(extra_data) && ~ismatrix(extra_data)
                error('''extra_data'' is not a numeric matrix.');
            end
            
            if ~isempty(extra_data) && size(x, 1) ~= size(extra_data, 1)
                error('The number of rows in ''x'' (=%d) and ''extra'' (=%d) do not match; specify ''extra_data''as a N x k matrix', size(x,1), size(extra_data,1));
            end
            
            obj = obj@geospm.BaseSpatialIndex(size(x, 1), crs);
            
            obj.x_ = x;
            obj.y_ = y;
            obj.z_ = z;

            obj.extra_data_ = extra_data;
            
            obj.segment_sizes_ = segment_sizes;
            [obj.segment_index_, obj.segment_offsets_] = obj.segment_indices_from_segment_sizes(size(x, 1), segment_sizes);
        end
        
        function [x, y, z] = xyz_coordinates_for_segment(obj, segment_index)
            
            [first, last] = obj.range_for_segment(segment_index);

            x = obj.x(first:last);
            y = obj.y(first:last);
            z = obj.z(first:last);
        end
        
        function result = row_indices_from_segment_indices(obj, segment_indices)
            
            row_selection = zeros(obj.N, 1, 'logical');

            for index=1:numel(segment_indices)
                segment = segment_indices(index);

                first = obj.segment_offsets(segment);
                last = first + obj.segment_sizes(segment) - 1;

                row_selection(first:last) = 1;
            end

            result = find(row_selection);
        end

        function result = segment_indices_from_row_indices(obj, row_indices)
            result = unique(obj.segment_index(row_indices));
        end
        
        function result = select_by_segment(obj, segment_selection, transform)
        
            if ~exist('segment_selection', 'var')
                segment_selection = [];
            end
            
            if isempty(segment_selection)
                segment_selection = 1:obj.S;
            end

            if ~isnumeric(segment_selection)
                
                if islogical(segment_selection)
                    if numel(segment_selection) ~= obj.S
                        error('select_by_segment(): The length of a logical segment selection vector must be equal to the number of segments.');
                    end
                else
                    error('select_by_segment(): segment selection vector must be a numeric or logical array.');
                end
            else
                segment_selection = segment_selection(:);

                try
                    tmp = (1:obj.S)';
                    tmp = tmp(segment_selection); %#ok<NASGU>
                    clear('tmp');
                catch
                    error('select_by_segment(): One or more segment selection indices are out of bounds.');
                end
            end
            
            if ~exist('transform', 'var')
                transform = @(specifier, modifier) specifier;
            end

            row_selection = obj.row_indices_from_segment_indices(segment_selection);
            result = obj.select(row_selection, [], transform);
        end
       
        function result = as_json_struct(obj, varargin)
            %Creates a JSON representation of this SpatialIndex object.
            % The following fields can be provided in the options
            % argument:
            % None so far.
            
            [~] = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            specifier = struct();
            
            specifier.ctor = 'geospm.SpatialIndex';

            specifier.crs = '';

            if ~isempty(obj.crs)
                specifier.crs = obj.crs.identifier;
            end

            specifier.N = obj.N;
            specifier.S = obj.S;

            specifier.x = obj.x;
            specifier.y = obj.y;
            specifier.z = obj.z;
            
            specifier.segment_index = obj.segment_index;
            specifier.segment_sizes = obj.segment_sizes;
            specifier.segment_offsets = obj.segment_offsets;
            
            result = specifier;
        end
    end
    
    methods (Access=protected)


        function result = access_x(obj)
            result = obj.x_;
        end
        
        function result = access_y(obj)
            result = obj.y_;
        end

        function result = access_z(obj)
            result = obj.z_;
        end
        
        function result = access_segment_sizes(obj)
            result = obj.segment_sizes_;
        end
        
        function result = access_S(obj)
            result = size(obj.segment_sizes, 1);
        end
        
        function result = access_segment_index(obj)
            result = obj.segment_index_;
        end
        
        function result = access_segment_offsets(obj)
            result = obj.segment_offsets_(1:end - 1);
        end
        
        function result = access_x_min(obj)
            if isempty(obj.x_min_)
                obj.x_min_ = min(obj.x);
            end
            
            result = obj.x_min_;
        end
        
        function result = access_x_max(obj)
            if isempty(obj.x_max_)
                obj.x_max_ = max(obj.x);
            end
            
            result = obj.x_max_;
        end
        
        function result = access_y_min(obj)
            if isempty(obj.y_min_)
                obj.y_min_ = min(obj.y);
            end
            
            result = obj.y_min_;
        end
        
        function result = access_y_max(obj)
            if isempty(obj.y_max_)
                obj.y_max_ = max(obj.y);
            end
            
            result = obj.y_max_;
        end
        
        function result = access_z_min(obj)
            if isempty(obj.z_min_)
                obj.z_min_ = min(obj.z);
            end
            
            result = obj.z_min_;
        end
        
        function result = access_z_max(obj)
            if isempty(obj.z_max_)
                obj.z_max_ = max(obj.z);
            end
            
            result = obj.z_max_;
        end
        
        function result = access_min_xy(obj)
            result = [obj.x_min, obj.y_min];
        end
        
        function result = access_max_xy(obj)
            result = [obj.x_max, obj.y_max];
        end
        
        function result = access_span_xy(obj)
            result = obj.max_xy - obj.min_xy;
        end
        
        function result = access_min_xyz(obj)
            result = [obj.x_min, obj.y_min, obj.z_min];
        end
        
        function result = access_max_xyz(obj)
            result = [obj.x_max, obj.y_max, obj.z_max];
        end

        function result = access_span_xyz(obj)
            result = obj.max_xyz - obj.min_xyz;
        end
        
        function result = access_centroid_x(obj)
            result = obj.centroid_xyz(1);
        end
        
        function result = access_centroid_y(obj)
            result = obj.centroid_xyz(2);
        end
        
        function result = access_centroid_z(obj)
            result = obj.centroid_xyz(3);
        end
        
        function result = access_centroid_xyz(obj)
            if isempty(obj.centroid_xyz_)
                obj.centroid_xyz_ = [mean(obj.x), mean(obj.y), mean(obj.z)];
            end
            
            result = obj.centroid_xyz_;
        end

        function result = access_square_min_xy(obj)
            span = obj.max_xy - obj.min_xy;
            d = max(span);
            offsets = (span - d) / 2;
            result = obj.min_xy + offsets;
        end

        function result = access_square_max_xy(obj)
            span = obj.max_xy - obj.min_xy;
            d = max(span);
            offsets = (span - d) / 2;
            result = obj.max_xy - offsets;
        end
        
        function result = access_square_xy(obj)
            span = obj.max_xy - obj.min_xy;
            d = max(span);
            offsets = (span - d) / 2;
            square_min = obj.min_xy + offsets;
            square_max = obj.max_xy - offsets;
            result = [square_min; square_max];
        end

        function result = access_cube_min_xyz(obj)
            span = obj.max_xyz - obj.min_xyz;
            d = max(span);
            offsets = (span - d) / 2;
            result = obj.min_xyz + offsets;
        end

        function result = access_cube_max_xyz(obj)
            span = obj.max_xyz - obj.min_xyz;
            d = max(span);
            offsets = (span - d) / 2;
            result = obj.max_xyz - offsets;
        end
        

        function result = access_cube_xyz(obj)
            span = obj.max_xyz - obj.min_xyz;
            d = max(span);
            offsets = (span - d) / 2;
            cube_min = obj.min_xyz + offsets;
            cube_max = obj.max_xyz - offsets;
            result = [cube_min; cube_max];
        end
        
        function result = access_xyz(obj)
            result = [obj.x, obj.y, obj.z];
        end
        
        function assign_property(obj, name, values)
            obj.(name) = values;
        end

        function [first, last] = range_for_segment(obj, segment_index)
            first = obj.segment_offsets_(segment_index);
            last = obj.segment_offsets_(segment_index + 1) - 1;
        end
        
        function [specifier, modifier] = define_clone_specifier(obj)
            
            [specifier, modifier] = define_clone_specifier@geospm.BaseSpatialIndex(obj);
            
            specifier.per_row.x = obj.x;
            specifier.per_row.y = obj.y;
            specifier.per_row.z = obj.z;
            specifier.per_row.segment_index = obj.segment_index;

            specifier.segment_sizes = obj.segment_sizes;
            specifier.segment_offsets = obj.segment_offsets_;
        end

        function result = create_clone_from_specifier(~, specifier)
            
            specifier_segment_sizes = ...
                geospm.SpatialIndex.segment_indices_to_segment_sizes(...
                    specifier.per_row.segment_index);

            result = geospm.SpatialIndex(specifier.per_row.x, ...
                                         specifier.per_row.y, ...
                                         specifier.per_row.z, ...
                                         specifier_segment_sizes, ...
                                         specifier.crs);
        end

    end

    methods (Static)

        function result = from_json_struct_impl(specifier)
            
            if ~isfield(specifier, 'x') || ~isnumeric(specifier.x)
                error('Missing ''x'' field in json struct or ''x'' field is not numeric.');
            end
            
            if ~isfield(specifier, 'y') || ~isnumeric(specifier.y)
                error('Missing ''y'' field in json struct or ''y'' field is not numeric.');
            end
            
            if ~isfield(specifier, 'z') || ~isnumeric(specifier.z)
                error('Missing ''z'' field in json struct or ''z'' field is not numeric.');
            end
            
            if ~isfield(specifier, 'segment_sizes') || ~isnumeric(specifier.segment_sizes)
                error('Missing ''segment_sizes'' field in json struct or ''segment_sizes'' field is not numeric.');
            end
            
            if isfield(specifier, 'crs') && ~ischar(specifier.crs)
                error('''crs'' field is not char.');
            end
            
            crs = '';

            if isfield(specifier, 'crs') && ~isempty(specifier.crs)
                crs = specifier.crs;
            end
            
            result = geospm.SpatialIndex(specifier.x, specifier.y, specifier.z, specifier.segment_sizes, crs);

        end
    end
end
