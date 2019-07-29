
<?php
session_start();
include 'include/head2.php';
require 'controller/ControllerDate.php';
// var_dump($_SESSION['id']);
$user = $_SESSION['id'];
$url='reportingLeader';
$choice = $_POST['choix'];
$navigate =  $_POST['naviguer'];
if (!isset ($_SESSION['id']))  // test si l'utilisateur et bien connecté
{
    header('Location: index.php');
}
?>
<!DOCTYPE html>
<html>
  <body>
    <div class="well">
      <div class="responsive_embed"><!-- div de la partie du haut de la page avec les boutons --> 
        <div class="row justify-content-md-center" id="bouton_global">
          <div class="col col-10">
            <form  method="POST">
              <div class="row" id="bouton_global">
                <?php 
                  echo nav_form($date_begin, $date_end, $choice, $navigate ); // methode pour la gestion des differents choix sur la dates
                ?>
                  <div class="col-6 offset-9" > 
                    <div class="btn-group-vertical" >
                      <input id="mois" name="choix" type="submit" class="btn btn-primary" value="mois" >&nbsp;
                      <input id="annee" name="choix" type="submit" class="btn btn-primary" value="annee" >&nbsp;
                      <input id="custom" name="choix" type="submit" class="btn btn-primary" value="custom" >&nbsp;
                    </div>
                  </div>
              </div>
              <div>Service
                <?php echo service($user,$service); ?>  <!-- methode pour afficher les services dont l'utilisateur et leader -->
                <input type="submit" name='select' value="Valider">
              </div>
            </form>          
          </div>
        </div>
        <div class="row" id="partie-central">
          <div class="col-6" id="est">
            <div class="graph_project_user" >
              <!-- div concernant le tableau projets par utilisateur -->
              <div id="graph_project_user" style="min-width: 310px; max-width: 800px; height: 400px; margin: 0 auto"></div>
            </div>
            <div class="tableau_p_u">
              <!-- creation du tableau1 des projets par Users -->
              <table class="display" id="tableau_project_user"></table>
            </div>
          </div>
          <div class ="col-6" id="west">
            <div class="graph_activity_user" >
              <!-- div concernant le tableu service par utilisateur -->
              <div id="graph_activity_user" style="min-width: 310px; max-width: 800px; height: 400px; margin: 0 auto"></div> 
            </div>
            <div class="" id="tableau_a_u">
              <!-- creation du tableau2 des activités associées au Projet -->
              <table class="display" id="tableau_activity_user"></table>
            </div>
          </div>
        </div>
        <div class="row" id="bouton_inferieur">  <!-- gestion des bouton de bas de page -->
          <div class="col-6" >
            <input class="btn btn-primary" type="button" value="Retour" id="retour" onclick="window.location='myTasksManagement.php'">
          </div>
          <div class="col-6 offset-9" >
            <a class="btn btn-primary" type="button" id="sauvegardesLeader" href ="#">Fichier en CSV</a>
          </div>
        </div>
        <?php
          $user_project_leader_day_json = userProjectLeaderDays($service,$date_begin,$date_end);// jours effectues des users pour le service par projet et date
          $user_activity_leader_days_json = userActivityLeaderDays($service,$date_begin,$date_end); // jours effectues des users pour le service par activity et date
        ?>

        <script>

        /*
        // fonction sur la validation du bouton de sauvegardes pour la page leader
        */
        $('#sauvegardesLeader').click(function(){
          activity_user.downloadCSV();
          project_user.downloadCSV();
        });


          // fonction datatable pour le tableau1 des projets associe au activité et au jours 
          $(document).ready(function() {
            $('#tableau_project_user').DataTable({
              data: user_project_leader_day,
              columns: [
                { title: "Projects" },
                { title: "Users" },
                { title: "Day" }
              ]
            } );
          } );

          // fonction Datatable pour le tableau2 des activitées associé au projets et au jours
          $(document).ready(function() {
            $('#tableau_activity_user').DataTable({ 
              data : user_activity_leader_day,
              columns: [
                { title: "Activity" },
                { title: "Users" },
                { title: "Day" } 
              ]                         
            } );
          } );

          // fonction sur le nombre de jour par project en fonction d'un user en forme d'une array liste avec 2 propriétées name et data;
          function userProjectsDays(user, projects, days){
            var datas = [];
            for (var i = 0; i < projects.length; i++) {
              datas.push(0);
            }
            for (var i = 0; i < projects.length; i++) {
              for (var j = 0; j < days.length; j++) {
                if ((user == days[j][1]) && (days[j][0] == projects[i])) {
                    datas[i] += parseFloat(days[j][2]);
                }
              }
            }
            resultat = {name : user , data : datas};
            return resultat;
          }
        
          // trie de la liste pour eviter les doublons
          function  cleanListe (liste){
            var i;
            var j;
            len = liste.length;
            result = [];
            obj ={};
              for ( i = 0; i < len; i++) { 
                obj[liste[i]] =0;
              }
              for (j in obj) {
                result.push(j);
              }
            return result;
          }

          // test si la liste est vide ou non.
          function if_empty(listing)
          {
            if (listing && listing.length )
            {
              // ok
            }
            else {
              alert( 'Empty');
            }
          }

          // -----------------partie correpondante au project par leader--------------------

          // recuperation de la liste des projets avec ses utilisateurs et les jours effectuées pour chaque
          var user_project_leader_day = <?php echo $user_project_leader_day_json; ?>;
          user_project_leader_day.sort(); // mettre la liste des projets par ordre alphabetique 
          // console.log(user_project_leader_day);
          if_empty(user_project_leader_day);// affiche si la liste est vide
          
          // recuperer la liste des noms des projets pour enlever les doublons .
          var name_project = []; //  array au nom des projets
          for (var i = 0; i < user_project_leader_day.length; i++) {
            name_project.push(user_project_leader_day[i][0]);// creation d'une array avec juste la liste des nom des projets
          }
          names_projects = cleanListe(name_project);// enlever les doublons de la liste
          names_projects.sort(); // mettre la liste des projets par ordre alphabétique
          // console.log(names_projects);

          // recupere la liste des user par projets par une boucle for
          var user_project = []; // array sur les users par projets
          for (var i = 0; i < user_project_leader_day.length; i++) {
            user_project.push(user_project_leader_day[i][1]);// tableau des user par projets
          }
          users_project = cleanListe(user_project);
          users_project.sort(); // mettre  la lise par orde alphabetique

          // recuperation sur le nombre de jour par project en fonction d'un user par une boucle for
          result_user_day = []; // array sur les jours effectués par utilisateur
          for (var i = 0; i < users_project.length; i++) {
            result_user_day.push(userProjectsDays(users_project[i],names_projects,user_project_leader_day));
            series_projects = result_user_day;
          }

          // -------------- partie correspondante au activiés par leader---------------------- 

          // recuperation de la liste des activités avec ses utilisateurs et les jours effectuées pour chaque
          var user_activity_leader_day =  <?php echo $user_activity_leader_days_json ; ?>;
          user_activity_leader_day.sort(); // mettre la liste par ordre alphabetique
          //console.log(user_activity_leader_day);
          if_empty(user_activity_leader_day);// affiche si la liste est vide

          // recuperer la liste des noms des activités pour enlever les doublons .
          var name_activity = [];
          for (var i = 0; i < user_activity_leader_day.length; i++) {
            name_activity.push(user_activity_leader_day[i][0]);// tableau des noms de projets
          }
          names_activity = cleanListe(name_activity);// enlever les doublons de la liste
          names_activity.sort(); // mettre la liste par ordre alphabetique
          //console.log(names_activity);

          // recupere la liste des users par activité
          var user_activity = []; // array sur la liste des users par activité
          for (var i = 0; i < user_activity_leader_day.length; i++) {
            user_activity.push(user_activity_leader_day[i][1]);// tableau des user par activité
          }
          var users_activity = cleanListe(user_activity);
          users_activity.sort(); // mettre la lise par orde alphabetique
          // console.log(users_activity);
            
          result_user_day_activity = []; // variable array pour la liste de jour effectuer par user
          for (var i = 0; i < users_activity.length; i++) {
            result_user_day_activity.push(userProjectsDays(users_activity[i],names_activity,user_activity_leader_day));
            series_activity = result_user_day_activity;
          }
          // console.log(series_activity);
 
          //C'est ici que l'on placera tout le code servant à nos dessins.

          // affichage des services au users par le plugin Highcharts
          var project_user = new Highcharts.chart('graph_project_user', {
            chart: {
              type: 'bar'
            },
            title: {
              text: 'Project -> user'
            },
            xAxis: {
              categories: names_projects  // liste des noms des projets
            },
            yAxis: {
              min: 0,
              title: {
                text: 'Numbers day'
              }
            },
            legend: {
              reversed: true
            },
            plotOptions: {
              series: {
                stacking: 'normal'
              }
            },
            series: series_projects // liste des jours effectué des utilisateurs par projets
          });
                    
          // affichage de l'activite  par user
          var activity_user = new Highcharts.chart('graph_activity_user', {
            chart: {
              type: 'bar'
            },
            title: {
              text: 'Activity -> user'
            },
            xAxis: {
              categories: names_activity // liste des noms des activités
            },
            yAxis: {
              min: 0,
              title: {
                text: 'Numbers day'
              }
            },
            legend: {
              reversed: true
            },
            plotOptions: {
              series: {
                stacking: 'normal'
              }
            },
            series: series_activity // liste des jours effectué des utilisateurs par activitées
          });
        </script>
      </div> 
    </div>
  </body>
</html>

