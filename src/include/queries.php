

<?php

if (!isset($_SESSION['id'])) {
    header('Location: index.php');
}
require_once 'connexion.php';
// include 'head2.php';

    $user = $_SESSION['id'];
    $date_begin = $_SESSION['date_begin'];
    $date_end = $_SESSION['date_end'];

    function leaderService($user){
        $leader = PdoBdd::leaderService($user);
        return $leader;
    }

    // variable de demande de requete pour les graphes et tableaux du la page reportingLeader
    function leaderUser($user) {
    // resultat sur les users du leader associe
        $leader_user= PdoBdd::leaderUser($user); 
        return json_encode($leader_user);
    }
     
    function leaderProject($user){// resultat sur les projet par rapport a l'user
        $leader_project = PdoBdd::leaderProject($user);
        return  json_encode($leader_project);
    }
    
    function userProjectLeaderDays($service,$date_begin,$date_end){// resultat sur les projets du leader avec les utilisateurs associe en leur jour effectués par rapport a une periode daté
        $user_project_leader_days = PdoBdd::userProjectLeaderDay($service,$date_begin,$date_end);
        return  json_encode($user_project_leader_days);
    }

    function userActivityLeaderDays($service,$date_begin,$date_end){
    // resultat sur les projets du leader avec les utilisateurs associe en leur jour effectués par rapport a une periode daté
        $user_activity_leader_days = PdoBdd::userActivityLeaderDay($service,$date_begin,$date_end);
        return json_encode($user_activity_leader_days);
    }

       // methode qui vas appeler la classe PdoBdd pour faire la requete et demander les projects associe au manager; 
       function managerProject($user){
        $manager_project = PdoBdd::managerProject($user);
        return $manager_project;
    }

    // methode qui vas apeler la calsse PdoBdd pour faire la requete et demander les user correspondant au manager;
    function projectUser($project) {
    // resultat sur les users du manager associe
        $project_user= PdoBdd::managerUser($project); 
        return json_encode($project_user);
    }

    function servicesUsers($user){
        $service_user = PdoBdd::serviceUser($user);
        return json_encode($service_user);
    }

    // methode pour recuperer les jours effectuer par users des services associe au projet avec la periode par date
    function servicesUsersDaysProjects($project,$date_begin,$date_end){
        $services_users_jours_project = PdoBdd::servicesUsersDaysProject($project,$date_begin,$date_end);
        return json_encode($services_users_jours_project);
    }

    function activityUsersDaysProjects($project,$date_begin,$date_end){
        $activity_users_days_projects = PdoBdd::activityUsersDaysProject($project,$date_begin,$date_end);
        return json_encode($activity_users_days_projects);
    }
function holidaysDay($user,$date_begin,$date_end){
    $holidays = PdoBdd::holiday($user,$date_begin,$date_end);
    return $holidays;
}



    // variable de demande de requete pour les graphes et tableaux du la page reportingLeader
 

    function managerProjectServices($project){
        $manager_Project_services = PdoBdd::managerProjectServices($project);
        return json_encode($manager_Project_services);
    }

    function userServiceManagerDays($user,$date_begin,$date_end){// resultat sur les projets du leader avec les utilisateurs associe en leur jour effectués par rapport a une periode daté
        $user_service_manager_days = PdoBdd::userServiceManagerDays($user,$date_begin,$date_end);
        return  json_encode($user_service_manager_days);
    }

?>


            
     



            