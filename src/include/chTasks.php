<?php
session_start();
include('connexion.php');
 
$tasks = PdoBdd::getMyTasks($_SESSION['id'], new \DateTime($_POST['date_min']), new \DateTime($_POST['date_max']), $_POST['month_max']);

echo json_encode($tasks);
 
?>
