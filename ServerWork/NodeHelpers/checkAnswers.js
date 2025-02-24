const { ResultSetDependencies, abs } = require('mathjs');
const math = require('mathjs')
const uutil = require('underscore')

/**
 * Helper function to output a value in the console. Value will be formatted.
 * @param {*} value
 */
function print (value) {
    const precision = 14
    console.log(math.format(value, precision))
  }
  

const compareNumericalValues = (a, ref, errTol) =>{
    let results = {
        res: false,
        errors: ''
    }
    d = math.subtract(a,ref);
   // console.log(`Is ${d} = ${a} - ${ref} < ${errTol}`);
   if ( math.abs(ref) < errTol) {
        if ( math.abs(d) < errTol) {
            results.res = true;
        }else{
            results.errors = 'Response mismatch';
        }
   } else {
       if ( math.abs(d)/math.abs(ref) < errTol) {
            results.res = true;
       } else {
            results.errors = 'Response mismatch';
       }
   }
 

    return results;
}

const convertPythonMatrixToJS = (inputMat) =>{
    results = {
        res: '',
        errors: ''
    }
    console.log(`Input Mat has type ${typeof(inputMat)} and has value ${inputMat}`);
    inputMat = inputMat.trim();
    numRows = countInstances(inputMat,'[') -1 ;
    x = inputMat.replaceAll('[', '').replaceAll(']', '').split(',');
    if ( math.mod(x.length, numRows) > 0) {
        results.errors = 'Incorrect number of elements in matrix';
        return results;
    }

    numCols = x.length/numRows;

    ma = [];
    for ( let i = 0; i < numRows; i++){
        mc = []; 
        for (let j = 0; j < numCols; j++){
            mc.push(Number(x[i*numCols + j]));
        }
        ma.push(mc);
    }
    
    results.res = math.matrix(ma);
    return results;
}

const convertMATLABMatrixtoJS = (inputMat) => {
    results = {
        res: '',
        errors: ''
    }
    m = inputMat.replace('[','').replace(']','');
    m1 = m.split(';');
    numRows = m1.length;

    ma = [];
    for ( let i = 0; i < numRows; i++){
        mc = []; 
        x = m1[i].trim().split(' ');

        let numCols = x.length;
        for (let j = 0; j < numCols; j++){
            mc.push(Number(x[j]));
        }
        ma.push(mc);
    }

    return results = {
        res: math.matrix(ma),
        errors: ''
    }

}


const compareMatrices = (a, ref, errTol) => {
    results = {
        res: '',
        errors: ''
    }

    try {
    d = math.subtract(a, ref);
    n = math.norm(d,1);
    if ( n < errTol){
        results['res'] = true;
    } else{
        results['res'] = false;
        results['errors'] += 'Response mismatch';
    }

    } catch (err) {
            results.res = false;
            results.errors += err.message;
    }

    return results;
}


const checkAnswer = (referenceData, studentResponse) =>{
    correctAnswerNum = Number(referenceData['correct-answers']);
    studentResponseNum = Number(studentResponse);
    sigFigs = Number(referenceData['sigfigs']);
    errTolerance = `1e-${sigFigs}`;
    isCorrect = compareNumericalValue = (a, ref, errTolerance);
    return isCorrect;
}

const processSingleNumeric = (refResponse, studentResponse, sigFigs) =>{
    sresp = studentResponse['studentResponse'];
    responseId = studentResponse.responseId;

   // key = Object.keys(refResponse);
    refVal = refResponse[responseId];
    errTol = Number(`1e-${sigFigs}`);
    console.log(`Comparing ${refVal} and ${sresp} to accuracy ${errTol} `);
    isCorrect = compareNumericalValues(refVal, sresp, errTol);
    console.log('isCorrect is ', isCorrect);
    return isCorrect;

}

const processSingleMatrix = (refResponse, studentResponse, sigFigs) =>{
    sresp = studentResponse['studentResponse'];
    const respResults = convertMATLABMatrixtoJS(sresp);
    let respMatrix = respResults['res'];

    if (respResults['errors']) {
        results = {
            res: false,
            errors: respResults['errors']
        };
        return results;
    }

    key = Object.keys(refResponse);
    refVal = refResponse[key];
    let strMat = math.matrix(refVal["_value"]);
    

    let refMatrix;
    if (typeof(strMat) === "string") {
        refResults = convertPythonMatrixToJS(strMat);
        refMatrix = refResults['res'];
    } else if (typeof(strMat) === "object") {
        refMatrix = strMat;
    }
    console.log(`String mat is ${typeof(strMat)} and Ref matrix is ${typeof(refMatrix)}`);
    errTol = Number(`1e-${sigFigs}`);
    console.log(`Now comparing ${refMatrix} and ${respMatrix} to tolerance ${errTol}`);
    isCorrect = compareMatrices(refMatrix, respMatrix, errTol );
    return isCorrect;
    
}

const checkMultipleAnswerResponse = (refResponses, sResponse) =>{
    results = {
        res: false,
        errors:''
    };
    console.log(`Reference is ${refResponses['answers']} and Stud is ${sResponse}`);
    
    rResp = refResponses.answers[0].correct_answers.sort();
    sResp = sResponse['studentResponse'].sort();

    console.log(`Ref: ${rResp} while Student : ${sResp}`);

    if ( uutil.isEqual(rResp, sResp)) {
        results.res = true;
    }
    else {
        results.errors = 'Response mismatch'
    }

    console.log('RESUKTS IS ', results);
    return results;

    

}

const checkMultipleChoiceResponse = (refResponses, sResponse)=>{
   // console.log(`Reference is ${refResponses['answers']} and Stud is ${studentResponse}`);

    results = {
        res: false,
        errors:''
    }
    rResp = refResponses.answers[0].correct_answers;
    sResp = sResponse['studentResponse'];

    if (rResp == sResp) {
        results.res = true;
    } else {
        results.errors = 'Response mismatch'
    }
    
    console.log('RESULTS IN MCQ is ', results)
    return results;
    
}

const checkNumericResponse = (refResponses, studentResponse)=>{
    console.log(`Reference is ${refResponses} and Stud is ${studentResponse}`);
    correct_answers = refResponses['correct_answers'];
    responseId = studentResponse.responseId;
    console.log('RESPONSE ID: ', responseId);
    let results = {
        res: false,
        errors: ''
    }
    if (correct_answers.length == undefined) {
        sigFigs = refResponses['sigfigs'];
    //    isCorrect = processSingleNumeric(correct_answers,studentResponses[0], sigFigs);
        console.log('CORRECT ANSWER IS ', correct_answers);
       // key = Object.keys(correct_answers);
        refVal = correct_answers[responseId];
        console.log(`KEY IS ${responseId} and refVal is ${refVal}`);
        if ( typeof(refVal) == "object"){
            if ("_type" in refVal){
            results = processSingleMatrix(correct_answers, studentResponse, sigFigs);
            }
        } else if (typeof(refVal) == "number") {
            results = processSingleNumeric(correct_answers,studentResponse, sigFigs);
        }
        console.log('IS CORRECT IS: ', results);
    }
    return results;
}

const checkAllResponses = (refResponses, studentResponses) => {
    correct_answers = refResponses['correct_answers'];

    if (correct_answers.length == undefined) {
        sigFigs = refResponses['sigfigs'];
    //    isCorrect = processSingleNumeric(correct_answers,studentResponses[0], sigFigs);
        console.log('CORRECT ANSWER IS ', correct_answers);
        key = Object.keys(correct_answers);
        refVal = correct_answers[key];
     //   console.log(' REF VAL is ', typeof(refVal));
        if ( typeof(refVal) == "object"){
            if ("_type" in refVal){
            isCorrect = processSingleMatrix(correct_answers, studentResponses[0], sigFigs);
            }
        } else if (typeof(refVal) == "number") {
            isCorrect = processSingleNumeric(correct_answers,studentResponses[0], sigFigs);
        }
        console.log('IS CORRECT IS: ', isCorrect);

    }
    else {


    }

}

const checkAllResponses1 = (referenceData, studentResponses) => {

    console.log('Reference data is ', referenceData);
    correct_answers = referenceData['correct_answers'];
    console.log('Reference response is ', correct_answers);
    console.log('Student Responses in check is ', studentResponses);

    key = Object.keys(correct_answers);
    console.log('Refval key is ', key[0]);
    console.log('Reference Value is ', refVal);

    for (k in studentResponses ) {
        resp = studentResponses[k];
        refVal = correct_answers[key[k]];
        console.log('RESPONSE IS: ', resp);
    if ( "_type" in refVal){
        if ( refVal["_type"] === "ndarray") {
            let strMat = refVal["_value"];
            console.log('StrMat is ', strMat, ' and has type ', typeof(strMat));

            if (typeof(strMat) === "string") {
                 refResults = convertPythonMatrixToJS(strMat);
                 refMatrix = refResults['res'];
            } else if (typeof(strMat) === "object") {
                refMatrix = strMat;
            }

            console.log('Reference Matrix is ', refMatrix);
            const respMatString = resp['studentResponse'];
            console.log('MATLAB string is ', respMatString);
            const respResults = convertMATLABMatrixtoJS(respMatString);
            const respMatrix = respResults['res'];
            console.log('Converted Response Matrix: ', respResults['res']);
            sigFigs = referenceData['sigfigs'];
            console.log('Sig figs is ', sigFigs);
            errTol = Number(`1e-${sigFigs}`);
            if ( !results['errors']) {
                isCorrect = compareMatrices(refMatrix, respMatrix, errTol );
            }
        }
    }else{ 
        sresp = resp['studentResponse'];
        sigFigs = referenceData['sigfigs'];
        console.log('Sig figs is ', sigFigs);
        errTol = Number(`1e-${sigFigs}`);
        console.log(`Comparing ${refVal} and ${sresp} to accuracy ${errTol} `);
        isCorrect = compareNumericalValues(refVal, sresp, errTol);
    }
}

    return isCorrect;

    // }
}


module.exports = {
    checkNumericResponse,
    checkMultipleChoiceResponse,
    checkMultipleAnswerResponse
}



// const a = 5;
// const ref = 5;
// const errTolerance = "1e-4";

// val = compareNumericalValue(a,ref, errTolerance);
// console.log(`The result of comparison of ${a} and ${ref} is `, val);

// A = math.matrix([])
// const d1 = math.matrix([[5, 6], [1, 1]]);
// const d2 = math.matrix([ [8, 9],[10, 11]]);
// const d3 = d1;
// const d4 = math.matrix([[1,2,3], [4,5,6]]);

// A = d1;
// B = d2;

// results = compareMatrices(d1, d2, errTolerance);
// console.log(`Matrix ${A} and ${B} are equal: ${results['errors']}`);