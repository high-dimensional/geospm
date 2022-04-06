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

classdef Generator < hdng.fractals.Generator
    %Generator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
    end
    
    properties (SetAccess=private)
        domain
        rules
        max_rule_length
    end
    
    methods
        
        function obj = Generator(domain, rule_definitions)
            obj = obj@hdng.fractals.Generator();
            
            if iscell(domain)
                
                N = numel(domain);
                
                name = domain{1};
                arguments = struct();
                
                for i=2:2:N
                    arguments.(domain{i}) = domain{i + 1};
                end
                
                domain = name;
            else
                arguments = struct();
            end
            
            if ischar(domain)
                switch lower(domain)
                    case 'triangular'
                        domain = hdng.fractals.substitutions.RegularDomain.triangular(arguments);
                        
                    case 'square'
                        domain = hdng.fractals.substitutions.RegularDomain.square(arguments);
            
                    otherwise
                        error(['SubstitutionGenerator: Unknown domain: ' domain]);
                end
            end
                        
            obj.domain = domain;
            obj.define_rules(rule_definitions);
        end
        
        function obj = define_rules(obj, rule_definitions)
            
            N = size(rule_definitions, 1);
            
            obj.rules = cell(N, 1);
            obj.max_rule_length = 0;
            
            for i=1:N
                
                initialiser = rule_definitions{i};
                seq_length = size(initialiser, 1);
                seq = obj.domain.create_sequence(initialiser);
                
                obj.rules{i} = seq;
                
                if seq_length > obj.max_rule_length
                    obj.max_rule_length = seq_length;
                end
            end
        end
        
        function result = render(obj, fractal, arguments)
            
            levels = 3;
            seed_sequence = obj.domain.create_sequence(1);
            seed_sequence.set_transform(1, obj.domain.create_identity_transform());
            
            if isfield(arguments, 'levels')
                levels = arguments.levels;
            end
            
            if isfield(arguments, 'seed_sequence')
                seed_sequence = obj.domain.create_sequence(arguments.seed_sequence);
            end
            
            iterator = hdng.fractals.substitutions.SubstitutionIterator( ...
                        obj.domain, obj.rules, seed_sequence, levels);
            
            capacity = seed_sequence.length * obj.max_rule_length ^ levels;
            
            result = hdng.fractals.substitutions.SubstitutionGraphic(fractal, arguments, iterator, capacity);
        end
    end
end
