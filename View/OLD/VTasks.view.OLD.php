<?php
/**
 * Fichier de classe de type Vue
 * pour l'affichage de la navigation
 * @author Michael Larboni
 * @version 1.0
 */

/**
 * Classe pour l'affichage des taches
 */
class VTasks
{
    /**
     * Constructeur de la classe VTasks
     * @access public
     *
     * @return void
     */
    public function __construct(){}

    /**
     * Destructeur de la classe VHtml
     * @access public
     *
     * @return void
     */
    public function __destruct(){}

    /**
     * Affichage du calendrier
     * @access public
     *
     * @return void
     */
    public function showMyTasksManagement()
    {
        //objet language
        $mlanguage = new MLanguage(isset($_SESSION['LANGUAGE']) ? $_SESSION['LANGUAGE'] : 'fr' );
        //tableau de langue associé
        $lang = $mlanguage->arrayLang();
        
//        include '../Html/head.php';  //todo a tester
        $musers = new MUsers();
        $user = $_SESSION['ID'];

        if (!isset($_SESSION['startDate']) or !$_SESSION['startDate']) {
            $_SESSION['startDate'] = $musers->getStartDate($user);
        }

        $_SESSION['date_begin'] = date ('Y-m-d');
        $_SESSION['date_end']   = date ('Y-m-01');

        // recuperation des projects et activités dans la bdd
        $data['projects']   = $musers->getAllProjects($user);
        $data['activities'] = $musers->getAllActivities($user);

        // variables des Options
        $optionsProjects = '';
        $optionsActivities  = '';

        // boucle sur l'array projects pour creer les options
        foreach($data['projects'] as $key=>$val)
        {
            if ($val['flag'])
            {
                $optionsProjects .= '<option value="'.$val['projectid'].'" label="'.$val['name'].'">'.$val['name'].'</option>';
            }
        }

        // boucle sur l'array activities pour creer les options
        foreach($data['activities'] as $val)
        {
            if ($val['flag'])
            {
                $optionsActivities .= '<option value="'.$val['activityid'].'" label="'.$val['activityname'].'">'.$val['activityname'].'</option>';
            }
        }

        $holiday      = $lang['holiday'];
        $projects     = $lang['projects'];
        $activities   = $lang['activities'];
        $commentary   = $lang['commentary'];
        $saveClose    = $lang['saveClose'];
        $cancel       = $lang['cancel'];
        $clear        = $lang['clear'];
        $savePrevious = $lang['savePrevious'];
        $saveNext     = $lang['saveNext'];

        /**
         * insertion du calendrier avec le script
         */
        echo <<<HERE

<style>

body {

    padding: 0;
    font-family: Arial, Helvetica Neue, Helvetica, sans-serif;
    font-size: 14px;
  }
    #calendar {
        max-width: 1000px;
        margin: 0 auto;
    }
    input[id="holiday"]:valid ~ div#options {
        display: none;
    }

    input[id="holiday"]:invalid ~ div#options {
        display: block;
    }

</style>
<script src="../Js/includeScript.js"></script>
<script type="text/javascript" src='../Js/calendrier.js'></script>

        <!-- affichage pour le formulaire d'entree sur le ou les jour effectué -->
        <div id="board" class="row-fluid">
            <div class="well">
                <div class="container" style="text-align:center" >
                    <div id='calendar' class="calendar">           
                    </div>
                </div>
                <div id="infos"></div>
            </div>
        </div>

        <!-- fancyBox-->
        <div id="dialog-form" class="row-fluid">
            <div action="#" method="POST" id="myform">

                <div id="complet-form" class="row_fluid span12">
                
                    <div class="row-fluid">
                        <div class="col-md-12">
                            <label class="col-lg-3">Dates</label>
                            <ul id="dates"></ul>
                        </div>
                    </div>
                    
                    <label class="col-lg-3" for="holiday">$holiday</label>
                    <input class="col-lg-1" name="holiday" id="holiday" type="checkbox" required/>
    
                    <!--N'affiche que si la checkbox Absence est décochée-->
                    <div id="options">
                        <div class="row-fluid">
                            <div class="col-md-12">
                                <label class="col-lg-3" for="projet">$projects</label>
                                <select class="col-lg-7" id="projet" name="projet">
                                    <?php echo $optionsProjects ?>
                                </select>
                            </div>
                        </div>
        
                        <div class="row-fluid">
                            <div class="col-md-12">
                                <label class="col-lg-3" for="activity">$activities</label>
                                <select class="col-lg-7" id="activity" name="activity">
                                    <?php echo $optionsActivities ?>
                                </select>
                            </div>
                        </div>
                    </div>
                    <!---->
                    
                    <div class="row-fluid">
                        <div class="col-md-12">
                            <label class="col-lg-3" for="comment">$commentary</label>
                            <textarea class="col-lg-7" name="comment" id="comment"></textarea>
                        </div>
                    </div>
                    
                    <div class="row_fluid" >
                        <div style="text-align:center">
                            <input type="submit" class="btn btn-primary" name="valid" value="$saveClose" />
                            <input type="submit" class="btn btn-primary" name="cancel" value="$cancel" />
                            <input type="submit" class="btn btn-danger"  name="delete" value="$clear"/>
                        </div>
                        <input type="hidden" value="add" name="action" />
                    </div>
                </div>
    
                <div class="row-fluid">
                    <div class="col-lg-12 align-items-center">
                        <input class="offset-1 col-lg-5 btn btn-arrow-left btn-primary" id="previous" type="submit" name="save_previous" value="$savePrevious"/>
                        <input class="col-lg-5 btn btn-arrow-right btn-primary" id="next" type="submit" name="save_next" value="$saveNext">
                    </div>
                </div>
            </div>

            </form>
        </div>

HERE;


    } //showMyTasksManagement()

} // VTasks
