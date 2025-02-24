const math = require('mathjs');

const generate = () => {


    XLSX = require('xlsx');
workbook = XLSX.readFile("questions/Thermo/vaporCycle/idealRankineCycle/SteamTablesMoranAndShapiro.xlsx");
                         

tempSheetRaw = XLSX.utils.sheet_to_json(workbook.Sheets["TemperatureSI"], { header: 1 });
pressureSheetRaw = XLSX.utils.sheet_to_json(workbook.Sheets["PressureSI"], { header: 1 });
superHeatedSheetRaw = XLSX.utils.sheet_to_json(workbook.Sheets["SuperheatedSI"], { header: 1 });

tempSheet = tempSheetRaw.slice(1); // Temperature data
pressureSheet = pressureSheetRaw.slice(1); // Pressure data
superHeatedSheet = superHeatedSheetRaw.slice(1); // Superheated data

// interp func ------------------------------------------------------------------------------------------------------
function interpolate(x, x1, x2, y1, y2) {
    return y1 + ((x - x1) * (y2 - y1)) / (x2 - x1);
}

// Function to map array to JSON structure manually -----------------------------------------------------------------
function mapToProperties(values, propertyNames) {
    jsonStruct = {};
    propertyNames.forEach((property, index) => {
        jsonStruct[property] = values[index];
    });
    return jsonStruct;
}

//Sat temp func -------------------------------------------------------------------------------------------------------
function PropertiesByTemperature(temp) {
    TEMP_COL = 0; 
    propertyNames = [
        "Psat (kPa)",
        "vf (m^3/kg)",
        "vg (m^3/kg)",
        "uf (kJ/kg)",
        "ug (kJ/kg)",
        "hf (kJ/kg)",
        "hfg (kJ/kg)",
        "hg (kJ/kg)",
        "sf (kJ/kg*K)",
        "sg (kJ/kg*K)"
    ];

    let lower = null, upper = null;

    for (let i = 0; i < tempSheet.length; i++) {
       currentTemp = tempSheet[i][TEMP_COL]; 
        if (currentTemp === temp) {
            return mapToProperties(tempSheet[i].slice(1), propertyNames); // Exact match
        } else if (currentTemp < temp) {
            lower = tempSheet[i];
        } else if (currentTemp > temp && upper === null) {
            upper = tempSheet[i];
            break;
        }
    }

    if (!lower || !upper) {
        console.error(`Temperature out of range. Input: ${temp}`); // Temp range [0.01 374.14]
        return null;
    }

    interpolated = lower.slice(1).map((value, index) => {
        if (typeof value === "number" && typeof upper[index + 1] === "number") {
            return interpolate(temp, lower[TEMP_COL], upper[TEMP_COL], value, upper[index + 1]);
        }
        return value;
    });

    return mapToProperties(interpolated, propertyNames);
}

// sat pressure func -----------------------------------------------------------------------------------------------
function PropertiesByPressure(pressure) {
    PRESSURE_COL = 0; // Column index for pressure (Psat) in the pressure sheet
    propertyNames = [
        "Tsat (deg C)",
        "vf (m^3/kg)",
        "vg (m^3/kg)",
        "uf (kJ/kg)",
        "ug (kJ/kg)",
        "hf (kJ/kg)",
        "hfg (kJ/kg)",
        "hg (kJ/kg)",
        "sf (kJ/kg*K)",
        "sg (kJ/kg*K)"
    ];

    let lower = null, upper = null;

    for (let i = 0; i < pressureSheet.length; i++) {
        currentPressure = pressureSheet[i][PRESSURE_COL]; // Use column index for pressure
        if (currentPressure === pressure) {
            return mapToProperties(pressureSheet[i].slice(1), propertyNames); // Exact match
        } else if (currentPressure < pressure) {
            lower = pressureSheet[i];
        } else if (currentPressure > pressure && upper === null) {
            upper = pressureSheet[i];
            break;
        }
    }

    if (!lower || !upper) {
        console.error(`Pressure out of range. Input: ${pressure}`); // Pressure range [4 22090] kpa
        return null;
    }

    interpolated = lower.slice(1).map((value, index) => {
        if (typeof value === "number" && typeof upper[index + 1] === "number") {
            return interpolate(pressure, lower[PRESSURE_COL], upper[PRESSURE_COL], value, upper[index + 1]);
        }
        return value;
    });

    return mapToProperties(interpolated, propertyNames);
}

// super-heated fluid func -----------------------------------------------------------------------------------------
function PropertiesForSuperHeated(P, T, v, u, h, s) {
    const propertyNames = [
        "Pressure (kPa)",
        "Temperature (deg C)",
        "Specific Volume (m^3/kg)",
        "Internal Energy (kJ/kg)",
        "Enthalpy (kJ/kg)",
        "Entropy (kJ/kg*K)"
    ];

    PRESSURE_COL = 1; 
    TEMP_COL = 2;
    V_COL = 3; 
    U_COL = 4;
    H_COL = 5; 
    S_COL = 6;

    // Determine the second property column
    let colIndex;
    let inputValue;

    if (T > 0) {
        colIndex = TEMP_COL;
        inputValue = T;
    } else if (v > 0) {
        colIndex = V_COL;
        inputValue = v;
    } else if (u > 0) {
        colIndex = U_COL;
        inputValue = u;
    } else if (h > 0) {
        colIndex = H_COL;
        inputValue = h;
    } else if (s > 0) {
        colIndex = S_COL;
        inputValue = s;
    } else {
        console.error("At least two properties must be greater than zero.");
        return null;
    }

    let lower = null, upper = null;

    // Check every row in the sheet
    for (let i = 0; i < superHeatedSheet.length; i++) {
        currentRow = superHeatedSheet[i].slice(1); // Exclude the first column (index 0) becouse the pressure is not relevent
        currentPressure = parseFloat(currentRow[PRESSURE_COL - 1]);
        currentValue = parseFloat(currentRow[colIndex - 1]);


        if (currentPressure === P && currentValue === inputValue) {
           // Ecact Match
            return mapToProperties(currentRow, propertyNames); // Adjust property names to match sliced row
        } else if (currentPressure === P) {
            if (currentValue < inputValue) {
                lower = currentRow;
            } else if (currentValue > inputValue && upper === null) {
                upper = currentRow;
                break;
            }
        }
    }

    if (!lower || !upper) {
        console.error("No suitable rows found for interpolation.");
        return null;
    }

    // Perform interpolation for the entire row
    interpolated = lower.map((lowerValue, index) => {
     upperValue = upper[index];
        if (typeof lowerValue === "number" && typeof upperValue === "number") {
            return interpolate(inputValue, parseFloat(lower[colIndex - 1]), parseFloat(upper[colIndex - 1]), lowerValue, upperValue);
        }
        return lowerValue; 
    });

    return mapToProperties(interpolated, propertyNames);
}



    // Variables
    P_turbine_in = math.randomInt(5,9); // MPa
    P_condenser_out = math.randomInt(1, 10) / 1000; // MPa
    W_net = math.randomInt(70,120); // MW
    T_cw_in = math.randomInt(5,15); // degrees Celsius
    T_cw_out = math.randomInt(30, 80); // degrees Celsius

    // Specific enthalpies and properties
  
    Data =  PropertiesByPressure(P_turbine_in*1000); //kpa
        h1 = Data['hg (kJ/kg)'];
        s1 = Data['sg (kJ/kg*K)']

    Data = PropertiesByPressure(P_condenser_out*1000);
        sg = Data['sg (kJ/kg*K)']
        sf = Data['sf (kJ/kg*K)']
        s2 = s1
        x  = (s2-sf)/(sg-sf);
        hg = Data['hg (kJ/kg)'];
        hf = Data['hf (kJ/kg)'];
        h2 = hf + x*(hg - hf);
        h3 = hf
        v = Data['vf (m^3/kg)']
        h4 = h3+v*(P_turbine_in-P_condenser_out)*1000;

    Data = PropertiesByTemperature(T_cw_in)
        h_cw_in = Data['hf (kJ/kg)'] ; 

    Data = PropertiesByTemperature(T_cw_out)
        h_cw_out = Data['hf (kJ/kg)'] ; 
    

    
    // (a) Thermal Efficiency
    Q_in = h1 - h4; // Heat input (kJ/kg)
    Q_out = h2 - h3; // Heat rejected (kJ/kg)
    thermal_efficiency = (Q_in - Q_out) / Q_in;

    // (b) Back Work Ratio
    back_work_ratio = (h4 - h3) / (h1 - h2);

    // (c) Mass Flow Rate of Steam
     mass_flow_rate = (W_net * 1e3) / ((h1 - h2) - (h4 - h3)); // kg/s

    // Convert to kg/h
    mass_flow_rate_hour = mass_flow_rate * 3600;

    // (d) Rate of Heat Transfer into Boiler
    Q_in_boiler = mass_flow_rate * Q_in / 1e3; // MW

    // (e) Rate of Heat Transfer from Condenser
    Q_out_condenser = mass_flow_rate * Q_out / 1e3; // MW

    // (f) Mass Flow Rate of Cooling Water
    mass_flow_rate_cooling_water = 
        (mass_flow_rate * Q_out) / (h_cw_out - h_cw_in); // kg/s

    // Convert to kg/h
    mass_flow_rate_cooling_water_hour = mass_flow_rate_cooling_water * 3600;

    data = {
        params: {
            P_turbine_in:P_turbine_in,
            P_condenser_out:P_condenser_out,
            W_net:W_net,
            T_cw_in:T_cw_in,
            T_cw_out:T_cw_in,
            h1:math.round(h1,3),
            h2:math.round(h2,3),
            h3: math.round(h3,3),
            h4: math.round(h4,3),
            s1: math.round(s1,3),
            s2: math.round(s2,3),
        },
        correct_answers: {
            thermal_efficiency: math.round(thermal_efficiency, 3),
            back_work_ratio: math.round(back_work_ratio, 5),
            mass_flow_rate_hour: math.round(mass_flow_rate_hour, 3),
            Q_in_boiler: math.round(Q_in_boiler, 3),
            Q_out_condenser: math.round(Q_out_condenser, 3),
            mass_flow_rate_cooling_water_hour: math.round(mass_flow_rate_cooling_water_hour, 3),
        },
        nDigits: 3,
        sigfigs: 3,
    };

    console.log(data);
    return data;
};

module.exports = {
    generate,
};
