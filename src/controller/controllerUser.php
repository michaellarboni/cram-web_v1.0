<?php

$user = $_SESSION['id'];

if (!isset ($_SESSION['id']))
{
    header('Location: ../index.php');
}
	 
// fonction pour savoir si l'utilisateur et un leader
function leader($user){
	$leader = PdoBdd::leader($user);
return $leader;
}

// fonction pour savoir si l'utilisateur et un manager
function manager($user){
	$manager = PdoBdd::manager($user);
return $manager;
}

/*
// function test sur l'état de l'utilisateur ( leader ou manager )
// Affiche le menu qui correspond
*/
function statusUser($user){
	$leader = leader($user);
	$manager = manager($user);
	if ($leader) {
		?>
			<li><a href="reportingLeader.php">Reporting Leader</a></li>
		<?php 
	}
	if ($manager) {
	?>
		<li><a href="reportingManager.php">Reporting Manager</a></li>
	<?php
	}
	?>
		<li> <a href="reportingUser.php">Reporting User</a></li>
	<?php
}

?>
 





