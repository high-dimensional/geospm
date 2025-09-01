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

classdef ScaleDeclarator < hdng.diagrams.Definition
    %ScaleDeclarator Summary.
    %   Detailed description 
    
    properties
        identifier
        ctor_arguments
    end
    
    properties (Dependent, Transient)
        ctor_name
        ctor
    end

    properties (Access=private)
        ctor_name_
        ctor_
    end
    
    methods

        function result = get.ctor_name(obj)
            result = obj.ctor_name_;
        end

        function set.ctor_name(obj, value)
            obj.ctor_name_ = value;
            obj.ctor_ = [];
        end

        function result = get.ctor(obj)

            if isempty(obj.ctor_) && ~isempty(obj.ctor_name_)
                obj.ctor_ = str2func(obj.ctor_name_);
            end

            result = obj.ctor_;
        end

        function obj = ScaleDeclarator(varargin)
            obj = obj@hdng.diagrams.Definition('scale_declarator');

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'identifier')
                options.identifier = '';
            end

            if ~isfield(options, 'ctor_name')
                options.ctor_name = '';
            end

            if ~isfield(options, 'ctor_arguments')
                options.ctor_arguments = struct();
            end

            obj.identifier = options.identifier;
            obj.ctor_name_ = options.ctor_name;
            obj.ctor_arguments = options.ctor_arguments;
        end

        function result = generate_scale(obj)

            if isempty(obj.ctor)
                error('ScaleDeclarator:UndefinedScaleCtor', 'No scale constructor defined in declarator.');
            end

            args = obj.ctor_arguments;

            if ~isfield(args, 'identifier')
                args.identifier = obj.identifier;
            end

            args = hdng.utilities.struct_to_name_value_sequence(args);

            result = obj.ctor(args{:});
        end
    end
end
