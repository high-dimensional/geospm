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

classdef SignificanceTest < handle
    
    %SignificanceTest 
    %
    
    properties (Constant)
        NO_CORRECTION = 'none'
        FALSE_DISCOVERY_RATE = 'FDR'
        FAMILY_WISE_ERROR = 'FWE'
        
        NORMAL_DISTRIBUTION = 'normal'
        T_DISTRIBUTION = 'T'
        F_DISTRIBUTION = 'F'
        UNIFORM_DISTRIBUTION = 'uniform'
        STEP_DISTRIBUTION = 'step'
        
        LEFT_TAILED = 1
        RIGHT_TAILED = 2
        TWO_TAILED = 3
        
        corrections = {
                 geospm.SignificanceTest.NO_CORRECTION, ...
                 geospm.SignificanceTest.FALSE_DISCOVERY_RATE, ...
                 geospm.SignificanceTest.FAMILY_WISE_ERROR};
        
        distributions = {
                 geospm.SignificanceTest.NORMAL_DISTRIBUTION, ...
                 geospm.SignificanceTest.T_DISTRIBUTION, ...
                 geospm.SignificanceTest.F_DISTRIBUTION, ...
                 geospm.SignificanceTest.UNIFORM_DISTRIBUTION, ...
                 geospm.SignificanceTest.STEP_DISTRIBUTION};
    end
    
    properties (GetAccess=public, SetAccess=public)
        level
        distribution
    end
    
    properties (Dependent, Transient)
        tails
        tails_code
        tail_level
        correction
        description
        
        distribution_description
    end
    
    
    properties (GetAccess=private, SetAccess=private)
        correction_
        tails_
    end
    
    methods
        
        function obj = SignificanceTest()
            obj.correction_ = geospm.SignificanceTest.NO_CORRECTION;
            obj.level = 0.05;
            obj.distribution = geospm.SignificanceTest.T_DISTRIBUTION;
            obj.tails_ = [1, 2];
        end
        
        function result = get.tails_code(obj)
            
            if numel(obj.tails) == 1
                if obj.tails == 1
                    result = geospm.SignificanceTest.LEFT_TAILED;
                    return;
                elseif obj.tails == 2
                    result = geospm.SignificanceTest.RIGHT_TAILED;
                    return;
                else
                    error('geospm.SignificanceTest.tails_code: Unknown tails element.');
                end
                
            elseif numel(obj.tails) == 2
                if isequal(obj.tails, [1, 2])
                    result = geospm.SignificanceTest.TWO_TAILED;
                    return;
                end
            end
            
            error('geospm.SignificanceTest.tails_code: Unknown tails.');
        end
        
        function result = get.tails(obj)
            result = obj.tails_;
        end
        
        function set.tails(obj, value)
            
            if numel(value) > 2
                error('geospm.SignificanceTest.tails: Cannot have more than 2 elements.');
            end
            
            value = sort(value);
            
            if any(strcmp(obj.distribution, {geospm.SignificanceTest.F_DISTRIBUTION}))
                if ~isempty(value)
                    error(['geospm.SignificanceTest.tails: Cannot assign non-empty tails to ' obj.distribution ' distribution test.']);
                end
                
            else
                if isempty(value)
                    error('geospm.SignificanceTest.tails: Cannot assign empty tails to %s distribution test.', obj.distribution);
                end
                
                if ~isequal(value, 1) && ~isequal(value, 2) && ~isequal(value, [1, 2])
                    error('geospm.SignificanceTest.tails: Can only contain 1 or 2 as elements.');
                end
            end
            
            obj.tails_ = value;
        end
        
        function result = get.tail_level(obj)
            result = obj.level / numel(obj.tails);
        end
        
        function result = get.correction(obj)
            result = obj.correction_;
        end
        
        function set.correction(obj, value)
            
            is_valid = false;
            
            for i=1:numel(obj.corrections)
                
                if strcmp(obj.corrections{i}, value)
                    is_valid = true;
                    obj.correction_ = value;
                    break;
                end
            end
            
            if ~is_valid
                if ~strcmp(lower(value), value)
                    error(['geospm.SignificanceTest.set.type(): ''' value ''' is not a valid threshold type.']);
                else
                    obj.correction_ = value;
                end
            end
        end
        
        function result = get.distribution_description(obj)
            
            tails_string = '';
            
            switch numel(obj.tails)
                case 1
                    tails_string = sprintf('[%g]', obj.tails(1));
                case 2
                    tails_string = sprintf('[%g, %g]', obj.tails(1), obj.tails(2));
                
            end
            
            result = [obj.distribution tails_string];
        end
        
        function result = get.description(obj)
            
            correction_string = '';
            
            if ~strcmp(obj.correction, geospm.SignificanceTest.NO_CORRECTION)
                correction_string = sprintf(' (%s)', obj.correction);
            end
            
            result = [obj.distribution_description ': p<' sprintf('%g', obj.level) correction_string];
        end
        
        function result = char(obj)
            result = obj.description;
        end
        
        function result = test(obj, statistics, varargin)
            
            I = obj.compute_null_interval(varargin{:});
            result = bitor(statistics < I(1), statistics > I(2));
        end
        
        function result = compute_null_interval(obj, varargin)
        
            if ~strcmp(obj.correction, 'none')
                error('geospm.SignificanceTest.compute_interval(): Can compute intervals only for uncorrected tests, but have correction: %s', obj.correction);
            end
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            alpha = 1.0 - obj.level;
            alpha2 = (alpha + 1) / 2;
            
            switch obj.distribution
                
                case 'T'
                    
                    if ~isfield(options, 'nu')
                        error('geospm.SignificanceTest.compute_interval(): Missing nu parameter for t distribution.');
                    end
                    
                    
                    switch obj.tails_code
                        case obj.LEFT_TAILED
                            result = [-tinv(alpha, options.nu), Inf];
                        case obj.RIGHT_TAILED
                            result = [-Inf, tinv(alpha, options.nu)];
                    
                        case obj.TWO_TAILED
                            
                            cv = tinv(alpha2, options.nu);
                            result = [-cv, cv];
                    
                        otherwise
                            error('geospm.SignificanceTest.compute_interval(): Specified tails are incompatible with normal distribution.');
                    end
                    
                case 'normal'
                    
                    switch obj.tails_code
                        case obj.LEFT_TAILED
                            result = [-norminv(alpha), Inf];
                        case obj.RIGHT_TAILED
                            result = [-Inf, norminv(alpha)];
                    
                        case obj.TWO_TAILED
                            
                            cv = norminv(alpha2);
                            result = [-cv, cv];
                    
                        otherwise
                            error('geospm.SignificanceTest.compute_interval(): Specified tails are incompatible with normal distribution.');
                    end
                    
                case 'F'
                    
                    if ~isfield(options, 'v1')
                        error('geospm.SignificanceTest.compute_interval(): Missing v1 parameter for F distribution.');
                    end
                    
                    
                    if ~isfield(options, 'v2')
                        error('geospm.SignificanceTest.compute_interval(): Missing v2 parameter for F distribution.');
                    end
                    
                    result = [-Inf, finv(alpha, options.v1, options.v2)];
                    
                case 'uniform'
                    
                    switch obj.tails_code
                        case obj.LEFT_TAILED
                            result = [-alpha, 0];
                            
                        case obj.RIGHT_TAILED
                            result = [0, alpha];
                    
                        case obj.TWO_TAILED
                            
                            result = [-alpha2, alpha2];
                    
                        otherwise
                            error('geospm.SignificanceTest.compute_interval(): Specified tails are incompatible with uniform distribution.');
                    end
                
                case 'step'
                    
                    switch obj.tails_code
                        case obj.LEFT_TAILED
                            result = [-alpha, Inf];
                            
                        case obj.RIGHT_TAILED
                            result = [-Inf, alpha];
                    
                        otherwise
                            error('geospm.SignificanceTest.compute_interval(): Specified tails are incompatible with step distribution.');
                    end
                    
                    
                otherwise
                    error('geospm.SignificanceTest.compute_interval(): Unsupported distribution ''%s''.', obj.distribution);
            end
        end
    end
    
    methods (Static)
        
        function result = from_char(argument)
            
            persistent SPECIFIER_EXPR;
            persistent DISTRIBUTION_EXPR;
            
            if isempty(SPECIFIER_EXPR)
                SPECIFIER_EXPR = '^\s*(?<distribution>\s*[^:]+\s*:)?\s*p\s*<\s*(?<level>[0-9]+\.[0-9]+)\s*(?<correction>\([^\)]*\))?\s*$';
                DISTRIBUTION_EXPR = '^\s*(?<distribution>[a-zA-Z_]\w*)\s*(?<tails>\[(1|2|1,\s*2)\])?\s*$';
            end
            
            result = {};
            
            if ischar(argument)
                specifier_cells = {argument};
            elseif iscell(argument)
                specifier_cells = argument;
            else
                error('geospm.SignificanceTest.from_char(): Expected char or cell array argument but have %s.', class(argument));
            end
            
            for index=1:numel(specifier_cells)
                
                specifier = specifier_cells{index};
                
                [parts]=regexp(specifier, SPECIFIER_EXPR, 'names');

                if isempty(parts)
                    error('geospm.SignificanceTest.from_char(): Syntax error in specifier: ''%s''', specifier);
                end

                if ~isempty(parts.distribution)

                    parts.distribution = parts.distribution(1:end - 1);

                    [tmp]=regexp(parts.distribution, DISTRIBUTION_EXPR, 'names');

                    if isempty(tmp)
                        error('geospm.SignificanceTest.from_char(): Syntax error in specifier. Expected distribution name followed by optional tails in brackets, but have: ''%s''', specifier);
                    end

                    parts.distribution = tmp.distribution;
                    parts.tails = tmp.tails;
                end

                if ~isempty(parts.correction)
                    parts.correction = parts.correction(2:end - 1);
                else
                    parts.correction = geospm.SignificanceTest.NO_CORRECTION;
                end

                if ~isempty(parts.tails)
                    parts.tails = parts.tails(2:end - 1);
                    parts.tails = eval(['[' parts.tails ']']);
                elseif any(strcmp(parts.distribution, {geospm.SignificanceTest.F_DISTRIBUTION}))
                    parts.tails = [];
                else
                    parts.tails = [1, 2];
                end

                specifier_result = geospm.SignificanceTest();
                specifier_result.distribution = parts.distribution;
                specifier_result.level = str2double(parts.level);
                specifier_result.tails = parts.tails;
                specifier_result.correction = parts.correction;
                
                result{end + 1} = specifier_result; %#ok<AGROW>
            end
            
            if ischar(argument)
                result = result{1};
            end
        end
    end
end
