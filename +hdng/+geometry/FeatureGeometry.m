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

classdef FeatureGeometry < handle
    %FeatureGeometry Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
        has_crs
        crs
        collection
        primitive_type
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = FeatureGeometry()
        end
        
        function result = get.has_crs(obj)
            result = obj.access_has_crs();
        end
        
        function result = get.crs(obj)
            result = obj.access_crs();
        end
        
        function result = get.collection(obj)
            result = obj.access_collection();
        end
        
        function result = get.primitive_type(obj)
            result = obj.access_primitive_type();
        end
        
        
        function save(obj, file_path, optional_attributes, varargin)
            
            if ~exist('optional_attributes', 'var')
                optional_attributes = {};
            end
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            [directory, basename, ext] = fileparts(file_path);
            projection_path = fullfile(directory, [basename '.prj']);
            
            write_prj_file = true;
            
            if strcmpi(ext, '.shp')
                
                shapevector = obj.collection.as_shapevector();
                hdng.geometry.FeatureGeometry.safe_shapewrite(shapevector, file_path);
            else
                error(['save(): Unrecognized feature geometry file format: ''' file_path '''']);
            end
            
            if ~isempty(obj.crs) && write_prj_file
                obj.crs.save(projection_path);
            end
        end
    end
    
    methods (Static)
        
        function safe_shapewrite(shapevector, file_path)
            
            N = numel(shapevector);
            
            if N > 1
                shapewrite(shapevector, file_path);
                return;
            end

            is_empty = N == 0;
            geometry = 'Null Shape';

            if ~is_empty && isfield(shapevector, 'X')
                geometry = shapevector.Geometry;
                is_empty = isempty(shapevector.X);
            elseif ~is_empty && isfield(shapevector, 'Lat')
                geometry = shapevector.Geometry;
                is_empty = isempty(shapevector.Lat);
            end

            if is_empty
                hdng.geometry.FeatureGeometry.write_empty_shapefile(file_path, geometry);
                [dir, file_name, ~] = fileparts(file_path);
                hdng.geometry.FeatureGeometry.write_empty_shapefile(fullfile(dir, [file_name, '.shx']), geometry);
            else
                shapewrite(shapevector, file_path);
            end
        end
        
        function write_empty_shapefile(file_path, geometry)
            
            switch geometry
                case 'Null Shape'
                    shapeType = 0;
                case 'Point'
                    shapeType = 1;
                case 'Line'
                    shapeType = 3;
                case 'Polygon'
                    shapeType = 5;
                otherwise
                    shapeType = 0;
            end

            fid = fopen(file_path, "w", "n");

            fileCode = 9994;
            version  = 1000;

            fileLengthInWords = 50;
            boundingBox = [0, 0, 0, 0];
            
            bytes0thru27 = int32([fileCode 0 0 0 0 0 fileLengthInWords]);
            fwrite(fid, bytes0thru27, 'int32', 'ieee-be');
            % Check that count = 7
            
            bytes28thru35 = int32([version shapeType]);
            fwrite(fid, bytes28thru35, 'int32', 'ieee-le');
            % Check that count = 2
            
            bytes36thru99 = [boundingBox 0 0 0 0];
            fwrite(fid, bytes36thru99, 'double', 'ieee-le');
            % Check that count = 8
            
            % fwrite(fid, int32([1 2 0]), 'int32', 'ieee-be');

            fclose(fid);
        end

        function result = define(collection, optional_crs)
            if ~exist('optional_crs', 'var')
                optional_crs = hdng.SpatialCRS.empty;
            end
            
            result = hdng.geometry.impl.FeatureGeometryImpl(collection, optional_crs);
        end
        
        function [result, attributes] = load(file_path, optional_crs, varargin)
            
            attributes = {};
            
            if ~exist('optional_crs', 'var')
                optional_crs = hdng.SpatialCRS.empty;
            end
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            [directory, basename, ext] = fileparts(file_path);
            projection_path = fullfile(directory, [basename '.prj']);
            
            if strcmpi(ext, '.shp')
                
                collection = hdng.geometry.Collection.from_shapefile(file_path);
                
                if isempty(optional_crs) && isfile(projection_path)
                    optional_crs = hdng.SpatialCRS.from_file(projection_path);
                end
            elseif strcmpi(ext, '.wkt')
                
                collection = hdng.geometry.Collection.from_wkt(file_path);
                
                if isempty(optional_crs) && isfile(projection_path)
                    optional_crs = hdng.SpatialCRS.from_file(projection_path);
                end
            elseif strcmpi(ext, '.csv')

                if ~isfield(options, 'csv')
                    options.csv = struct();
                end
                
                csv_arguments = hdng.utilities.struct_to_name_value_sequence(options.csv);
                [collection, attributes] = hdng.geometry.Collection.from_csv(file_path, csv_arguments{:});
                
                if isempty(optional_crs) && isfile(projection_path)
                    optional_crs = hdng.SpatialCRS.from_file(projection_path);
                end
                
            else
                error(['load(): Unrecognized feature geometry file format: ''' file_path '''']);
            end
            
            result = hdng.geometry.FeatureGeometry.define(collection, optional_crs);
        end
    end
    
    
    methods (Static, Access = protected)
    end
    
    methods (Access = protected)
        
        function result = access_has_crs(~) %#ok<STOUT>
            error('access_has_crs() must be implemented by a subclass.');
        end
        
        function result = access_crs(~) %#ok<STOUT>
            error('access_crs() must be implemented by a subclass.');
        end
        
        function result = access_collection(~) %#ok<STOUT>
            error('access_collection() must be implemented by a subclass.');
        end
        
        function result = access_primitive_type(obj)
            result = obj.collection.element_type;
        end
    end
end
