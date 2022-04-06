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

classdef ValueGenerator < handle
    
    %ValueGenerator Encapsulates a method of generating variable values.
    %
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = ValueGenerator()
        end
        
        
        function varargout = subsref(obj,s)
            
            switch s(1).type
               
                case '()'
                    
                    arguments = obj.prepare_arguments(s(1).subs{:});
                    
                    result = obj.create_iterator(arguments);
                    
                    if numel(s) > 1
                    
                        [varargout{1:nargout}] = builtin('subsref',result,s(2:end));
                    else
                        varargout = { result };
                    end
                    
                otherwise
                    [varargout{1:nargout}] = builtin('subsref',obj,s);
            end
        end
        
    end
    
    methods (Access=protected)
        
        function arguments = prepare_arguments(~, arguments)
            
            names = fieldnames(arguments);
            
            for index=1:numel(names)
                name = names{index};
                value = arguments.(name);
                arguments.(name) = value.content;
            end
            
        end
        
        function result = create_iterator(~, arguments) %#ok<INUSD>
            result = hdng.experiments.ValueIterator();
        end
    end
    
    methods (Static, Access=public)
    end
    
end
