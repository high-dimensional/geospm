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

classdef Diagnostic < handle
    %Diagnostic Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        INFO_STATUS = 'info'
        WARNING_STATUS = 'warning'
        ERROR_STATUS = 'error'
    end
    
    properties
        status
        message
    end
    
    
    methods
        
        function obj = Diagnostic()
            obj.status = hdng.patch.Diagnostic.INFO_STATUS;
            obj.message = '';
        end
    end
    
    methods (Static)
        
        function result = info(message, varargin)
            result = hdng.patch.Diagnostic();
            result.status = hdng.patch.Diagnostic.INFO_STATUS;
            result.message = sprintf(message, varargin{:});
        end
        
        function result = warning(message, varargin)
            result = hdng.patch.Diagnostic();
            result.status = hdng.patch.Diagnostic.WARNING_STATUS;
            result.message = sprintf(message, varargin{:});
        end
        
        function result = error(message, varargin)
            result = hdng.patch.Diagnostic();
            result.status = hdng.patch.Diagnostic.ERROR_STATUS;
            result.message = sprintf(message, varargin{:});
        end
        
    end
    
end
