const math = require('mathjs');

const generate = () => {
    // Interest compounding frequencies
    const compoundingFrequencies = {
        monthly: 12,
        weekly: 52,
        daily: 365
    };

    // 1. Dynamic Parameter Selection
    const principal = math.randomInt(1000, 10001); // Principal amount between $1000 and $10000
    const interestRate = math.randomInt(1, 11); // Interest rate between 1% and 10%

    // 2. Value Generation
    const calculateAmount = (principal, rate, n) => {
        const r = rate / 100; // convert percentage to a decimal
        return principal * Math.pow((1 + r / n), n);
    };

    // 3. Solution Synthesis
    const amountMonthly = calculateAmount(principal, interestRate, compoundingFrequencies.monthly);
    const amountWeekly = calculateAmount(principal, interestRate, compoundingFrequencies.weekly);
    const amountDaily = calculateAmount(principal, interestRate, compoundingFrequencies.daily);

    // Return the structured data
    return {
        params: {
            principal: principal,
            interestRate: interestRate
        },
        correct_answers: {
            amountMonthly: math.round(amountMonthly, 3),
            amountWeekly: math.round(amountWeekly, 3),
            amountDaily: math.round(amountDaily, 3)
        },
        nDigits: 3,
        sigfigs: 3
    };
};

module.exports = {
    generate
};