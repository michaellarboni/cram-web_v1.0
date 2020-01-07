/**
 * Fichier Javascript appelant tous les autres fichiers
 */
const src = [];
let i = 0;


src[i++] = '../libs/fullcalendar/dist/fullcalendar.min.js';

for (let j = 0; j < i; ++j)
{
  document.write('<script src="' + src[j] + '"></script>');
}
