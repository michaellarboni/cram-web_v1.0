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

// Variable de contrôle
$EX = isset ($_REQUEST['EX']) ? $_REQUEST['EX'] : 'deconnexion';
if(isset($_SESSION['AUTORISATION']) AND $_SESSION['AUTORISATION'] == 'erreur'){
    $EX = 'deconnexion';
}

//$_SESSION['LANGUAGE'] = isset($_REQUEST['LANG']) ? $_REQUEST['LANG'] : $_SESSION['LANGUAGE'];

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

    case 'connect'                     : connect();                               break;
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
    $content ['class']  = 'VAdmin';
    $content ['method'] = 'showForm';
    $content ['arg']    =  $erreur;

    return;

} // home()

/**
 * Vérification de la connexion
 *
 * @return void
 */
function connect()
{
    $musers   = new MUsers();
    $value['user'] = isset($_POST['user']) ? $_POST['user'] : 'null' ;
    $musers->setValue($value);
    $result = $musers->VerifUser();

    $status['LEADER']  = $musers->leader ($result['userid']);
    $status['MANAGER'] = $musers->manager($result['userid']);

    if ($result) {
        $_SESSION['AUTORISATION'] = '';
    }
    elseif (!isset($_POST['user']))
    {
        $_SESSION['AUTORISATION'] = 'deconnect';
    }
    else{
        $_SESSION['AUTORISATION'] = 'erreur';
    }

    $_SESSION['ID']           = ($result['userstatut'] == 'valid') ? $result['userid'] : null;
    $_SESSION['USERNAME']     = $result['username'];
    $_SESSION['USERSTATUT']   = $result['userstatut'];
    $_SESSION['ADMIN']        = ($result['useradmin'] == true) ? true : false;

    if (isset($_SESSION['ID']) and ($_SESSION['USERSTATUT'] == 'valid'))
    {
        myTasksManagement();
        return;
    }
    elseif ($_SESSION['USERSTATUT'] == 'pending')
    {
        $erreur = 'Inscription en attente de validation par un admin';
        home($erreur);
    }
    elseif ($_SESSION['AUTORISATION'] == 'erreur')
    {
        $erreur = 'Vous n\'êtes pas inscrit';
        home($erreur);
    }
    elseif ($_SESSION['AUTORISATION'] == 'deconnect')
    {
        $erreur = 'Vous n\'êtes pas connecté';
        home($erreur);
    }

    return;

} // connect()

/**
 * Déconnexion
 *
 * @param $LANG
 * @return void
 */
function deconnexion()
{
    // On détruit les variables de notre session
    session_unset();
    // On détruit notre session
    session_destroy();
    // On redirige le visiteur vers la page d'accueil
//    $_SESSION['LANGUAGE'] = 'fr';
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
    if(!($_POST))
    {
        connect();
    }

    else{

        global $content;

        $content ['title']  = 'Cram-Web';
        $content ['class']  = 'VAdmin';
        $content ['method'] = 'showInscription';
        $content ['arg']    = '';

        return;
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
        connect();
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
        connect();
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
debug($_POST);
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
        connect();
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
        connect();
    }
    else{

        global $content;

        $content ['title']  = 'Cram-Web';
        $content ['class']  = 'VUserManagements';
        $content ['method'] = 'showManagement';
        $content ['arg']    = '';

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
        connect();
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

//        header('Loacation, ../Php/index.php?EX=userManagement');
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
        connect();
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
