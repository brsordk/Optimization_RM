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
