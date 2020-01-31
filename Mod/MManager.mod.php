<?php
/**
 * Class de type Modèle gérant la table manager
 *
 * @author Michael Larboni
 * @version 1.0
 */
class MManager
{
    /**
     * Connexion à la Base de Données
     * @var object $conn
     */
    private $conn;

    /**
     * clé primaire de la table manager
     * @var int $userid
     * @var int $projectid
     */
    private $userid;
    private $projectid;

    /**
     * Tableau de gestion de données (insert ou update)
     * @var array $value
     */
    private $value;

    /**
     * Constructeur de la class MManager
     * @access public
     *
     * @param null $_userid
     * @param null $_projectid
     */
    public function __construct($_userid = null, $_projectid = null)
    {
        // Connexion à la Base de Données
        $this->conn = new PDO(DATABASE, LOGIN, PASSWORD);

        // Instanciation des membres $userid, $projectid
        $this->userid = $_userid;
        $this->projectid = $_projectid;

    } // __construct()

    /**
     * Destructeur de la class MManager
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
     * insertion dans la table manager
     */
    public function insert()
    {

        $query = 'insert into manager (userid, projectid)
                  values (:userid, :projectid)';

        $result = $this->conn->prepare($query);

        $result->bindValue(':userid', $this->value['userid'],PDO::PARAM_INT);
        $result->bindValue(':projectid', $this->value['projectid'], PDO::PARAM_INT);

        $result->execute();

        $this->projectid = $this->conn->lastInsertId();

//        return $this->value;
        return ;
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
} // MManager

