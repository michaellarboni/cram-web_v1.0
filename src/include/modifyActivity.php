<?php
require("connexion.php");
session_start();

if (isset($_POST['autresactivites'])) //si on a sélectionné des activités dans la liste des autres activités
{
    foreach ($_POST['autresactivites'] as $value)
    {
        PdoBdd::addActivity($value, $_SESSION['id']); //On associe ces activités à l'utilisateur
    }
}
else // sinon, soit si on a sélectionné des activités déjà associées
{
    foreach ($_POST['mesactivites'] as $value)
    {
         PdoBdd::deleteActivity($value, $_SESSION['id']); //On supprime l'association entre les activités et l'utilisateur
    }
}
header('Location: ../userConfigurationActivities.php');

?>
