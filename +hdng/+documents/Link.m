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

classdef Link < handle
    
    %Link [Description]
    %
    
    properties
    end
    
    properties (Dependent, Transient)
        node
    end
    
    properties (GetAccess=private, SetAccess=private)
        node_
    end
    
    methods
        
        function result = get.node(obj)
            result = obj.node_;
        end
        
        function set.node(obj, value)
            if ~isempty(obj.node_)
                obj.node_.unlink(obj);
            end
            
            obj.node_ = value;
        end
        
        function obj = Link()
            obj.node_ = hdng.documents.Node.empty;
        end
        
        function varargout = subsref(obj,s)
            
           switch s(1).type
               
              case '()'
                 
                 if numel(s(1).subs) ~= 0
                     error('hdng.documents.Link(): Use without subscript argument.');
                 end
                  
                 node_value = builtin('subsref', obj, substruct('.', 'node'));
                 
                 if numel(s) > 1
                    varargout = {subsref(node_value, s(2:end))};
                 else
                    varargout = {node_value};
                 end
                 
              otherwise
              	 [varargout{1:nargout}] = builtin('subsref',obj,s);
           end
        end
        
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
    
end
