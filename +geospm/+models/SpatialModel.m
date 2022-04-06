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

classdef SpatialModel < handle
    %SpatialModel Summary of this class goes here
    %
    %   A spatial model is defined by one or more factors of interest
    %   together with a density and provides a joint distribution of these
    %   factors for each point in space.
    %
    
    properties
        probes
        attachments
    end
    
    properties (SetAccess=private)
        
        domain
        spatial_resolution
        
        quantities
        
        density
        joint_distribution
    end
    
    properties (Dependent, Transient)
        N_quantities
    end
    
    properties (GetAccess=private, SetAccess=private)
        quantities_by_name
    end
    
    methods
        
        function obj = SpatialModel(domain, spatial_resolution)
            
            obj.domain = domain;
            obj.spatial_resolution = spatial_resolution;
            obj.quantities = cell(0, 1);
            
            obj.quantities_by_name = containers.Map('KeyType', 'char','ValueType', 'any');
            
            obj.probes = [];
            obj.attachments = struct();
        end
        
        function result = get.N_quantities(obj)
            result = numel(obj.quantities);
        end
        
        function nth_quantity = add_quantity(obj, quantity)
            
            obj.quantities{end + 1} = quantity;
            nth_quantity = numel(obj.quantities);
            obj.quantities_by_name(quantity.name) = quantity;
            
            if strcmp(quantity.name, 'density')
                obj.density = quantity;
            elseif strcmp(quantity.name, 'joint_distribution')
                obj.joint_distribution = quantity;
            end
        end
        
        function result = contains_quantity_for_name(obj, name)
            result = isKey(obj.quantities_by_name, name);
        end
        
        function [did_exist, result] = quantity_for_name(obj, name, default_value)
            
            if ~exist('default_value', 'var')
                default_value = [];
            end
            
            if ~isKey(obj.quantities_by_name, name)
                did_exist = false;
                result = default_value;
            else
                did_exist = true;
                result = obj.quantities_by_name(name);
            end
        end
        
                
        function marginals = recover_marginals(obj)
            
            s = obj.spatial_resolution;
            d = obj.joint_distribution.dimensions;
            N = numel(d);
            
            if obj.domain.N_variables ~= N
                error('SpatiaModel.recover_marginals(): Joint distribution dimension doesn''t match number of variables in domain.');
            end
            
            have_marginals = true;
            cached_marginals = cell(N, 1);
            
            for i=1:N
                name = ['marginal ' obj.domain.variables{i}.name];
                
                [did_exist, cached_marginals{i}] = obj.quantity_for_name(name);
                
                if ~did_exist
                    have_marginals = false;
                    break;
                end
            end
            
            if have_marginals
                marginals = cached_marginals;
                return;
            end
            
            flat_d = obj.joint_distribution.flatten();
            
            marginals = cell(N, 1);
            
            for i=1:N
                marginals{i} = zeros(s(1), s(2), d(i));
            end
            
            for i=1:s(1)
                for j=1:s(2)
                   local_distribution = flat_d(i, j, :);
                   local_distribution = reshape(local_distribution, d);
                   local_marginals = geospm.models.SpatialModel.recover_local_marginals(local_distribution);
                   
                   for k=1:N
                       m = marginals{k};
                       m(i, j, :) = local_marginals{k};
                       marginals{k} = m;
                   end
                end
            end
            
            for i=1:N
                marginals{i} = geospm.models.quantities.DiscreteQuantity(obj, ['marginal ' obj.domain.variables{i}.name], marginals{i});
            end
        end
    end
    
    methods (Static, Access=private)
        
        function result = recover_local_marginals(joint_distribution)
            
            d = size(joint_distribution);
            N = numel(d);
            
            result = cell(N, 1);
            
            for i=1:N
                result{i} = sum(joint_distribution, i);
            end
        end
    end
    
end
