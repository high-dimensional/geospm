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

classdef RequestStatus < handle
    
    %RequestStatus [Description]
    %
    
    properties
        transfer_size
        expected_size
        stop_reason
        error_message
        http_code
    end
    
    methods
        
        function obj = RequestStatus(transfer_size, expected_size, stop_reason, error_message, http_code)

            if ~exist('http_code', 'var')
                http_code = [];
            end

            if ~exist('error_message', 'var')
                error_message = [];
            end

            if ~exist('stop_reason', 'var')
                stop_reason = '';
            end

            if ~exist('expected_size', 'var')
                expected_size = [];
            end

            if ~exist('transfer_size', 'var')
                transfer_size = 0;
            end

            obj.transfer_size = transfer_size;
            obj.expected_size = expected_size;
            obj.stop_reason = stop_reason;
            obj.error_message = error_message;
            obj.http_code = http_code;
        end
    end
end
