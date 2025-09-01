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

classdef DirectoryScope < hdng.diagrams.rendering.RenderScope
    %DirectoryScope Summary.
    %   Detailed description 
    
    properties
    end
    
    properties (Dependent, Transient)
    end

    properties (Access=private)
        saved_directory
    end
    
    methods
        
        function obj = DirectoryScope(varargin)

            obj@hdng.diagrams.rendering.RenderScope(varargin{:});

            %options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            obj.saved_directory = '';
        end

        function enter(obj, context)

            enter@hdng.diagrams.rendering.RenderScope(obj, context);
            
            if isempty(context.base_directory)
                error('No base directory defined in render context.');
            end
            
            directory_path = fullfile(context.base_directory, obj.name);
            
            [status, msg, msgID] = mkdir(directory_path);

            if ~status
                error(msgID, msg);
            end
            
            obj.saved_directory = context.directory;
            context.directory = directory_path;

        end
        
        function exit(obj, context)
            exit@hdng.diagrams.rendering.RenderScope(obj, context);
            context.directory = obj.saved_directory;
        end
    end
end
