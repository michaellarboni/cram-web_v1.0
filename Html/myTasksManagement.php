<?php
include '../Inc/head.php';

//objet language
$mlanguage = new MLanguage(isset($_SESSION['LANGUAGE']) ? $_SESSION['LANGUAGE'] : 'fr' );
//tableau de langue associé
$lang = $mlanguage->arrayLang();

$musers = new MUsers();
$mactivity = new MActivity();
$mproject = new MProject();
$user = $_SESSION['ID'];

if (!isset($_SESSION['startDate']) or !$_SESSION['startDate']) {
    $_SESSION['startDate'] = $musers->getStartDate($user);
}

$_SESSION['date_begin'] = date ('Y-m-d');
$_SESSION['date_end']   = date ('Y-m-01');

$data['projects']   = $mproject->getAllProjects($user);
$data['activities'] = $mactivity->getAllActivities($user);

// variables des Options
$optionsProjects = '';
$optionsActivities  = '';

foreach($data['projects'] as $key=>$val)
{
    if ($val['flag'])
    {
        $optionsProjects .= '<option value="'.$val['projectid'].'" label="'.$val['projectname'].'">'.$val['projectname'].'</option>';
    }
}

foreach($data['activities'] as $val)
{
    if ($val['flag'])
    {
        $optionsActivities .= '<option value="'.$val['activityid'].'" label="'.$val['activityname'].'">'.$val['activityname'].'</option>';
    }
}
?>

<style>

    #calendar {
        max-width: 1170px;
        margin: 10px auto;
    }
    input[id="holiday"]:valid ~ div#options {
        display: none;
    }

    input[id="holiday"]:invalid ~ div#options {
        display: block;
    }
    input.btn {
        padding-left: 0;
        padding-right: 0;
    }

</style>
<?php
    switch ($_SESSION['LANGUAGE']) {
        case 'fr' : echo '<script src=\'../libs/fullcalendar/dist/lang/fr.js\'></script>'; break;
        case 'en' : echo '<script src=\'../libs/fullcalendar/dist/lang/en-gb.js\'></script>'; break;
    }
?>
<script src="../Js/calendrier.js"></script>
<!--<script src='../libs/fullcalendar/dist/lang/fr.js'></script>-->
<!--<script src='../libs/fullcalendar/dist/lang/en-gb.js'></script>-->

<!-- affichage pour le formulaire d'entree sur le ou les jour effectué -->
<div id="board" class="row-fluid">
    <div class="well">
        <div class="">
            <div id='calendar' class="calendar">
            </div>
        </div>
        <div id="infos"></div>
    </div>
</div>

<!-- fancyBox-->
<div id="dialog-form" class="row-fluid">
    <form action="#" method="POST" id="myform">

        <div id="complet-form" class="span12">

            <div class="row-fluid">
                <div class="col-md-12">
                    <label class="col-lg-3">Dates</label>
                    <ul id="dates"></ul>
                </div>
            </div>

            <label class="col-lg-3" for="holiday"><?php echo $lang['holiday'] ?></label>
            <input class="col-lg-1" name="holiday" id="holiday" type="checkbox" required/>

            <!--N'affiche que si la checkbox Absence est décochée-->
            <div id="options">
                <div class="row-fluid">
                    <div class="col-md-12">
                        <label class="col-lg-3" for="projet"><?php echo $lang['projects'] ?></label>
                        <select class="col-lg-7" id="projet" name="projet">
                            <?php echo $optionsProjects ?>
                        </select>
                    </div>
                </div>

                <div class="row-fluid">
                    <div class="col-md-12">
                        <label class="col-lg-3" for="activity"><?php echo $lang['activities'] ?></label>
                        <select class="col-lg-7" id="activity" name="activity">
                            <?php echo $optionsActivities ?>
                        </select>
                    </div>
                </div>
            </div>
            <!---->

            <div class="row-fluid">
                <div class="col-md-12">
                    <label class="col-lg-3" for="comment"><?php echo $lang['commentary'] ?></label>
                    <textarea class="col-lg-7" name="comment" id="comment"></textarea>
                </div>
            </div>

            <div class="row_fluid" >
                <div class="text-center">
                    <input type="submit" class="btn btn-primary" name="valid" value="<?php echo $lang['saveClose'] ?>" />
                    <input type="submit" class="btn btn-primary" name="cancel" value="<?php echo $lang['cancel'] ?>" />
                    <input type="submit" class="btn btn-danger"  name="delete" value="<?php echo $lang['clear'] ?>"/>
                </div>
                <input type="hidden" value="add" name="action" />
            </div>

            <div class="row-fluid">
                <div class="col-lg-12 text-center">
<!--                    <input class="col-lg-5 btn btn-primary" id="previous" type="submit" name="save_previous" value="<?php echo $lang['savePrevious'] ?>"/> -->
<!--                    <input class="col-lg-5 btn btn-primary" id="next" type="submit" name="save_next" value="<?php echo $lang['saveNext'] ?>"> -->
                </div>
            </div>

        </div>

    </form>
</div>

