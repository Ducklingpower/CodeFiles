const math = require('mathjs');

const generate = () => {
    const celsiusToKelvin = (celsius) => celsius + 273.15;

    // Dynamic Parameter Selection is not necessary here because we know the input temperatures
    const tempC_a = math.round(math.random(-50,50));  // Temperature in Celsius
    const tempC_b = math.round(math.random(-50,50));  // Temperature in Celsius

    // Calculate temperatures in Kelvin
    const tempK_a = celsiusToKelvin(tempC_a);
    const tempK_b = celsiusToKelvin(tempC_b);

    const data = {
        params: {
            tempC_a: tempC_a,  // Original temperature in Celsius
            tempC_b: tempC_b   // Original temperature in Celsius
        },
        correct_answers: {
            temp_a: math.round(tempK_a, 2),  // Temperature in Kelvin, rounded to 2 decimal places
            temp_b: math.round(tempK_b, 2)   // Temperature in Kelvin, rounded to 2 decimal places
        },
        nDigits: 2,  // Define the number of digits after the decimal place.
        sigfigs: 3   // Define the number of significant figures for the answer.
    };

    console.log(data);
    return data;
};

module.exports = {
    generate
};