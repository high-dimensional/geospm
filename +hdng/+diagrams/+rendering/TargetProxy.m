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

classdef TargetProxy < hdng.diagrams.rendering.Target
    %TargetProxy Summary.
    %   Detailed description 
    
    properties
        delegate
    end
    
    properties (Dependent, Transient)
    end

    properties (SetAccess=private)
        fragments
        fragment_order
        target_ctor
    end

    methods
        
        function obj = TargetProxy(varargin)

            obj@hdng.diagrams.rendering.Target(varargin{:});

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'fragments')
                options.fragments = [];
            end
            
            if ~isfield(options, 'fragment_order')
                options.fragment_order = {};
            end

            if ~isfield(options, 'target_ctor')
                options.target_ctor = @hdng.diagrams.rendering.BufferedTarget;
            end

            if ~isfield(options, 'delegate')
                options.delegate = [];
            end

            obj.fragment_order = options.fragment_order;
            
            obj.fragments = options.fragments;
            
            obj.target_ctor = options.target_ctor;

            obj.delegate = options.delegate;
            
            if isempty(options.fragments)
                obj.fragments = struct();
    
                for index=1:numel(options.fragment_order)
                    name = options.fragment_order{index};
                    obj.fragments.(name) = obj.target_ctor();
                end
            else
                obj.fragment_order = fieldnames(obj.fragments);
            end
        end
        
        function write_bytes(obj, output)
            
            if isempty(obj.delegate)
                return;
            end

            obj.delegate.write_bytes(output);
        end
        
        function write_text(obj, output)
            if isempty(obj.delegate)
                return;
            end
            
            obj.delegate.write_text(output);
        end

        function finalise(obj, ~, context)
            
            for index=1:numel(obj.fragment_order)
                name = obj.fragment_order{index};
                target = obj.fragments.(name);
                target.finalise(obj, context);
            end
        end
    end
end
