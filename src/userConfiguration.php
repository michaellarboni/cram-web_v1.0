<?php
include('include/head.php');
if (!isset ($_SESSION['id']))
{
    header('Location: index.php');
}
?>
<html>
    <script type='text/Javascript'>
        //Si on sélectionne un projet dans les autres projets, on n'a accès qu'à ajout et l'autre liste est vidée
        function choixLesProjets() 
        {
            var nb=document.formulaire.mesprojets.options.length;
            for(i=0;i<nb;i++)
            {
              document.formulaire.mesprojets.options[i].selected=false;
            }
            document.formulaire.suppression.disabled = true;
            
            if (estVide(document.formulaire.autresprojets) == true)
            {
                document.formulaire.ajout.disabled = true; 
            }
            else
            {
                document.formulaire.ajout.disabled = false; 
            }
            
        }
        
        //Si on sélectionne un projet dans les projets associés, on n'a accès qu'à suppression et l'autre liste est vidée
        function choixMesProjets()
        {
            var nb=document.formulaire.autresprojets.options.length;
            for(i=0;i<nb;i++)
            {
              document.formulaire.autresprojets.options[i].selected=false;
            }
            document.formulaire.ajout.disabled = true; 
            
            if (estVide(document.formulaire.mesprojets) == true)
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
        <form action ="include/modifyProject.php" name="formulaire" class="well" method="post">
            
            <!-- Liste des projets associés à l'utilisateur -->
            <?php echo '<h5>'.$myprojects.' :</h5>'; ?>
            <select size="5" id="mesprojets" name="mesprojets[]" multiple="multiple" onchange='javascript:choixMesProjets()'>
            <?php
              $rs = PdoBdd::getAllProjects($_SESSION['id']);
              foreach ($rs as $value) 
              {
                 if ($value['flag']== true)
                    echo "<OPTION value=".$value['projectid'].">".$value['name']."</OPTION>";
              }
            ?>
            </select>
            <br />
            
            <!--Bouton pour associer des nouveaux projets à l'utilisateur -->
            <button name="ajout" class="btn btn-success" type="submit" disabled> <i class="icon-black icon-arrow-up"></i> </button>
            <!--Bouton pour ne plus associer des projets à l'utilisateur -->
            <button name="suppression" class="btn btn-danger" type="submit" disabled> <i class="icon-black icon-arrow-down"></i> </button>
            <br />
            
            <!-- Liste des projets qui ne sont pas associés à l'utilisateur -->
            <?php echo '<h5>'.$otherprojects.' :</h5>'; ?>
            <select size="5" id="autresprojets" name="autresprojets[]" multiple="multiple" onchange="javascript:choixLesProjets()">
            <?php
              foreach ($rs as $value) 
              {
                 if ($value['flag']== false)
                    echo "<OPTION value=".$value['projectid'].">".$value['name']."</OPTION>";
              }
            ?>
            </select>
        </form>
    </center>
    </body>
</html>