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

classdef OrderedMap < containers.Map
    %OrderedMap Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
        firstKey
        lastKey
    end
    
    properties (GetAccess = private, SetAccess = private)
        order
        first
        last
    end
    
    methods
        
        function obj = OrderedMap(varargin)
            obj = obj@containers.Map(varargin{:});
            obj.order = containers.Map('KeyType', obj.KeyType, 'ValueType', 'any');
            obj.first = [];
            obj.last = [];
        end
        
        function result = get.firstKey(obj)
            
            if obj.Count == 0
                result = missing;
                return
            end
            
            result = obj.first{1};
        end
        
        function result = get.lastKey(obj)
            
            if obj.Count == 0
                result = missing;
                return
            end
            
            result = obj.last{1};
        end
        
        function result = keys(obj)
            
            result = cell(1, obj.Count);
            
            if obj.Count == 0
                result = {};
                return;
            end
            
            key = obj.first{1};
            
            for index=1:obj.Count
                link = obj.order(key);
                result{index} = key;
                
                if index + 1 <= obj.Count
                    key = link.next{1};
                elseif ~isempty(link.next)
                    error('hdng.utilities.OrderedMap.keys(): Detected internal inconsistency.');
                end
            end
        end
        
        function obj = remove(obj, keySet)
            obj = remove@containers.Map(obj, keySet);
            
            if ~iscell(keySet)
                keySet = { keySet };
            end
            
            for index=1:numel(keySet)
                key = keySet{index};
                obj.remove_key(key);
            end
        end
        
        function obj = subsasgn(obj, s, varargin)
           
            obj = subsasgn@containers.Map(obj, s, varargin{:});
            
            if numel(s) == 1
               
                switch s(1).type

                    case '()'

                        key = s(1).subs{1};
                        obj.add_key(key);
                end
            end
        end
        
        function result = jsonencode(obj, varargin)
            
            result = '';
            keys = obj.keys();
            
            for index=1:numel(keys)
                key = keys{index};
                value = subsref(obj, substruct('()', key));
                delim = ',';
                
                if index + 1 > numel(keys)
                    delim = '';
                end
                
                result = [result sprintf('%s:%s%s', jsonencode(key, varargin{:}), jsonencode(value, varargin{:}), delim)]; %#ok<AGROW>
            end
            
            result = ['{' result '}'];
        end
        
    end
    
    methods (Static)
    end
    
    methods (Access = protected)
        
        function result = create_key_link(obj) %#ok<MANU>
            
            result = struct();
            result.previous = [];
            result.next = [];
        end
        
        function add_key(obj, key)
            
            if isKey(obj.order, key)
                return
            end
            
            link = obj.create_key_link();
            link.previous = obj.last;
            
            obj.order(key) = link;
            
            if ~isempty(obj.last)
                last_key = obj.last{1};
                last_link = obj.order(last_key);
                last_link.next = { key };
                obj.order(last_key) = last_link;
            end
            
            obj.last = { key };
            
            if isempty(obj.first)
                obj.first = { key };
            end
        end
        
        function remove_key(obj, key)
            
            if ~isKey(obj.order, key)
                return
            end
            
            link = obj.order(key);
            
            if ~isempty(link.previous)
                previous_key = link.previous{1};
                previous_link = obj.order(previous_key);
                previous_link.next = link.next;
                obj.order(previous_key) = previous_link;
            end
            
            if ~isempty(link.next)
                next_key = link.next{1};
                next_link = obj.order(next_key);
                next_link.previous = link.previous;
                obj.order(next_key) = next_link;
            end
            
            remove(obj.order, key);
            
            if strcmp(obj.first{1}, key)
                obj.first = link.next;
            end
            
            if strcmp(obj.last{1}, key)
                obj.last = link.previous;
            end
        end
    end
    
end
