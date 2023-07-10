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

classdef Source < handle
    
    %Source Description to follow.
    
    properties
    end
    
    
    properties (GetAccess=public, SetAccess=private)
        name
        type
        uuid
        creation_utc_timestamp
        file_root
    end

    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = Source()
            obj.name = '';
            obj.type = '';
            obj.uuid = '';
            obj.creation_utc_timestamp = struct();
            obj.file_root = '';
        end
    end
    
    methods (Access=protected)
        
    end
    
    methods (Static, Access=public)

        function source = from_json(proxy)
            source = hdng.granular.Source();
            source.name = proxy.name;
            source.type = proxy.type;
            source.uuid = proxy.uuid;
            source.creation_utc_timestamp = proxy.creation_utc_timestamp;
            source.file_root = proxy.file_root;
        end

    end
    
end
