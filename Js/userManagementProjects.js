/**
 *  Script de configuration du profil l'utilisateur
 *  Projets
 */

//Si on sélectionne un projet dans les autres projets, on n'a accès qu'à ajout et l'autre liste est vidée
function choixLesProjets() {
    var nb = document.formProject.mesprojets.options.length;
    for (i = 0; i < nb; i++) {
        document.formProject.mesprojets.options[i].selected = false;
    }
    document.formProject.suppression.disabled = true;

    document.formProject.ajout.disabled = estVide(document.formProject.autresprojets) === true;
}

//Si on sélectionne un projet dans les projets associés, on n'a accès qu'à suppression et l'autre liste est vidée
function choixMesProjets() {
    var nb = document.formProject.autresprojets.options.length;
    for (i = 0; i < nb; i++) {
        document.formProject.autresprojets.options[i].selected = false;
    }
    document.formProject.ajout.disabled = true;

    document.formProject.suppression.disabled = estVide(document.formProject.mesprojets) === true;
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
