const math = require('mathjs');

const generate = () => {
    // Define unit systems (SI)
    const units = {
        si: {
            entropy: "kJ/kg·K",
            pressure: "kPa",
            massFlow: "kg/s",
            temperature: "°C"
        }
    };

    const unitSel = "si"; // Using SI units
    const unitEntropy = units[unitSel].entropy;
    const unitPressure = units[unitSel].pressure;
    const unitMassFlow = units[unitSel].massFlow;
    const unitTemperature = units[unitSel].temperature;

    // Random variable generation within a reasonable range
    p_steam = 300; // Pressure of steam in kPa
    p_out = 300; // Output pressure in kPa (constant)
    t_water = 80; // Water temperature in °C
    mass = math.randomInt(20, 500)/10; // Mass flow rate in kg/s
  
    // Given properties from the thermodynamic table
    h1 = 2725.5; // Enthalpy of saturated steam at 300 kPa (kJ/kg)
    s1 = 6.9919; // Entropy of saturated steam at 300 kPa (kJ/kg·K)
    h2 = 335.7; // Enthalpy of water at Tc°C (kJ/kg)
    s2 = 1.0751; // Entropy of water at Tc°C (kJ/kg·K)
    h3 = 561.2; // Enthalpy of saturated liquid at 300 kPa (kJ/kg)
    s3 = 1.6698; // Entropy of saturated liquid at 300 kPa (kJ/kg·K)

    // Energy balance to determine mass flow rate of steam (ṁ₁)
    m2 = mass; // Mass flow rate of water entering (kg/s)
    m3 = m2 - ((m2 * h2 - m2 * h3) / (h1 - h3)); // Total mass flow rate out
    m1 = m3 - m2; // Mass flow rate of steam entering

    // Entropy production calculation (ΔS_prod)
    entropyProduction = (m3 * s3 - m2 * s2 - m1 * s1).toFixed(3); // Rounded to 3 significant figures

    // Package parameters and correct answers
    const data = {
        params: {
            p_steam: p_steam,
            p_out: p_out,
            t_water: t_water,
            mass: mass
        },
        correct_answers: {
            entropyProduction: entropyProduction
        },
        units: {
            entropy: unitEntropy,
            pressure: unitPressure,
            massFlow: unitMassFlow,
            temperature: unitTemperature
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