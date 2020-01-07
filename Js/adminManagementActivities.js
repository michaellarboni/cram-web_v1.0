/**
 * Fichier de gestion de la page d'aministration des utilisateurs
 */

/**
 *  gère le bouton Supprimer
 */
Array.from( // crée un array depuis la nodelist de button
    document.querySelectorAll('.deleteActivity') // selectionne tous les boutons (retourne une nodelist)
).forEach(
    function (button) { // pour chaque bouton dans l'array
        button.addEventListener('click', function () { //ajoute un callback sur le click
            let body = { // construit le body de la requete post
                action: 'deleteActivity',
                data: {
                    id: this.dataset.id,
                }
            };

            fetch('../Php/editActivities.php', { // fait un appel asynchrone au serveur
                method: 'POST',
                cache: "no-cache",
                headers: {
                    'Content-Type': 'application/json',
                    'accepts': 'text/plain'
                },
                body: JSON.stringify(body) // converti l'objet javascript body en json
            }).then((response) => { // si le serveur repond ok
                if (response.status === 201) {
                    window.location="../Php/index.php?EX=adminManagementActivities";
                }
            }).catch((error) => alert(error));

        });
    });


/**
 *  gère le bouton Ajouter
 */
Array.from( // crée un array depuis la nodelist de button
    document.querySelectorAll('#insertActivity') // selectionne tous les boutons (retourne une nodelist)
).forEach(
    function (button) { // pour chaque bouton dans l'array
        button.addEventListener('click', function () { //ajoute un callback sur le click
            alert('ok');
            button.submit();
            let body = { // construit le body de la requete post
                action: 'insertActivity',
                data: {
                    id: this.dataset.id,
                }
            };

            fetch('../Php/editActivities.php', { // fait un appel asynchrone au serveur
                method: 'POST',
                cache: "no-cache",
                headers: {
                    'Content-Type': 'application/json',
                    'accepts': 'text/plain'
                },
                body: JSON.stringify(body) // converti l'objet javascript body en json
            }).then((response) => { // si le serveur repond ok
                if (response.status === 201) {

                }
            }).catch((error) => alert(error));

        });
    });
