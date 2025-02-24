const fs = require('fs');
const cheerio = require('cheerio');
const proc = require('process');

const questionName = "positionTimeGraph";
const qdir = "./questions/".concat(questionName);
const qoutDir ="./questionsoutput/".concat(questionName);
const plutil = require('./plutilities.js');



fs.readFile(qdir.concat('/question.html') , (err,html)=>{
    if (err) {
        console.log('Cannot read file ', qdir.concat('/question.html'));
    }else{
        r = /\$([^\$]*)\$/g; // set up regular expression to take care of math
        html = html.toString().replace(r,'\\( $1 \\)');
        const $ = cheerio.load(html, null, false);
                
        const polyfill = '<script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>';
        const mathjax = '<script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>';

        $('head').append(polyfill);
        $('head').append(mathjax);

       let im = $('pl-figure');
       im.each( (i,el)=>{
            // const att = $(el).attr();
            // nm= att['file-name']; 
            // imFileName = qdir + '/clientFilesQuestion/' + nm;
            // const htmlString = `<img src="${imFileName}" alt="Picture for problem" width="300" height="300" class="pic" />`;
            htmlString = plutil.pl_figure($,qoutDir,el);
            $(el).before(htmlString);
            $(el).remove();
       });

       let h = $('pl-checkbox');
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

       const h2 = $('pl-number-input');
       h2.each( (i,el) =>{
        qdata = {};
          htmlString = plutil.pl_number_input($, qdata, el);
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

       console.log($.html());
       const outHTMLfname = qoutDir + '/questionoutput.html';
       console.log(outHTMLfname);

       fs.mkdir(qoutDir, (err)=>{
       console.log(`In Creating Directory: ${err}`);
       fs.writeFile(outHTMLfname, $.html(), err=>{
           if (err)
           console.log('Error writing output file', err);
           });
       });

       sclientFiles = qdir + '/clientFilesQuestion';
       dclientFiles = qoutDir + '/clientFilesQuestion';
       console.log(`Attempting to copy from ${sclientFiles} tp ${dclientFiles}`);
       fs.cp(qdir + '/clientFilesQuestion',  qoutDir + '/clientFilesQuestion', {recursive: true}, err =>{
            if (err){
                console.log('Error copying clientFilesQuestion directory ');
            } else{
                console.log('Client files directory copied over');
            }
       })

    //    fs.writeFile('./questionoutput1.html', $.html(), err=>{
    //     if (err)
    //     console.log('Error writing output file');
    //  });
            
            //console.log($(el).children()[0]);
            // let htmlString = '<form action="" method = "" >';
            // children = $(el).children();
            // console.log('Number of children is ', children);
            // for (let i = 0; i < children.length; i++){
            //     child = children[i];
            //     console.log(`${i} : ${child}`);
            //     tx = child.textContent;
            //     id = "child".concat(i);
            //     let s = `<label for=${tx}> ${tx} </label> <input type="checkbox" name=${tx} id=${id}`;
            //     htmlString = htmlString.concat(s);
            // }
            // console.log(htmlString);
            // $(el).before(htmlString);
            // $(el).remove();
        

    }
});