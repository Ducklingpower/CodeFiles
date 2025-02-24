# -*- coding: utf-8 -*-
"""
Created on Fri Nov 11 22:41:00 2022

@author: vsundar
"""
import importlib
#m = importlib.import_module("elements.pl-variable-output.pl-variable-output")
#
# m = importlib.import_module("elements.pl-matrix-latex.pl-matrix-latex")
m = importlib.import_module("tempservers.server")

#from server import generate

params = dict()
correct_answers = dict()
#params = dict(A="", B="")
#correct_answers = dict(C="")
nDigits = 2
sigfigs = 2
data = dict(params=params, correct_answers=correct_answers, nDigits=nDigits, sigfigs=sigfigs)

m.generate(data)

print(data)


# sent = '<pl-matrix-latex params-name="B" digits={{params.nDigits}}></pl-matrix-latex>'
# i1 = sent.find('{{')
# i2 = sent.find('}}')
# tag = sent[(i1+2):(i2)]
# fullTag = '{{' + tag + '}}'
# field  = tag[7:]
# r = data[field]
# print(field, ' ', r, ' ', fullTag)
# b = sent.replace(fullTag, str(r))
# print(b)
#m.prepare(sent,data)
#str = m.render(sent,data)
#print(str)
