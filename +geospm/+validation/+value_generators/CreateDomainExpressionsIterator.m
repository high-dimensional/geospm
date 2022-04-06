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

classdef CreateDomainExpressionsIterator < hdng.experiments.ValueIterator
    %CreateDomainExpressionsIterator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        value_generator
        index
        limit
        generator
        encodings
    end
    
    methods
        
        function obj = CreateDomainExpressionsIterator(value_generator, generator_context)
            obj = obj@hdng.experiments.ValueIterator();
            
            obj.value_generator = value_generator;
            obj.generator = generator_context.generator;
            obj.encodings = geospm.models.DomainEncodings();
            
            obj.index = 0;
            obj.limit = 1;
            
            if iscell(obj.value_generator.encoding)
                obj.limit = numel(obj.value_generator.encoding);
            end
        end
        
        function [is_valid, value] = next(obj)
            
            is_valid = obj.index < obj.limit;
            value = [];
            
            if is_valid
                
                obj.index = obj.index + 1;
                
                encoding = obj.value_generator.encoding;

                if iscell(encoding)
                    encoding = encoding{obj.index};
                end

                encoding_method = obj.encodings.resolve_encoding_method(encoding);
                
                value = encoding_method(obj.encodings, obj.generator.domain);
                value = hdng.experiments.Value.from(value, char(value), missing, 'builtin.missing');
            end
        end
    end
    
    methods (Static, Access=private)
    end
    
end
