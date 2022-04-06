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

classdef WKTAuditScopeGuard < matlab.mixin.Copyable
    %WKTAuditScopeGuard Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
        audit
    end
    
    methods
        
        function obj = WKTAuditScopeGuard(audit)
            
            obj.audit = audit;
            obj.audit.enter_scope();
        end
        
        function delete(obj)
            obj.audit.leave_scope();
        end
    end
end
