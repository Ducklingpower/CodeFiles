const math = require('mathjs');

const generate = () => {
    // Unit definitions (SI units are used for this problem)
    const units = {
        pressure: "MPa",
        temperature: "°C",
        energy: "kJ/kg",
        power: "MW",
        massFlowRate: "kg/h"
    };




    XLSX = require('xlsx');
workbook = XLSX.readFile("questions/Thermo/vaporCycle/idealReheatCycle/SteamTablesMoranAndShapiro.xlsx");
                         

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


    
    
      
        possibleP1 = [2, 3, 4, 6, 8, 10];
        p1 = possibleP1[math.randomInt(0, possibleP1.length)]
        t1   = math.randomInt(450,480) 
        possibleP2 = [7, 5, 3]; 
        p2 = possibleP2[math.randomInt(0, possibleP2.length)]/10;
        tr   = math.randomInt(400, 440) 
        p3   = math.randomInt(1,10)/100 
        w_net= math.randomInt(100,300) 
   

   
   Data =  PropertiesForSuperHeated(p1*1000, t1, 0, 0, 0, 0)
     h1 = Data["Enthalpy (kJ/kg)"];
     s1 = Data[ "Entropy (kJ/kg*K)"];

    Data = PropertiesByPressure(p2*1000)
    sf = Data["sf (kJ/kg*K)"] 
    sg = Data["sg (kJ/kg*K)"] 
    hf = Data["hf (kJ/kg)"]
    hg = Data["hg (kJ/kg)"]

    s2 = s1;
    x2 = (s2-sf)/(sg-sf);
    h2 = hf + x2*(hg-hf);




    Data =  PropertiesForSuperHeated(p2*1000, tr, 0, 0, 0, 0)
    h3 = Data["Enthalpy (kJ/kg)"];
    s3 = Data["Entropy (kJ/kg*K)"];
   

  Data = PropertiesByPressure(p3*1000)
    sf = Data["sf (kJ/kg*K)"] 
    sg = Data["sg (kJ/kg*K)"] 
    hf = Data["hf (kJ/kg)"]
    hg = Data["hg (kJ/kg)"]
    s4 = s3;
    x4 = (s4-sf)/(sg-sf);
    h4 = hf + x4*(hg-hf);

    Data = PropertiesByPressure(p3*1000)
    h5 = Data["hf (kJ/kg)"]
    v = Data['vf (m^3/kg)']
    h6 = h5+v*(p1-p3)*1000;


    
     Q_in = (h1 - h6) + (h3 - h2); 
     W_net = w_net * 1000; 
     efficiency = (((h1-h2)+ (h3-h4) - (h6 - h5)) / Q_in) * 100; 

    
    massFlowRate = W_net / ((h1 - h2) + (h3 - h4) - (h6 - h5)); 
     massFlowRate_h = massFlowRate * 3600; 

    
     Q_out = massFlowRate * (h4 - h5) / 1000; 

    data = {
         params: {
            p1:p1,
            t1:t1,
            p2:p2,
            tr:tr,
            p3:p3,
            w_net:w_net, 
                },
        correct_answers: {
            thermal_efficiency: math.round(efficiency, 3),
            mass_flow_rate: math.round(massFlowRate_h, 3),
            heat_transfer_rate: math.round(Q_out, 3)
        },
        units: units
    };

    console.log(data);
    return data;
};

generate();

module.exports = {
    generate
};
