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
