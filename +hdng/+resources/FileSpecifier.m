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

classdef FileSpecifier < handle
    %FileSpecifier Summary.
    %   Detailed description 
    
    properties
        source_ref
        path
        type
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = FileSpecifier(varargin)

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'source_ref')
                options.source_ref = '';
            end

            if ~isfield(options, 'path')
                options.path = '';
            end

            if ~isfield(options, 'type')
                options.type = 'binary';
            end

            obj.source_ref = options.source_ref;
            obj.path = options.path;
            obj.type = options.type;
        end
    end
end
