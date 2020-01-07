/**
 * Fichier Javascript appelant tous les autres fichiers
 */

var src = new Array();
var i = 0;

src[i++] = 'calcul.js';
src[i++] = 'form.js';
src[i++] = 'peintres.js';
src[i++] = 'init.js';

for (var j = 0; j < i; ++j)
{
  document.write('<script src="../Js/' + src[j] + '"></script>');
}
