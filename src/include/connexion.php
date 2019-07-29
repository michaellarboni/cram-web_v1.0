<?php

// valeur pour le serveur nonlocal.
/*

        $serveur = "cram.lam.fr"; // L'adresse du serveur 
        $port='5432'; // le port TCP sur lequel écoute l'instance 
        $login = "consult"; // Votre nom d'utilisateur 
        $password = "consult"; // Votre mot de passe 
        $Base ="cram_0"; //votre base de donnée 
*/




class PdoBdd {   		
    private static $serveur='localhost';
    //  private static $serveur='cram.lam.fr';
    private static $port='5432';
    private static $bdd='cram_0';

    private static $user='cram';
    private static $mdp='docker';

    // private static $user='consult';
    // private static $mdp='consult' ;	
    
    private static $monPdo;
	//private static $monPdoBdd=null;
        
    /**
     * Constructeur privé, crée l'instance de PDO qui sera sollicitée
     * pour toutes les méthodes de la classe
     */	
	private function __construct(){
        try
            {
                PdoBdd::$monPdo = new PDO('pgsql:dbname='.PdoBdd::$bdd.'; host='.PdoBdd::$serveur.';port='.PdoBdd::$port.';', PdoBdd::$user, PdoBdd::$mdp);
                PdoBdd::$monPdo->exec("SET CHARACTER SET utf8");
            }
            catch (Exception $e)
            {
                die('Erreur : connexion failed' . $e->getMessage());
            }
         }

	public function _destruct(){
		PdoBdd::$monPdo = null;
	}
        
        
    /**
     * Fonction statique qui crée l'unique instance de la classe
     */
	public  static function getPdoBdd(){
		if(PdoBdd::$monPdo==null){
            $monPdo = new PdoBdd();
            // PdoBdd::$monPdo = new PDO('pgsql:dbname='.PdoBdd::$bdd.'; host='.PdoBdd::$serveur.';
            // port='.PdoBdd::$port.';', PdoBdd::$user, PdoBdd::$mdp);
		}
		return PdoBdd::$monPdo;  
	}
        
        
    function estConnecte() {
        return isset($_SESSION['idVisiteur']);
    }
        
    /**
    * Enregistre dans une variable session les infos d'un visiteur
    */
        
    function connecter($id,$name)
    {
        $_SESSION['idVisiteur']= $id; 
        $_SESSION['name']= $name;
    }
       
    /**
    * Détruit la session active
    */
    function deconnecter(){
        session_destroy();
    }
        
    /*Renvoie un tableau contenant toutes les informations sur toutes les tâches du user dont
    l'identifiant est passé en paramètre */
    function getMyTasks($user, $date_min, $date_max)
    {
        $pdo = PdoBdd::getPdoBdd();
        $stmt = $pdo->prepare("
            SELECT t.taskcomment as taskcomment, t.taskdate AS taskdate, t.taskam AS taskam, t.taskdayoff AS taskdayoff, 
                    full_projectname(p.projectid) AS projectname, a.activityname AS activityname
            FROM task t
                LEFT OUTER JOIN project p ON p.projectid = t.projectid
                LEFT OUTER JOIN activity a ON a.activityid = t.activityid
            WHERE t.userrid = :user 
            AND t.taskdate >= :date_min 
            AND t.taskdate <= :date_max
            ORDER BY t.taskdate, t.taskam;
        ");
        $stmt->bindParam(':user', $user);
        $stmt->bindParam(':date_min', $date_min);
        $stmt->bindParam(':date_max', $date_max);
        $stmt->execute();
        $rs = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $rs;
    }
        
    //Permet de supprimer la tâche dont la date et l'am sont passés en paramètre
    function clearTask($user, $date, $am)
    {
        $pdo = PdoBdd::getPdoBdd();
        $stmt = $pdo->prepare("DELETE FROM task WHERE userrid = :user AND taskdate = :date
            AND taskam = :am");
        $stmt->bindParam(':user', $user);
        $stmt->bindParam(':date', $date);
        $stmt->bindParam(':am', $am);
        $stmt->execute();
        PdoBdd::updateUserVersion($user);
    }
        
    //Ajoute les informations de la tâche passées en paramètre dans la base de données
    function addMyTask($user, $date, $am, $off, $idProject, $idActivity, $comment)
    {
        $pdo = PdoBdd::getPdoBdd();
        $stmt = $pdo->prepare("INSERT INTO task VALUES (:idActivity, :idProject, :user, :date, :am, :off, :comment)");
            $stmt->bindParam(':user', $user);
            $stmt->bindParam(':idActivity', $idActivity);
            $stmt->bindParam(':idProject', $idProject);
            $stmt->bindParam(':date', $date);
            $stmt->bindParam(':am', $am);
            $stmt->bindParam(':off', $off);
            $stmt->bindParam(':comment', $comment);
            $stmt->execute();
            PdoBdd::updateUserVersion($user);
    }
        
    //Vérifie si une tâche existe déjà pour un utilisateur à une date donnée et à un am donné.
    function tacheExiste($user, $date, $ampm)
    {
        $pdo = PdoBdd::getPdoBdd();
        $stmt = $pdo->prepare("SELECT * FROM task WHERE userrid = :user AND taskdate = 
            :date AND taskam = :ampm");
        $stmt->bindParam(':user', $user);
        $stmt->bindParam(':date', $date);
        $stmt->bindParam(':ampm', $ampm);
        $stmt->execute();
        $rs = $stmt->fetchAll();
        if (count($rs) == 0)
        {
            return false;
        }
        else
        {
        return true;
        }
    }
        
        /*Modifie les informations passées en paramètre pour la tâche passée en paramètre (identifiable
        grâce au user, la date et le am)*/
        function modifyTask($user, $date, $am, $off, $idProject, $idActivity, $comment)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare("UPDATE task
                                SET projectid = :idProject,
                                activityid = :idActivity,
                                taskdayoff = :off,
                                taskcomment = :comment
                                WHERE userrid = :user AND taskdate = :date AND taskam = :am");
            $stmt->bindParam(':user', $user);
            $stmt->bindParam(':idActivity', $idActivity);
            $stmt->bindParam(':idProject', $idProject);
            $stmt->bindParam(':date', $date);
            $stmt->bindParam(':am', $am);
            $stmt->bindParam(':off', $off);
            $stmt->bindParam(':comment', $comment);
            $stmt->execute();
            PdoBdd::updateUserVersion($user);
        }
        
        
        /*Grâce aux 3 fonctions précédentes, cette fonction va : 
        - Vérifier dans un premier temps si la tâche existe déjà ou non dans la BDD
        - Si oui, utiliser modifyTask() pour modifier les informations de la tâche
        - Si non, utiliser addMyTask() pour ajouter la tâche dans la BDD */
        function saveTask($user, $date, $am, $off, $idProject, $idActivity, $comment)
        {
            if($off=="TRUE"){
                $idActivity = null;
                $idProject  = null;
            }
            if (PdoBdd::tacheExiste($user, $date, $am)== true)
            {
                PdoBdd::modifyTask($user, $date, $am, $off, $idProject, $idActivity, $comment);
            }
            else
            {
                PdoBdd::addMyTask($user, $date, $am, $off, $idProject, $idActivity, $comment);
            }
        }
        
        
        /*Cette fonction va renvoyer un tableau de tous les projets et du lien qu'ils ont avec
        l'user : true si l'utilisateur passé en paramètre est lié au projet, false si non.*/
        function getAllProjects($user)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare('SELECT P.projectid, full_projectname(P.projectid) as name,
                                case when U.userrid is not null then true else false end as flag
                                from project as P
                                left join projectuser as U on (U.userrid = :user and  
                                P.projectid = U.projectid )
                                order by name;');
            $stmt->bindParam(':user', $user);
            $stmt->execute();
            $rs = $stmt->fetchAll();
            return $rs;
        }
        
        
        /*Cette fonction va renvoyer un tableau de toutes les activités et leur association à 
        l'utilisateur : true si l'utilisateur passé en paramètre est lié à l'activité, false si non.*/
        function getAllActivities($user)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare('SELECT A.activityid, activityname,
                                case when U.userrid is not null then true else false end as flag
                                from activity as A
                                left join activityuser as U on (U.userrid = :user and  
                                A.activityid = U.activityid )
                                order by activityname;');
            $stmt->bindParam(':user', $user);
            $stmt->execute();
            $rs = $stmt->fetchAll();
            return $rs;
        }
        
        
        //Le projet en paramètre est associé à l'utilisateur en paramètre. il ajoute a sa liste
        function addProject($idProject, $user)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare('INSERT INTO projectuser VALUES (:user, :project)');
            $stmt->bindParam(':user', $user);
            $stmt->bindParam(':project', $idProject);
            $stmt->execute();
            PdoBdd::updateUserVersion($user);
        }
        
        
        //Le projet en paramètre n'est plus associé à l'utilisateur en paramètre. il le supprime
        function deleteProject($idProject, $user)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare('DELETE FROM projectuser WHERE userrid = :user AND projectid = :project');
            $stmt->bindParam(':user', $user);
            $stmt->bindParam(':project', $idProject);
            $stmt->execute();
            PdoBdd::updateUserVersion($user);
        }
        
        
        //L'activité en paramètre est associée à l'utilisateur en paramètre. il ajoute a sa liste
        function addActivity($idActivity, $user)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare('INSERT INTO activityuser VALUES (:user, :activity)');
            $stmt->bindParam(':user', $user);
            $stmt->bindParam(':activity', $idActivity);
            $stmt->execute();
            
            PdoBdd::updateUserVersion($user);
        }
        
        
        //L'activité en paramètre n'est plus associée à l'utilisateur en paramètre. il le supprime
        function deleteActivity($idActivity, $user)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare('DELETE FROM activityuser WHERE userrid = :user 
                AND activityid = :activity');
            $stmt->bindParam(':user', $user);
            $stmt->bindParam(':activity', $idActivity);
            $stmt->execute();
            
            PdoBdd::updateUserVersion($user);
        }
        
        //Retourne dans un tableau les informations concernant la tâche dont la date et l'am sont en paramètre
        function getTaskInfos($user, $date, $am)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare("SELECT projectid, activityid, taskcomment FROM task 
                WHERE userrid = :user AND taskdate = :date AND taskam = :am");
            $stmt->bindParam(':user', $user);
            $stmt->bindParam(':date', $date);
            $stmt->bindParam(':am', $am);
            $stmt->execute();
            $rs = $stmt->fetchAll();
            return $rs;
        }
        
        
        //Retourne l'id de l'utilisateur passé en paramètre, et permet sa connexion
        function connexionBDD($user)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare("SELECT userrid, username FROM cramuser
                WHERE username = :user");
            $stmt->bindParam(':user', $user);
            $stmt->execute();
            $rs = $stmt->fetchAll();
            foreach ($rs as $value)
                return array("id" => $value['userrid'], "username" => $value['username']);
        }

        
        // retourne les jours effectués pour chaque activité selon une periodes daté de l'utilisateur
        function projectActivityJour($user,$date_begin,$date_end)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo ->prepare("SELECT P.projectname ,A.activityname , round(count(*)/2.,1) as etp
                 from task as T 
                 natural join activity as A
                 natural join cramuser as U
                 natural join project as P
                 where U.userrid = :user
                 and  T.taskdate between :dateBegin and :dateEnd
                 group by P.projectname,A.activityname
                 having count(*) > 0
                 order by 1;");
             $stmt->bindParam(':user',$user,PDO::PARAM_INT);
             $stmt->bindParam(':dateBegin',$date_begin,PDO::PARAM_STR);
             $stmt->bindParam(':dateEnd',$date_end,PDO::PARAM_STR);
             $stmt->execute();
             $result_stmt = $stmt->fetchAll(PDO::FETCH_NUM);
             return  $result_stmt;
         }
    
        // retourne le nom des projets associés à l'utilisateur avec le nombre de jour effectué par rapport à la date
        function projectNameDay($user,$date_begin,$date_end)
        {
            $pdo = PdoBdd::getPdoBdd();
             $stmt = $pdo ->prepare("SELECT P.projectname, count(*)/2 as etp
                 from task as T 
                 natural join project as P
                 natural join cramuser as U
                 where U.userrid = :user
                 and  T.taskdate between :dateBegin and :dateEnd
                 group by P.projectname
                 order by 1 ;");
             $stmt->bindParam(':user',$user,PDO::PARAM_INT);
             $stmt->bindParam(':dateBegin',$date_begin,PDO::PARAM_STR);
             $stmt->bindParam(':dateEnd',$date_end,PDO::PARAM_STR);
             $stmt->execute();
             $result_jour = $stmt->fetchAll(PDO::FETCH_ASSOC);
             return  $result_jour;
         }
    
        // retourne le nom des activites et les jours effectués par raport à une periode daté
        function activityNameJour($user,$date_begin,$date_end)
        {
            $pdo = PdoBdd::getPdoBdd();
             $stmt = $pdo ->prepare("SELECT A.activityname, count(*)/2 as etp
                   from task as T 
                   natural join activity as A
                   natural join cramuser as U
                   where U.userrid = :user
                   and  T.taskdate between :dateBegin and :dateEnd
                   group by A.activityname
                   order by 1 ;");
             $stmt->bindParam(':user',$user,PDO::PARAM_INT);
             $stmt->bindParam(':dateBegin',$date_begin,PDO::PARAM_STR);
             $stmt->bindParam(':dateEnd',$date_end,PDO::PARAM_STR);
             $stmt->execute();
             $result_jour = $stmt->fetchAll(PDO::FETCH_ASSOC);
             return  $result_jour;
         }
    
        // retourne les activités effectuées par rapport à une periode daté
        function activityProjectDay($user,$date_begin,$date_end)
        {
            $pdo = PdoBdd::getPdoBdd();
             $stmt = $pdo ->prepare("SELECT A.activityname  ,P.projectname ,round(count(*)/2.,1) as etp
                   from task as T 
                   natural join activity as A
                   natural join cramuser as U
                   natural join project as P
                   where U.userrid = :user
                   and  T.taskdate between :dateBegin and :dateEnd
                   group by A.activityname ,P.projectname 
                   having count(*) >0
                   order by 1;");
             $stmt->bindParam(':user',$user,PDO::PARAM_INT);
             $stmt->bindParam(':dateBegin',$date_begin,PDO::PARAM_STR);
             $stmt->bindParam(':dateEnd',$date_end,PDO::PARAM_STR);
             $stmt->execute();
             $result_jour = $stmt->fetchAll(PDO::FETCH_NUM);
             return  $result_jour;
         }
        // requete pour savoir si l user et un chef de service ou non
        function leader($user)
        {
            $pdo = PdoBdd::getPdoBdd();
             $stmt = $pdo ->prepare("SELECT T.label
                    from teamleader
                    natural join team as T
                    where userrid = :user
                    group by T.teamid;");
             $stmt->bindParam(':user',$user,PDO::PARAM_INT);
             $stmt->execute();
             $result_head = $stmt->fetchAll(PDO::FETCH_NUM);
             return  $result_head;
         }

         // parametre de l'user pour verifier dans la base de donne qu'il est chef de project true ou false
        function manager($user)
        {
            $pdo = PdoBdd::getPdoBdd();
             $stmt = $pdo ->prepare("SELECT distinct M.userrid
             from manager as M
             natural join project as P
             where M.userrid = :user;");
             $stmt->bindParam(':user',$user,PDO::PARAM_INT);
             $stmt->execute();
             $result_head = $stmt->fetchAll(PDO::FETCH_NUM);
             return  $result_head;
        }

        function managerProject($user)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo ->prepare("SELECT distinct P.projectname ,P.projectid
            from manager as M
            natural join project as P
            where M.userrid = :user
            order by P.projectname;");
            $stmt->bindParam(':user',$user,PDO::PARAM_INT);
            $stmt->execute();
            $result_name_p = $stmt->fetchAll(PDO::FETCH_ASSOC);
            return  $result_name_p;
        }

        // liste des users par rapport au project
        function projectUser($project)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo ->prepare("SELECT U.username as name, P.projectname 
            from projectuser
            natural join project as P
            natural join cramuser as U
            where projectid = :project;");
            $stmt->bindParam(':project',$project,PDO::PARAM_INT);
            $stmt->execute();
            $result_name_users = $stmt->fetchAll(PDO::FETCH_ASSOC);
            return  $result_name_users;
        }
        // retourne les jours effectués pour chaque projet selon une periodes daté de l'utilisateur par service
        function servicesUsersDaysProject($project,$date_begin,$date_end)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo ->prepare("SELECT T.label , U.username , round(count(*)/2.,1)  as etp
            from projectuser as PU
            natural join cramuser as U
            natural join teamuser as TU
            natural join team as T
            natural join task
            where PU.projectid = (select projectid
                from project
                where projectname = :projectname) 
            and taskdate between :dateBegin and :dateEnd
            group by T.label , U.username;");
            $stmt->bindParam(':projectname',$project,PDO::PARAM_STR);
            $stmt->bindParam(':dateBegin',$date_begin,PDO::PARAM_STR);
            $stmt->bindParam(':dateEnd',$date_end,PDO::PARAM_STR);
            $stmt->execute();
            $result_service_user_day = $stmt->fetchAll(PDO::FETCH_NUM);
            return  $result_service_user_day;
        }

        // // liste des users par rapport au service
        function serviceUser($user)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt =$pdo ->prepare ("SELECT label
                    from teamuser
                    natural join team as T
                    where userrid = :user;");
            $stmt->bindParam(':user',$user,PDO::PARAM_INT);
            $stmt->execute();
            $service_user = $stmt->fetchAll(PDO::FETCH_ASSOC);
            return $service_user;
        }
        
        // retourne la liste des services du chef de service
        function leaderService($user)
        {
           $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo ->prepare("SELECT TL.userrid as userrid, T.label as label
                    from teamleader as TL
                    natural join team as T
                    where TL.userrid = :user
                    order by T.label;");
            $stmt->bindParam(':user', $user);        
            $stmt->execute();
            $result_service = $stmt->fetchAll(PDO::FETCH_ASSOC);
            return $result_service;
        }

        // retourn la date de debut d'inscription de l'user 
        function getStartDate($user)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare("SELECT userstartdate FROM cramuser
                WHERE userrid=:user");
            $stmt->bindParam(':user', $user);
            $stmt->execute();
            $rs = $stmt->fetchAll();
            foreach ($rs as $value)
                return $value['userstartdate'];
        }



        // retourne le nombre de congé pris par rapportàa une periode daté par user
        function holiday($userrid,$date_begin,$date_end)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare("SELECT count(taskdayoff)/2
                    from task
                    where taskdayoff = true
                    and userrid = :user 
                    and taskdate between :dateBegin and :dateEnd;");
            $stmt->bindParam(':user',$userrid,PDO::PARAM_INT);
            $stmt->bindParam(':dateBegin',$date_begin,PDO::PARAM_STR);
            $stmt->bindParam(':dateEnd',$date_end,PDO::PARAM_STR);
            $executeIsOk = $stmt->execute();
            $result_jour = $stmt->fetch(PDO::FETCH_NUM);
            return $result_jour[0];
        }
        
        // retourne le nom des projets par user correspondant au leader
        function leaderProject($user)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare("SELECT distinct P.projectname
                    from project as P
                    natural join task as T
                    where P.projectid=T.projectid
                    and T.userrid = :user
                    order by P.projectname;");
            
            $stmt->bindParam(':user',$user,PDO::PARAM_INT);
            $executeIsOk = $stmt->execute();
            $result = $stmt->fetchAll(PDO::FETCH_NUM);
            return $result;
        }

        // retourne le nom des users d'on le leader est responsable
        function leaderUser($user)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare("SELECT U.username
                    from teamuser as TU
                    natural join cramuser as U
                    natural join team as T
                    where leader = :user
                    order by userrid;");
            $stmt->bindParam(':user',$user,PDO::PARAM_INT);
            $executeIsOk = $stmt->execute();
            $result_jour = $stmt->fetchAll(PDO::FETCH_NUM);
            return $result_jour;
        }

         // fonction de requete sur la demande des user,  des project ainsi que les jours effectués pour un service
         function userProjectLeaderDay($service,$date_begin,$date_end)
         {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare("SELECT P.projectname ,U.username, round(count(taskdayoff)/2.,1) as day
                    from project as P 
                    natural join projectuser as PU
                    natural join cramuser as U
                    natural join task as T
                    natural join teamuser as TU 
                    natural join team as TE 
                    where P.projectid = PU.projectid
                    and TE.label = :label
                    and T.taskdate between :dateBegin and :dateEnd
                    group by P.projectname , U.username , P.projectid , PU.userrid
                    order by P.projectname, userrid;");
            $stmt->bindParam(':label',$service,PDO::PARAM_STR);
            $stmt->bindParam(':dateBegin',$date_begin,PDO::PARAM_STR);
            $stmt->bindParam(':dateEnd',$date_end,PDO::PARAM_STR);
            $executeIsOk = $stmt->execute();
            $result_project_leader_day = $stmt->fetchAll(PDO::FETCH_NUM);
            return $result_project_leader_day;

         }
        // fonction de requete sur la demande des user,  des project ainsi que les jours effectués pour une activités
         function userActivityLeaderDay($service, $date_begin, $date_end)
         {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare("SELECT A.activityname as activityname ,U.username as username, round(count(taskdayoff)/2.,1) as day
                    from activity as A
                    natural join task
                    natural join activityuser as AU
                    natural join cramuser as U
                    natural join teamuser as TU
                    natural join team as TE 
                    where TE.teamid = TU.teamid
                    and AU.userrid =TU.userrid
                    and TE.label = :label
                    and task.activityid = AU.activityid
                    and taskdate between :dateBegin and :dateEnd
                    group by A.activityid ,A.activityname, task.userrid , U.username
                    order by A.activityname, U.username;");
            $stmt->bindParam(':label',$service,PDO::PARAM_STR);
            $stmt->bindParam(':dateBegin',$date_begin,PDO::PARAM_STR);
            $stmt->bindParam(':dateEnd',$date_end,PDO::PARAM_STR);
            $executeIsOk = $stmt->execute();
            $result_activity_leader_day = $stmt->fetchAll(PDO::FETCH_NUM);
            return $result_activity_leader_day;
         }

        function managerProjectServices($project)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare("SELECT T.label as service,  U.username
                    from projectuser as PU
                    natural join cramuser as U
                    natural join teamuser as TU
                    natural join team as T
                    where projectid = :projectid
                    and PU.userrid = TU.userrid
                    group by service , U.username;");
            $stmt->bindParam(':projectid',$project,PDO::PARAM_STR);
            $executeIsOk = $stmt->execute();
            $result_project_services = $stmt ->fetchAll(PDO::FETCH_ASSOC);
            return $result_project_services;

        }

        // retourne les jours effectués avec les noms et activite pour chaque projet selon une periode
        function activityUsersDaysProject($project,$date_begin, $date_end)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare("SELECT A.activityname , U.username, round(count(*)/2.,1)  as etp 
            from projectuser as PU
            natural join cramuser as U
            natural join activityuser as AU
            natural join activity as A
            natural join task as T
            where PU.projectid = (select projectid
                from project
                where projectname = :projectname)
            and T.taskdate between :dateBegin and :dateEnd
            group by U.username, U.userrid , A.activityname
            order by 1;");
            $stmt->bindParam(':projectname',$project,PDO::PARAM_STR);
            $stmt->bindParam(':dateBegin',$date_begin,PDO::PARAM_STR);
            $stmt->bindParam(':dateEnd',$date_end,PDO::PARAM_STR);
            $executeIsOk = $stmt->execute();
            $result_activity_leader_day = $stmt->fetchAll(PDO::FETCH_NUM);
            return $result_activity_leader_day;
        }
         
        /*
        //function pour metter a jour la version
        */
        function updateUserVersion($user)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare("SELECT centralversion FROM userversion
                WHERE userrid=:user");
            $stmt->bindParam(':user', $user);
            $stmt->execute();
            $rs = $stmt->fetchAll();
            $centralversion = 0;
            foreach ($rs as $value)
            $centralversion = $value['centralversion'];
            $centralversion++;
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare("UPDATE userversion SET centralversion = :centralversion WHERE userrid=:user");
            $stmt->bindParam(':user', $user);
            $stmt->bindParam(':centralversion', $centralversion);
            $stmt->execute();
        }
}

?>
