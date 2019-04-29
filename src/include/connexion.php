<?php

class PdoBdd {   		
      	private static $serveur='172.17.42.1';
        private static $port='5432';
      	private static $bdd='cram_0';
      	private static $user='agross' ;
      	private static $mdp='kkuet47' ;	
	private static $monPdo;
	private static $monPdoBdd=null;
        
/**
 * Constructeur privé, crée l'instance de PDO qui sera sollicitée
 * pour toutes les méthodes de la classe
 */	
	private function __construct(){
            try
            {
                PdoBdd::$monPdo = new PDO('pgsql:dbname='.PdoBdd::$bdd.'; host='.PdoBdd::$serveur.';
                    port='.PdoBdd::$port.';', PdoBdd::$user, PdoBdd::$mdp);
                PdoBdd::$monPdo->exec("SET CHARACTER SET utf8");
            }
            catch (Exception $e)
            {
                die('Erreur : ' . $e->getMessage());
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
			PdoBdd::$monPdo = new PDO('pgsql:dbname='.PdoBdd::$bdd.'; host='.PdoBdd::$serveur.';
                    port='.PdoBdd::$port.';', PdoBdd::$user, PdoBdd::$mdp);
		}
		return PdoBdd::$monPdo;  
	}
        
        
        function estConnecte()
        {
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
        function getMyTasks($user, \DateTime $date_min, \DateTime $date_max)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare("
                SELECT t.taskcomment as taskcomment, t.taskdate AS taskdate, t.taskam AS taskam, t.taskdayoff AS taskdayoff, full_projectname(p.projectid) AS projectname, a.activityname AS activityname
                FROM task t
                    LEFT OUTER JOIN project p ON p.projectid = t.projectid
                    LEFT OUTER JOIN activity a ON a.activityid = t.activityid
                WHERE t.userrid = :user 
                AND t.taskdate >= :date_min 
                AND t.taskdate <= :date_max
                ORDER BY t.taskdate, t.taskam;
            ");
            
            $stmt->bindParam(':user', $user);
            $stmt->bindParam(':date_min', $date_min->format("Y-m-d"));
            $stmt->bindParam(':date_max', $date_max->format("Y-m-d"));
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
            $stmt = $pdo->prepare('select P.projectid, full_projectname(P.projectid) as name,
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
            $stmt = $pdo->prepare('select A.activityid, activityname,
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
        
        
        //Le projet en paramètre est associé à l'utilisateur en paramètre
        function addProject($idProject, $user)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare('INSERT INTO projectuser VALUES (:user, :project)');
            $stmt->bindParam(':user', $user);
            $stmt->bindParam(':project', $idProject);
            $stmt->execute();
            
            PdoBdd::updateUserVersion($user);
        }
        
        
        //Le projet en paramètre n'est plus associé à l'utilisateur en paramètre
        function deleteProject($idProject, $user)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare('DELETE FROM projectuser WHERE userrid = :user AND projectid = :project');
            $stmt->bindParam(':user', $user);
            $stmt->bindParam(':project', $idProject);
            $stmt->execute();
            
            PdoBdd::updateUserVersion($user);
        }
        
        
        //L'activité en paramètre est associée à l'utilisateur en paramètre
        function addActivity($idActivity, $user)
        {
            $pdo = PdoBdd::getPdoBdd();
            $stmt = $pdo->prepare('INSERT INTO activityuser VALUES (:user, :activity)');
            $stmt->bindParam(':user', $user);
            $stmt->bindParam(':activity', $idActivity);
            $stmt->execute();
            
            PdoBdd::updateUserVersion($user);
        }
        
        
        //L'activité en paramètre n'est plus associée à l'utilisateur en paramètre
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
                WHERE username=:user");
            $stmt->bindParam(':user', $user);
            $stmt->execute();
            $rs = $stmt->fetchAll();
            foreach ($rs as $value)
                return array("id" => $value['userrid'], "username" => $value['username']);
        }
        
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
        
        function updateUserVersion($user){
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
