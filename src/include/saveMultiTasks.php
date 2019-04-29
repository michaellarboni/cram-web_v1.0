<?php
require("connexion.php");
session_start();
if ($_SESSION['lang'] == 'en'){
    include('langues/en.php');
}
else{
    include('langues/fr.php');
}

$comment    = $_POST['comment'];
$projet     = $_POST['projet'];
$activity   = $_POST['activity'];
$holiday    = (isset($_POST["holiday"]))?"TRUE":"FALSE";
$dates      = $_POST['dates'];
$action     = $_POST['action'];


if(count($dates) > 0){
    foreach($dates as $d){
        $date = new \DateTime($d);
        $part = ($date->format('H') == 8)?"am":"pm";
        
        if($action=="add"){
            PdoBdd::saveTask($_SESSION['id'], $date->format('Y-m-d'), $part, $holiday, $projet, $activity, $comment);
        }
    }
}
?>
