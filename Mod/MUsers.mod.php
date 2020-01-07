<?php
/**
 * Class de type Modèle gérant la table cramuser
 *
 * @author Michael Larboni
 * @version 1.0
 */
class MUsers  //extends MLang
{
    /**
     * Connexion à la Base de Données
     * @var object $conn
     */
    private $conn;

    /**
     * Tableau de gestion de données (insert ou update)
     * @var array $value
     */
    private $value;

    /**
     * clé primaire
     * @var array $id_user
     */
    private $id_user;

    /**
     * Constructeur de la class MUsers
     * @access public
     *
     * @return void
     */
    public function __construct()
    {
        // Connexion à la Base de Données
        $this->conn = new PDO(DATABASE, LOGIN, PASSWORD);

    } // __construct()

    /**
     * Destructeur de la class MUsers
     * @access public
     *
     * @return void
     */
    public function __destruct(){} // __destruct()

    /**
     * Instancie le membre $value
     * @access public
     * @param array tableau des données
     *
     * @return void
     */
    public function setValue($_value)
    {
        $this->value = $_value;

        return;

    } // SetValue($_value)

    /**
     * Instancie le membre $user
     * @access public
     * @param $id_user
     * @return void
     */
    public function setIdUser($id_user)
    {
        $this->id_user = $id_user;

        return;

    } // SetIdUser($id_user)

    /**
     * Récupère l'ID, le USERNAME, si ADMIN ou non, et le statut VALID ou PENDING dans la table cramuser
     * @access public
     *
     * @return array tuple de la table cramuser
     */
    public function VerifUser()
    {
        $query = "select userid, username, useradmin, userstatut
                  from cramuser
                  where username = :user";

        $result = $this->conn->prepare($query);

        $result->bindValue(':user', $this->value['user'], PDO::PARAM_INT);

        $result->execute();

        return $result->fetch();

    } //VerifUser()

    /**
     *  Ajoute un nouvel utilisateur avec le statut 'pending' en attente
     */
    public function addUser()
    {
        $query = "insert into cramuser (username, userpwd, userstatut, email)
                  values (:username, :userpwd, :userstatut, :email)";

        $result = $this->conn->prepare($query);
        $result->bindValue(':username', $this->value['username'], PDO::PARAM_STR);
        $result->bindValue(':userpwd', $this->value['userpwd'], PDO::PARAM_STR);
        $result->bindValue(':userstatut', $this->value['userstatut'], PDO::PARAM_STR);
        $result->bindValue(':email', $this->value['email'], PDO::PARAM_STR);

        $result->execute() or die($this->ErrorSQL($result));
        $this->id_user = $this->conn->lastInsertId();
        $this->value['userid'] = $this->id_user;

        return $this->value;

    } //addUser()

    /**
     * Requete pour changer les droits d'admin en fonction de l'userid
     */
    public function setAdmin()
    {
        $query = "update cramuser 
                  set useradmin =  case when (useradmin = false) then (true) else (false) end 
                  where userid = :userid ";

        $result = $this->conn->prepare($query);

        $result->bindValue(':userid', $this->id_user, PDO::PARAM_INT);

        $result->execute();

        return $result->fetch();

    } //setAdmin()

    /**
     * Requete pour changer les droits d'admin en fonction de l'userid
     */
    public function setValid()
    {
        $query = "update cramuser 
                  set userstatut =  case when (userstatut = 'valid') then ('pending') else ('valid') end 
                  where userid = :userid ";

        $result = $this->conn->prepare($query);

        $result->bindValue(':userid', $this->id_user, PDO::PARAM_INT);

        $result->execute();

        return $result->fetch();

    } //setValid()

    /**
     * Requete pour changer les droits d'admin en fonction de l'userid
     * @param $date
     * @return mixed
     */
    public function setDate($date)
    {
        $query = 'update cramuser 
                     set userstartdate = :userstartdate
                   where userid = :userid';

        $result = $this->conn->prepare($query);

        $result->bindValue(':userstartdate', $date, PDO::PARAM_INT);
        $result->bindValue(':userid', $this->id_user, PDO::PARAM_INT);

        $result->execute();

        return $result->fetch();

    } //setDate()

    /**
     * @param $date
     * @return mixed
     */
    public function selectMinDate()
    {
        $query = 'select min(taskdate) 
                     from task
                   where userid = :userid';

        $result = $this->conn->prepare($query);

        $result->bindValue(':userid', $this->id_user, PDO::PARAM_INT);

        $result->execute();

        return $result->fetch();

    } //setDate()

    /**
     * renvoie true si l'utilisateur est chef de service (leader) ou false
     * @param $user
     * @return array
     */
    public function leader($user)
    {
        $query = "SELECT T.label
                    from teamleader
                    natural join team as T
                    where userid = :user
                    group by T.teamid";

        $result = $this->conn->prepare($query);

        $result->bindValue(':user', $user, PDO::PARAM_INT);

        $result->execute();

        $result_head = $result->fetchAll(PDO::FETCH_NUM);
        return  $result_head;

    } //leader($user)

    /**
     * renvoie true si l'utilisateur est chef de projet (manager) ou false
     * @param $user
     * @return mixed
     */
    public function manager($user)
    {
        $query = "SELECT distinct M.userid
             from manager as M
             natural join project as P
             where M.userid = :user";

        $result = $this->conn->prepare($query);

        $result->bindValue(':user', $user, PDO::PARAM_INT);

        $result->execute();

        return $result->fetch();

    } //manager($user)

    /**
     *  retourne la liste de tous les utilisateurs
     * @return array
     */
    function selectAll()
    {
        $query = "select userid,
                         lastname,
                         name,
                         username,
                         userstatut,
                         userdatestatut,
                         useradmin,
                         userstartdate,
                         usersynchrodate 

        from cramuser  order by username";


        $result = $this->conn->prepare($query);
        $result->execute() or die ($this->ErrorSQL($result));

        return $result->fetchAll();

    } //selectAll()

    /**
     * renvoie un tableau avec l'id et le username
     * @return mixed
     */
    public function select()
    {
        $query = "select userid, username
                from cramuser
                where userid = :userid";

        $result = $this->conn->prepare($query);

        $result->bindValue(':userid', $this->id_user, PDO::PARAM_INT);

        $result->execute() or die ($this->ErrorSQL($result));

        return $result->fetch();

    }
    /**
     * renvoie un tableau avec l'id et le username
     * @return mixed
     */
    public function selectByUsername()
    {
        $query = "select userid,
                         username,
                         userstatut,
                         userdatestatut,
                         useradmin,
                         userstartdate,
                         usersynchrodate 
                from cramuser
                where username = :username";

        $result = $this->conn->prepare($query);

        $result->bindValue(':username', $this->value['username'], PDO::PARAM_STR);

        $result->execute() or die ($this->ErrorSQL($result));

        return $result->fetchAll();

    }

    /**
     * renvoie un tableau avec l'id et le username
     * @return mixed
     */
    public function selectUsername()
    {
        $query = "select username
                from cramuser";

        $result = $this->conn->prepare($query);

        $result->execute() or die ($this->ErrorSQL($result));

        return $result->fetchAll();

    }

    /**
     *  retourne le nombre de congé pris par rapport à une periode datée par user
     * @param $userid
     * @param $date_begin
     * @param $date_end
     * @return array
     */
    function holiday($userid,$date_begin,$date_end)
    {
        $query = "SELECT count(taskdayoff)/2
                    from task
                    where taskdayoff = true
                    and userid = :user 
                    and taskdate between :dateBegin and :dateEnd";

        $result = $this->conn->prepare($query);

        $result->bindParam(':user',$userid,PDO::PARAM_INT);
        $result->bindParam(':dateBegin',$date_begin,PDO::PARAM_STR);
        $result->bindParam(':dateEnd',$date_end,PDO::PARAM_STR);
        $result->execute();
        $result_jour = $result->fetch(PDO::FETCH_NUM);
        return $result_jour[0];
    }

    /**
     * retourne le nom des projets par user correspondant au leader
     * @param $user
     * @return array
     */
    function leaderProject($user)
    {
        $query = "SELECT distinct P.projectname
                    from project as P
                    natural join task as T
                    where P.projectid=T.projectid
                    and T.userid = :user
                    order by P.projectname";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user',$user,PDO::PARAM_INT);
        $stmt->execute();
        $result = $stmt->fetchAll(PDO::FETCH_NUM);
        return $result;
    }

    /**
     * fonction de requete sur la demande des user,  des project ainsi que les jours effectués pour une activités
     * @param $service
     * @param $date_begin
     * @param $date_end
     * @return mixed
     */
    function userActivityLeaderDay($service, $date_begin, $date_end)
    {
        $query = "SELECT A.activityname as activityname ,U.username as username, round(count(taskdayoff)/2.,1) as day
                    from activity as A
                    natural join task
                    natural join activityuser as AU
                    natural join cramuser as U
                    natural join teamuser as TU
                    natural join team as TE 
                    where TE.teamid = TU.teamid
                    and AU.userid =TU.userid
                    and TE.label = :label
                    and task.activityid = AU.activityid
                    and taskdate between :dateBegin and :dateEnd
                    group by A.activityid ,A.activityname, task.userid , U.username
                    order by A.activityname, U.username";
        $result = $this->conn->prepare($query);
        $result->bindParam(':label',$service,PDO::PARAM_STR);
        $result->bindParam(':dateBegin',$date_begin,PDO::PARAM_STR);
        $result->bindParam(':dateEnd',$date_end,PDO::PARAM_STR);
        $result->execute();
        $result_activity_leader_day = $result->fetchAll(PDO::FETCH_NUM);
        return $result_activity_leader_day;
    }

    /**
     * fonction de requete sur la demande des user,  des project ainsi que les jours effectués pour un service
     * @param $service
     * @param $date_begin
     * @param $date_end
     * @return mixed
     */
    function userProjectLeaderDay($service,$date_begin,$date_end)
    {
        $query = "SELECT P.projectname ,U.username, round(count(taskdayoff)/2.,1) as day
                    from project as P 
                    natural join projectuser as PU
                    natural join cramuser as U
                    natural join task as T
                    natural join teamuser as TU 
                    natural join team as TE 
                    where P.projectid = PU.projectid
                    and TE.label = :label
                    and T.taskdate between :dateBegin and :dateEnd
                    group by P.projectname , U.username , P.projectid , PU.userid
                    order by P.projectname, userid";
        $result = $this->conn->prepare($query);
        $result->bindParam(':label',$service,PDO::PARAM_STR);
        $result->bindParam(':dateBegin',$date_begin,PDO::PARAM_STR);
        $result->bindParam(':dateEnd',$date_end,PDO::PARAM_STR);
        $result->execute();
        $result_project_leader_day = $result->fetchAll(PDO::FETCH_NUM);
        return $result_project_leader_day;

    }
    /**
     * retourne la date de debut d'inscription de l'user
     * @param $user
     * @return void
     */
    function getStartDate($user)
    {
        $query = "SELECT userstartdate FROM cramuser
                WHERE userid=:user";

        $result = $this->conn->prepare($query);

        $result->bindValue(':user', $user, PDO::PARAM_INT);

        $result->execute();

        $rs = $result->fetchAll();

        foreach ($rs as $value)
            return $value['userstartdate'];

        return ;
    } //getStartDate($user)

    /**
     * retourne la liste des services du chef de service
     * @param $user
     * @return array
     */
    function leaderService($user)
    {
        $query = "SELECT TL.userid as userid, T.label as label
                    from teamleader as TL
                    natural join team as T
                    where TL.userid = :user
                    order by T.label";

        $result = $this->conn->prepare($query);

        $result->bindValue(':user', $user, PDO::PARAM_INT);

        $result->execute();

        return $result->fetchAll();

    } //leaderService($user)

    /**
     * Retourne les projects associés au manager;
     * @param $user
     * @return mixed
     */
    function managerProject($user)
    {
        $query = "SELECT distinct P.projectname ,P.projectid
            from manager as M
            natural join project as P
            where M.userid = :user
            order by P.projectname";

        $result = $this->conn->prepare($query);

        $result->bindValue(':user', $user, PDO::PARAM_INT);

        $result->execute();

        return $result->fetchAll();

    } // managerProject($user)

    /**
     *
     * Le projet en paramètre est associé à l'utilisateur en paramètre. il ajoute a sa liste
     * @param $idProject
     * @param $user
     */
    function addProject($idProject, $user)
    {
        $query = 'INSERT INTO projectuser VALUES (:user, :project)';
        $result = $this->conn->prepare($query);

        $result->bindParam(':user', $user,PDO::PARAM_INT);
        $result->bindParam(':project', $idProject,PDO::PARAM_INT);

        $result->execute();

        $this->updateUserVersion($user);

    } //addProject($idProject, $user)

    /**
     * Le projet en paramètre n'est plus associé à l'utilisateur en paramètre. il le supprime
     * @param $idProject
     * @param $user
     */
    function deleteProject($idProject, $user)
    {

        $query = 'DELETE FROM projectuser WHERE userid = :user AND projectid = :project';

        $result = $this->conn->prepare($query);

        $result->bindParam(':user', $user,PDO::PARAM_INT);
        $result->bindParam(':project', $idProject,PDO::PARAM_INT);

        $result->execute();

        $this->updateUserVersion($user);

    } //deleteProject($idProject, $user)

    /**
     * L'activité en paramètre est associée à l'utilisateur en paramètre. il ajoute a sa liste
     * @param $idActivity
     * @param $user
     *
     */
    function addActivity($idActivity, $user)
    {
        $query = 'INSERT INTO activityuser VALUES (:user, :activity)';

        $result = $this->conn->prepare($query);

        $result->bindParam(':user', $user,PDO::PARAM_INT);
        $result->bindParam(':activity', $idActivity,PDO::PARAM_INT);

        $result->execute();

        $this->updateUserVersion($user);

    } //addActivity($idActivity, $user)

    /**
     * L'activité en paramètre n'est plus associée à l'utilisateur en paramètre. il le supprime
     * @param $idActivity
     * @param $user
     */
    function deleteActivity($idActivity, $user)
    {
        $query = 'DELETE FROM activityuser WHERE userid = :user 
                  AND activityid = :activity';

        $result = $this->conn->prepare($query);

        $result->bindParam(':user', $user,PDO::PARAM_INT);
        $result->bindParam(':activity', $idActivity,PDO::PARAM_INT);

        $result->execute();

//        $this->updateUserVersion($user);

    } //deleteActivity($idActivity, $user)

    /**
     * Mettre a jour la version
     * @param $user
     */
    function updateUserVersion($user)
    {
        $query = "SELECT centralversion FROM userversion
                WHERE userid=:user";

        $result = $this->conn->prepare($query);

        $result->bindParam(':user', $user,PDO::PARAM_INT);

        $result->execute();

        $rs = $result->fetchAll();
        $centralversion = 0;
        foreach ($rs as $value)
            $centralversion = $value['centralversion'];
        $centralversion++;

        $query = "UPDATE userversion SET centralversion = :centralversion WHERE userid=:user";

        $result = $this->conn->prepare($query);

        $result->bindParam(':user', $user,PDO::PARAM_INT);
        $result->bindParam(':centralversion', $centralversion,PDO::PARAM_INT);
        $result->execute();

    } //updateUserVersion($user)

    /**
     *
     *retourne le nom des projets associés à l'utilisateur avec le nombre de jour effectué par rapport à la date
     * @param $user
     * @param $date_begin
     * @param $date_end
     * @return array
     */
    function projectNameDay($user,$date_begin,$date_end)
    {
        $query = "SELECT P.projectname, count(*)/2 as etp
                 from task as T 
                 natural join project as P
                 natural join cramuser as U
                 where U.userid = :user
                 and  T.taskdate between :dateBegin and :dateEnd
                 group by P.projectname
                 order by 1 ";

        $result = $this->conn->prepare($query);

        $result->bindParam(':user',$user,PDO::PARAM_INT);
        $result->bindParam(':dateBegin',$date_begin,PDO::PARAM_STR);
        $result->bindParam(':dateEnd',$date_end,PDO::PARAM_STR);
        $result->execute();

        $result_jour = $result->fetchAll(PDO::FETCH_ASSOC);

        return  $result_jour;

    } //projectNameDay($user,$date_begin,$date_end)

    /**
     * retourne le nom des activites et les jours effectués par raport à une periode daté
     * @param $user
     * @param $date_begin
     * @param $date_end
     * @return array
     */
    function activityNameJour($user,$date_begin,$date_end)
    {
        $query = "SELECT A.activityname, count(*)/2 as etp
                   from task as T 
                   natural join activity as A
                   natural join cramuser as U
                   where U.userid = :user
                   and  T.taskdate between :dateBegin and :dateEnd
                   group by A.activityname
                   order by 1 ";

        $result = $this->conn->prepare($query);

        $result->bindParam(':user',$user,PDO::PARAM_INT);
        $result->bindParam(':dateBegin',$date_begin,PDO::PARAM_STR);
        $result->bindParam(':dateEnd',$date_end,PDO::PARAM_STR);
        $result->execute();

        $result_jour = $result->fetchAll(PDO::FETCH_ASSOC);

        return  $result_jour;

    } //activityNameJour($user,$date_begin,$date_end)

    /**
     * retourne les jours effectués pour chaque activité selon une periodes daté de l'utilisateur
     * @param $user
     * @param $date_begin
     * @param $date_end
     * @return array
     */
    function projectActivityJour($user,$date_begin,$date_end)
    {
        $query = "SELECT P.projectname ,A.activityname , round(count(*)/2.,1) as etp
                 from task as T 
                 natural join activity as A
                 natural join cramuser as U
                 natural join project as P
                 where U.userid = :user
                 and  T.taskdate between :dateBegin and :dateEnd
                 group by P.projectname,A.activityname
                 having count(*) > 0
                 order by 1";

        $result = $this->conn->prepare($query);
        $result->bindParam(':user',$user,PDO::PARAM_INT);
        $result->bindParam(':dateBegin',$date_begin,PDO::PARAM_STR);
        $result->bindParam(':dateEnd',$date_end,PDO::PARAM_STR);
        $result->execute();
        $_result = $result->fetchAll(PDO::FETCH_NUM);

        return  $_result;

    } //projectActivityJour($user,$date_begin,$date_end)

    /**
     * retourne les activités effectuées par rapport à une periode daté
     * @param $user
     * @param $date_begin
     * @param $date_end
     * @return array
     */
    function activityProjectDay($user,$date_begin,$date_end)
    {
        $query = "SELECT A.activityname  ,P.projectname ,round(count(*)/2.,1) as etp
                   from task as T 
                   natural join activity as A
                   natural join cramuser as U
                   natural join project as P
                   where U.userid = :user
                   and  T.taskdate between :dateBegin and :dateEnd
                   group by A.activityname ,P.projectname 
                   having count(*) >0
                   order by 1";
        $result = $this->conn->prepare($query);

        $result->bindParam(':user',$user,PDO::PARAM_INT);
        $result->bindParam(':dateBegin',$date_begin,PDO::PARAM_STR);
        $result->bindParam(':dateEnd',$date_end,PDO::PARAM_STR);
        $result->execute();
        $result_jour = $result->fetchAll(PDO::FETCH_NUM);
        return  $result_jour;

    } //activityProjectDay($user,$date_begin,$date_end)

    /**
     * liste des users par rapport au service
     * @param $user
     * @return array
     */
    function serviceUser($user)
    {
        $query = "SELECT label
                    from teamuser
                    natural join team as T
                    where userid = :user";

        $result = $this->conn->prepare($query);
        $result->bindParam(':user',$user,PDO::PARAM_INT);
        $result->execute();
        $service_user = $result->fetchAll(PDO::FETCH_ASSOC);
        return $service_user;

    } //serviceUser($user)

    /**
     * retourne les jours effectués pour chaque projet selon une periodes daté de l'utilisateur par service
     * @param $project
     * @param $date_begin
     * @param $date_end
     * @return array
     */
    function servicesUsersDaysProject($project,$date_begin,$date_end)
    {
        $query = "SELECT T.label , U.username , round(count(*)/2.,1)  as etp
            from projectuser as PU
            natural join cramuser as U
            natural join teamuser as TU
            natural join team as T
            natural join task
            where PU.projectid = (select projectid
                from project
                where projectname = :projectname) 
            and taskdate between :dateBegin and :dateEnd
            group by T.label , U.username";

        $result = $this->conn->prepare($query);
        $result->bindParam(':projectname',$project,PDO::PARAM_STR);
        $result->bindParam(':dateBegin',$date_begin,PDO::PARAM_STR);
        $result->bindParam(':dateEnd',$date_end,PDO::PARAM_STR);
        $result->execute();
        $result_service_user_day = $result->fetchAll(PDO::FETCH_NUM);

        return  $result_service_user_day;

    } //servicesUsersDaysProject($project,$date_begin,$date_end)

    // retourne les jours effectués avec les noms et activite pour chaque projet selon une periode
    function activityUsersDaysProject($project,$date_begin, $date_end)
    {
        $query = "SELECT A.activityname , U.username, round(count(*)/2.,1)  as etp 
            from projectuser as PU
            natural join cramuser as U
            natural join activityuser as AU
            natural join activity as A
            natural join task as T
            where PU.projectid = (select projectid
                from project
                where projectname = :projectname)
            and T.taskdate between :dateBegin and :dateEnd
            group by U.username, U.userid , A.activityname
            order by 1";

        $result = $this->conn->prepare($query);
        $result->bindParam(':projectname',$project,PDO::PARAM_STR);
        $result->bindParam(':dateBegin',$date_begin,PDO::PARAM_STR);
        $result->bindParam(':dateEnd',$date_end,PDO::PARAM_STR);
//        $executeIsOk = $result->execute();
        $result->execute();
        $result_activity_leader_day = $result->fetchAll(PDO::FETCH_NUM);

        return $result_activity_leader_day;

    } // activityUsersDaysProject($project,$date_begin, $date_end)

    /**
     *  Renvoie un tableau contenant toutes les informations sur toutes les tâches du user dont
     *  l'identifiant est passé en paramètre
     * @param $user
     * @param $date_min
     * @param $date_max
     * @return array
     */
    function getMyTasks($user, $date_min, $date_max)
    {
        $query = "
            SELECT t.taskcomment as taskcomment, t.taskdate AS taskdate, t.taskam AS taskam, t.taskdayoff AS taskdayoff, 
                    full_projectname(p.projectid) AS projectname, a.activityname AS activityname
            FROM task t
                LEFT OUTER JOIN project p ON p.projectid = t.projectid
                LEFT OUTER JOIN activity a ON a.activityid = t.activityid
            WHERE t.userid = :user 
            AND t.taskdate >= :date_min 
            AND t.taskdate <= :date_max
            ORDER BY t.taskdate, t.taskam;";

        $result = $this->conn->prepare($query);

        $result->bindParam(':user', $user);
        $result->bindParam(':date_min', $date_min);
        $result->bindParam(':date_max', $date_max);
        $result->execute();
        $rs = $result->fetchAll(PDO::FETCH_ASSOC);

        return $rs;

    } //getMyTasks($user, $date_min, $date_max)

    /*    function getMyTasks($user, $date_min, $date_max)
        {
            $result = $this->conn->prepare("
                SELECT  case when t.taskam = 'am' then t.taskdate||'T08:00:00' else t.taskdate||'T14:00:00' end as start,
                        case when t.taskam = 'am' then t.taskdate||'T12:00:00' else t.taskdate||'T17:00:00' end as \"end\",
                        case when t.taskdayoff = true then 'Congé' else full_projectname(p.projectid) || '-' || a.activityname end as title,
                        t.taskcomment as taskcomment,
                        t.taskdate AS taskdate,
                        t.taskam AS taskam,
                        t.taskdayoff AS taskdayoff,
                        full_projectname(p.projectid) AS projectname,
                        a.activityname AS activityname
                FROM task t
                    LEFT OUTER JOIN project p ON p.projectid = t.projectid
                    LEFT OUTER JOIN activity a ON a.activityid = t.activityid
                WHERE t.userid = :user
                AND t.taskdate >= :date_min
                AND t.taskdate <= :date_max
                ORDER BY t.taskdate, t.taskam;
            ");
            $result->bindParam(':user', $user);
            $result->bindParam(':date_min', $date_min);
            $result->bindParam(':date_max', $date_max);
            $result->execute();
            $rs = $result->fetchAll(PDO::FETCH_ASSOC);
            return $rs;
        } //getMyTasks($user, $date_min, $date_max) */

    //Permet de supprimer la tâche dont la date et l'am sont passés en paramètre
    function clearTask($user, $date, $am)
    {
        $query = "DELETE FROM task WHERE userid = :user AND taskdate = :date
            AND taskam = :am";
        $result = $this->conn->prepare($query);
        $result->bindParam(':user', $user);
        $result->bindParam(':date', $date);
        $result->bindParam(':am', $am);
        $result->execute();
        $this->updateUserVersion($user);
    }

    //Ajoute les informations de la tâche passées en paramètre dans la base de données
    function addMyTask($user, $date, $am, $off, $idProject, $idActivity, $comment)
    {
        $query = "INSERT INTO task VALUES (:idActivity, :idProject, :user, :date, :am, :off, :comment)";

        $result = $this->conn->prepare($query);

        $result->bindParam(':user', $user);
        $result->bindParam(':idActivity', $idActivity);
        $result->bindParam(':idProject', $idProject);
        $result->bindParam(':date', $date);
        $result->bindParam(':am', $am);
        $result->bindParam(':off', $off);
        $result->bindParam(':comment', $comment);
        $result->execute();
        $this->updateUserVersion($user);
    }

    //Vérifie si une tâche existe déjà pour un utilisateur à une date donnée et à un am donné.
    function tacheExiste($user, $date, $ampm)
    {
        $query = "SELECT * FROM task WHERE userid = :user AND taskdate = 
            :date AND taskam = :ampm";

        $result = $this->conn->prepare($query);

        $result->bindParam(':user', $user);
        $result->bindParam(':date', $date);
        $result->bindParam(':ampm', $ampm);
        $result->execute();
        $rs = $result->fetchAll();
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
        $query = "UPDATE task
                                SET projectid = :idProject,
                                activityid = :idActivity,
                                taskdayoff = :off,
                                taskcomment = :comment
                                WHERE userid = :user AND taskdate = :date AND taskam = :am";

        $result = $this->conn->prepare($query);

        $result->bindParam(':user', $user);
        $result->bindParam(':idActivity', $idActivity);
        $result->bindParam(':idProject', $idProject);
        $result->bindParam(':date', $date);
        $result->bindParam(':am', $am);
        $result->bindParam(':off', $off);
        $result->bindParam(':comment', $comment);
        $result->execute();

        $this->updateUserVersion($user);
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
        if ($this->tacheExiste($user, $date, $am)== true)
        {
            $this->modifyTask($user, $date, $am, $off, $idProject, $idActivity, $comment);
        }
        else
        {
            $this->addMyTask($user, $date, $am, $off, $idProject, $idActivity, $comment);
        }
    }

    /**
     *  ErrorSQL
     * @param $result
     * @return array
     */
    private function ErrorSQL($result)
    {
        // Récupère le tableau des erreurs
        $error = $result->errorInfo();

        echo 'TYPE_ERROR = ' . $error[0] . '<br />';
        echo 'CODE_ERROR = ' . $error[1] . '<br />';
        echo 'MSG_ERROR = ' . $error[2] . '<br />';

        return $error;

    }

} // MUsers

