% <Copyright>
% Author:   Baris Ördek
% Contact:  baris.ordek@unibg.it - barisordek@gmail.com
% Update:   05/04/25
% Version:  1.0.0
% License: GNU General Public License v3.0

% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License.

% This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.

function optimize_I_tot_clean()
    global iteration_log;

    constants = get_constants(); % Load physical and environmental constants
    impact_categories = constants.impact_categories;

    lb = 0.0; % 🔽 Lower bound: mass ratio of fibre (abaca) [-]
    ub = 0.2; % 🔼 Upper bound: mass ratio of fibre (abaca) [-]

    all_results = [];

    for i = 1:length(impact_categories)
        category = impact_categories{i};
        fprintf('\n🔍 Optimizing I_tot for category: %s\n', category);
        constants.target_category = category;

        best_fval = inf;
        best_alpha_fiber = NaN;

        for trial = 1:10
            iteration_log = [];
            x0 = lb + rand() * (ub - lb); % Random initial value for optimization

            [x_opt, fval] = fmincon(@(x) objective_fiber(x, constants), x0, [], [], [], [], lb, ub, ...
                [], optimoptions('fmincon', 'Algorithm', 'sqp', 'Display', 'off', ...
                'ConstraintTolerance', 1e-10, 'OptimalityTolerance', 1e-10, 'StepTolerance', 1e-10, ...
                'MaxFunctionEvaluations', 1e5, 'MaxIterations', 1e4));

            if fval < best_fval
                best_fval = fval;
                best_alpha_fiber = x_opt;
            end
        end

        alpha_Fiber = best_alpha_fiber;                                             % [-] Fiber mass ratio
        alpha_PEMA = 0.5 * alpha_Fiber;                                             % [-] PEMA mass ratio (fixed relation)
        alpha_LDPE = 1 - alpha_Fiber - alpha_PEMA;                                  % [-] LDPE mass ratio

        PIAT_composite = constants.PIAT_LDPE - alpha_Fiber * constants.deltaT_fibre; % Peak internal ambient temperature of the Composite [°C]
        t_cook = (PIAT_composite - constants.T_amb) / constants.slope_mouldMaterial; % Cooking time of the Product [sec]
        full_x = [t_cook, alpha_Fiber, alpha_PEMA];

        [~, I_mat, I_cook, I_rot, mass_composite] = compute_all_impacts(full_x, constants);
        idx = strcmp(constants.impact_categories, category);
        I_category = I_mat(idx) + I_cook(idx) + I_rot(idx);

        result_row = cell2table({category, I_category/mass_composite, I_cook(idx), I_rot(idx), I_mat(idx), ...
                         I_category, ...
                         mass_composite, alpha_LDPE, alpha_Fiber, alpha_PEMA, ...
                         t_cook, PIAT_composite}, ...
    'VariableNames', {'Category', 'Impact/kg', 'Cooking Impact', 'Rotating Impact', 'Material Impact', ...
                      'Total Impact', 'Mass [kg]', '%LDPE', '%Fiber', '%PEMA', 'Cook Time [sec]', 'PIAT Composite'});

        if isempty(all_results)
            all_results = result_row;
        else
            all_results = [all_results; result_row];
        end
    end

    writetable(all_results, 'optimized_Impacts.xlsx');                   % Export the results into an MS Excel File
    disp('✅ Results saved to optimized_Impacts.xlsx');

    fprintf('\n-----------------------------------------------------\n');   % Display the Optimization and Impact Results
    fprintf('                 OPTIMIZATION RESULTS                \n');
    fprintf('-----------------------------------------------------\n');
    disp(all_results);
end

function f = objective_fiber(alpha_Fiber, c)
    global iteration_log;

    alpha_PEMA = 0.5 * alpha_Fiber;                                         % [-] PEMA content (fixed rule)
    alpha_LDPE = 1 - alpha_Fiber - alpha_PEMA;                              % [-] LDPE mass ratio

    if alpha_LDPE < 0 || alpha_PEMA < 0 || alpha_Fiber < 0
        f = 1e6;
        return;
    end

    PIAT_composite = c.PIAT_LDPE - alpha_Fiber * c.deltaT_fibre;            % Peak internal ambient temperature of the Composite [°C]
    t_cook = (PIAT_composite - c.T_amb) / c.slope_mouldMaterial;            % Cooking time of the Product [sec]
    full_x = [t_cook, alpha_Fiber, alpha_PEMA];

    [impacts_normalized, ~, ~, ~, ~] = compute_all_impacts(full_x, c);
    idx = strcmp(c.impact_categories, c.target_category);
    f = impacts_normalized(idx);                                            % Objective: Minimize category-specific impact per kg

    iteration_log(end+1,:) = [alpha_LDPE, alpha_Fiber, alpha_PEMA, f];
end

function [impacts_normalized, I_mat, I_cooking, I_rotating, mass_composite] = compute_all_impacts(x, c)     % Impact calculation function
    t_cook = x(1);                                                                                          % Cooking time of the Product [sec]
    alpha_Fiber = x(2);                                                                                     % Fibre mass fraction [-]
    alpha_PEMA = x(3);                                                                                      % PEMA mass fraction [-]
    alpha_LDPE = 1 - alpha_Fiber - alpha_PEMA;                                                              % Constraint: Sum of mass fractions = 1

    if any([alpha_LDPE, alpha_Fiber, alpha_PEMA] < 0)
        N = length(c.impact_categories);
        impacts_normalized = inf(1, N);
        I_mat = impacts_normalized;
        I_cooking = impacts_normalized;
        I_rotating = impacts_normalized;
        mass_composite = NaN;
        return;
    end

    alpha = [alpha_LDPE, alpha_Fiber, alpha_PEMA];                                    % All mass fractions to constitude the composite [LDPE, Fibre, PEMA]
    sigma_composite = -34 * alpha_Fiber + c.sigma_LDPE;                               % Composite strength [MPa]

    thickness_comp = c.sigma_LDPE * c.thickness_LDPE / sigma_composite;               % Thickness of the composite [m]
    mass_composite = sum(alpha .* c.rho) * c.surface_area_mould * thickness_comp;     % Mass of the Composite [kg]

    t_cook_LDPE = (c.PIAT_LDPE - c.T_amb) / c.slope_mouldMaterial;                    % Cooking time for LDPE [sec]
    En_cook = c.P_furnace * mass_composite / t_cook_LDPE * t_cook;                    % Cooking Energy consumed by the furnace [MJ]

    t_cool = (c.t_cool_PE + 50 * alpha_Fiber) * 60;                                   % Ambient Cooling time of the composite [sec]
    t_total = (t_cook + t_cool) / 3600;                                               % Total operating time of Rotational Moulding [h]

    mass_mould = c.thickness_mould * c.rho_mould * c.surface_area_mould;              % Mass of the Mould [kg]
    En_rot = c.n_mould * c.P_rotation * (mass_composite + mass_mould) / 35 * t_total; % Total Energy consumption due to Rotating system [kWh]

    N = length(c.impact_categories);
    I_mat = zeros(1, N);
    I_cooking = zeros(1, N);
    I_rotating = zeros(1, N);
    impacts_normalized = zeros(1, N);

    for i = 1:N
        cat = c.impact_categories{i};

        I_mat(i) = sum(alpha .* [ c.EF_PE.(cat), ...                                        % Material Impact of the composite
            c.EF_Fiber.(cat) + ...
            (c.distance_truck * c.EF_Truck.(cat) + c.distance_ship * c.EF_Ship.(cat)), ...
            c.EF_PEMA.(cat)]) * mass_composite;

        I_cooking(i) = En_cook * c.EF_NG.(cat);                                             % Cooking Impact of the composite
        I_rotating(i) = En_rot * c.EF_El.(cat);                                             % Rotating Impact of the composite

        impacts_normalized(i) = (I_mat(i) + I_cooking(i) + I_rotating(i)) / mass_composite; % Total impact per 1 kg of composite
    end
end




function constants = get_constants()                                                        % Input of Constants and user parameters function
    constants = struct();

    fprintf('Please enter the following parameters:\n');
    
    
    constants.T_amb = input('🔹 Ambient temperature (°C): ');                                           % 🔹 Ambient temperature [°C]
    mould_material = lower(input('🔹 Mould material (aluminum or steel): ', 's'));                      % 🔹 Mould material selection (affects heat transfer slope and density)
    constants.n_mould = input('🔹 Number of moulds: ');                                                 % 🔹 Number of moulds rotating in the process [number]
    constants.r_i = input('🔹 Mould rotation radius (m): ');                                            % 🔹 Radius of mould rotation [m]
    constants.P_furnace = input('🔹 Furnace energy (MJ/kg): ');                                         % 🔹 Furnace energy input per kg of material cooked [MJ/kg]
    constants.thickness_mould = input('🔹 Mould thickness (m):');                                       % 🔹 mould wall thickness [m]
    constants.surface_area_mould = input('🔹 Mould surface area (m²):');                                % 🔹 Surface area of the mould [m²]
    constants.thickness_LDPE = input('🔹 The thickness of the product produced using only LDPE [m]:');  % 🔹 Thickness of product made from 100% LDPE [m]
    region = input('🔹 Region (EU or CN): ', 's');                                                      % 🔹 Region selection (affects impact factors and transport distances)

    % 📌 Default Constants

    constants.PIAT_LDPE = 200;                                                                           % Peak Internal Air Temperature for LDPE [°C] 
    constants.deltaT_fibre = 50.67;                                                                      % Decrease in PIAT per unit fiber content [°C] 
    constants.t_cool_PE = 42;                                                                            % Cooling time for 100% LDPE part [min] 
    constants.sigma_LDPE = 16.1;                                                                         % Tensile strength of LDPE [MPa]
    constants.P_rotation = 7.5;                                                                          % Rotating motor power [kW]

    
    constants.rho = [924.2, 1500, 930];                                                                  % 📦 Material densities [kg/m³]: [LDPE, Fibre, PEMA]

    % Area and mass of full LDPE product
    constants.Area_LDPE = constants.surface_area_mould * constants.thickness_LDPE;                       % External Surface area of the product made only via LDPE [m³]
    constants.m_productLDPE = constants.rho(1) * constants.Area_LDPE;                                    % Mass of the product made only via LDPE [kg]

    % 📉 Set mould-specific slope and density
    switch mould_material
        case 'aluminum'
            constants.slope_mouldMaterial = 0.1957 * constants.m_productLDPE + 0.0304;                   % Temperature change per second for Aluminum mould [°C/s]
            constants.rho_mould = 2700;                                                                  % Aluminum mould density [kg/m³]
        case 'steel'
            constants.slope_mouldMaterial = 0.1755 * constants.m_productLDPE + 0.0258;                   % Temperature change per second for Steel mould [°C/s]
            constants.rho_mould = 7850;                                                                  % Steel mould density [kg/m³]
        otherwise
            error('Invalid mould material. Use "aluminum" or "steel".');
    end

    % 🌍 Transport distances [km] based on region
    if strcmpi(region, 'EU')
        constants.distance_truck = 650;                                                                  % Transportation via truck in Ecuador and EU [km]
        constants.distance_ship = 10964;                                                                 % Transportation via Ship from Ecuador to EU [km]
    elseif strcmpi(region, 'CN')
        constants.distance_truck = 380;                                                                  % Transportation via truck in Ecuador and China [km]
        constants.distance_ship = 16938;                                                                 % Transportation via Ship from Ecuador to China [km]
    else
        error('Region must be "EU" or "CN".');
    end

    % 📊 Impact categories
    constants.impact_categories = { ...                                                                  % Environmental Impact Categories
        'TAP','GWP100','FETP','METP','TETP','FFP','FEP','MEP', ...
        'HTPc','HTPnc','IRP','LOP','SOP','ODPinfinite','PMFP', ...
        'HOFP','EOFP','WCP'};

    % 📈 Load environmental factors from external Excel file
    impact_data = readtable('impact_factors.xlsx');                                                      % Load Environmental Impact Categories from an MS Excel file with a name impact_categories.xlsx
    for i = 1:height(impact_data)
        if strcmpi(impact_data.Region{i}, region)
            mat = impact_data.Material{i};
            for cat = constants.impact_categories
                constants.(['EF_' mat]).(cat{1}) = impact_data{i, cat{1}};
            end
        end
    end
end
