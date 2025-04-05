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
