<?php
/**
 * Class de type Modèle gérant la table USERS
 * 
 * @author Michael Larboni
 * @version 1.0
 */
class MDates
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
    public function __destruct(){}

    /**
    * Instancie le membre $value
    * @access public
    * @param array tableau des données
    *
    * @return void
    */
    public function SetValue($_value)
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
    public function SetIdUser($id_user)
    {
        $this->id_user = $id_user;
        return;

    } // SetIdUser($id_user)

/*    //Retourne l'id de l'utilisateur passé en paramètre, et permet sa connexion
    public function connexionBDD($user)
    {
        $pdo = PdoBdd::getPdoBdd();
        $stmt = $pdo->prepare("SELECT userid, username FROM cramuser
                               WHERE username = :user");
        $stmt->bindParam(':user', $user);
        $stmt->execute();
        $rs = $stmt->fetchAll();
        foreach ($rs as $value)
        return array("id" => $value['userid'], "username" => $value['username']);
    } //connexionBDD($user)*/

    /**
     * Retourne le nombre de congé pris par rapport à une période daté par user
     * @param $id_user
     * @param $date_begin
     * @param $date_end
     * @return mixed
     */

    public function holiday($id_user,$date_begin,$date_end)
    {
        $query = 'SELECT count(taskdayoff)/2
                    from task
                    where taskdayoff = true
                    and userid = :user 
                    and taskdate between :dateBegin and :dateEnd';

        $result = $this->conn->prepare($query);

        $result->bindValue(':user', $id_user, PDO::PARAM_INT);
        $result->bindValue(':dateBegin',$date_begin, PDO::PARAM_STR);
        $result->bindValue(':dateEnd',$date_end, PDO::PARAM_STR);

        $result->execute();

        $result_jour = $result->fetch(PDO::FETCH_NUM);

        return $result_jour[0];

//        return $result->fetchAll(PDO::FETCH_NUM);

    }

} // MUsers

