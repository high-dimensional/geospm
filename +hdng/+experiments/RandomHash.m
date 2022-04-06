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

classdef RandomHash < handle
    %RandomHash Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
        seed
        state
    end
     
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
        
        hash_engine
        numbers
    end
    
    methods
        
        function obj = RandomHash(seed)
            
            obj.hash_engine = java.security.MessageDigest.getInstance('SHA-256');
            obj.seed = seed;
            obj.state = RandStream('mt19937ar', 'Seed', obj.seed);
            obj.numbers = obj.state.randi(intmax('uint8'), [32, 1], 'uint8');
        end
        
        function result = for_strings(obj, strings, result_type)
            
            if ~exist('result_type', 'var')
                result_type = 'uint64';
            end
            
            switch result_type
                
                case 'uint8'
                    W = 1;
                case 'uint16'
                    W = 2;
                case 'uint32'
                    W = 4;
                case 'uint64'
                    W = 8;
                    
                otherwise
                    error('Unsupported result type: %s', result_type);
            end
            
            K = numel(strings);
            
            obj.hash_engine.reset();
            obj.hash_engine.update(obj.numbers);
            
            for i=1:K
                part = strings{i};
                obj.hash_engine.update(unicode2native(part, 'UTF-8'));
            end
            
            result = typecast(obj.hash_engine.digest(), 'uint8');
            
            B = numel(result);
            
            seed_bytes = repmat(cast(255, 'uint8'), W, 1);
            
            for i=1:B
                p = mod(i - 1, W) + 1;
                seed_bytes(p) = bitxor(seed_bytes(p), result(i));
            end
            
            result = zeros(1, 1, result_type);
            
            for i=1:W
                s = W * (i - 1);
                result = bitor(result, bitshift(cast(seed_bytes(i), result_type), s));
            end
            
            result = mod(result, intmax(result_type));
        end
    end
end
