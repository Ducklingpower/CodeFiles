const math = require('mathjs');

const generate = () => {
    // Define the parameters for cash flow calculations
     beforeTaxAndLoanCashFlow = math.randomInt(8000, 10000); // Random before-tax cash flow
     loanPrincipalPayment = math.randomInt(1500, 2000); // Random loan principal payment
     loanInterestPayment = math.round(loanPrincipalPayment*.15,2);
     macrsDepreciationDeduction = math.randomInt(4000, 5000); // Random MACRS depreciation deduction
     tax = math.randomInt(15,25);


     i = tax/100;

    // Calculate taxable income
     taxable = beforeTaxAndLoanCashFlow - loanInterestPayment - macrsDepreciationDeduction;


     // part 2

     taxPayed = taxable*i;

    // part 3

    ATCF = beforeTaxAndLoanCashFlow-taxPayed-loanPrincipalPayment;
    // Prepare return data
     data = {
        params: {
            before_tax_and_loan_cash_flow: beforeTaxAndLoanCashFlow,
            loan_principal_payment: loanPrincipalPayment,
            loan_interest_payment: loanInterestPayment,
            macrs_depreciation_deduction: macrsDepreciationDeduction,
            tax:tax,
        },
        correct_answers: {
            taxable: math.round(taxable,2),
            taxPayed:math.round(taxPayed,2),
            ATCF:math.round(ATCF,2),
        },
        nDigits: 2,
        sigfigs: 2
    };

    console.log(data);
    return data;
};

module.exports = { generate };