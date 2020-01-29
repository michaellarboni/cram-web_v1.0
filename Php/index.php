<?php
/**
 * Contrôleur
 * @author Michael LARBONI
 * @version 1.0
 * @package MVC
 */

// Inclusion du fichier des utilitaires de l'application
require('../Inc/require.inc.php');

// Crée une session nommée
session_name('cram-web');
session_start();

//objet language
$mlanguage = new MLanguage(isset($_SESSION['LANGUAGE']) ? $_SESSION['LANGUAGE'] : 'fr' );
//tableau de langue associé
$lang = $mlanguage->arrayLang();

// Variable de contrôle
$EX = isset ($_REQUEST['EX']) ? $_REQUEST['EX'] : 'deconnexion';
if(isset($_SESSION['AUTORISATION']) AND $_SESSION['AUTORISATION'] == 'erreur'){
    $EX = 'deconnexion';
}

if (isset($_REQUEST['LANG'])){
    switch ($_REQUEST['LANG'])
    {
        case 'fr' : $_SESSION['LANGUAGE'] = 'fr'; break;
        case 'en' : $_SESSION['LANGUAGE'] = 'en'; break;
    }
}
    elseif (!isset($_SESSION['LANGUAGE'])) {
        $_SESSION['LANGUAGE'] = 'fr';
    }

// Contrôleur
switch ($EX)
{
    case 'home'                        : home();                                  break;

    case 'ldap'                        : ldap();                                  break;
    case 'deconnexion'                 : deconnexion();                           break;
    case 'inscription'                 : inscription();                           break;

    case 'myTasksManagement'           : myTasksManagement();                     break;

    case 'adminManagementUsers'        : adminManagement('Users');           break;
    case 'adminManagementProjects'     : adminManagement('Projects');        break;
    case 'adminManagementActivities'   : adminManagement('Activities');      break;

    case 'form_project'                : formProject();                           break;
    case 'insert_project'              : adminModifyProject('insert');       break;
    case 'update_project'              : adminModifyProject('update');       break;
    case 'delete_project'              : adminModifyProject('delete');       break;

    case 'insert_activity'             : adminModifyActivity('insert');      break;
    case 'update_activity'             : adminModifyActivity('update');      break;
    case 'delete_activity'             : adminModifyActivity('delete');      break;

    case 'reportingUser'               : reporting('reportingUser');         break;
    case 'reportingManager'            : reporting('reportingManager');      break;
    case 'reportingLeader'             : reporting('reportingLeader');       break;

    case 'userManagement'              : userManagement();                         break;
    case 'userModifyActivity'          : userModifyActivity();                     break;
    case 'userModifyProject'           : userModifyProject() ;                     break;

    default: home();
}

// Mise en page
require('../View/layout.view.php');

/**
 *  Affichage de la page d'accueil
 *
 * @param string $erreur
 * @return void
 */
function home($erreur = '')
{
    unset($_SESSION['ID']);

    global $content;

    $content ['title']  = 'Cram-Web';
    $content ['class']  = 'VForm';
    $content ['method'] = 'showForm';
    $content ['arg']    =  $erreur;

    return;

} // home()

/**
 * Vérification sur le serveur LDAP
 *
 * @return void
 */
function ldap()
{
    // Eléments d'authentification LDAP
    $username = isset($_POST['username']) ? $_POST['username'] : 'null' ;
    $ldapRdn  = 'uid=' . $username . ',ou=people,dc=pytheas,dc=fr';     // DN ou RDN LDAP
    $ldapPass = $_POST['userpwd'];

    // Connexion au serveur LDAP
    // JCM 13/01  define(LDAP_OPT_DIAGNOSTIC_MESSAGE, 0x0032);
    $ldapConn = ldap_connect("ldaps://ldap.osupytheas.fr:636")
        or die("Impossible de se connecter au serveur LDAP.");

    // pour developpement
    // constante LDAP dans /Inc/require.inc permet de désactiver le controle LDAP en affectant false
    if (LDAP) {
        if ($ldapConn) {
            // Connexion au serveur LDAP
            $ldapbind = ldap_bind($ldapConn, $ldapRdn, $ldapPass);

            // Vérification de l'authentification dans la base
            if ($ldapbind) {
                verifUser($username);
            } else {
                    home('Identifiant ou mot de passe inccorect');
            }
        }
    }
        else{
            verifUser($username);
        }

    return;

} // connect()

/**
 * Verification sur la base de données du CRAM
 * @param $username
 */
function verifUser($username){

    // dictionnaire de langues
    global $lang;

    $musers = new MUsers();
    $user = $musers->verifUser($username);

    if ($user['username'] == $username) {
        $_SESSION['AUTORISATION'] = 'granted';}

    else {
        home($lang['notRegistered']); //Vous n'avez pas la permission d'accéder au CRAM
    }

    $_SESSION['ID'] = ($user['userstatut'] == 'valid') ? $user['userid'] : null;
    $_SESSION['USERNAME'] = $user['username'];
    $_SESSION['NAME'] = $user['name'];
    $_SESSION['USERSTATUT'] = $user['userstatut'];
    $_SESSION['ADMIN'] = ($user['useradmin'] == true) ? true : false;

    if (isset($_SESSION['ID']) and ($_SESSION['USERSTATUT'] == 'valid')) {
        myTasksManagement();
        return;
    }

    if ($_SESSION['USERSTATUT'] == 'pending') {
        home($lang['pending']);  // Inscription en attente de validation par un admin
    }

    return;
}

/**
 * Déconnexion
 *
 * @return void
 */
function deconnexion()
{
    // On détruit les variables de notre session
    session_unset();
    // On détruit notre session
    session_destroy();
    // On redirige le visiteur vers la page d'accueil
    home();

    return;

} // deconnect()

/**
 *  Inscription
 *
 * @return void
 */
function inscription()
{
    // dictionnaire de langues
    global $lang;

    if(!($_POST)) {
        home();
    }

    else {
        include_once ('../securimage/securimage.php');
        $securimage = new Securimage();

        if ($securimage->check($_POST['captcha_code']) == false)
        {
            // code incorrect
            home($lang['securityCodeIncorrect']);
            return;
        }

        else {
            // Eléments d'authentification LDAP
            $username = isset($_POST['username']) ? $_POST['username'] : 'null' ;
            $ldapRdn  = 'uid=' . $username . ',ou=people,dc=pytheas,dc=fr';     // DN ou RDN LDAP
            $ldapPass = $_POST['userpwd'];

            // Connexion au serveur LDAP
            $ldapConn = ldap_connect("ldaps://ldap.osupytheas.fr:636")
            or die("Impossible de se connecter au serveur LDAP.");

            // pour developpement
            // constante LDAP dans /Inc/requiere.inc permet de désactiver le controle LDAP en affectant false
            if (LDAP) {
                if ($ldapConn) {
                    // Connexion au serveur LDAP
                    $ldapbind = ldap_bind($ldapConn, $ldapRdn, $ldapPass);

                    // Vérification de l'authentification dans la base
                    if ($ldapbind) {
                        // données POST nécessaires a l'enregistrement provisoire
                        $value['username']    = $_POST['username'];
                        $value['userpwd']    = md5($_POST['userpwd']);
                        $value ['userstatut'] = 'pending';

                        $musers = new MUsers();
                        $musers->setValue($value);

                        // verifie s'il existe deja dans la base pour éviter les doublons
                        $user = $musers->verifUser($_POST['username']);
                        if($user['username'] == $_POST['username']){
                            if($user['userstatut'] == 'pending'){
                                home($lang['alreadyRequested']);
                                return;
                            }
                            else{
                                home($lang['alreadyRegistered']);
                                return;
                            }
                        }
                        else{
                            $musers->addUser();  // ajout dans la bdd avec le statut 'pending'
                            home($lang['securityCodeCorrect']);
                            return;
                        }

                    }
                    else{
                        home('Identifiant ou mot de passe inccorect');
                    }
                }
                else{
                    home('LDAP n\'est pas disponible, impossible de procéder à l \'inscription');
                }
            }
            else{
                home('LDAP n\'est pas disponible, impossible de procéder à l \'inscription');
            }
        }
    }

} // inscription()

/**
 * myTasksManagement
 *
 * @return void
 */
function myTasksManagement()
{
    if (!isset($_SESSION['ID'])){
        home();
        return;
    }
    else
    {
        global $content;

        $content ['title']  = 'Cram-Web';
        $content ['class']  = 'VHtml';
        $content ['method'] = 'showHtml';
        $content ['arg']    = '../Html/myTasksManagement.php';

        return;

    }
} //myTasksManagement

/**
 * Gestion ADMIN des projets, activités, utilisateur
 *
 * @param $type
 * @return void
 */
function adminManagement($type)
{
    if (isset($_SESSION['AUTORISATION']) AND ($_SESSION['AUTORISATION']) == 'deconnect' OR !isset($_SESSION['AUTORISATION']))
    {
        home();
    }
    else{

        $mproject  = new MProject();
        $musers    = new MUsers();
        $mactivity = new MActivity();
        $data      = '';

        switch ($type) {
            case 'Projects'  :
                $data = $mproject->selectAll();
                break;
            case 'Users'     :
                $value = null;
                $musers->setValue($value);
                $data = $musers->selectAll();
                break;
            case 'Activities':
                $data = $mactivity->selectAll();
                break;
        }

        global $content;

        $content ['title'] = 'CRAM-Web';
        $content ['class'] = 'VAdminManagements';
        $content ['method'] = 'show' . $type . 'Management';
        $content ['arg'] = $data;

        return;
    }

} //adminManagement($type)

/**
 * fomrulaire de projet
 */
function formProject()
{
    global $content;

    $content ['title']  = 'CRAM-Web';
    $content ['class']  = 'VAdminManagements';
    $content ['method'] = 'showFormProject';
    $content ['arg']    = '';

    return;
}

/**
 * Modifie un projet dans la table project
 *
 * @param $type
 * @return void
 */
function adminModifyProject($type)
{
    $id_project = isset($_REQUEST['projectid']) ? $_REQUEST['projectid'] : '';
    $mproject = new MProject($id_project);
    $value = $_POST;
    $value['projectid'] = $id_project;
    if($type != 'delete'){
        $value['projectparentid'] = (isset($_POST['projectparentid'])) ? $_POST['projectparentid'] : null;
        $value['projectenddate']  = ($_POST['projectenddate']) ? $_POST['projectenddate'] : null;
        $mproject->setValue($value);
        $mproject->Modify($type);
    }
    else{
        if($mproject->verifContrainte()){
            echo 'impossible de supprimer le projet actif';
        }
        else{
            $mproject->setValue($value);
            $mproject->Modify($type);
        }
    }
    adminManagement('Projects');

    return;

} // modify_project($type)

/**
 * Modifie une activité dans la table activity
 *
 * @param $type
 * @return void
 */
function adminModifyActivity($type)
{
    $activityid = isset($_REQUEST['activityid']) ? $_REQUEST['activityid'] : '';
    $value = $_POST;
    $value['activityid'] = $activityid;

    $mactivity = new MActivity($activityid);
    $mactivity->setValue($value);
    $mactivity->Modify($type);

    adminManagement('Activities');

    return;

} // modify_activity($type)

function reporting($type)
{
    if (isset($_SESSION['AUTORISATION']) AND ($_SESSION['AUTORISATION']) == 'deconnect' OR !isset($_SESSION['AUTORISATION']))
    {
        home();
    }
    else{

        global $content;

        $content ['title']  = 'Cram-Web';
        $content ['class']  = 'VHtml';
        $content ['method'] = 'showHtml';
        $content ['arg']    = '../Html/'.$type.'.php';

        return;
    }

} //reportingUser($type)

/**
 * Affichage de la page de config de l'utilisateur
 */
function userManagement()
{
    if (isset($_SESSION['AUTORISATION']) AND ($_SESSION['AUTORISATION']) == 'deconnect' OR !isset($_SESSION['AUTORISATION']))
    {
        home();
    }
    else{

        $mproject = new MProject();
        $mactivity = new MActivity();

        $data['project']  = $mproject->getAllProjects($_SESSION['ID']);;
        $data['activity'] = $mactivity->getAllActivities($_SESSION['ID']);;

        global $content;

        $content ['title']  = 'Cram-Web';
        $content ['class']  = 'VUserManagements';
        $content ['method'] = 'showManagement';
        $content ['arg']    = $data;

        return;
    }
} //userManagement()

/**
 *  function modifyProject
 *  pour la config de l'utilisateur
 */
function userModifyProject()
{
    if (isset($_SESSION['AUTORISATION']) AND ($_SESSION['AUTORISATION']) == 'deconnect' OR !isset($_SESSION['AUTORISATION']))
    {
        home();
    }
    else{

        $musers = new MUsers();

        if (isset($_POST['autresprojets'])) //si on a sélectionné des projets dans la liste des autres projets
        {
            foreach ($_POST['autresprojets'] as $value)
            {
                $musers->addProject($value, $_SESSION['ID']); //On associe ces projets à l'utilisateur
            }
        }
        else // sinon, soit si on a sélectionné des activités déjà associées
        {
            foreach ($_POST['mesprojets'] as $value)
            {
                $musers->deleteProject($value, $_SESSION['ID']); //On supprime l'association entre les projets et l'utilisateur
            }
        }

        userManagement();


        return;

    }

} //modifyProject()

/**
 *  function modifyActivity()
 *  pour la config de l'utilisateur
 */
function userModifyActivity()
{
    if (isset($_SESSION['AUTORISATION']) AND ($_SESSION['AUTORISATION']) == 'deconnect' OR !isset($_SESSION['AUTORISATION']))
    {
        home();
    }
    else{

        $musers = new MUsers();

        if (isset($_POST['autresactivites'])) //si on a sélectionné des activités dans la liste des autres activités
        {
            foreach ($_POST['autresactivites'] as $value)
            {
                $musers->addActivity($value, $_SESSION['ID']); //On associe ces activités à l'utilisateur
            }
        }
        else // sinon, soit si on a sélectionné des activités déjà associés
        {
            foreach ($_POST['mesactivites'] as $value)
            {
                $musers->deleteActivity($value, $_SESSION['ID']); //On supprime l'association entre les activités et l'utilisateur
            }
        }

        userManagement();

        return;

    }

} //modifyActivity()
