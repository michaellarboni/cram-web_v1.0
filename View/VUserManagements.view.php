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
     */
    public function __construct(){
    }

    /**
     * Destructeur de la classe VUserManagements
     * @access public
     *
     * @return void
     */
    public function __destruct(){}

    public function showManagement($_data)
    {
        $this->showProjectsManagement($_data['project']);
        $this->showActivitiesManagement($_data['activity']);
    }

    /**
     * Affichage du ProjectsManagement
     * @access public
     *
     * @param $_data
     * @return void
     */
    public function showProjectsManagement($_data)
    {
        //objet language
        $mlanguage = new MLanguage(isset($_SESSION['LANGUAGE']) ? $_SESSION['LANGUAGE'] : 'fr' );
        //tableau de langue associé
        $lang = $mlanguage->arrayLang();

        // variables d'option
        $optionsProjets = '';
        $optionsOthers  = '';

        // Parcour le tableau et propose les options
        foreach ($_data as $value)
        {
            if ($value['flag'] == true)

                $optionsProjets .= "<option value=".$value['projectid'].">".$value['projectname']."</option>";

            if ($value['flag'] == false)
            {
                $optionsOthers .= "<option value=".$value['projectid'].">".$value['projectname']."</option>";
            }
        }

?>

<style>
    [class*="col-"]{
        text-align: center;
    }
    .row{
        margin-left:0;
        margin-right:0;
    }
    .divProject{
        margin-top: 50px;
        margin-bottom: 50px;
    }
select, input{
    width: 100%;
    margin-top: 5px;
    margin-bottom: 5px;

}
</style>

<script src="../Js/userManagementProjects.js"></script>
<script>
(function (w, doc,co) {
    // http://stackoverflow.com/questions/901115/get-query-string-values-in-javascript
    var u = {},
        e,
        a = /\+/g,  // Regex for replacing addition symbol with a space
        r = /([^&=]+)=?([^&]*)/g,
        d = function (s) { return decodeURIComponent(s.replace(a, " ")); },
        q = w.location.search.substring(1),
        v = '2.0.3';

    while (e = r.exec(q)) {
        u[d(e[1])] = d(e[2]);
    }

    if (!!u.jquery) {
        v = u.jquery;
    }

    doc.write('<script src="https://ajax.googleapis.com/ajax/libs/jquery/'+v+'/jquery.min.js">' + "<" + '/' + 'script>');
    co.log('\nLoading jQuery v' + v + '\n');
})(window, document, console);
</script>
<script src="../Js/jquery.quicksearch.js"></script>
<script>
    $(function () {

        $("#autresprojetsSearch").quicksearch("#autresprojets option", {
            noResults: "#noResultMessage3"
        });
        $("#mesprojetsSearch").quicksearch("#mesprojets option", {
            noResults: "#noResultMessage4"
        });
    });
</script>

<div class="container border divProject">
    <form action ="../Php/index.php?EX=userModifyProject" name="formProject" class="well" method="post">
        <div class="row">
                     
            <div class="col-md-4">
                <!-- Liste des projets disponibles -->
                <h4><?php echo $lang['projectsAvailables']?></h4>
                <input type="text" id="autresprojetsSearch" name="search" placeholder="<?php echo $lang['findProject']?>"/>
                <select size="15" id="autresprojets" name="autresprojets[]" multiple="multiple" onchange="choixLesProjets()">
                    <?php echo $optionsOthers?>
                </select>
                <div id="noResultMessage3" class="no-results-container">
                    <?php echo $lang['noReresults']?>
                </div>
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
                <input type="text" id="mesprojetsSearch" name="search" placeholder="<?php echo $lang['findProject']?>"/>
                <select size="15" id="mesprojets" name="mesprojets[]" multiple="multiple" onchange="choixMesProjets()">
                    <?php echo $optionsProjets?>
                </select>
                <div id="noResultMessage4" class="no-results-container">
                    <?php echo $lang['noReresults']?>
                </div>
            </div>
            
        </div><!--<div class="row">-->
    </form>
</div>

<?php

        return;

    } //showProjectsManagement($_data)

    /**
     * Affichage du ActivitiesManagement
     * @access public
     *
     * @param $_data
     * @return void
     */
    public function showActivitiesManagement($_data)
    {
        //objet language
        $mlanguage = new MLanguage(isset($_SESSION['LANGUAGE']) ? $_SESSION['LANGUAGE'] : 'fr' );
        //tableau de langue associé
        $lang = $mlanguage->arrayLang();

        // variables d'option
        $optionsActivities = '';
        $optionsOthers     = '';

        // Parcour le tableau et propose les options
        foreach ($_data as $value) {

            if ($value['flag'] == true)

                $optionsActivities .= "<option value=".$value['activityid'].">".$value['activityname']."</option>";

            if ($value['flag'] == false)
            {
                $optionsOthers .= "<option value=".$value['activityid'].">".$value['activityname']."</option>";
            }
        }

?>



<script src="../Js/userManagementActivities.js"></script>
<script>
(function (w, doc,co) {
    // http://stackoverflow.com/questions/901115/get-query-string-values-in-javascript
    var u = {},
        e,
        a = /\+/g,  // Regex for replacing addition symbol with a space
        r = /([^&=]+)=?([^&]*)/g,
        d = function (s) { return decodeURIComponent(s.replace(a, " ")); },
        q = w.location.search.substring(1),
        v = '2.0.3';

    while (e = r.exec(q)) {
        u[d(e[1])] = d(e[2]);
    }

    if (!!u.jquery) {
        v = u.jquery;
    }

    doc.write('<script src="https://ajax.googleapis.com/ajax/libs/jquery/'+v+'/jquery.min.js">' + "<" + '/' + 'script>');
    co.log('\nLoading jQuery v' + v + '\n');
})(window, document, console);
</script>
<script src="../Js/jquery.quicksearch.js"></script>
<script>
    $(function () {

        $("#autresactivitesSearch").quicksearch("#autresactivites option", {
            noResults: "#noResultMessage1"
        });
        $("#mesactivitesSearch").quicksearch("#mesactivites option", {
            noResults: "#noResultMessage2"
        });
    });
</script>


<div class="container border">
    <form action ="../Php/index.php?EX=userModifyActivity" name="formActivities" class="well" method="post">
        <div class="row">

            <div class="col-md-4">
                <!-- Liste des activités disponibles -->
                <h4><?php echo $lang['activitiesAvailables']?></h4>
                <input type="text" id="autresactivitesSearch" name="search" placeholder="<?php echo $lang['findActivity']?>"/>
                <select size="15" id="autresactivites" name="autresactivites[]" multiple="multiple" onchange="choixLesActivites()">
                    <?php echo $optionsOthers?>
                </select>
                <div id="noResultMessage1" class="no-results-container">
                    <?php echo $lang['noReresults']?>
                </div>
            </div>


           <div class="row col-4">
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
                <input type="text" id="mesactivitesSearch" name="search" placeholder="<?php echo $lang['findActivity']?>"/>
                <select size="15" id="mesactivites" name="mesactivites[]" multiple="multiple" onchange="choixMesActivites()">
                    <?php echo $optionsActivities?>
                </select>
               <div id="noResultMessage2" class="no-results-container">
                    No results.
                </div>
            </div>

        </div><!--<div class="row">-->
    </form>
</div>

<?php
        return;

    } //showActivitiesManagement($_data)

} // VUserManagements
