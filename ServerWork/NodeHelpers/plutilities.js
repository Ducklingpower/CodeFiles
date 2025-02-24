const math = require('mathjs');
const mathhelper = require('./mathhelper.js');
const _ = require("lodash");

const replace_params = (x,data) =>{
    while ( st = x.match('{{') ) {
        stind = st.index;
        enind = x.match('}}').index;
        fullString = x.slice( stind, enind+2);
     //   console.log(`FullString is ${fullString}`);
        if ( fullString.includes('params')) {
            y  = x.slice( stind+ 9, enind);
       //     console.log(`In PARAMS ${y}`);
        //    d = data['params'][y];
            d = _.get(data.params, y);
            x = x.replace(fullString,d);
        } 
        else if (fullString.includes('param_labels')) {
     //       console.log(`In PARAM LABELS ${y}`);
            y  = x.slice( stind+ 15, enind);
            d = data['param_labels'][y];
            x = x.replace(fullString,d);
        }
        else if (fullString.includes('correct_answers_labels')) {
      //      console.log(`In CORRECT ANSWER LABEL ${y}`);
            y  = x.slice( stind+ 25, enind);
            d = data['correct_answers_labels'][y];
            x = x.replace(fullString,d);
        }
        else if (fullString.includes('correct_answers')) {
            y  = x.slice( stind+ 18, enind);
            d = data['correct_answers'][y];
            x = x.replace(fullString,d);
        }
 //       console.log(`From ${fullString}, we are replacing ${y} with ${d}`);
    }
    return x;
}

const pl_symbolic_input = ($,qdate,el)=>{
    const att = $(el).attr();
    dp = att['answers-name'];
    val = qdata['correct_answers'][dp];
    let label = att['label'];
    if (!label) {
        label = "Answer";
    }
    const formOpen = `<form action = "" method =""> <fieldset class="answers"> <legend> Answer </legend>`;
    let s = `<p> <label for="response"> ${label} </label> <input type="text" name="response" id="C" size="50"/> </p>`;
    let formEnd = "</fieldset> </form>";
    htmlString = formOpen.concat(s);
    htmlString = htmlString.concat(formEnd);
    return htmlString;
}

const pl_figure = ($, qname, el)=>{
    const att = $(el).attr();
    nm= att['file-name']; 
    //imFileName = qdir + '/clientFilesQuestion/' + nm;
    imFileName = '/questions/' + qname + '/' + nm;
    const htmlString = `<img src="${imFileName}" alt="Picture for problem" style="width:400;height:auto;" class="pic" />`;
    return htmlString;
}

const pl_quest_prompt = ($, qname, el)=>{
    let htmlString = `<p>`;
    htmlString += $(el).contents();
    htmlString += `</p>`;
    return htmlString;
}

const pl_mca_adaptive = ($, qdata, el) => {
    h1 = $(el).find('pl-checkbox');
    let htmlString = ``;
    const att = $(h1).attr();
    nm = att['answers-name'];
    console.log('NAME = ', nm);

    h2 = $(h1).find('pl-answer');
    h2.each( (i,ael) => {
        const att1 = $(ael).attr();
        choiceName = att1['choice-name'];
        console.log('CHOICE NAME = ', choiceName);
        console.log('CORRECT ANSWERS = ', qdata.correct_answers[nm]);
        att1['correct'] = qdata.correct_answers[nm][choiceName];
    });

    return htmlString;
}

const pl_mcq_adaptive = ($, qdata, el)=>{
    h1 = $(el).find('pl-multiple-choice');
    let htmlString = ``;
    const att = $(h1).attr();
    nm = att['answers-name'];
    console.log('NAME = ', nm);

    h2 = $(h1).find('pl-answer');
    h2.each( (i,ael) => {
        const att1 = $(ael).attr();
        choiceName = att1['choice-name'];
        console.log('CHOICE NAME = ', choiceName);
        console.log('CORRECT ANSWERS = ', qdata.correct_answers[nm]);
        att1['correct'] = qdata.correct_answers[nm][choiceName];
    });

    return htmlString;
}

const pl_checkbox = ($,el)=>{
    const att = $(el).attr();
    nm = att['answers-name'];
    cs = $(el).children();
   // console.log(cs.length);
    
    let htmlString = `<form class="answers" action="" method="" name = ${nm}> \n`;
    B = mathhelper.getRandomPermutationRange(cs.length);
    let correctAnswers = [];
    let itemOrder = [];
    for (let j = 0; j < B.length; j++) {
        let i = B[j];
  //  for (let i = 0; i < cs.length; i++) {
      let tx = cs[i.toString()].children[0].data.trim();
     // console.log(`${i} : ${tx}`);
      let id = "child".concat(i);
      console.log('Child node correctness is ', cs[i.toString()]['attribs']['correct']);
      if (cs[i.toString()]['attribs']['correct'] === 'true') {
          console.log(`Pushing ${id} onto correct-answers`);
          correctAnswers.push(id);
      }
      itemOrder.push(id);
      let s = `<input class ="response" type="checkbox" name="${nm}" id="${id}" value="${j+1}">  <label for="${id}"> ${j+1}. ${tx} </label> <br\> \n` ;
      //let s = `<input class ="response" type="checkbox" name="${nm}" id="${id}">  <label> ${tx} </label> <br\>` ;
      htmlString = htmlString.concat(s);
    }
    htmlString += "<div class='feedback'> </div> \n";
    htmlString = htmlString.concat('</form>');
    return {
        name: nm,
        htmlString: htmlString,
        correctAnswers: correctAnswers,
        itemOrder: itemOrder
    }
}

const pl_multiple_choice = ($,el)=>{
    const att = $(el).attr();
    // console.log('Attribute = ', att);
    nm= att['answers-name'];
    cs = $(el).children();
    let htmlString = `<form name = ${nm} class = "answers" action="" method=""> \n`;
    htmlString += '<fieldset>'
    B = mathhelper.getRandomPermutationRange(cs.length);
    let correctAnswers = [];
    let itemOrder = [];
    console.log(' B = ', B, ' cs.length = ', cs.length);
    for (let j = 0; j < B.length; j++) {
        let i = B[j];
  //  for (let i = 0; i < cs.length; i++) {
        let tx = cs[i.toString()].children[0].data.trim();
        let id = "child".concat(i);
        console.log('Child node correctness is ', cs[i.toString()]['attribs']['correct']);
        if (cs[i.toString()]['attribs']['correct'] === 'true') {
            console.log(`Pushing ${id} onto correct-answers`);
            correctAnswers.push(id);
        }
        itemOrder.push(id);
        let s = `<input type="radio" name="${nm}" class="response" id="${id}" value="${j+1}">  ${j+1}. ${tx} </br> \n`;
        //let s = `<input type="radio" name="${nm}" class="response" id="${id}"> ${tx} <br/> `;
       // console.log(`This string is: ${s}`);
        htmlString = htmlString.concat(s);
        }
    htmlString += '</fieldset>'
    htmlString += "<div class='feedback'> </div> \n";
    htmlString = htmlString.concat('</form>');
    return {
        name: nm,
        htmlString: htmlString,
        correctAnswers: correctAnswers,
        itemOrder: itemOrder
    }
}

const pl_static_text = ($, qdata, el)=> {
    const att = $(el).attr();
    dp = att['name'];
    return dp;
}

// const pl_static_text = ($, qdata, el)=> {
//     const att = $(el).attr();
//     dp = att['name'];
//     let tx = $(el).contents();
//   //  console.log('TEXT HERE IS ', tx);
//     tx.each(function (i, elem) {
//         t = $(this).text();
//         console.log('Item # = ', i, ' T HERE IS ', t);
//       });
//     return htmlString;
// }

const pl_number_input_fixed = ($, qdata, el)=>{
    const att = $(el).attr();
    let correctAnswers = [];
    dp = att['answers-name'];
    if (att['correct-answer-fixed']) {
        val = att['correct-answer-fixed'];
        sigfigs = att['digits'];
    } else{
        val = qdata['correct_answers'][dp];
    }
    const formOpen = `<form class = "answers" name="${dp}" action = "" method =""> <fieldset class=""> <legend> Answer </legend>`;
    let s = `<p> <label for="response"> ${att['label']} </label> <input type="number" class="response" name="${dp}" id="${dp}" size="50"/> </p>`;
    
    let formEnd = "</fieldset> <div class='feedback'> </div> </form>";
    htmlString = formOpen.concat(s);
    htmlString = htmlString.concat(formEnd);

    return {
        name: dp,
        htmlString: htmlString,
        correctAnswers: val,
        sigfigs: sigfigs
    }
    
}

const pl_number_input = ($, qdata, el)=>{
    const att = $(el).attr();
    dp = att['answers-name'];
    if (att['correct-answer']) {
        val = att['correct-answer'];
    } else{
        val = qdata['correct_answers'][dp];
    }
    const formOpen = `<form class = "answers" name="${dp}" action = "" method =""> <fieldset class=""> <legend> Answer </legend>`;
    let s = `<p> <label for="response"> ${att['label']} </label> <input type="number" class="response" name="${dp}" id="${dp}" size="50"/> </p>`;
    
    let formEnd = "</fieldset> <div class='feedback'> </div> </form>";
    htmlString = formOpen.concat(s);
    htmlString = htmlString.concat(formEnd);
    return htmlString;
    
}

const pl_hint = ($,qdata,el) => {
    const att = $(el).attr();
    let htmlString = $(el).html();
    return htmlString;
}

const pl_matrix_input = ($,qdata,el)=>{
    const att = $(el).attr();
   // console.log('Attribute = ', att);
  //  console.log('QDATA-222 ', qdata);
    dp = att['answers-name'];
 //   console.log('ANSWERS NAME is ',dp);
    // val = qdata['correct_answers'][dp];
    // console.log('CORRECT ANSWER IS :',val);
    // let st = emitLatexMatrix(val);
  //  console.log('C = ', st);
    const formOpen = `<form class="answers" name = "${dp}" action = "" method =""> <fieldset > <legend> Answer </legend>`;
    let s = `<p> <label for="response"> ${att['label']} </label> <input type="matrix" class="response" name="${dp}" id="${dp}" size="150"/> </p>`;
    let formEnd = "</fieldset> <div class='feedback'> </div> </form>";
    htmlString = formOpen.concat(s);
    htmlString = htmlString.concat(formEnd);
    return htmlString;
  //  console.log(htmlString);
}

const pl_matrix_latex = ($,qdata,el)=>{
    const att = $(el).attr();
    console.log(att['params-name']);
    dp = att['params-name'];
    val = qdata["params"][dp];
    
    let st = emitLatexMatrix(val);
    return st;
}

const emitLatexMatrix= (mat)=>{
    console.log('In Emit LATEX: ', mat);
    let innerString = "";
    ms = mat;
  //  ms= mat._value;
 
    let nrow = ms.length;
    let c = 0;
    ms.forEach( row=>{
        let rowString = "";
        let ncol = row.length;
        let r = 0;
        row.forEach( el => {
            el = math.round(100*el)/100;
            rowString = rowString.concat(el);
            
            if (r < ncol-1) {
                rowString = rowString.concat(' & ');
            }    
            r += 1;        
        });
        innerString = innerString.concat(rowString);
        
        if (c < nrow - 1) {
            innerString = innerString.concat('\\\\');
        }
        c += 1;
    });

    let st = '\\begin{bmatrix} '.concat(innerString);
    st = st.concat('\\end{bmatrix}');
    return st;
 }


module.exports = {
                pl_checkbox,
                pl_multiple_choice,
                pl_figure,
                pl_number_input,
                pl_symbolic_input,
                pl_checkbox,
                pl_multiple_choice,
                pl_matrix_input,
                pl_matrix_latex,
                replace_params,
                pl_static_text,
                pl_quest_prompt,
                pl_mcq_adaptive,
                pl_mca_adaptive,
                pl_number_input_fixed,
                pl_hint,
                emitLatexMatrix
                };