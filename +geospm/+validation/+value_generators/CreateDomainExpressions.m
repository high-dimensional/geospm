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

classdef CreateDomainExpressions < hdng.experiments.ValueGenerator
    %CreateDomainExpressions Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        encoding
        encoding_arguments
        description
    end
    
    
    methods
        
        function obj = CreateDomainExpressions(varargin)
            obj = obj@hdng.experiments.ValueGenerator();
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'description')
                options.description = '';
            end
            
            if ~isfield(options, 'encoding')
                options.encoding = geospm.models.DomainEncodings.DIRECT_ENCODING;
            end
            
            obj.encoding = options.encoding;
            obj.description = options.description;
            
            arguments = rmfield(options, 'encoding');
            obj.encoding_arguments = rmfield(arguments, 'description');
        end
        
    end
    
    methods (Access=protected)
        
        function result = create_iterator(obj, arguments)
            generator = arguments.generator;
            result = geospm.validation.value_generators.CreateDomainExpressionsIterator(obj, generator);
        end
    end
    
    
    methods (Static, Access=private)
        
    end
    
end
