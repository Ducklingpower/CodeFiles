//require('dotenv').config();
const spawn = require('child_process').spawn;
const pythonPath = process.env.PYTHONPATH;
//const pythonPath = 'C:/Users/vsundar/Anaconda3/python';
const { once } = require('events');
const fs = require('fs');
const cheerio = require('cheerio');
const proc = require('process');
const math = require('mathjs');
const mathhelper = require('./mathhelper.js');
const plutil = require('./plutilities.js');
const { Server } = require('http');
const questionPath = './questions/';

const DEBUG = true;












const writeOutputHTML = (questionName, htmlOutput) => {
    const qoutDir = "./questionsoutput/".concat(questionName);
    const outHTMLfname = qoutDir + '/questionoutput.html';
    console.log(outHTMLfname);

    fs.mkdir(qoutDir, {recursive: true},(err) => {
        console.log(`In Creating Directory: ${err}`);
        let header = `<html> <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Document</title>
        <link rel="stylesheet" href="/styles.css">
        <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
        <script id="MathJax-script" async="" src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
      </head>`;
        let footer = `</html>`;
        let htmlString = header + htmlOutput + footer;
        fs.writeFile(outHTMLfname, htmlString, errw => {
            if (errw)
                console.log('Error writing output file', errw);
        });
    });
}

const writeOutputSolution = (questionName, solnStrings) => {
    const qoutDir = "./questionsoutput/".concat(questionName);
    const outHTMLfname = qoutDir + '/solutionoutput.html';
    console.log(outHTMLfname);

    fs.mkdir(qoutDir, {recursive: true},(err) => {
        console.log(`In Creating Directory: ${err}`);
        let header = `<html> <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Document</title>
        <link rel="stylesheet" href="/styles.css">
        <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
        <script id="MathJax-script" async="" src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
      </head>`;

        let htmlBody ='';
        for (let i = 0; i < solnStrings.length; i++){
            htmlBody += `<h2> Level ${i} </h2>`;
            htmlBody += `<p>`
            htmlBody += solnStrings[i];
            htmlBody += `</p>`;
        }

        let footer = `</html>`;
        let htmlString = header + htmlBody + footer;
        fs.writeFile(outHTMLfname, htmlString, errw => {
            if (errw)
                console.log('Error writing output file', errw);
        });
    });
}

const processPrairielearnTags = (html, qdata, qdir,questionName, choiceParams) => {
    const $ = cheerio.load(html, null, false);

    let h;

    let solutions = [];

    let ans = {
        answers: []
    }

    // h = $('pl-static-text');
    // h.each((i, el) => {
    //     dp = plutil.pl_static_text($, qdata, el);
    //     $(el).before(htmlString);
    //     let cnt = $(el).contents();
    //     let par = $(el).parent();
    //     $(el).replaceWith(cnt);
    //     $(el).remove();
    // });

    h = $('pl-matrix-input');
    h.each((i, el) => {
        htmlString = plutil.pl_matrix_input($, qdata, el);
        $(el).before(htmlString);
        $(el).remove();
    });

    h = $('pl-matrix-latex');
    h.each((i, el) => {
        htmlString = plutil.pl_matrix_latex($, qdata, el);
        $(el).before(htmlString);
        $(el).remove();
    });

    h = $('pl-number-input');
    h.each((i, el) => {
        htmlString = plutil.pl_number_input($, qdata, el);
        $(el).before(htmlString);
        $(el).remove();
    });


    h = $('pl-number-input-fixed');
    h.each( (i,el) =>{
    res = plutil.pl_number_input_fixed($, qdata, el);
    htmlString = res['htmlString'];
    $(el).before(htmlString);
    $(el).remove();
    dat = {
        name: res['name'],
        correct_answers: res['correctAnswers'],
        sigfigs: res['sigfigs']
    }
    ans.answers.push(dat);
    });

    h = $('pl-symbolic-input');
    h.each((i, el) => {
        htmlString = plutil.pl_symbolic_input($, qdata, el);
        $(el).before(htmlString);
        $(el).remove();
    });

    h = $('pl-quest');
    let numQuestions = h.length;
    console.log('This contains ', numQuestions, ' questions');
    let minQuestions = math.floor(numQuestions*choiceParams.fracQuestions[0]);
    let maxQuestions = math.ceil(numQuestions*choiceParams.fracQuestions[1]);
    let numSelQuestions = math.randomInt(minQuestions, maxQuestions+1);
    console.log(`min = ${minQuestions}, max = ${maxQuestions}, numSelQuestions = ${numSelQuestions}`);
    (selectQuestionsMask = []).length = numQuestions;
    selectQuestionsMask.fill(0);
    for (let i = 0; i < numSelQuestions; i++) {
        selectQuestionsMask[i] = 1;
    }
    console.log('Selection Questions = ', selectQuestionsMask);
    mathhelper.shuffleArray(selectQuestionsMask);
    console.log('Random Selection Array = ', selectQuestionsMask); 
    h.each((i, el) => {
        if (selectQuestionsMask[i] == 1) {
            let cnt = $(el).contents();
            let par = $(el).parent();
            $(el).replaceWith(cnt);
        } else {
            $(el).replaceWith('');
        }
    });
    
    h = $('pl-mcq-adaptive');
    h.each( (i,el)=> {
        let cnt = $(el).contents();
        htmlString = plutil.pl_mcq_adaptive($,qdata,el);
        let par = $(el).parent();
        $(el).replaceWith(cnt);
    });

    h = $('pl-mca-adaptive');
    h.each( (i,el)=> {
        let cnt = $(el).contents();
        htmlString = plutil.pl_mca_adaptive($,qdata,el);
        let par = $(el).parent();
        $(el).replaceWith(cnt);
    });

    h = $('pl-quest-prompt');
    h.each( (i, el) => {
        htmlString = plutil.pl_quest_prompt($, qdata,el);
        $(el).before(htmlString);
        $(el).remove();
    });

    h = $('pl-question-panel');
    h.wrapAll('<div class="wrapper">');
    h.each((i, el) => {
        let cnt = $(el).contents();
        let par = $(el).parent();
        $(el).replaceWith(cnt);
    });

    h = $('pl-static-text');
    h.each((i, el) => {
        dp = plutil.pl_static_text($, qdata, el);
        h.wrapAll(`<div class="static_text" name=${dp}>`);
        let cnt = $(el).contents();
        let par = $(el).parent();
        $(el).replaceWith(cnt);
        $(el).remove();
    });
    // h = $('pl-static-text');
    // h.wrapAll('<div class="static_text">');
    // h.each((i, el) => {
    //     let cnt = $(el).contents();
    //     let par = $(el).parent();
    //     $(el).replaceWith(cnt);
    //     $(el).remove();
    // });
    
    let im = $('pl-figure');
    im.each((i, el) => {
        // const att = $(el).attr();
        // nm= att['file-name']; 
        // imFileName = qdir + '/clientFilesQuestion/' + nm;
        // const htmlString = `<img src="${imFileName}" alt="Picture for problem" width="300" height="300" class="pic" />`;
        htmlString = plutil.pl_figure($, questionName, el);
        $(el).before(htmlString);
        $(el).remove();
    });

    h = $('pl-checkbox');
    h.each((i, el) => {
        res = plutil.pl_checkbox($, el);
        htmlString = res['htmlString'];
        dat = {
            name: res['name'],
            correct_answers: res['correctAnswers'],
            itemOrder: res['itemOrder']
        }
        ans.answers.push(dat);
        //     console.log(htmlString);
        $(el).before(htmlString);
        $(el).remove();
    });

    h = $('pl-multiple-choice');
    h.each((i, el) => {
        res = plutil.pl_multiple_choice($, el);
        htmlString = res['htmlString'];
        dat = {
            name: res['name'],
            correct_answers: res['correctAnswers'],
            itemOrder: res['itemOrder']
        }
        ans.answers.push(dat);
        // console.log(htmlString);
        $(el).before(htmlString);
        $(el).remove();

    });

    h = $('pl-hint');
    h.each((i,el) => {
       htmlString = plutil.pl_hint($,qdata,el);
       solutions.push(htmlString);
    });

    return {
        answers: ans,
        solutions: solutions,
        htmlString: $.html()
    };
}

const generateSolutionHTMLFromString = (qdata, html, questionName) => {
    console.log('HTML IN GENE = ', html);
    console.log('QDATA = ',qdata);
    let choiceParams = { fracQuestions: [1.0, 1.0]};
    let r = /\$([^\$]*)\$/g; // set up regular expression to take care of math
    html = html.toString().replace(r,'\\( $1 \\)');
    html = plutil.replace_params(html, qdata);
    html = html.toString().replace(r,'\\( $1 \\)');
    console.log('SOLUTION HTML = ', html);
    let qdir = null;
    let res = processPrairielearnTags (html,qdata,qdir,questionName,choiceParams);
    return res.solutions;
}

const generateSolutionHTMLFromFile= (qdata, questionName, qdir = null)=> {
    return new Promise( (resolve, reject) =>{
    const solutionHTMLFile = './questions/' + questionName + '/solution.html';
    if (!qdir) {
      qdir =  questionPath + questionName;
    }
    console.log(' Solution HTML File =', solutionHTMLFile);
    fs.readFile( solutionHTMLFile, { encoding: 'utf8' },(err, html) => {
        if (err) {
            console.log('Solution file cannot be opened', err);
            reject('Unable to open solution file', err);
        } 
        else{
          //  console.log('HTMLS is = ', html);
            let choiceParams = { fracQuestions: [1.0, 1.0]};
            let r = /\$([^\$]*)\$/g; // set up regular expression to take care of math
            html = html.toString().replace(r,'\\( $1 \\)');
            html = plutil.replace_params(html, qdata);
            html = html.toString().replace(r,'\\( $1 \\)');
          //  console.log('SOLUTION HTML = ', html);
            let res = processPrairielearnTags (html,qdata,qdir,questionName,choiceParams);
            resolve(res.solutions);
        }
    });
})
}


const generateDataFromPrairieLearnFixed = async (questionName, html, choiceParams = null) => {
    return new Promise((resolve, reject) => {
       // const qdir = "./questions/".concat(questionName);
       const qdir = questionPath + questionName;
        let qdata = {};
        let r = /\$([^\$]*)\$/g; // set up regular expression to take care of math
        html = html.toString().replace(r, '\\( $1 \\)');
        html = plutil.replace_params(html, qdata);

        if (!choiceParams){
            choiceParams = {fracQuestions: [1.0, 1.0]};
        }

        let res = processPrairielearnTags(html, qdata, qdir, questionName, choiceParams);
        htmlString = res['htmlString'];
        qdata = res['answers'];
        //   console.log(`HTML Output in FIXED is :::: ${htmlOutput}`);
        if (htmlString === '') {
            reject('Error making FIXED html string');
        }
        writeOutputHTML(questionName, htmlString);

        let returnValues = {
            answers: qdata,
            htmlString: htmlString
        };
        console.log('RESULTS IS ', JSON.stringify(returnValues));
        resolve(returnValues);
    });
}

const readQuestionHTMLNonAdaptive =    (questionName) =>{
    const questionHTMLFile = questionPath + questionName + '/question.html';
    //const questionHTMLFile = "./questions/".concat(questionName) + '/question.html';
    fs.readFile(questionHTMLFile,  (err, html) =>{
      if(err){
        console.log('Error in reading file', err);
    }else{
        generateDataFromPrairieLearnFixed(questionName, html)
            .then( (returnedValues) => {
                // qdata = returnedValues['data'];
                // let solnHTML = generateSolutionHTML(qdata,questionName);
                console.log('PROMISED RESOLVED');
            })
            .catch( (err) => console.log('PROMISE REJECTED',err))
    }
  });
}

const readQuestionHTMLNonAdaptiveWithSolution =    (questionName) =>{
    const questionHTMLFile = questionPath + questionName + '/question.html';
    //const questionHTMLFile = "./questions/".concat(questionName) + '/question.html';
    fs.readFile(questionHTMLFile,  (err, html) =>{
      if(err){
        console.log('Error in reading file', err);
    }else{
        generateDataFromPrairieLearnFixed(questionName, html)
            .then( async (returnedValues) => {
                 console.log('Returned values are = ', returnedValues)
                // qdata = returnedValues['data'];
                answers = returnedValues.answers;
                let solnHTML = await generateSolutionHTMLFromFile(answers,questionName);
                console.log('Solution HTML =', solnHTML);
                writeOutputSolution(questionName,solnHTML);
                console.log('PROMISED RESOLVED');
            })
            .catch( (err) => console.log('PROMISE REJECTED',err))
    }
  });
}

const readQuestionHTML = (questionName) => {
    const questionHTMLFile = questionPath + questionName + '/question.html';
  //  const questionHTMLFile = "./questions/".concat(questionName) + '/question.html';
    fs.readFile(questionHTMLFile, (err, html) => {
        if (err) {
            console.log('Error in reading file', err);
        } else {
            //let choiceParams = { fracQuestions: [0.5, 1.0]};
            generateDataFromJSAdaptive(questionName, html)
                .then((returnedValues) => {
                    // qdata = returnedValues['data'];
                    // let solnHTML = generateSolutionHTML(qdata,questionName);
                    console.log('PROMISED RESOLVED');
                })
                .catch(() => console.log('PROMISE REJECTED'));
            //  generateDataFromPrairieLearnAdaptive(questionName, html)
            //     .then( (returnedValues)=> {
            //         console.log('PROMISED RESOLVED: ', returnedValues);
            //         return returnedValues;
            //     })
            //     .catch( ()=> console.log('PROMISE REJECTED'));

            //  x = await generateDataFromPrairieLearnFixed(questionName, html);
        }
    });
}

const readQuestionHTMLWithSolution =  (questionName) => {
    const questionHTMLFile = questionPath + questionName + '/question.html';
  //  const questionHTMLFile = "./questions/".concat(questionName) + '/question.html';
    fs.readFile(questionHTMLFile, (err, html) => {
        if (err) {
            console.log('Error in reading file', err);
        } else {
            //let choiceParams = { fracQuestions: [0.5, 1.0]};
            generateDataFromJSAdaptive(questionName, html)
                .then(async (returnedValues) => {
                    qdata = returnedValues['data'];
                    try {
                        let solnHTML = await generateSolutionHTMLFromFile(qdata,questionName);
                
                        console.log('Solution is ', solnHTML)
                        writeOutputSolution(questionName,solnHTML);
                        console.log('PROMISED RESOLVED');
                        
                    }
                    catch (err) {console.log('INNER PROMISE REJECTED',err)};
                })
                .catch((err) => console.log('OUTER PROMISE REJECTED',err));
            //  generateDataFromPrairieLearnAdaptive(questionName, html)
            //     .then( (returnedValues)=> {
            //         console.log('PROMISED RESOLVED: ', returnedValues);
            //         return returnedValues;
            //     })
            //     .catch( ()=> console.log('PROMISE REJECTED'));

            //  x = await generateDataFromPrairieLearnFixed(questionName, html);
        }
    });
}


const getDataFromPythonFile =  (questionName, html)=>{
    console.log(' INVOKING: ', pythonPath);
    let sPyFile = 'questions/' +  questionName + ".server"; // needs special
    //let sPyFile = 'questions.' +  questionName + ".server";
    sPyFile = sPyFile.replace(/\//g,".");

    console.log('Python file = ', sPyFile);
    const process = spawn(pythonPath,['./accessprairielearn.py',sPyFile]);
    return new Promise ( (resolve, reject)=>{
    process.stdout.on('data',  async data=>{
        let returnValues = {};
        let dataString = new String();
        data.forEach( i=>{ ii = String.fromCharCode(i); dataString = dataString.concat(ii);})
        //console.log(`Output in here is ${typeof(dataString)} is ${dataString}`);
        dataString = dataString.replaceAll('\'','\"');
       // console.log(`After replacement: Output in here is ${typeof(dataString)} is ${dataString}`);
        qdata = await JSON.parse(dataString);
    //    console.log(`DATA STRING is ${dataString}`)
        resolve(qdata);
    });

        process.stderr.on('data', data => {
            console.log(`stderr is: ${data}`)
            reject(`Error in spawned process ${data}`);
        });

    });
}



const generateDataFromJSAdaptive =  (questionName, html, choiceParams = null)=>{
    return new Promise ( async (resolve,reject)=>{
    const qdir =  questionPath + questionName;
  //  const qdir = "./questions/".concat(questionName);
    //const qdir = "./questions/".concat(questionName);
   
    const jsFile = qdir + "/server.js";
    console.log(`QUESTION NAME is ${questionName} and QDIR is ${qdir} and ${jsFile}`);
    const jsFuncs = await import(jsFile);
    qdata = jsFuncs.generate();

    let r = /\$([^\$]*)\$/g; // set up regular expression to take care of math
    html = html.toString().replace(r,'\\( $1 \\)');
   // console.log('HTML is ', html);
    html = plutil.replace_params(html,qdata);
    html = html.toString().replace(r,'\\( $1 \\)');
    console.log(html);
    if (!choiceParams){
        choiceParams = {fracQuestions: [1.0, 1.0]};
    }
    let res = processPrairielearnTags (html, qdata,qdir,questionName, choiceParams);
    let htmlString  = res['htmlString'];
    qdata.answers = res['answers'].answers;
    writeOutputHTML(questionName, htmlString);
    returnValues = {data: qdata,
                 htmlString: htmlString};
    resolve(returnValues);

    });
}
const generateDataFromPrairieLearnAdaptive = (questionName, html, choiceParams = null) => {
    return new Promise((resolve, reject) => {
      //  const qdir = "questions/".concat(questionName); // Needs special 
     const qdir =  questionPath + questionName;
        //const qdir = "./questions/".concat(questionName);
        // console.log(`QUESTION NAME is ${questionName} and PYTHON QDIR is ${qdir}`);
        const sPyFile = qdir + "/server.py";
        const dPyFile = "./helpers/tempservers" + "/server.py"
        // let sPyFile = 'questions.' +  questionName + ".server";
        // sPyFile = sPyFile.replace(/\//g,".");
        // fs.copyFile(sPyFile, dPyFile, (err) => {
        //     if (err) {
        //         reject(`Error copying Python file from ${sPyFile} to ${dPyFile}`);
        //     }

            getDataFromPythonFile(questionName, html)
                .then(qdata => {
                    let r = /\$([^\$]*)\$/g; // set up regular expression to take care of math
                    html = html.toString().replace(r, '\\( $1 \\)');
                    html = plutil.replace_params(html, qdata);
                    if (!choiceParams){
                        choiceParams = {fracQuestions: [1.0, 1.0]};
                    }
                    let res = processPrairielearnTags(html, qdata, qdir, questionName, choiceParams);
                    let htmlString = res['htmlString']
                    returnValues = {
                        data: qdata,
                        htmlString: htmlString
                    };
                    resolve(returnValues);
                })
                .catch(err => {
                    console.log('Error in GENERATE QUESTION');
                    reject(err);
                });
 //       });
    });

}

//const questionName = 'friction1';
//readQuestionHTML(questionName);

// const questionName = 'arithOperationMAJS';
// const questionName = "statics/distributed/distForces2Fixed";
// readQuestionHTMLNonAdaptive(questionName);

 const questionName = "Thermo/ControlledVolume/heliumCycle";
readQuestionHTMLWithSolution(questionName);

//const questionName = "friction1";
//readQuestionHTMLNonAdaptiveWithSolution(questionName);

module.exports = {
    generateDataFromPrairieLearnAdaptive,
    generateDataFromPrairieLearnFixed,
    generateDataFromJSAdaptive,
    generateSolutionHTMLFromFile,
    generateSolutionHTMLFromString
}


