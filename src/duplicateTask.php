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
            <?php
            echo '<form name="formulaire" class="well" method="post" action="include/duplicateTaskTr.php?off='.$_GET['off'].'&projet='.$_GET['projet']
                    .'&activite='.$_GET['activite'].'&commentaire='.$_GET['commentaire'].'">';
                    
                    if (isset($_GET['erreurs']))
                    {
                        echo '<font color="red">'.$_GET['erreurs'].'</font><br /><br />';
                    }
                    ?>
                    <!--Champ date-->
                    <?php echo "<h4>".$startdate." :</h4>";
                    echo '<input id= "startdate" name="startdate" size="16" type="text" readonly="" value='.$_GET['date'].'>'; 
                    ?>
                    <br />
                   
                    <!--Champ date de fin-->
                    <?php echo "<h4>".$enddate." :</h4>";
                    echo '<input id= "enddate" name="enddate" size="16" type="text" value='.$_GET['date'].'>'; 
                    ?>
                    <br />

                    <!-- off -->
                    <?php
                    if ($_GET['off']== 'TRUE')
                    {
                        echo '<h5>'.$off.'</h5>';
                    }
                    else
                    {
                        ?>
                        <br />

                        <?php

                        //Liste des projets associés à l'utilisateur
                        echo "<h4>".$project." :</h4>"; 
                        echo '<SELECT id="projet" name="projet" size="1" disabled>';
                        $rs = PdoBdd::getAllProjects($_SESSION['id']);
                        foreach($rs as $value)
                        {
                            if ($value['flag']== true)
                            {
                                if ($_GET['projet'] == $value['projectid'])
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
                        echo '<SELECT id="activite" name="activite" size="1" disabled>';
                        $rs = PdoBdd::getAllActivities($_SESSION['id']);
                        foreach($rs as $value)
                        {
                            if ($value['flag']== true)
                            {
                                if ($_GET['activite'] == $value['activityid'])
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
                        echo '<textarea id="commentaire" name="commentaire" rows="5" cols="50" disabled>';
                        echo $_GET['commentaire'];
                        echo '</textarea>';
                        
                    }
                    ?>
                        <br /><br />
                    <!-- Case à cocher off -->
                    <?php echo $overwrite;
                    
                    echo '&nbsp;<INPUT type="checkbox" name="overwrite" value="0">';
                    
                    ?>
                    <br /><br /><br />
                     
                
                <!--Les boutons -->
                <?php
                 
                 echo '<button name="dupliquer" class="btn btn-success" type="submit">'.$duplicate.' <i class="icon-white icon-plus-sign"></i></button>';
                 ?>
            </form>
        </center>
    </body>
</html>    
