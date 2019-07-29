<?php
include('include/head.php');
require 'controller/controllerUser.php';
if (!isset($_SESSION['id'])) {
    header('Location: index.php');
}
if (!isset($_SESSION['startDate'])) {
    $_SESSION['startDate'] = PdoBdd::getStartDate($_SESSION['id']);
}
$user = $_SESSION['id'];
$name = $_SESSION['username'];
$_SESSION['date_end']= date ('Y-m-d');
$_SESSION['date_begin'] = date ('Y-m-01'); 
?>

<html>
    <!--insertion du calendrier avec le script -->
    <script type="text/javascript" src='public/js/modules/calendrier.js'></script>
    <body>
        <!--Menu-->
        <nav class="navbar navbar-inner">
            <div class="container">
                <p class="navbar-text pull-right">
                    Logout <a href="include/deconnexion.php" title="Logout" class="navbar-link"><b><?php echo $name; ?> <i class="icon-black icon-off"></i></b></a>
                </p>
                <ul class="nav">
                    <?php
                        echo'<li> <a href="myTasksManagement.php">' . $myTasks . '</a> </li>';
                        echo'<li class="dropdown"> <a class="dropdown-toggle" data-toggle="dropdown" href="#">' . $userConfig . '<b class="caret"></b> </a>
                                <ul class="dropdown-menu">
                                <li><a href="userConfiguration.php">' . $projects . '</a></li>
                                <li><a href="userConfigurationActivities.php">' . $activities . '</a></li>
                                </ul>
                            </li>';
                        echo'<li class="dropdown"> <a class="dropdown-toggle" data-toggle="dropdown" href="#">'.$reporting.'<b class="caret"></b> </a>
                            <ul class="dropdown-menu">';
                        echo statusUser($user);
                    ?>
                </ul>
            </div>
        </nav>
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
        <div id="dialog-form" class="row-fluid">
            <form action="include/saveMultiTasks.php" method="POST" id="myform">
                <table>
                    <tr>
                        <th>
                            <div class="row-fluid" id="previous">
                                    <input type="submit" name="save_previous" value="save & previous" class="btn btn-primary"/>
                            </div>
                        </th>
                        <td>
                            <div id="complet-form" class="row_fluid span12">
                                <div class="row_fluid">
                                    <div class="span12">
                                        <label for="name">Dates</label>
                                        <ul id="dates"></ul>
                                    </div>
                                </div>
                                <div class="row-fluid">
                                    <div class="span3">
                                        <label for="holiday">Absence</label>
                                    </div>
                                    <div class="span9">
                                        <input name="holiday" id="holiday" type="checkbox"/>
                                    </div>
                                </div>
                                <div class="row-fluid">
                                    <label for="projet"><?= $projects; ?></label>
                                    <select name="projet">
                                        <?php 
                                            $projects = PdoBdd::getAllProjects($user);
                                            foreach($projects as $p){
                                                if($p['flag']):
                                        ?>
                                        <option value="<?php echo $p['projectid']; ?>" label="<?php echo $p['name']; ?>"><?php echo $p['name']; ?></option>
                                        <?php 
                                                endif;
                                            }
                                        ?>
                                    </select>
                                </div>
                                <div class="row-fluid">
                                    <label for="activity"><?= $activities; ?></label>
                                    <select name="activity">
                                        <?php 
                                            $activities = PdoBdd::getAllActivities($user);
                                            foreach($activities as $a){
                                                if($a['flag']):
                                        ?>
                                        <option value="<?php echo $a['activityid']; ?>" label="<?php echo $a['activityname']; ?>"><?php echo $a['activityname']; ?></option>
                                        <?php 
                                                endif;
                                            }
                                        ?>
                                    </select>
                                </div>
                                <div class="">
                                    <label for="comment"><?= $commentary; ?></label>
                                    <textarea name="comment" id="comment"></textarea>
                                </div>
                                <div class="row_fluid" >
                                    <div style="text-align:center">
                                        <input type="submit" class="btn btn-primary" name="valid" value="Save&Close" />
                                        <input type="submit" class="btn btn-primary" name="cancel" value="Cancel" />
                                        <input type="submit" class="btn btn-danger" name="delete" value="Supp"/>
                                    </div>
                                    <input type="hidden" value="add" name="action" />
                                </div>
                            </div>
                        </td>
                        <th>
                            <!-- espace pour les boutons de racourcis a prevoir -->
                        </th>
                        <th>
                            </div class="span2">
                                <div>
                                    <input type="submit" value="save & next" name="save_next" class="btn btn-primary" >
                                </div>
                            <div>
                        </th>
                    </tr>
                </table>
            </form>
        </div>
    </body>
</html>
