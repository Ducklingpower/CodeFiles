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
    

    P1 = math.randomInt(100,500); // kPa
    P2 = P1 
    P3 = P1 
    T2 = math.randomInt(40,100);  // Celsius
    m2 = math.randomInt(100,700)/10;  // kg/s
    

    // state 1 sat vape
    Data = PropertiesByPressure(P1);
    s1 = Data["sg (kJ/kg*K)"];
    h1 = Data["hg (kJ/kg)"];

    // state 2 sat liq approx.
    Data = PropertiesByTemperature(T2);
    s2  = Data["sf (kJ/kg*K)"];
    h2  = Data["hf (kJ/kg)"];

    // state 3 sta liq P3

    Data = PropertiesByPressure(P3);
    s3 = Data["sf (kJ/kg*K)"];
    h3 = Data["hf (kJ/kg)"];

    
    // Solve for steam mass flow rate (m1)
    m1 = ((m2 * h2) - (m2 * h3)) / (h3 - h1);
    m3 = m1 + m2;
    
    // Solve for entropy production
    entropy_production = (m3 * s3) - (m2 * s2) - (m1 * s1);
    
    let data = {
        params: {
            P1: P1,
            P2: P2,
            P3: P3,
            T2: T2,
            m2: m2
        },
        correct_answers: {
            entropy_production: math.round(entropy_production, 3),
            h1:math.round(h1,3),
            h2:math.round(h2,3),
            h3:math.round(h3,3),
            s1:math.round(s1,3),
            s2:math.round(s2,3),
            s3:math.round(s3,3),
            m1:math.round(m1,3),
            m2:math.round(m2,3),
            m3:math.round(m3,3)

        },
        nDigits: 3,
        sigfigs: 3
    };
    
    console.log(data);
    return data;
};

generate();

module.exports = {
    generate
};
