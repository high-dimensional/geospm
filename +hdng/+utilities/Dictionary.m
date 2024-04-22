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

classdef Dictionary < handle
    %Dictionary Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
        length
    end
    
    properties (GetAccess = private, SetAccess = private)
        fields__
    end
    
    methods
        
        function obj = Dictionary(varargin)
            fields = hdng.utilities.OrderedMap('KeyType', 'char', 'ValueType', 'any');
            obj = builtin('subsasgn', obj, substruct('.', 'fields__'), fields);
            
            assignments = hdng.utilities.parse_struct_from_varargin(varargin{:});
            names = fieldnames(assignments);
            
            for index=1:numel(names)
                name = names{index};
                value = assignments.(name);
                fields(name) = value;
            end
        end
        
        function result = get.length(obj)
            result = length(obj.fields__); %#ok<CPROP>
        end
        
        function result = copy(obj, dict)
            
            if ~exist('dict', 'var')
                result = hdng.utilities.Dictionary();
            else
                result = dict;
            end
            
            keys = obj.keys();
            
            for index=1:numel(keys)
                key = keys{index};
                fields = builtin('subsref', obj, substruct('.', 'fields__'));
                value = fields(key);
                fields = builtin('subsref', result, substruct('.', 'fields__'));
                fields(key) = value; %#ok<NASGU>
            end
        end
        
        function result = holds_key(obj, key)
            result = isKey(obj.fields__, key);
        end
        
        function result = keys(obj)
            
            fields = builtin('subsref', obj, substruct('.', 'fields__'));
            result = keys(fields)';
        end
        
        function result = values(obj)
            
            fields = builtin('subsref', obj, substruct('.', 'fields__'));
            result = values(fields)';
        end
        
        function remove(obj, key)
            fields = builtin('subsref', obj, substruct('.', 'fields__'));
            remove(fields, key);
        end

        function n = numArgumentsFromSubscript(obj, s, indexingContext)
           
            switch s(1).type
            
                case {'()'}

                    if indexingContext == matlab.mixin.util.IndexingContext.Expression
                        n = 1;
                    else
                        n = builtin('numArgumentsFromSubscript', obj, s, indexingContext);
                    end

                otherwise
                    n = builtin('numArgumentsFromSubscript', obj, s, indexingContext);
            end
        end
        
        function varargout = subsref(obj,s)
            
           switch s(1).type
               
              case '()'
                 
                 if numel(s(1).subs) > 1
                     error('hdng.utilities.Dictionary(): Only one subscript argument is supported.');
                 end
                  
                 fields = builtin('subsref', obj, substruct('.', 'fields__'));
                 
                 if isa(fields, 'hdng.utilities.Dictionary')
                     fields = builtin('subsref', fields, substruct('.', 'fields__'));
                 end

                 if ~isa(fields, 'containers.Map')
                     varargout = {hdng.utilities.DictionaryError()};
                     return
                 end

                 key = s(1).subs{1};

                 if ~isKey(fields, key)
                     varargout = {hdng.utilities.DictionaryError()};
                     return
                 end

                 fields = fields(key);
                 
                 if numel(s) > 1
                    varargout = {subsref(fields, s(2:end))};
                 else
                    varargout = {fields};
                 end
                 
              otherwise
              	 [varargout{1:nargout}] = builtin('subsref',obj,s);
           end
        end
        
        function obj = subsasgn(obj,s, varargin)

           % Allow subscripted assignment to uninitialized variable
           
           switch s(1).type
               
              case '()'
                 
                 fields = builtin('subsref', obj, substruct('.', 'fields__'));
                 
                 N = numel(s(1).subs);
                 previous_key = '';
                 
                 for index=1:N - 1
                    
                    key = s(1).subs{index};
                    
                    if isa(fields, 'hdng.utilities.Dictionary')
                        fields = builtin('subsref', fields, substruct('.', 'fields__'));
                    end
                    
                    if ~isa(fields, 'containers.Map')
                        error('Dictionary: Field ''%s'' is not a key container.', previous_key);
                    end
                    
                    if ~isKey(fields, key)
                        % error('Dictionary: Field ''%s'' is missing.', key);
                        fields(key) = hdng.utilities.Dictionary();
                    end
                    
                    fields = fields(key);
                    previous_key = key;
                 end

                 if isa(fields, 'hdng.utilities.Dictionary')
                     fields = builtin('subsref', fields, substruct('.', 'fields__'));
                 end
                 
                 if ~isa(fields, 'containers.Map')
                    error('Dictionary: Field ''%s'' is not a key container.', previous_key);
                 end

                 fields(s(1).subs{N}) = varargin{1}; %#ok<NASGU>
                 
                 %s(1).subs = s(1).subs(N);
                 %fields = builtin('subsasgn', fields, s, varargin);
                 
              otherwise
                 obj = builtin('subsasgn', obj, s, varargin);
           end
        end
    end
    
    methods (Static)
        function result = from_containers_Map(map)
            result = hdng.utilities.Dictionary();
            
            keys = map.keys();
            
            for index=1:numel(keys)
                key = keys{index};
                result(key) = map(key);
            end
            
        end
    end
    
    methods (Access = protected)
    end
    
end
