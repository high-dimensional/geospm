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

classdef SpatialCRS < handle
    %SpatialCRS Summary goes here.
    %
    
    properties (Constant)
        
        UNKNOWN_TYPE = 0
        GEOGRAPHIC_TYPE = 1
        GEOCENTRIC_TYPE = 2
        PROJECTED_TYPE = 3
        
    end
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
        
        type
        is_projected
        
        authority_name
        authority_issued_identifier
        
        identifier
        
        wkt
        
        description
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = SpatialCRS()
        end
        
        function result = get.type(obj)
            result = obj.access_type();
        end
        
        function result = get.is_projected(obj)
            result = obj.access_is_projected();
        end
        
        function result = get.identifier(obj)
            result = obj.access_identifier();
        end
        
        function result = get.authority_name(obj)
            result = obj.access_authority_name();
        end
        
        function result = get.authority_issued_identifier(obj)
            result = obj.access_authority_issued_identifier();
        end
         
        function result = get.wkt(obj)
            result = obj.access_wkt();
        end
        
        function result = get.description(obj)
            result = obj.access_description();
        end
        
        function save(obj, file_path)
            
            [directory, ~, ext] = fileparts(file_path);
            
            if strcmpi(ext, '.prj')
                
                [dirstatus, dirmsg] = mkdir(directory);
                if dirstatus ~= 1; error(dirmsg); end

                text = obj.wkt.format_as_text();
                hdng.utilities.save_text(text, file_path);
                
            else
                error(['save(): Unrecognized spatial crs file format: ''' file_path '''']);
            end
        end
    end
    
    methods (Static)
        
        
        function result = from_identifier(identifier)
            
            parts = split(identifier, ':');
            
            if numel(parts) < 2
                error('SpatialCRS.from_identifier(): Invalid identifier. Expected authority name, followed by colon, followed by authority issued identifier.');
            end
            
            authority_name = strtrim(parts{1});
            authority_issued_identifier = join(parts(2:end), ':');
            authority_issued_identifier = strtrim(authority_issued_identifier{1});
            
            urls = {};
            
            if strcmpi(authority_name, 'EPSG')
                urls{end + 1} = ['https://spatialreference.org/ref/epsg/', authority_issued_identifier, '/prettywkt/'];
                urls{end + 1} = ['https://epsg.io/', authority_issued_identifier, '.wkt?download'];
            end
            

            wkt_result = struct();
            wkt_result.errors = {sprintf('Unknown authority name: ''%s''', authority_name)};
            wkt_result.value = hdng.wkt.WKTCoordinateSystem.empty;
            
            
            for i=1:numel(urls)
                url = urls{i};
                
                try
                    wkt_result = hdng.wkt.WKTCoordinateSystem.from_url(url);
                    
                    if isempty(wkt_result.errors)
                        break;
                    end
                    
                catch ME
                    wkt_result.errors = {ME.message};
                    continue;
                end
            end
            
            
            if ~isempty(wkt_result.errors)
                error('from_wkt_file(): Parsing coordinate reference system in WKT format produced parse errors.');
            end
            
            result = hdng.SpatialCRS.from_wkt(wkt_result.value);
        end
        
        function result = from_file(file_path)
            
            [~, ~, ext] = fileparts(file_path);
            
            result = []; %#ok<NASGU>
            
            if strcmpi(ext, '.prj') || strcmpi(ext, '.wkt')
                result = hdng.SpatialCRS.from_wkt_file(file_path);
            else
                error(['load(): Unrecognized feature crs file format: ''' file_path '''']);
            end
        end
    end
    
    
    methods (Static, Access = protected)
        
        function result = from_wkt_file(file_path)
            wkt_result = hdng.wkt.WKTCoordinateSystem.from_file(file_path);
            
            if ~isempty(wkt_result.errors)
                error('from_wkt_file(): Parsing coordinate reference system in WKT format produced parse errors.');
            end
            
            result = hdng.SpatialCRS.from_wkt(wkt_result.value);
        end
        
        function result = from_wkt(wkt_crs)
            
            authority = wkt_crs.authority;
            
            authority_name = '';
            identifier = '';
            
            if ~isempty(authority)
                authority_name = authority.name;
                identifier = authority.code;
            end
            
            result = hdng.impl.SpatialCRSImpl(authority_name, identifier, wkt_crs);
        end
        
    end
    
    methods (Access = protected)
        
        function result = access_identifier(obj)
            name = obj.authority_name;
            id = obj.authority_issued_identifier;
            
            if isempty(name) || isempty(id)
                result = '';
            else
                result = [lower(name) ':' lower(id)];
            end
        end
        
        function result = access_authority_name(~) %#ok<STOUT>
            error('access_authority_name() must be implemented by a subclass.');
        end
        
        function result = access_authority_issued_identifier(~) %#ok<STOUT>
            error('access_authority_issued_identifier() must be implemented by a subclass.');
        end
        
        function result = access_type(~) %#ok<STOUT>
            error('access_type() must be implemented by a subclass.');
        end
        
        function result = access_is_projected(obj)
            result = obj.type == hdng.SpatialCRS.PROJECTED_TYPE;
        end
        
        function result = access_wkt(~) %#ok<STOUT>
            error('access_wkt() must be implemented by a subclass.');
        end
        
        function result = access_description(~) %#ok<STOUT>
            error('access_description() must be implemented by a subclass.');
        end
        
    end
end
