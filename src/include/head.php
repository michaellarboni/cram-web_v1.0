<?php
session_start();
require "include/connexion.php";
$pdo = PdoBdd::getPdoBdd();

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
?>
<html>
    <head>
        <meta charset="utf-8">
        <title>Cram</title>

        <meta name="viewport" content="width=device-width, initial-scale=1.0">

        <!--Tous les includes nécessaire-->
        <link href="./public/css/bootstrap.css" rel="stylesheet" type="text/css">
        <link href="./public/css/bootstrap-responsive.css" rel="stylesheet" type="text/css">
        <link href='./public/libs/fullcalendar/dist/fullcalendar.css' rel='stylesheet' />
        <link href='./public/libs/fullcalendar/dist/fullcalendar.print.css' rel='stylesheet' media='print' />
        <link href='./public/libs/fontawesome/css/font-awesome.min.css' rel='stylesheet' />
        <link href="./public/libs/jquery-ui/themes/redmond/jquery-ui.min.css" rel="stylesheet" type="text/css">
        <link href="./public/libs/fancybox/source/jquery.fancybox.css?v=2.1.5" rel="stylesheet" type="text/css" media="screen" />
        <link href='./public/css/style.css' rel='stylesheet' />
        
        <?php
        if ($Langue == 'en') { //si la langue est l'anglais, on inclus les deux fichiers associés
            include('include/langues/en.php'); //ce fichier gère le texte sur les boutons, etc...
        } else { //si c'est une autre langue, cela deviendra français
            include('include/langues/fr.php');  //ce fichier gère le texte sur les boutons, etc...
        }
        ?>

        <script src='./public/libs/jquery/jquery.min.js'></script>
        <script src='./public/libs/jquery-ui/ui/minified/jquery-ui.min.js'></script>
        <script src='./public/libs/moment/min/moment.min.js'></script>
        <script src='./public/libs/fullcalendar/dist/fullcalendar.min.js'></script>
        <script src="./public/libs/bootstrap/docs/assets/js/bootstrap.js"></script>
        <script src='./public/libs/fancybox/source/jquery.fancybox.pack.js?v=2.1.5'></script>
        <script src='./public/libs/jquery.form/jquery.form.js'></script>
        
    </head>
</html>



