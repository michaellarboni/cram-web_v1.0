<html>
  <?php
    include ('include/head.php');
    if (!isset ($_SESSION['id']))
    {
        header('Location: index.php');
    }
  ?>
<!--la fonction enConge permet de rendre innaccessible les champs/listes projets, activités et commentaires
si l'utilisateur coche la case off et vice versa-->
<script type='text/Javascript'>
    function enConge()
    {
        if(document.formulaire.off.value == 0)
        {
            document.formulaire.projet.disabled = true;
            document.formulaire.projet.value = 0;
            document.formulaire.activite.disabled = true;
            document.formulaire.activite.value = 0;
            document.formulaire.commentaire.disabled = true;
            document.formulaire.commentaire.value = "";
            document.formulaire.off.value = 1;
            document.formulaire.dupliquer.disabled = false;
            document.formulaire.ajouter.disabled = false;
        }
        else
        {
            document.formulaire.projet.disabled = false;
            document.formulaire.activite.disabled = false;
            document.formulaire.commentaire.disabled = false;
            document.formulaire.off.value = 0;
            document.formulaire.dupliquer.disabled = true;
            document.formulaire.ajouter.disabled = true;
        }
    
    }
    
    function valide()
    {
        if (document.formulaire.projets.value != 0 && document.formulaire.activites.value != 0)
        {
            document.formulaire.dupliquer.disabled = false;
            document.formulaire.ajouter.disabled = false;
        }
        else
        {
            document.formulaire.dupliquer.disabled = true;
            document.formulaire.ajouter.disabled = true;
        }
    }
</script>
    <body>
        <!--Menu-->
            <nav class="navbar navbar-inner">
                  <div class="container">
                      <p class="navbar-text pull-right">
                          Logged in as <a href="include/deconnexion.php" title="Logout" class="navbar-link"><b><?php echo $_SESSION['username']; ?> <i class="icon-black icon-off"></i></b></a>
                    </p>
                        <ul class="nav">
                          <?php
                            echo '<li> <a href="myTasksManagement.php">'.$myTasks.'</a> </li>'; 
                        echo '<li class="dropdown"> <a class="dropdown-toggle" data-toggle="dropdown" href="#">'.$userConfig.'<b class="caret"></b> </a>
                                <ul class="dropdown-menu">
                                  <li><a href="userConfiguration.php">'.$projects.'</a></li>
                                  <li><a href="userConfigurationActivities.php">'.$activities.'</a></li>
                                </ul>
                              </li>';
                      ?>
                        </ul>
                  </div>
              </nav>
        <!--Formulaire de la tâche-->
        <center>
            <form name="formulaire" class="well" method="post" action="include/saveTask.php">
                    <?php
                    if (isset($_GET['erreurs']))
                    {
                        echo '<font color="red">'.$_GET['erreurs'].'</font><br /><br />';
                    }
                    ?>
                    <!--Champ date-->
                    <?php echo "<h4>Date : </h4>";
                    echo '<input id= "date" name="date" size="16" type="text" readonly="" value='.$_GET['date'].'>'; 
                    ?>
                    <br />

                    <!-- Boutons radios am, pm et am&pm -->
                    <?php
                    $ampm = ['am','pm','am-pm'];

                    for ($i=0;$i<=2;$i++)
                    {
                        if ($_GET['am'] == $ampm[$i])
                        {
                            echo '<INPUT id ="ampm" type="radio" name="ampm"  value='.$ampm[$i].' checked>&nbsp; '.$ampm[$i];
                        }
                        else
                        {
                            echo '<INPUT id ="ampm" type="radio" name="ampm" value='.$ampm[$i].'>&nbsp; '.$ampm[$i];
                        }
                        echo ' &nbsp;&nbsp;&nbsp;&nbsp;';
                    }
                    ?>
                    <br /><br /><br />

                    <!-- Case à cocher off -->
                    <?php echo $off;
                    if ($_GET['color']== 'grey')
                    {
                        echo '&nbsp;<INPUT type="checkbox" name="off" value="1" checked onClick="enConge()">';
                        $disabled = "disabled"; //si oui, on rend innaccessible certains champs
                        $add = $modify;
                    }
                    else
                    {
                        echo '&nbsp;<INPUT type="checkbox" name="off" value="0" onClick="enConge()">';
                        $disabled = "";
                    }
                    ?>
                    <br /><br />

                    <!-- Ici on vérifie si la demi journée est considérée en congé ou non -->
                    <?php
                    if (PdoBdd::tacheExiste($_SESSION['id'], $_GET['date'], $_GET['am']))
                    {
                        $infos = PdoBdd::getTaskInfos($_SESSION['id'],$_GET['date'], $_GET['am']);
                        foreach ($infos as $value) 
                        {
                            $projet = $value['projectid'];
                            $activite = $value['activityid'];
                            $commentaire = $value['taskcomment'];
                        }
                    }
                    
                    if (isset($_GET['project']))
                        $projet = $_GET['project'];
                    if (isset($_GET['activity']))
                        $activite = $_GET['activity'];
                    if (isset($_GET['comment']))
                        $commentaire = $_GET['comment'];
                    
                         
                    //Liste des projets associés à l'utilisateur
                    echo "<h4>".$project." :</h4>"; 
                    echo '<SELECT id="projets" name="projet" size="1" onchange="valide()" '.$disabled.'>';
                    echo '<OPTION value="0">...</OPTION>';
                    $rs = PdoBdd::getAllProjects($_SESSION['id']);
                    foreach($rs as $value)
                    {
                        if ($value['flag']== true)
                        {
                            if ($projet == $value['projectid'])
                                echo "<OPTION value=".$value['projectid']." selected>".$value['name'].'</OPTION>';
                            else 
                            {
                                echo "<OPTION value=".$value['projectid'].">".$value['name'].'</OPTION>';
                            }
                        }
                        
                    }
                    echo '</SELECT>';
                     ?>
                    <br />

                    <!--Liste des activités associées à l'utilisateur-->
                    <?php echo "<h4>".$activity." :</h4>";
                    echo '<SELECT id="activites" name="activite" size="1" onchange="valide()" '.$disabled.'>';
                    echo '<OPTION value="0">...</OPTION>';
                    $rs = PdoBdd::getAllActivities($_SESSION['id']);
                    foreach($rs as $value)
                    {
                        if ($value['flag']== true)
                        {
                            if ($activite == $value['activityid'])
                                echo "<OPTION value=".$value['activityid']." selected>".$value['activityname'].'</OPTION>';
                            else
                                echo "<OPTION value=".$value['activityid'].">".$value['activityname'].'</OPTION>';      
                        }
                    }
                    echo '</SELECT>';
                    ?>
                    <br />

                    <!-- Text area commentaire -->
                    <?php echo "<h4>".$commentary." :</h4>";
                    echo '<textarea id="comment" name="commentaire" rows="5" cols="50" '.$disabled.'>';
                    echo $commentaire;
                    echo '</textarea>';
                    ?>
                <br /><br />
                <!--Les boutons -->
                <?php
                 //Si la tâche n'existe pas, on ne permet pas de la supprimer, donc le bouton est 'disabled'
                 if ($_GET['color'] == 'white')
                 { 
                     echo '<button name="ajouter" class="btn btn-info" type="submit" disabled>'.$add.' <i class="icon-white icon-ok-sign"></i></button>';
                     echo '&nbsp;&nbsp;&nbsp;<button name="effacer" class="btn btn-danger" type="submit" disabled>'.$clear.' <i class="icon-white icon-remove-sign"></i></button>';
                     echo '&nbsp;&nbsp;&nbsp;<button name="dupliquer" class="btn btn-success" type="submit" disabled>'.$duplicate.' <i class="icon-white icon-plus-sign"></i></button>';
                 }
                 else
                 {
                     echo '<button name="ajouter" class="btn btn-info" type="submit">'.$modify.' <i class="icon-white icon-ok-sign"></i></button>';
                     echo '&nbsp;&nbsp;&nbsp;<button name="effacer" class="btn btn-danger" type="submit">'.$clear.' <i class="icon-white icon-remove-sign"></i></button>';
                     echo '&nbsp;&nbsp;&nbsp;<button name="dupliquer" class="btn btn-success" type="submit">'.$duplicate.' <i class="icon-white icon-plus-sign"></i></button>';
                 }
                 ?>
            </form>
        </center>
    </body>
</html>    
