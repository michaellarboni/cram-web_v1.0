<?php
require('../Inc/require.inc.php');
$musers = new MUsers();

session_name('cram-web');
session_start();

$user       = $_SESSION['ID'];
$date_min   = $_POST['date_min'];
$date_max   = $_POST['date_max'];

$tasks= $musers->getMyTasks($user,$date_min, $date_max);

echo json_encode($tasks);
