<?php
require("../Inc/require.inc.php");
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
$next       = $_POST['save_next'];
$previous   = $_POST['save_previous'];

if (!isset($next)) {
    $next = "";
}
if (!isset($previous)) {
 
    $previous="";
}
    if(count($dates) > 0){
        foreach($dates as $d){
            $date = new \DateTime($d);
            $part = ($date->format('H') == 8)?"am":"pm";
            
            if($action=="add"){
                $musers->saveTask($user, $date->format('Y-m-d'), $part, $holiday, $projet, $activity, $comment);
            }
        }
    }
