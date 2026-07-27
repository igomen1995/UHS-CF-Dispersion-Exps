function fluidRP = fluidNameREFPROP(fluid)

fluid = upper(string(fluid));

switch fluid

    case "HE"
        fluidRP = "HELIUM";

    case "XE"
        fluidRP = "XENON";

    case "H2"
        fluidRP = "HYDROGEN";

    case "CO2"
        fluidRP = "CO2";

    case "CH4"
        fluidRP = "METHANE";

    otherwise
        fluidRP = fluid;

end

end