/**
 *  Script de configuration du profil l'utilisateur
 *  Activités
 */

//Si l'activité sélectionnée est dans la liste des autres activités, alors on n'a accès qu'à ajout et l'autre liste est vidée
function choixLesActivites() {
    var nb = document.formActivities.mesactivites.options.length;
    for (i = 0; i < nb; i++) {
        document.formActivities.mesactivites.options[i].selected = false;
    }
    document.formActivities.suppression.disabled = true;

    document.formActivities.ajout.disabled = estVide(document.formActivities.autresactivites) === true;
}

//Si l'activité sélectionnée est dans la liste des activités associées, alors on n'a accès qu'à suppresion et l'autre liste est vidée
function choixMesActivites() {
    var nb = document.formActivities.autresactivites.options.length;
    for (i = 0; i < nb; i++) {
        document.formActivities.autresactivites.options[i].selected = false;
    }
    document.formActivities.ajout.disabled = true;

    document.formActivities.suppression.disabled = estVide(document.formActivities.mesactivites) === true;
}

//La fonction va vérifier s'il y a encore des éléments cochés dans la liste en paramètre
function estVide(liste) {
    var count = 0;
    for (i = 0; i < liste.options.length; i++) {
        if (liste.options[i].selected) {
            count++;
        }
    }
    return count === 0;
}
