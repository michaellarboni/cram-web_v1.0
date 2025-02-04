<?php
/**
 * Class de type Modèle gérant la table project
 *
 * @author Michael Larboni
 * @version 1.0
 */
class MProject
{
    /**
     * Connexion à la Base de Données
     * @var object $conn
     */
    private $conn;

    /**
     * clé primaire de la table project
     * @var int projectid
     */
    private $projectid;

    /**
     * Tableau de gestion de données (insert ou update)
     * @var array $value
     */
    private $value;

    /**
     * Constructeur de la class MProject
     * @access public
     *
     * @param null $_projectid
     */
    public function __construct($_projectid = null)
    {
        // Connexion à la Base de Données
        $this->conn = new PDO(DATABASE, LOGIN, PASSWORD);

        // Instanciation du membre $projectid
        $this->projectid = $_projectid;

    } // __construct()

    /**
     * Destructeur de la class MProject
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
     * Renvoi le nom du projet précédé de sa hierarchie sous la forme grdParent.parent.enfant
     * @return mixed
     */
    public function fullProjectName()
    {
        $query = 'SELECT full_projectname(projectid) 
                    from project where projectid= :projectid';

        $result = $this->conn->prepare($query);

        $result->bindValue(':projectid', $this->projectid, PDO::PARAM_INT);

        $result->execute() or die ($this->ErrorSQL($result));

        return $result->fetch();
    }

    /**
     * Retourne la liste de tous les projets
     * @return array
     */
    public function selectAll()
    {
        $query = 'select projectid,
                         projectname,
                         projectparentid,
                         projectenddate 
                    from project order by projectname';

        $result = $this->conn->prepare($query);

        $result->execute() or die ($this->ErrorSQL($result));

        return $result->fetchAll();

    } //selectAllProjects()

    /**
     * renvoie un tableau avec les valeur d'un tuple sur la table project
     * @return mixed
     */
    public function select()
    {
        $query = "select projectid, projectname, projectenddate
                from project
                where projectid = :projectid";

        $result = $this->conn->prepare($query);

        $result->bindValue(':projectid', $this->projectid, PDO::PARAM_INT);

        $result->execute() or die ($this->ErrorSQL($result));

        return $result->fetch();

    }
    /**
     * renvoie un tableau avec les valeur d'un tuple sur la table project
     * @return mixed
     */
    public function listProject()
    {
        $query = "select projectname, projectid
                from project order by projectname";

        $result = $this->conn->prepare($query);


        $result->execute() or die ($this->ErrorSQL($result));

        return $result->fetchAll();

    }

    /**
     * Retourne le nom du chef de projet associé au projet;
     * @return mixed
     */
    function managerNameProject()
    {
        $query = "SELECT distinct M.userid, C.username, C.lastname, C.name
                  from project as P
                           natural join manager as M
                           natural join cramuser as C
                  where P.projectid = :projectid
                  order by M.userid";

        $result = $this->conn->prepare($query);

        $result->bindValue(':projectid', $this->projectid, PDO::PARAM_INT);

        $result->execute();

        return $result->fetchAll();

    } // managerNameProject()

    /**
     * addManager
     * @param $user
     * @return array
     */
    function addManager($user){
        $query = 'insert into manager (projectid, userid)
                  values (:projectid, :userid)';

        $result = $this->conn->prepare($query);

        $result->bindValue(':projectid', $this->projectid, PDO::PARAM_INT);
        $result->bindValue(':userid', $user,PDO::PARAM_INT);

        $result->execute() or die ($this->ErrorSQL($result));

        $this->projectid = $this->conn->lastInsertId();

        $this->value['projectid'] = $this->projectid;

        return $this->value;
    }


    /**
     * deleteManagerProject
     * @param $userid
     * @return void
     */
    function deleteManagerProject($userid)
        {
            $query = 'delete from manager
                where projectid = :projectid and userid = :userid';

            $result = $this->conn->prepare($query);

            $result->bindValue(':projectid', $this->projectid, PDO::PARAM_INT);
            $result->bindValue(':userid', $userid, PDO::PARAM_INT);

            $result->execute()  or die ($this->ErrorSQL($result));

            return;

    } //deleteManagerProject

    /**
     * Retourne le nom des users ayant déclaré une tache sur un projet; en fonction du projectid
     * @return mixed
     */
    function usernameTaskProject()
    {
        $query = "select distinct C.username, C.name, C.lastname
                  from task as T
                  natural join cramuser as C
                  where projectid = :projectid";

        $result = $this->conn->prepare($query);

        $result->bindValue(':projectid', $this->projectid, PDO::PARAM_INT);

        $result->execute();

        return $result->fetchAll();

    } // managerNameProject()

    /**
     * Renvoie un tableau de tous les projets et du lien qu'ils ont avec
     * l'user : true si l'utilisateur passé en paramètre est lié au projet, false si non
     * @param $user
     * @return mixed
     */
    function getAllProjects($user)
    {
        $query = "SELECT P.projectid, full_projectname(P.projectid) as projectname,
                                case when U.userid is not null then true else false end as flag
                                from project as P
                                left join projectuser as U on (U.userid = :user and  
                                P.projectid = U.projectid )
                                order by projectname";

        $result = $this->conn->prepare($query);

        $result->bindValue(':user', $user, PDO::PARAM_INT);

        $result->execute();

        return $result->fetchAll();

    } //getAllProjects($user)


    /**
     * Renvoie un tableau de tous les users et du lien qu'ils ont avec
     * le projet : true si le projet passé en paramètre est lié à l'utilisateur, sinon false
     * @return mixed
     */
    function getAllManagers()
    {
        $query = "  select u.userid, u.username, U.lastname, U.name,
                    case when count(m.projectid)>=1 then TRUE else FALSE end as flag
                    from cramuser as u
                    left join manager as m on m.userid=u.userid and m.projectid = :projectid 
                    group by u.userid";

        $result = $this->conn->prepare($query);

        $result->bindValue(':projectid', $this->projectid, PDO::PARAM_INT);

        $result->execute();

        return $result->fetchAll();

    } //getAllManagers()

    /**
     *  Verifie si un projet est attribué à un utilisateur en fonction de l'id du PROJET
     */
    public function verifContrainte()
    {
        $query = "select userid
                  from projectuser
                  where projectid = :projectid";

        $result = $this->conn->prepare($query);

        $result->bindValue(':projectid', $this->projectid, PDO::PARAM_INT);

        $result->execute() or die ($this->ErrorSQL($result));

        return $result->fetch();

    } //verifContrainte()

    /**
     * Déclenche une modification de la table project
     * @access public
     *
     * @param $_type
     * @return void
     */
    public function modify($_type)
    {
        switch ($_type) {
            case 'insert' : $this->insert(); break;
            case 'update' : $this->update(); break;
            case 'delete' : $this->delete(); break;
        }

        return;

    } // Modify($_type)

    /**
     *  addProject // Ajoute un projet dans la table projet
     * @return array
     */
    public function insert()
    {
        $query = 'insert into project (projectname, projectenddate, projectparentid)
                  values (:projectname, :projectenddate, :projectparentid)';

        $result = $this->conn->prepare($query);

        $result->bindValue(':projectname', $this->value['projectname'], PDO::PARAM_STR);
        $result->bindValue(':projectparentid', $this->value['projectparentid'],PDO::PARAM_INT);
        $result->bindValue(':projectenddate', $this->value['projectenddate'],PDO::PARAM_STR);

        $result->execute() or die ($this->ErrorSQL($result));

        $this->projectid = $this->conn->lastInsertId();

        $this->value['projectid'] = $this->projectid;

        return $this->value;

    } // insert()

    /**
     * Modifie les données d'un tuple dans la table project
     * @access private
     *
     * @return void
     */
    private function update()
    {
        $query = 'update project
                     set projectname = :projectname,
                         projectparentid = :projectparentid,
                         projectenddate = :projectenddate
                   where projectid = :projectid';

        $result = $this->conn->prepare($query);

        $result->bindValue(':projectid', $this->projectid, PDO::PARAM_INT);
        $result->bindValue(':projectname', $this->value['projectname'], PDO::PARAM_STR);
        $result->bindValue(':projectparentid', $this->value['projectparentid'], PDO::PARAM_INT);
        $result->bindValue(':projectenddate', $this->value['projectenddate'], PDO::PARAM_STR);

        $result->execute()  or die ($this->ErrorSQL($result));

        return;

    } // updateProject()

    /**
     * Modifie les données d'un tuple dans la table project
     * @access private
     *
     * @return void
     */
    private function delete()
    {
        $this->deleteProjectUser();
        
        $query = 'delete from project
                where projectid = :projectid';

        $result = $this->conn->prepare($query);

        $result->bindValue(':projectid', $this->projectid, PDO::PARAM_INT);

        $result->execute()  or die ($this->ErrorSQL($result));

        return;

    } //deleteProject()
    /**
     * Supprime une entrée dans la table projectuser
     * @access private
     *
     * @return void
     */
    private function deleteProjectUser()
    {
        $query = 'delete from projectuser
                where projectid = :projectid';

        $result = $this->conn->prepare($query);

        $result->bindValue(':projectid', $this->projectid, PDO::PARAM_INT);

        $result->execute()  or die ($this->ErrorSQL($result));

        return;

    } //deleteProjectUser()

} // MProject

