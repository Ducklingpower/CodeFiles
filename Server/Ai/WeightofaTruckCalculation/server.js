const physics = require('mathjs');

class BrakeEnergyCalculator {
    /**
     * Converts speed from kilometers per hour to meters per second.
     * @param {number} speedKmH - The speed in kilometers per hour.
     * @return {number} The speed in meters per second.
     */
    static kmHtoMs(speedKmH) {
        return speedKmH * (1000 / 3600);
    }

    /**
     * Calculates the heat energy gained by each brake drum.
     * @param {number} mass - The mass of the brake drum in kilograms.
     * @param {number} specificHeat - The specific heat of the brake material in J/(kg*C).
     * @param {number} tempIncrease - The temperature increase in Celsius.
     * @return {number} The heat energy in Joules.
     */
    static heatEnergy(mass, specificHeat, tempIncrease) {
        return mass * specificHeat * tempIncrease;
    }
}

const generate = () => {
    // Extracting parameters from the problem statement
    const { speed, distance, numTires, diameter, weight, tempIncrease, specificHeat } = params;

    // Convert speed to m/s from km/h
    const initialSpeed = BrakeEnergyCalculator.kmHtoMs(speed);

    // Assuming the final speed is 0 (since the truck comes to a halt)
    const finalSpeed = 0;

    // Calculate the kinetic energy lost by the truck (which is converted into heat energy by the brakes)
    // Since kinetic energy (KE) = 1/2 * m * v^2, and we assume that the total KE lost is equal to the total heat gained by the brakes,
    // We rearrange the equation to solve for the mass of the truck (m).
    // Note: We are ignoring the mass of the brakes themselves for simplicity in this calculation.
    const totalHeatEnergy = numTires * BrakeEnergyCalculator.heatEnergy(weight, specificHeat, tempIncrease);
    const truckMass = (2 * totalHeatEnergy) / (initialSpeed ** 2);

    // Convert truck mass to weight assuming Earth's gravity
    const gravity = 9.81; // m/s^2
    const truckWeight = physics.round(truckMass * gravity, 3); // rounding to 3 decimal places

    return {
        truckWeight: truckWeight
    };
};



// Example usage:
const problemParams = {
    speed: 80, // km/h
    distance: 100, // meters (not directly used in this calculation)
    numTires: 4,
    diameter: 0.5, // meters (not directly used in this calculation)
    weight: 5, // kg per brake drum
    tempIncrease: 100, // Celsius
    specificHeat: 450 // J/(kg*C)
};



generate();

module.exports = {
    generate
}