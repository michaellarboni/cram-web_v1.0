<?php
require('../Inc/require.inc.php');
$musers = new MUsers();

session_name('cram-web');
session_start();

$user       = $_SESSION['ID'];
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
            $musers->clearTask($user, $date->format('Y-m-d'), $part);

        }
    }
}

