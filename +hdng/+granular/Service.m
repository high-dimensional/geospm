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

classdef Service < handle
    
    %Service Description to follow.
    
    properties
    end
    
    
    properties (GetAccess=public, SetAccess=private)
    end

    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = Service()
        end
        
        function connection = connect(~, url)
            connection = hdng.granular.Connection(url);
        end
        
    end
    
    methods (Access=protected)
        
    end
    
    methods (Static, Access=public)

        function obj = local_instance()

            persistent instance;

            if isempty(instance)
                instance = hdng.granular.Service();
            end

            obj = instance;
        end

    end
    
end
