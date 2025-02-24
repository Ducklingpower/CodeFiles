const math = require('mathjs');

const generate = () => {
    // Unit systems
    const unitSystems = ['si', 'uscs'];
    const units = {
        "si": {
            "mass": "kg",
            "volume": "liters",
            "temperature": "degree C",
            "specificHeat": "J/(kg C)",
            "heat": "kJ",
            "heatAlternate": "J"
        },
        "uscs": {
            "mass": "lb",
            "volume": "gallons",
            "temperature": "degree F",
            "specificHeat": "BTU/(lb F)",
            "heat": "BTU",
            "heatAlternate": "cal"
        }
    };

    // Randomly choose unit system
    const unitSel = math.randomInt(0, 2); // 0 for SI, 1 for USCS
    const chosenUnits = units[unitSystems[unitSel]];

    // Define known properties
    const materials = {
        copper: {
            specificHeat: unitSel === 0 ? 390 : 0.092,
            name: "copper"
        },
        water: {
            specificHeat: unitSel === 0 ? 4200 : 1,
            name: "water"
        }
    };

    // Random value generation
    const massCopper = math.randomInt(100, 1000); // in grams or pounds
    const volumeWater = unitSel === 0 ? math.randomInt(1, 5) : math.randomInt(1, 2); // in liters or gallons
    const initialTemp = unitSel === 0 ? math.randomInt(10, 30) : math.randomInt(50, 80); // in degree Celsius or Fahrenheit
    const boilingTemp = unitSel === 0 ? 100 : 212; // boiling point of water in chosen units

    const heatCopper = (massCopper / (unitSel === 0 ? 1000 : 1)) * materials.copper.specificHeat * (boilingTemp - initialTemp);
    const massWater = unitSel === 0 ? volumeWater * 1 : volumeWater * 8.34; // Convert volume to mass (kg or lb)
    const heatWater = (massWater / (unitSel === 0 ? 1000 : 1)) * materials.water.specificHeat * (boilingTemp - initialTemp);
    const totalHeat = heatCopper + heatWater; // Total heat in chosen unit system

    // Prepare output data structure
    const data = {
        params: {
            massWater:massWater,
            massCopper: massCopper,
            volumeWater: volumeWater,
            initialTemperature: initialTemp,
            boilingTemperature: boilingTemp,
            specificHeatCopper: materials.copper.specificHeat,
            specificHeatWater: materials.water.specificHeat,
            materialNameCopper: materials.copper.name,
            materialNameWater: materials.water.name,
            unitsMass: chosenUnits.mass,
            unitsVolume: chosenUnits.volume,
            unitsTemperature: chosenUnits.temperature,
            unitsSpecificHeatCopper: chosenUnits.specificHeat,
            unitsSpecificHeatWater: chosenUnits.specificHeat,
            unitsHeat: chosenUnits.heat,
            unitsHeatAlternate: chosenUnits.heatAlternate
        },
        correct_answers: {
            Q: totalHeat
        },
        nDigits: 2,
        sigfigs: 2
    };

    return data;
};

module.exports = {
    generate
};