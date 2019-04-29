<?php
require("connexion.php");
session_start();


$enddate = $_POST['enddate'];
$year = substr($enddate, 0, -6);
$month = substr($enddate, 5, -3);
$day = substr($enddate, 8);
$projet = $_GET['projet'];
$activite = $_GET['activite'];
$commentaire = $_GET['commentaire'];
$off = $_GET['off'];
if ($off == "TRUE")
{
    $projet = null;
    $activite = null;
    $commentaire = '';
}

if (checkdate ( $month , $day , $year ) == true)//si la date est valide
{
    $today = date('Y-m-d');
    if ($enddate > $today) //si la date de fin dépasse aujourd'hui, on la met à aujourd'hui
    {
        $enddate = $today;
    }
    
    $startdate = $_POST['startdate'];
    if ($startdate <= $enddate) //si la date de début est plus petite ou égale à la date de fin
    {
        if (isset($_POST['overwrite']))//si la personne souhaite écraser toutes les dates de l'intervalle
        {
            $date = $startdate;
            while ($date <= $enddate) //on parcourt l'intervalle et on remplace toutes les tâches
            {
               PdoBdd::saveTask($_SESSION['id'], $date, 'am', $off, $projet, $activite, $commentaire);
               PdoBdd::saveTask($_SESSION['id'], $date, 'pm', $off, $projet, $activite, $commentaire); 
               
               $date = date("Y-m-d", strtotime($date."+1 day"));
            }
           
        }
        else //si la personne ne souhaite pas écraser les tâches déjà présentes
        {
     
            $date = $startdate;
            while ($date <= $enddate) //on parcourt l'intervalle et on vérifie que la tâche n'existe pas avant de la remplacer
            {
               if (PdoBdd::tacheExiste($_SESSION['id'], $date, 'am') == false)
                    PdoBdd::saveTask($_SESSION['id'], $date, 'am', $off, $projet, $activite, $commentaire);
               if (PdoBdd::tacheExiste($_SESSION['id'], $date, 'pm') == false)
                    PdoBdd::saveTask($_SESSION['id'], $date, 'pm', $off, $projet, $activite, $commentaire); 
            
               $date = date("Y-m-d", strtotime($date."+1 day"));
            }
           
        }
        header('Location: ../myTasksManagement.php');
    }
    else
        echo "start date > end date !";

}
else
    echo $enddate." is not valid";

?>
