<?php
/**
 * Fichier de classe de type Vue
 * pour l'affichage des Managements
 * @author Michael Larboni
 * @version 1.0
 */

/**
 * Classe pour l'affichage des Managements
 */
class VUserManagements
{
    /**
     * Constructeur de la classe VUserManagements
     * @access public
     *
     * @return void
     */
    public function __construct(){}

    /**
     * Destructeur de la classe VUserManagements
     * @access public
     *
     * @return void
     */
    public function __destruct(){}

    public function showManagement()
    {
        $this->showProjectsManagement();
        $this->showActivitiesManagement();
    }

    /**
     * Affichage du ProjectsManagement
     * @access public
     *
     * @return void
     */
    public function showProjectsManagement()
    {
        //objet language
        $mlanguage = new MLanguage(isset($_SESSION['LANGUAGE']) ? $_SESSION['LANGUAGE'] : 'fr' );
        //tableau de langue associé
        $lang = $mlanguage->arrayLang();

        $mproject = new MProject();
        $data = $mproject->getAllProjects($_SESSION['ID']);

        // variables d'option
        $optionsProjets = '';
        $optionsOthers  = '';

        // Parcour le tableau et propose les options
        foreach ($data as $value)
        {
            if ($value['flag'] == true)

                $optionsProjets .= "<option value=".$value['projectid'].">".$value['name']."</option>";

            if ($value['flag'] == false)
            {
                $optionsOthers .= "<option value=".$value['projectid'].">".$value['name']."</option>";
            }
        }

?>

<style>
    [class*="col-"]{
        text-align: center;
    }
    .divProject{
        margin-top: 50px;
        margin-bottom: 50px;
    }
</style>

<script src="../Js/userManagementProjects.js"></script>

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">

<div class="container border divProject">
    <form action ="../Php/index.php?EX=userModifyProject" name="formProject" class="well" method="post">
        <div class="row">
                     
            <div class="col-md-4">
                <!-- Liste des projets qui ne sont pas associées à l'utilisateur -->
                <h4><?php echo $lang['projectsAvailables']?></h4>
                <select size="15" id="autresprojets" name="autresprojets[]" multiple="multiple" onchange="choixLesProjets()">
                    <?php echo $optionsOthers?>
                </select>
            </div>       
               
           <div class="row col-4">
                 <div class="row container align-content-center">
                            <div class="col-lg-12">
                                <!-- Bouton pour associer de nouveaux projets à l'utilisateur -->
                                <button name="ajout" class="btn col-md-6" type="submit" disabled><i class="fa fa-arrow-right" style="font-size:36px;color:green"></i></button>
                            </div>
                            <div class="col-lg-12">
                                <!-- Bouton pour ne plus associer des projets à l'utilisateur -->
                                <button name="suppression" class="btn col-md-6" type="submit" disabled><i class="fa fa-arrow-left" style="font-size:36px;color:red"></i></button>
                            </div>     
                    </div>   
            </div>
            
           <div class="col-md-4">
                <!--Liste des projets associées à l'utilisateur -->
                <h4><?php echo $lang['myProjects']?></h4>
                <select size="15" id="mesprojets" name="mesprojets[]" multiple="multiple" onchange="choixMesProjets()">
                    <?php echo $optionsProjets?>
                </select>
            </div>
            
        </div>
    </form>
</div>

<?php

        return;

    } //showProjectsManagement($_data)

    /**
     * Affichage du ActivitiesManagement
     * @access public
     *
     * @return void
     */
    public function showActivitiesManagement()
    {
        //objet language
        $mlanguage = new MLanguage(isset($_SESSION['LANGUAGE']) ? $_SESSION['LANGUAGE'] : 'fr' );
        //tableau de langue associé
        $lang = $mlanguage->arrayLang();

        $mactivity = new MActivity();
        $data = $mactivity->getAllActivities($_SESSION['ID']);

        // variables d'option
        $optionsActivities = '';
        $optionsOthers     = '';

        // Parcour le tableau et propose les options
        foreach ($data as $value)
        {
            if ($value['flag'] == true)

                $optionsActivities .= "<option value=".$value['activityid'].">".$value['activityname']."</option>";

            if ($value['flag'] == false)
            {
                $optionsOthers .= "<option value=".$value['activityid'].">".$value['activityname']."</option>";
            }
        }

?>
     
<script src="../Js/userManagementActivities.js"></script>

<div class="container border">
    <form action ="../Php/index.php?EX=userModifyActivity" name="formActivities" class="well" method="post">
        <div class="row">
        
            <div class="col-md-4">
                <!-- Liste des activités qui ne sont pas associées à l'utilisateur -->
                <h4><?php echo $lang['activitiesAvailables']?></h4>
                <select size="15" id="autresactivites" name="autresactivites[]" multiple="multiple" onchange="choixLesActivites()">
                    <?php echo $optionsOthers?>
                </select>
            </div>
                       
           <div class="row col-4 ">
                 <div class="row container align-content-center">
                            <div class="col-lg-12">
                                <!-- Bouton pour associer de nouvelles activités à l'utilisateur -->
                                <button name="ajout" class="btn col-md-6" type="submit" disabled><i class="fa fa-arrow-right" style="font-size:36px;color:green"></i></button>
                            </div>
                            <div class="col-lg-12">
                                <!-- Bouton pour ne plus associer des activités à l'utilisateur -->
                                <button name="suppression" class="btn col-md-6" type="submit" disabled><i class="fa fa-arrow-left" style="font-size:36px;color:red"></i></button>
                            </div>     
                    </div>   
            </div>
            
           <div class="col-md-4">
                <!--Liste des activités associées à l'utilisateur -->
                <h4><?php echo $lang['myActivities']?></h4>
                <select size="15" id="mesactivites" name="mesactivites[]" multiple="multiple" onchange="choixMesActivites()">
                    <?php echo $optionsActivities?>
                </select>
            </div>
            
        </div>
    </form>
</div>

<?php

        return;

    } //showActivitiesManagement($_data)

} // VUserManagements
