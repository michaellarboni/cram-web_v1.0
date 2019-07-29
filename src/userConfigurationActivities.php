<?php
include('include/head.php');
if (!isset ($_SESSION['id']))
{
    header('Location: index.php');
}
?>
<html>
    <script type='text/Javascript'>
        //Si l'activité sélectionnée est dans la liste des autres activités, alors on n'a accès qu'à ajout et l'autre liste est vidée
        function choixLesActivites()
        {
            var nb=document.formulaire.mesactivites.options.length;
            for(i=0;i<nb;i++)
            {
              document.formulaire.mesactivites.options[i].selected=false;
            }
            document.formulaire.suppression.disabled = true; 
            
            if (estVide(document.formulaire.autresactivites) == true)
            {
                document.formulaire.ajout.disabled = true; 
            }
            else
            {
                document.formulaire.ajout.disabled = false; 
            }
        }
        
        //Si l'activité sélectionnée est dans la liste des activités associées, alors on n'a accès qu'à suppresion et l'autre liste est vidée
        function choixMesActivites()
        {
            var nb=document.formulaire.autresactivites.options.length;
            for(i=0;i<nb;i++)
            {
              document.formulaire.autresactivites.options[i].selected=false;
            }
            document.formulaire.ajout.disabled = true; 
            
            if (estVide(document.formulaire.mesactivites) == true)
            {
                document.formulaire.suppression.disabled = true; 
            }
            else
            {
                document.formulaire.suppression.disabled = false; 
            }
        }
        
        //La fonction va vérifier s'il y a encore des éléments cochés dans la liste en paramètre
        function estVide(liste)
        {
            var count = 0;
            for (i=0; i<liste.options.length; i++) 
            {
                if (liste.options[i].selected) 
                {
                    count++;
                }
            }
            if (count == 0)
            {
                return true;
            }
            else
            {
                return false;
            }
        }
        
    </script>
    <body>
<!--Menu-->
        
        <nav class="navbar navbar-inner">
              <div class="container">
                  <p class="navbar-text pull-right">
                      Logout <a href="include/deconnexion.php" title="Logout" class="navbar-link"><b><?php echo $_SESSION['username']; ?> <i class="icon-black icon-off"></i></b></a>
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
        
<!--Contenu-->

<center>
        <form action ="include/modifyActivity.php" name="formulaire" class="well" method="post">
            
            <!--Liste des activités associées à l'utilisateur -->
            <?php echo '<h5>'.$myactivities.' :</h5>'; ?>
            <select size="5" id="mesactivites" name="mesactivites[]" multiple="multiple" onchange='javascript:choixMesActivites()'>
            <?php
            $rs = PdoBdd::getAllActivities($_SESSION['id']);
              foreach($rs as $value)
              {
                 if ($value['flag']== true)
                    echo "<OPTION value=".$value['activityid'].">".$value['activityname'].'</OPTION>';
              }
            ?>
            </select>
            <br />
            <!-- Bouton pour associer de nouvelles activités à l'utilisateur --> 
            <button name="ajout" class="btn btn-success" type="submit" disabled> <i class="icon-black icon-arrow-up"></i> </button>
            <!-- Bouton pour ne plus associer des activités à l'utilisateur -->
            <button name="suppression" class="btn btn-danger" type="submit" disabled> <i class="icon-black icon-arrow-down"></i> </button>
            <br />
            
            <!-- Liste des activités qui ne sont pas associées à l'utilisateur -->
            <?php echo '<h5>'.$otheractivities.' :</h5>'; ?>
            <select size="5" id="autresactivites" name="autresactivites[]" multiple="multiple" onchange='javascript:choixLesActivites()'>
            <?php
              foreach($rs as $value)
              {
                 if ($value['flag']== false)
                    echo "<OPTION value=".$value['activityid'].">".$value['activityname'].'</OPTION>'; 
              }
            ?>
            </select>
        </form>
    </center>
    </body>
</html>