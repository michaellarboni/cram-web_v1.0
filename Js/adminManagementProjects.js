/**
 * Fichier de gestion de la page d'aministration des projets
 */

/**
 *  gère le bouton Supprimer
 */
Array.from( // crée un array depuis la nodelist de button
    document.querySelectorAll('.deleteProject') // selectionne tous les boutons (retourne une nodelist)
).forEach(
    function (button) { // pour chaque bouton dans l'array
        button.addEventListener('click', function (e) { //ajoute un callback sur le click
            let body = { // construit le body de la requete post
                action: 'deleteProject',
                data: {
                    id: this.dataset.id,
                }
            };

            fetch('../Inc/editProjects.php', { // fait un appel asynchrone au serveur
                method: 'POST',
                cache: "no-cache",
                headers: {
                    'Content-Type': 'application/json',
                    'accepts': 'text/plain'
                },
                body: JSON.stringify(body) // converti l'objet javascript body en json
            }).then((response) => { // si le serveur repond ok
                if (response.status === 201) {
                    window.location="../Php/index.php?EX=adminManagementProjects";
                }
            }).catch((error) => alert(error));

        });
    });

/**
 *  Script de configuration de manager
 */

//Si on sélectionne un manager dans les autres manager, on n'a accès qu'à ajout et l'autre liste est vidée
function choixLesManagers() {
    var nb = document.formManager.managers.options.length;
    for (i = 0; i < nb; i++) {
        document.formManager.managers.options[i].selected = false;
    }
    document.formManager.suppression.disabled = true;

    document.formManager.ajout.disabled = estVide(document.formManager.autresmanagers) === true;
}

//Si on sélectionne un manager dans les managers associés, on n'a accès qu'à suppression et l'autre liste est vidée
function choixManagers() {
    var nb = document.formManager.autresmanagers.options.length;
    for (i = 0; i < nb; i++) {
        document.formManager.autresmanagers.options[i].selected = false;
    }
    document.formManager.ajout.disabled = true;

    document.formManager.suppression.disabled = estVide(document.formManager.managers) === true;
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
