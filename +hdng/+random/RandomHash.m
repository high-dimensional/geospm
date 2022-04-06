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

classdef RandomHash < handle
    %RandomHash Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess = private, SetAccess = private)
        stream_
        hash_prefix_
        hash_suffix_
    end
    
    methods
        
        function obj = RandomHash(seed)
            
            if ~exist('seed', 'var')
                seed = 'shuffle';
            end
            
            obj.stream_ = RandStream('mlfg6331_64', 'Seed', seed);
            
            obj.hash_prefix_ = cast(obj.stream_.randi(256, 1, obj.stream_.randi(100, 1)) - 1, 'uint8');
            obj.hash_suffix_ = cast(obj.stream_.randi(256, 1, obj.stream_.randi(100, 1)) - 1, 'uint8');
        end
        
        function result = rand(obj, varargin)
            result = obj.stream_.rand(varargin{:});
        end
        
        function result = randn(obj, varargin)
            result = obj.stream_.randn(varargin{:});
        end
        
        function result = randi(obj, varargin)
            result = obj.stream_.randi(varargin{:});
        end
        
        function result = randperm(obj, varargin)
            result = obj.stream_.randperm(varargin{:});
        end
        
        function result = hash(obj, string)
        
            persistent hash_function
            
            if isempty(hash_function)
                hash_function = java.security.MessageDigest.getInstance('SHA-256');
            end
            
            string_bytes = [obj.hash_prefix_, uint8(string), obj.hash_suffix_];
            hash_values = typecast(hash_function.digest(string_bytes), 'uint64');
            
            result = 0;
            
            for i=1:numel(hash_values)
                result = bitxor(result, hash_values(i));
            end
            
        end
    end
    
    methods (Static)
        
    end
    
    
end
