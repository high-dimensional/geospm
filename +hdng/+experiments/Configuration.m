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

classdef Configuration < handle
    
    %Configuration .
    %
    
    properties
        number
        schedule
        values
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = Configuration()
            obj.number = 0;
            obj.schedule = hdng.experiments.Schedule.empty;
            obj.values = hdng.utilities.Dictionary();
        end
        
        function varargout = subsref(obj,s)
            
           switch s(1).type
               
              case '()'
                 
                 values = builtin('subsref', obj, substruct('.', 'values')); %#ok<PROPLC>
                 
                 if numel(s(1).subs) <= 0
                     error('Configuration.subsref(): At least one subscript argument is required.');
                 end
                 
                 if numel(s(1).subs) > 2
                     error('Configuration.subsref(): Too many subscript arguments.');
                 end
                 
                 result = values(s(1).subs{1}); %#ok<PROPLC>
                 
                 if isa(result, 'hdng.utilities.DictionaryError') && (numel(s(1).subs) == 2)
                     result = s(1).subs{2};
                 end
                 
                 if isa(result, 'hdng.experiments.Value')
                     varargout = {result.content};
                 else
                     varargout = {result};
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
