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

%#ok<*CPROPLC>

classdef RegularDomain < hdng.fractals.substitutions.TransformDomain
    %RegularDomain Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        scale_base
        
        orientation_initialiser
        
        orientation_map
        orientation_bases
        orientation_degrees
        orientation_flips
    end
    
    methods    
        
        function obj = RegularDomain()
            
            obj = obj@hdng.fractals.substitutions.TransformDomain();
            
            obj.scale_base = 1;
            obj.orientation_initialiser = @(value) value;
            obj.orientation_map = zeros(1,1);
            obj.orientation_bases = {eye(2)};
            obj.orientation_degrees = zeros(1,1);
            obj.orientation_flips = {eye(2)};
        end
        
        function result = create_identity_transform(obj) %#ok<MANU>
            result = struct();
            result.rule        = 1;
            result.scale_power = 0;
            result.orientation = 1;
            result.flipped     = 0;
            result.reversed    = 0;
        end
        
        function result = create_transform(obj, initialiser)
            
            result = struct();
            result.rule        = 1;
            result.scale_power = initialiser{1};
            result.orientation = obj.orientation_initialiser(initialiser{2});
            result.flipped     = initialiser{3};
            result.reversed    = initialiser{4};
        end
        
        function result = transform_to_string(obj, transform)
            
            flipped = 'no';
            
            if transform.flipped
                flipped = 'yes';
            end
            
            reversed = 'normal';
            
            if transform.reversed
                reversed = 'reversed';
            end
            
            scale       = num2str(obj.scale_base ^ transform.scale_power, '%03d');
            orientation = num2str(obj.orientation_degrees(transform.orientation), '%03.1f');
            
            result = ['      scale: ' scale newline, ...
                      'orientation: ' orientation newline, ...
                      '    flipped: ' flipped newline, ...
                      '   reversed: ' reversed newline];
        end
        
        function result = create_sequence(obj, length_or_initialisers)
            
            if iscell(length_or_initialisers)
                
                length = size(length_or_initialisers, 1);
                initialisers = length_or_initialisers;
            else
                
                length = length_or_initialisers;
                initialisers = {};
            end
            
            result = hdng.fractals.substitutions.RegularSequence(length);
            
            for i=1:size(initialisers, 1)
                result.set_transform(i, obj.create_transform(initialisers(i, :)));
            end
            
        end

        function result = multiply_transforms(obj, left, right)

            result = struct();
            result.rule        = 1;
            result.scale_power = left.scale_power + right.scale_power;
            
            %We flip the orientation, then rotate it.
            
            flips       = obj.orientation_flips{right.orientation};
            orientation = flips(left.reversed + 1, left.flipped + 1);
            
            orientation = obj.orientation_map(left.orientation, orientation);
            
            result.orientation = orientation;
            
            result.flipped     = xor(left.flipped,  right.flipped);
            result.reversed    = xor(left.reversed, right.reversed);
            
        end
        
        function [x, y] = compute_step(obj, x, y, transform)
            
            R = obj.orientation_bases{transform.orientation};
            
            result = R(:,1)' * (obj.scale_base ^ cast(transform.scale_power, 'double'));
            
            x = x + result(1);
            y = y + result(2);
        end
    end
    
    methods (Static)
        
        function domain = triangular(arguments)
            
            if ~exist('arguments', 'var')
                arguments = struct();
            end
            
            domain = hdng.fractals.substitutions.RegularDomain();
            hdng.fractals.substitutions.RegularDomain.define_orientations(domain, 30);
            
            if ~isfield(arguments, 'scale_base')
                arguments.scale_base = 1;
            end
            
            domain.scale_base = arguments.scale_base;
        end
        
        function domain = square(arguments)
            
            if ~exist('arguments', 'var')
                arguments = struct();
            end
            
            domain = hdng.fractals.substitutions.RegularDomain();
            hdng.fractals.substitutions.RegularDomain.define_orientations(domain, 45);
            
            if ~isfield(arguments, 'scale_base')
                arguments.scale_base = 1;
            end
            
            domain.scale_base = arguments.scale_base;
        end
        
        function define_orientations(domain, step_in_degrees)
            
            step_in_degrees = cast(step_in_degrees, 'int32');
            
            N = idivide(360, step_in_degrees);
            H = idivide(180, step_in_degrees);
            Q = idivide( 90, step_in_degrees);
            
            orientation_map = zeros(N, 'uint8');
            orientation_bases = cell(N,1);
            orientation_degrees = zeros(N, 1);
            orientation_flips = cell(N,1);
            
            rot_90f = @(value) mod(value - 1 + Q, N) + 1;
            rot_90b = @(value) mod(value - 1 + N - Q, N) + 1;
            
            flip_v  = @(value) mod(N - value + 1, N) + 1;
            flip_h  = @(value) mod(rot_90b(flip_v(rot_90f(value))) - 1 + H, N) + 1;
            
            for i=1:N
                for j=1:N
                    orientation_map(i, j) = mod(i - 1 + j - 1, N) + 1;
                end
                
                d = cast(step_in_degrees * (i - 1), 'double') / 180.0;
                
                orientation_bases{i} = [cospi(d) -sinpi(d);
                                        sinpi(d)  cospi(d)];
                
                %{
                         flipped
                             0       1
                reversed 
                         0   
                                        
                         1
                                        
                %}
                                    
                orientation_flips{i} = [i         flip_v(i);
                                        flip_h(i) i];
                
                orientation_degrees(i) = d * 180.0;
                
                %fprintf('%02d: %02d %02d %02d %02d\n', i, orientation_flips{i}(1), orientation_flips{i}(4), orientation_flips{i}(2), orientation_flips{i}(3));
            end
            
            domain.orientation_initialiser = @(value) 1 + idivide(value, step_in_degrees);
            domain.orientation_map = orientation_map;
            domain.orientation_bases = orientation_bases;
            domain.orientation_degrees = orientation_degrees;
            domain.orientation_flips = orientation_flips;
            
        end
    end
end
