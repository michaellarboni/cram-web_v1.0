
<?php


if (!isset($_SESSION['lang'])) { //si il n'y a pas encore de variable session langue (l'utilisateur n'a pas choisi)
    if (isset($HTTP_ACCEPT_LANGUAGE)) {
        $Langue = explode(",", $HTTP_ACCEPT_LANGUAGE);
        $Langue = strtolower(substr(chop($Langue[0]), 0, 2));
    } else {
        $Langue == 'fr'; //le français est la langue par défaut
    }
} else {
    $Langue = $_SESSION['lang'];
}

if ($Langue == 'en') { //si la langue est l'anglais, on inclus les deux fichiers associés
    include('langues/en.php'); //ce fichier gère le texte sur les boutons, etc...
} else { //si c'est une autre langue, cela deviendra français
    include('langues/fr.php');  //ce fichier gère le texte sur les boutons, etc...
}

?>