<?php
session_start();
include_once('connexion.php');
 

$user       = $_SESSION['id'];
$date_min = $_POST['date_min'];
$date_max   = $_POST['date_max'];


$tasks = PdoBdd::getMyTasks($user,$date_min, $date_max);
// $tasks = PdoBdd::getMyTasks($_SESSION['id'], new \DateTime($_POST['date_min']), new \DateTime($_POST['date_max']));


echo json_encode($tasks);
 
?>
