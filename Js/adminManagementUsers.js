/**
 * Fichier de gestion de la page d'aministration des utilisateurs
 */

/**
 *  gère le bouton ADMIN
 */
Array.from( // crée un array depuis la nodelist de button
    document.querySelectorAll('.setAdminBtn') // selectionne tous les boutons (retourne une nodelist)
).forEach(
    function (button) { // pour chaque bouton dans l'array
        button.addEventListener('click', function (e) { //ajoute un callback sur le click
            let body = { // construit le body de la requete post
                action: 'setAdmin',
                data: {
                    id: this.dataset.id,
                }
            };

            fetch('../Php/editUsers.php', { // fait un appel asynchrone au serveur
                method: 'POST',
                cache: "no-cache",
                headers: {
                    'Content-Type': 'application/json',
                    'accepts': 'text/plain'
                },
                body: JSON.stringify(body) // converti l'objet javascript body en json
            }).then((response) => { // si le serveur repond ok
                if (response.status === 201) {
                    if (this.parentNode.querySelector('span').innerHTML === 'yes') {
                        this.parentNode.querySelector('span').innerHTML = 'no';
                    } else {
                        this.parentNode.querySelector('span').innerHTML = 'yes';

                    }
                }
            }).catch((error) => alert(error));

        });
    });

/**
 *  gère le bouton STATUT
 */
Array.from( // crée un array depuis la nodelist de button
    document.querySelectorAll('.setValidBtn') // selectionne tous les boutons (retourne une nodelist)
).forEach(
    function (button) { // pour chaque bouton dans l'array
        button.addEventListener('click', function (e) { //ajoute un callback sur le click
            let body = { // construit le body de la requete post
                action: 'setValid',
                data: {
                    id: this.dataset.id,
                }
            };

            fetch('../Php/editUsers.php', { // fait un appel asynchrone au serveur
                method: 'POST',
                cache: "no-cache",
                headers: {
                    'Content-Type': 'application/json',
                    'accepts': 'text/plain'
                },
                body: JSON.stringify(body) // converti l'objet javascript body en json
            }).then((response) => { // si le serveur repond ok
                if (response.status === 201) {
                    if (this.parentNode.querySelector('span').innerHTML === 'valid') {
                        this.parentNode.querySelector('span').innerHTML = 'pending';
                    } else {
                        this.parentNode.querySelector('span').innerHTML = 'valid';

                    }
                }
            }).catch((error) => alert(error));

        });
    });

/**
 *  gère le bouton date
 */
Array.from( // crée un array depuis la nodelist de button
    document.querySelectorAll('.setValidDate') // selectionne tous les boutons (retourne une nodelist)
).forEach(
    function (button) { // pour chaque bouton dans l'array
        button.addEventListener('click', function (e) { //ajoute un callback sur le click
            let body = { // construit le body de la requete post
                action: 'setDate',
                data: {
                    id: this.dataset.id,
                    userstartdate: this.parentNode.querySelector('input').value,
                }
            };

            fetch('../Php/editUsers.php', { // fait un appel asynchrone au serveur
                method: 'POST',
                cache: "no-cache",
                headers: {
                    'Content-Type': 'application/json',
                    'accepts': 'text/plain'
                },
                body: JSON.stringify(body) // converti l'objet javascript body en json
            }).then((response) => { // si le serveur repond ok
                if (response.status === 201) {
                    this.classList.add("hidden");
                }
                else{
                    alert("la date d'entrée doit être antérieur ou égale à la date de 1ère tache de l'utilisateur");
                    this.classList.add("hidden");
                    //todo afficher la date de la plus ancienne tache
                }
            }).catch((error) => alert(error));

        });
    });

/**
 *  gère le bouton date
 */
Array.from( // crée un array depuis la nodelist de button
    document.querySelectorAll('.inputDate') // selectionne tous les boutons (retourne une nodelist)
).forEach(
    function (input) { // pour chaque bouton dans l'array
        input.addEventListener('change', function (e) {
            this.parentNode.querySelector('button').classList.remove("hidden");
            // this.parentNode.querySelector('span').innerHTML = 'attention';
        });
        // button.addEventListener('click', function (e) { //ajoute un callback sur le click
        //     let body = { // construit le body de la requete post
        //         action: 'setDate',
        //         data: {
        //             id: this.dataset.id,
        //             userstartdate: document.querySelector('#userstartdate').value,
        //         }
        //     };
        //
        //     fetch('../Php/editUsers.php', { // fait un appel asynchrone au serveur
        //         method: 'POST',
        //         cache: "no-cache",
        //         headers: {
        //             'Content-Type': 'application/json',
        //             'accepts': 'text/plain'
        //         },
        //         body: JSON.stringify(body) // converti l'objet javascript body en json
        //     }).then((response) => { // si le serveur repond ok
        //         if (response.status === 201) {
        //         }
        //     }).catch((error) => alert(error));
        //
        // });
    });