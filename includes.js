// Based on https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/includes

if ( ! Array.prototype.includes ) {
  Array.prototype.includes = function(searchElement) {
    'use strict';

    var len = this.length;
    if (len === 0) {
      return false;
    }

    var currentElement;
    
    for (var i=0; i<len; i++) {
      currentElement = this[i];

      if ( searchElement === currentElement || (isNaN(searchElement) && isNaN(currentElement)) ) {
        return true;
      }
    }

    return false;
  };
}
