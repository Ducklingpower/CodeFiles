const math = require('mathjs')


function removeItemOnce(arr, value) {
    var index = arr.indexOf(value);
    if (index > -1) {
      arr.splice(index, 1);
    }
    return arr;
  }

function getRandomPermutationArray(A1) {
    A = A1._data;
    numEls = A.length;
    B = [];
 for (let i = 0; i < numEls; i++) {
    x = math.pickRandom(A);
    y = removeItemOnce(A,x);
    B.push(x);
 }
 return B;
}

function getRandomPermutationRange(num){
    A = math.range(0, num);
    B = getRandomPermutationArray(A);
    return B;

}

function getRandomInt(max) {
  return Math.floor(Math.random() * max);
}

function shuffleArray(array) {
  for (var i = array.length - 1; i > 0; i--) {
      var j = Math.floor(Math.random() * (i + 1));
      var temp = array[i];
      array[i] = array[j];
      array[j] = temp;
  }
}

function getRandomMask(maxElements, minOnes, maxOnes ) {
  let selectionMask;
  (selectionMask = []).length = maxElements;
  selectionMask.fill(0);
  let numOnes = math.randomInt(minOnes, maxOnes);
  for (let i = 0; i < numOnes; i++) {
      selectionMask[i] = 1;
  }
  shuffleArray(selectionMask);
  console.log('Shuffled array = ', selectionMask);

  return selectionMask;

}

module.exports = {
    getRandomPermutationRange,
    getRandomInt,
    getRandomPermutationArray,
    shuffleArray,
    getRandomMask
}

// B = getRandomPermutationRange(4);
// console.log(B);