<?php
require("connexion.php");
session_start();
if (isset($_POST['autresprojets'])) //si on a sélectionné des projets dans la liste des autres projets
{
    foreach ($_POST['autresprojets'] as $value)
    {
        PdoBdd::addProject($value, $_SESSION['id']); //On associe ces projets à l'utilisateur
    }
}
else // sinon, soit si on a sélectionné des projets déjà associés
{
    foreach ($_POST['mesprojets'] as $value)
    {
         PdoBdd::deleteProject($value, $_SESSION['id']); //On supprime l'association entre les projets et l'utilisateur
    }
}
header('Location: ../userConfiguration.php');

?>
