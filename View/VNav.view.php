<?php
/**
 * Fichier de classe de type Vue
 * pour l'affichage de la navigation
 * @author Michael Larboni
 * @version 1.0
 */

/**
 * Classe pour l'affichage de la navigation
 */
class VNav // todo extends MLang
{

    /**
     * constructeur de la classe VNav
     */
    public function __construct(){}
    public function __destruct(){}

    /**
     * Affichage de la navigation
     * @access public
     *
     * @return void
     */
    public function showNav()
    {
        //objet language
        $mlanguage = new MLanguage(isset($_SESSION['LANGUAGE']) ? $_SESSION['LANGUAGE'] : 'fr' );
        //tableau de langue associé
        $lang = $mlanguage->arrayLang();

        $musers  = new MUsers();
        $leader  = $musers->leader($_SESSION['ID']);
        $manager = $musers->manager($_SESSION['ID']);

        $name = $_SESSION['USERNAME'];
        $liReportUser    = '<a href="../Php/index.php?EX=reportingUser">'.$lang['user'].'</a>';
        $liReportLeader  = ($leader) ? '<a href="../Php/index.php?EX=reportingLeader">'.$lang['leader'].'</a>' : '';
        $liReportManager = ($manager) ? '<a href="../Php/index.php?EX=reportingManager">'.$lang['manager'].'</a>' : '' ;

        $liAdmin = ($_SESSION['ADMIN']) ?
            '     <div class="dropdowndiv">
                    <button class="dropbtn">Administration
                        <i class="fa fa-caret-down"> </i>
                    </button>
                    <div class="dropdowndiv-content">
                        <a href="../Php/index.php?EX=adminManagementUsers">'.$lang['users'].'</a>
                        <a href="../Php/index.php?EX=adminManagementActivities">'.$lang['activities'].'</a>
                        <a href="../Php/index.php?EX=adminManagementProjects">'.$lang['projects'].'</a>
                    </div>
                </div>' : '';

        $tasks     = $lang['tasks'];
        $reporting = $lang['reporting'];
        $account   = $lang['account'];
        $logout    = $lang['logout'];

        switch ($_REQUEST['EX']){
            case 'connect' : $_ex = 'myTasksManagement' ; break;
            case 'update_activity':
            case 'insert_activity': $_ex = 'adminManagementActivities' ; break;
            case 'update_project':
            case 'insert_project': $_ex = 'adminManagementProjects' ; break;
            case 'userModifyActivity':
            case 'userModifyProject': $_ex = 'userManagement' ; break;

            default: $_ex =  $_REQUEST['EX']; break;
        }
        $exFR = $_ex.'&amp;LANG=fr';
        $exEN = $_ex.'&amp;LANG=en';

        echo<<<HERE

<div class="navbardiv">
  <a href="../Php/index.php?EX=myTasksManagement">$tasks</a>
  <div class="dropdowndiv">
    <button class="dropbtn">$reporting 
      <i class="fa fa-caret-down"> </i>
    </button>
    <div class="dropdowndiv-content">
        $liReportUser   
        $liReportLeader 
        $liReportManager
    </div>
  </div> 
  
  <div class="pull-right">
      $liAdmin
      
      <div class="dropdowndiv">
        <button class="dropbtn">$name
          <i class="fa fa-caret-down"> </i>
        </button>
        <div class="dropdowndiv-content">
          <a href="../Php/index.php?EX=userManagement">$account</a>
          <div class="dropdowndiv-divider"></div>
          <a href="../Php/index.php?EX=deconnexion">$logout</a>
        </div>
      </div>   
        
        <div class="dropdowndiv">
            <button class="dropbtn">Language<i class="fa fa-caret-down"> </i></button>
            <div class="dropdowndiv-content">
                <a href="../Php/index.php?EX=$exEN">English</a>
            <div class="dropdowndiv-divider"></div>
                <a href="../Php/index.php?EX=$exFR">Français</a>
            </div>
        </div>   
  </div>
</div>
HERE;

    } //showNav()

} // VNav
