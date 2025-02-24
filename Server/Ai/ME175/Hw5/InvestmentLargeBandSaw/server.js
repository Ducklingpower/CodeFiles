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

i = MARR/100;
 
    



annualCashFlow = annualIncome - annualExpenses; // Net annual cash flow (income - expenses)
 years = 7; // Planning horizon

// Binary search setup
let lowerBound = 0; // 0% interest rate
let upperBound = 1; // 100% interest rate
let tolerance = 1e-6; // Tolerance for IRR accuracy

// IRR calculation using binary search
while ((upperBound - lowerBound) > tolerance) {
    let midPoint = (upperBound + lowerBound) / 2;

    // Calculate NPV at the midPoint interest rate
    let annualFactor = (1 - Math.pow(1 + midPoint, -years)) / midPoint;
    let salvageFactor = 1 / Math.pow(1 + midPoint, years);
    let npv = (annualCashFlow * annualFactor + salvageValue* salvageFactor - cost);

    if (npv > 0) {
        lowerBound = midPoint;
    } else {
        upperBound = midPoint;
    }
}

// Convert IRR to a percentage and display it
 irr = (lowerBound * 100).toFixed(2);

    // Rounding off the present worth
    presentWorth = math.round(presentWorth, 3) - cost; // rounding to 3 decimal places

    aw = presentWorth*((i*(1+i)**(7))/((1+i)**(7)-1))

    fw = presentWorth*(1+i)**(7)
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
            unitsExpenses: units.expenses,
            i:i,

        },
        correct_answers: {
            presentWorth: math.round(presentWorth,2),
            fw:math.round(fw,3),
            aw:math.round(aw,3),
            irr:math.round(irr,3),
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