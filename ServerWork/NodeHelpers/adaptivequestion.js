const spawn = require('child_process').spawn;
const pythonPath = 'C:/Users/vsundar/Anaconda3/python';
//const process = spawn(pythonPath,['./accessprairielearn.py','Sundar!']);
const fs = require('fs');
const cheerio = require('cheerio');
const proc = require('process');

const questionName = "addNumbers";
const qdir = "../questions/".concat(questionName);
const qoutDir ="../questionsoutput/".concat(questionName);
const plutil = require('./plutilities.js');

const curDir = proc.cwd();




// const replace_params = (x,data) =>{
//     while ( st = x.match('{{') ) {
//         stind = st.index;
//         enind = x.match('}}').index;
//         fullString = x.slice( stind, enind+2);
//         y  = x.slice( stind+ 9, enind);
//         d = data['params'][y];
//         x = x.replace(fullString,d);
//        // console.log(`From ${fullString}, we are replacing ${y} with ${d}`);
//     }
//     return x;
// }

// const pl_symbolic_input = ($,qdate,el)=>{
//     const att = $(el).attr();
//     dp = att['answers-name'];
//     val = qdata['correct_answers'][dp];
//     let label = att['label'];
//     if (!label) {
//         label = "Answer";
//     }
//     const formOpen = `<form action = "" method =""> <fieldset class="answers"> <legend> Answer </legend>`;
//     let s = `<p> <label for="response"> ${label} </label> <input type="text" name="response" id="C" size="50"/> </p>`;
//     let formEnd = "</fieldset> </form>";
//     htmlString = formOpen.concat(s);
//     htmlString = htmlString.concat(formEnd);
//     return htmlString;
// }

// const pl_number_input = ($, qdata, el)=>{
//     const att = $(el).attr();
//     dp = att['answers-name'];
//     val = qdata['correct_answers'][dp];
//     const formOpen = `<form action = "" method =""> <fieldset class="answers"> <legend> Answer </legend>`;
//     let s = `<p> <label for="response"> ${att['label']} </label> <input type="text" name="response" id="C" size="50"/> </p>`;
//     let formEnd = "</fieldset> </form>";
//     htmlString = formOpen.concat(s);
//     htmlString = htmlString.concat(formEnd);
//     return htmlString;
    
// }



// const pl_matrix_input = ($,qdata,el)=>{
//     const att = $(el).attr();
//    // console.log('Attribute = ', att);
//     dp = att['answers-name'];
//   //  console.log(dp);
//     val = qdata['correct_answers'][dp];
//   //  console.log(val);
//     let st = emitLatexMatrix(val);
//     console.log('C = ', st);
//     const formOpen = `<form action = "" method =""> <fieldset class="answers"> <legend> Answer </legend>`;
//     let s = `<p> <label for="response"> ${att['label']} </label> <input type="text" name="response" id="C" size="50"/> </p>`;
//     let formEnd = "</fieldset> </form>";
//     htmlString = formOpen.concat(s);
//     htmlString = htmlString.concat(formEnd);
//     return htmlString;
//   //  console.log(htmlString);
// }

// const pl_matrix_latex = ($,qdata,el)=>{
//     const att = $(el).attr();
//     console.log(att['params-name']);
//     dp = att['params-name'];
//     val = qdata["params"][dp];
//  //   console.log(dp,' ', val);
//     let st = emitLatexMatrix(val);
//     return st;
// }

// const emitLatexMatrix= (mat)=>{
    
//     let innerString = "";
//     ms= mat._value;
//     console.log('in Emit Latex Matrix ', ms);
//     let nrow = ms.length;
//     let c = 0;
//     ms.forEach( row=>{
//         let rowString = "";
//         let ncol = row.length;
//         let r = 0;
//         row.forEach( el => {
//             rowString = rowString.concat(el);
            
//             if (r < ncol-1) {
//                 rowString = rowString.concat(' & ');
//             }    
//             r += 1;        
//         });
//         innerString = innerString.concat(rowString);
        
//         if (c < nrow - 1) {
//             innerString = innerString.concat('\\\\');
//         }
//         c += 1;
//     });

//     let st = '\\begin{bmatrix} '.concat(innerString);
//     st = st.concat('\\end{bmatrix}');
//     return st;
//  }

fs.readFile(qdir.concat('/question.html'),  (err,html)=>{
        if(err){
            console.log('Error in reading file', err);
        }else{
         //  console.log('Outputing file', html.toString());
           
           fs.readFile(qdir.concat('/server.py'), (err, pyf) =>{
                if (err){
                    console.log('Unable to read server.py in ', qdir);
                }
                else{
                    fs.writeFile('./server.py', pyf, (err) =>{
                        if (err){
                            console.log('Error writing file');
                        }
                    });
                }
           });
           const process = spawn(pythonPath,['./accessprairielearn.py','Sundar!']);

           process.stdout.on('data', async data=>{
              //  datastring = data.join("");

                let dataString = new String();
                data.forEach( i=>{ ii = String.fromCharCode(i); dataString = dataString.concat(ii);})
                //console.log(`Output in here is ${typeof(dataString)} is ${dataString}`);
                dataString = dataString.replaceAll('\'','\"');
               // console.log(`After replacement: Output in here is ${typeof(dataString)} is ${dataString}`);
                qdata = JSON.parse(dataString);
                console.log('After replacement the data string is ', qdata);
                r = /\$([^\$]*)\$/g; // set up regular expression to take care of math
                html = html.toString().replace(r,'\\( $1 \\)');

                html = plutil.replace_params(html,qdata);

                const $ = cheerio.load(html, null, false);
                

                const polyfill = '<script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>';
                const mathjax = '<script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>';

                $('head').append(polyfill);
                $('head').append(mathjax);
                
                let h;
                 

                h = $('pl-matrix-input');
                h.each( (i,el) =>{
                    htmlString = plutil.pl_matrix_input($,qdata,el);
                    $(el).before(htmlString);
                    $(el).remove();
                 });

                 h = $('pl-matrix-latex');
                 h.each( (i,el)=>{
                    htmlString = plutil.pl_matrix_latex($, qdata, el);
                    $(el).before(htmlString);
                    $(el).remove();
                 });


                 h = $('pl-number-input');
                 h.each( (i,el) =>{
                    htmlString = plutil.pl_number_input($, qdata, el);
                    $(el).before(htmlString);
                    $(el).remove();
                 });

                 h = $('pl-symbolic-input');
                 h.each( (i,el)=>{
                    htmlString = plutil.pl_symbolic_input($, qdata, el);
                    $(el).before(htmlString);
                    $(el).remove();
                 });

                h = $('pl-question-panel');
                h.wrapAll('<div class="wrapper">');
                h.each( (i,el)=>{
                    let cnt = $(el).contents();
                    let par = $(el).parent();
                    $(el).replaceWith(cnt);
                });
            
                let im = $('pl-figure');
                im.each( (i,el)=>{
            // const att = $(el).attr();
            // nm= att['file-name']; 
            // imFileName = qdir + '/clientFilesQuestion/' + nm;
            // const htmlString = `<img src="${imFileName}" alt="Picture for problem" width="300" height="300" class="pic" />`;
            htmlString = plutil.pl_figure($,qdir,el);
            $(el).before(htmlString);
            $(el).remove();
       });

        h = $('pl-checkbox');
       h.each( (i,el)=>{
          htmlString = plutil.pl_checkbox($, el);
     //     console.log(htmlString);
          $(el).before(htmlString);
          $(el).remove();
       });

       h = $('pl-multiple-choice');
       h.each( (i,el)=>{
        htmlString = plutil.pl_multiple_choice($,el);
       // console.log(htmlString);
        $(el).before(htmlString);
        $(el).remove();
       });

                
        console.log($.html());
        
        const outHTMLfname = qoutDir + '/questionoutput.html';
        console.log(outHTMLfname);

        fs.mkdir(qoutDir, (err)=>{
        console.log(`In Creating Directory: ${err}`);
        fs.writeFile(outHTMLfname, $.html(), errw=>{
            if (errw)
            console.log('Error writing output file');
            });
        });


        });

           process.stderr.on('data', data=>{
               console.log(`stderr is: ${data}`);
           });

           process.on('close',(code)=>{
               console.log(`Child process exited with code ${code}`);
           });
        }
        return html;
    });







