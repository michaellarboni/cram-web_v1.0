<?php
/**
 * Class de type Modèle gérant la table activity
 * 
 * @author Michael Larboni
 * @version 1.0
 */
class MActivity
{
    /**
    * Connexion à la Base de Données
    * @var object $conn
    */
    private $conn;

    /**
     * clé primaire de la table activity
     * @var int activityid
     */
    private $activityid;

    /**
    * Tableau de gestion de données (insert ou update)
    * @var array $value
    */
    private $value;

    /**
    * Constructeur de la class MActivity
    * @access public
    *
    * @return void
    */
    public function __construct($_activityid = null)
    {
        // Connexion à la Base de Données
        $this->conn = new PDO(DATABASE, LOGIN, PASSWORD);

        // Instanciation du membre $activityid
        $this->activityid = $_activityid;
 
    } // __construct()
  
    /**
    * Destructeur de la class MActivity
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
     * Retourne l'id de l'utilisateur passé en paramètre, et permet sa connexion
     * @return array
     */
    public function selectAll()
    {
        $query = 'select activityid,
                         activityname
                    from activity order by activityname';

        $result = $this->conn->prepare($query);

        $result->execute() or die ($this->ErrorSQL($result));

        return $result->fetchAll();

    } //selectAllActivitys()

    public function select()
    {
        $query = "select activityid, activityname
                from activity
                where activityid = :activityid";

        $result = $this->conn->prepare($query);

        $result->bindValue(':activityid', $this->activityid, PDO::PARAM_INT);
//        $result->bindValue(":$_value", "$_value", PDO::PARAM_INT);

        $result->execute() or die ($this->ErrorSQL($result));

        return $result->fetch();

    }

    /**
     * Déclenche une modification de la table activity
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
     *  addActivity // Ajoute un projet dans la table projet
     * @return array
     */
    public function insert()
    {
        $query = 'insert into activity (activityname)
                  values (:activityname)';

        $result = $this->conn->prepare($query);

        $result->bindValue(':activityname', $this->value['activityname'], PDO::PARAM_STR);

        $result->execute() or die ($this->ErrorSQL($result));

        $this->activityid = $this->conn->lastInsertId();

        $this->value['activityid'] = $this->activityid;

        return $this->value;

    } // addActivity()

    /**
     * Modifie les données d'un tuple dans la table activity
     * @access private
     *
     * @return void
     */
    private function update()
    {
        $query = 'update activity
                     set activityname = :activityname
                   where activityid = :activityid';

        $result = $this->conn->prepare($query);

        $result->bindValue(':activityid', $this->activityid, PDO::PARAM_INT);
        $result->bindValue(':activityname', $this->value['activityname'], PDO::PARAM_STR);

        $result->execute()  or die ($this->ErrorSQL($result));

        return;

    } // updateActivity()

    /**
     * Modifie les données d'un tuple dans la table activity
     * @access private
     *
     * @return void
     */
    private function delete()
    {
        $query = 'delete from activity
                where activityid = :activityid';

        $result = $this->conn->prepare($query);

        $result->bindValue(':activityid', $this->activityid, PDO::PARAM_INT);

        $result->execute() or die ($this->ErrorSQL($result));

        return ;

    } //deleteActivity()

    /**
     * Cette fonction va renvoyer un tableau de toutes les activités et leur association à
     * l'utilisateur : true si l'utilisateur passé en paramètre est lié à l'activité, false si non
     * @param $user
     * @return mixed
     */
    function getAllActivities($user)
    {
        $query = 'SELECT A.activityid, activityname,
                    case when U.userid is not null then true else false end as flag
                    from activity as A
                    left join activityuser as U on (U.userid = :user and  
                    A.activityid = U.activityid )
                    order by activityname';

        $result = $this->conn->prepare($query);

        $result->bindValue(':user', $user, PDO::PARAM_INT);

        $result->execute();

        return $result->fetchAll();

    } //getAllActivities($user)

    /**
     *  Verifie si une activité est attribué à un utilisateur en fonction de l'id de l'activité
     */
    public function usernameTaskActivity()
    {
        $query = "select distinct C.username, C.name, C.lastname
                  from task as T
                  natural join cramuser as C
                  where activityid = :activityid";

        $result = $this->conn->prepare($query);

        $result->bindValue(':activityid', $this->activityid, PDO::PARAM_INT);

        $result->execute();

        return $result->fetchAll();

    } //usernameTaskActivity()

    /**
     *  ErrorSQL
     * @param $result
     */
    private function ErrorSQL($result)
    {
        // Récupère le tableau des erreurs
        $error = $result->errorInfo();

        echo 'TYPE_ERROR = ' . $error[0] . '<br />';
        echo 'CODE_ERROR = ' . $error[1] . '<br />';
        echo 'MSG_ERROR = ' . $error[2] . '<br />';

        return;

    }
} // MActivity

