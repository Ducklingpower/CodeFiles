const math = require('mathjs');

const generate = () => {


    XLSX = require('xlsx');
    workbook = XLSX.readFile("questions/Thermo/vaporCycle/regenerativeCycle/SteamTablesMoranAndShapiro.xlsx");
                             
    
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
    
 possibleP1 = [2, 3, 4, 6, 8, 10, 12];
         P1 = possibleP1[math.randomInt(0, possibleP1.length)]
         T1 = math.randomInt(450, 550);
 possibleP2 = [0.3, 0.5, 0.7]; 
         P2 = possibleP2[math.randomInt(0, possibleP2.length)]
 possibleP3 = [0.004, 0.006, 0.008, 0.01, 0.02]; 
         P3 = possibleP3[math.randomInt(0, possibleP3.length)]
eta_turbine = math.randomInt(50,70); // %
      W_net = math.randomInt(70,150); // MW



    Data =  PropertiesForSuperHeated(P1*1000,T1,0,0,0,0); //kpa
    h1 = Data['Enthalpy (kJ/kg)'];
    s1 = Data["Entropy (kJ/kg*K)"]
    
    Data = PropertiesByPressure(P2*1000);
    sg = Data['sg (kJ/kg*K)']
    sf = Data['sf (kJ/kg*K)']
    hg = Data['hg (kJ/kg)'];
    hf = Data['hf (kJ/kg)'];
    x  = (s1-sf)/(sg-sf);
    h2s = hf + x*(hg - hf);
    h2 = h1 - eta_turbine / 100 * (h1 - h2s);

    Data =  PropertiesForSuperHeated(P2*1000,0,0,0,h2,0)
    s2 = Data["Entropy (kJ/kg*K)"];

    Data = PropertiesByPressure(P3*1000);
    h4 = Data["hf (kJ/kg)"];
    v4 = Data["vf (m^3/kg)"]

    Data = PropertiesByPressure(P3*1000);
    h3 = 2249.3;
    hf = Data["hf (kJ/kg)"];
    hg = Data["hg (kJ/kg)"];
    sg = Data['sg (kJ/kg*K)']
    sf = Data['sf (kJ/kg*K)']
    x = (s2-sf)/(sg-sf);
    h3s = hf + x*(hg-hf);
    h3 = h2 - (eta_turbine / 100) * (h2 - h3s);


    Data = PropertiesByPressure(P2*1000);
    h6 = Data["hf (kJ/kg)"]
    v6 = Data["vf (m^3/kg)"]

    h5 = h4 + v4 * (P2 - P3) * 1e3; // Pump 1 work
    h7 = h6 + v6 * (P1 - P2) * 1e3; // Pump 2 work


    // Mass extraction fraction y
    y = (h6 - h5) / (h2 - h5);

    // Turbine work per unit mass
    Wt_per_kg = (h1 - h2) + (1 - y) * (h2 - h3);

    // Pump work per unit mass
    Wp_per_kg = (h7 - h6) + (1 - y) * (h5 - h4);

    // Heat added per unit mass
    Qin_per_kg = h1 - h7;

    // Thermal efficiency
    thermal_efficiency = ((Wt_per_kg - Wp_per_kg) / Qin_per_kg) * 100;

    // Mass flow rate calculation
    net_work_per_kg = Wt_per_kg - Wp_per_kg;
    mass_flow_rate = (W_net * 1e3) / net_work_per_kg * 3600; // kg/h

    data = {
        params: {
            P1: P1,
            T1: T1,
            P2: P2,
            P3: P3,
            eta_turbine: eta_turbine,
            W_net: W_net,
        },
        correct_answers: {
            thermal_efficiency:  math.round(thermal_efficiency,3),
            mass_flow_rate:  math.round(mass_flow_rate,3),
            h1: math.round(h1,3),
            s1: math.round(s1,3),
            h2: math.round(h2,3),
            s2: math.round(s2,3),
            h2s:math.round(h2,3),
            h3: math.round(h3,3),
            h3s: math.round(h3s,3),
            h4: math.round(h4,3),
            h5: math.round(h5,3),
            h6: math.round(h6,3),
            h7: math.round(h7,3),
            v4: v4,
            v6: v6,
            

        },
        nDigits: 3,
        sigfigs: 3
    };

    console.log(data);
    return data;
}

generate();

module.exports = {
    generate
};
