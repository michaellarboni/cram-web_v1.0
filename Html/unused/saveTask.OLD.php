<?php
require("connexion.php");
session_start();

//On récupère les données du formulaire
$date = $_POST['date'];
$ampm = $_POST['ampm'];

if (isset($_POST['ajouter']))
{
    $valide = true;
    if (isset($_POST['off']))
    {
        $off = "TRUE";
        $project = null;
        $activity = null;
        $comment = '';
    }
    else
    {
        $off = "FALSE";
        $erreurs = "";

        $project = $_POST['projet'];
        if ($project == 0)
        {
            $valide = false;
            $erreurs = $erreurs.$noProject;
        }

        $activity = $_POST['activite'];
        if ($activity == 0)
        {
            $valide = false;
            $erreurs = $erreurs.$noActivity;
        }

        $comment = $_POST['commentaire'];
        if ($comment > 500)
        {
            $valide = false;
            $erreurs = $erreurs.$noComment;
        }
    }

    if ($valide == true)
    {
        //Si la tâche a été choisie pour am ou pm, alors on l'ajoute directement dans la BDD
        if ($ampm != "am-pm")
        {
            PdoBdd::saveTask($_SESSION['id'], $date, $ampm, $off, $project, $activity, $comment);
        }

        //Si la tâche a été choisie pour am&pm, alors on l'ajoute deux fois : une fois pour am, une fois pour pm
        else
        {
             PdoBdd::saveTask($_SESSION['id'], $date, 'am', $off, $project, $activity, $comment);
             PdoBdd::saveTask($_SESSION['id'], $date, 'pm', $off, $project, $activity, $comment);
        }

       header('Location: /myTasksManagement.php'); //todo verifier chemin
    }
    else
    {
        header('Location: ../addTask.php?date='.$date.'&am='.$ampm.'&project='.$project.
                '&activity='.$activity.'&comment='.$comment.'&erreurs='.$erreurs);
    }
}
else if (isset($_POST['effacer']))
{
   //Si la tâche a été choisie pour am ou pm, alors on la supprime directement dans la BDD
        if ($ampm != "am-pm")
        {
            PdoBdd::clearTask($_SESSION['id'], $date, $ampm);
        }

        //Si la tâche a été choisie pour am&pm, alors on la supprime deux fois : une fois pour am, une fois pour pm
        else
        {
             PdoBdd::clearTask($_SESSION['id'], $date, 'am');
             PdoBdd::clearTask($_SESSION['id'], $date, 'pm');
        }

        header('Location: /myTasksManagement.php'); //todo verifier chemin
}
else
{
    if (isset($_POST['off']))
    {
        $off = "TRUE";
    }
    else
    {
        $off = "FALSE";
    }
    $projet = $_POST['projet'];
    $activite = $_POST['activite'];
    $commentaire = $_POST['commentaire'];
    header('Location:../duplicateTask.php?date='.$date.'&ampm='.$ampm.'&off='.$off.'&projet='.$projet
            .'&activite='.$activite.'&commentaire='.$commentaire);
}
?>
