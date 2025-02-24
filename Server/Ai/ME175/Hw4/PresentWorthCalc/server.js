const math = require('mathjs');

const generate = () => {
    // Cost and financial parameters
    const unitSystems = {
        si: {
            cost: 'USD',
            income: 'USD',
            expenses: 'USD',
            years: 'years'
        },
        uscs: {
            cost: 'USD',
            income: 'USD',
            expenses: 'USD',
            years: 'years'
        }
    };

    // Dynamic Parameter Selection
 selectedSystem = math.randomInt(0, 2) === 0 ? 'si' : 'uscs';
 units = unitSystems[selectedSystem];

    // Value Generation
 cost = math.randomInt(10, 20)*1000; // Cost of the saw
 lifespan = 7; // Fixed lifespan
 salvageValue = math.randomInt(1, 8)*1000; // Estimated salvage value
 annualIncome = math.randomInt(8000, 10001); // Annual income
 annualExpenses = math.randomInt(1000, 5001); // Annual operating expenses
 MARR = math.randomInt(5, 16); // MARR in percentage


    // Calculate Equivalent Present Worth (EPW)
    const cashFlows = [];
    for (let year = 1; year <= lifespan; year++) {
        cashFlows.push(annualIncome - annualExpenses);
    }
    // Add the salvage value in the last year
    cashFlows[lifespan - 1] += salvageValue;

    // Calculate present worth using the formula
    let presentWorth = 0;
    for (let year = 0; year < cashFlows.length; year++) {
        presentWorth += cashFlows[year] / math.pow(1 + MARR / 100, year + 1);
    }

    // Rounding off the present worth
    presentWorth = math.round(presentWorth, 3) - cost; // rounding to 3 decimal places

    // Return the structured data
    return {
        params: {
            cost: cost,
            lifespan: lifespan,
            salvageValue: salvageValue,
            annualIncome: annualIncome,
            annualExpenses: annualExpenses,
            MARR: MARR,
            unitsCost: units.cost,
            unitsYears: units.years,
            unitsIncome: units.income,
            unitsExpenses: units.expenses
        },
        correct_answers: {
            presentWorth: math.round(presentWorth,2)
        },
        nDigits: 3,
        sigfigs: 3
    };
};

module.exports = {
    generate
};

// Example usage:
const result = generate();
console.log(result);