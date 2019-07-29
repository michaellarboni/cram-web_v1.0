
<?php
session_start();
include 'include/head2.php'; // pour les scriptes supplémentaire
require 'controller/ControllerDate.php'; // pour les methodes est les controles des variables
// var_dump($_SESSION['id']);
$user = $_SESSION['id'];
$url = 'reportingManager';
if (!isset ($_SESSION['id']))
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
                  echo nav_form($date_begin, $date_end, $_POST['choix'], $_POST['naviguer'] );
                ?>
                <div class="col-6 offset-9"> 
                  <div class="btn-group-vertical">
                    <input id="mois" name="choix" type="submit" class="btn btn-primary" value="mois"/>&nbsp;
                    <input id="annee" name="choix" type="submit" class="btn btn-primary" value="annee"/>&nbsp;
                    <input id="custom" name="choix" type="submit" class="btn btn-primary" value="custom">&nbsp;
                  </div>
                </div>
              </div>
              <div>Project
                <?php echo project($user,$project) ?>
                <input type="submit" name='select' value="Validate"/>
              </div>
            </form>
          </div>
        </div>    
        <div class="row" id="partie-central">
          <div class="col-6" id="est">
            <div class="graph_service_user" >

              <!-- div concernant le tableau Service par utilisateur -->
              <div id="graph_service_user" style="min-width: 310px; max-width: 800px; height: 400px; margin: 0 auto"></div>
            </div>
            <div class="tableau_p_u">
            <!-- creation du tableau1 des projets par Users -->
              <table class="display" id="tableau_services_users" width="100%">
              </table>
            </div>
          </div>
          <div class ="col-6" id="west">
            <div class="graph_activity_user" >
              <!-- div concernant le tableu service par utilisateur -->
              <div id="graph_activity_user" style="min-width: 310px; max-width: 800px; height: 400px; margin: 0 auto"></div> 
            </div>
            <div class="" id="tableau_a_u">
                <!-- creation du tableau2 des activités associées au Projet -->
              <table class="display" id="tableau_activity_user" width="100%">
              </table>
            </div>
          </div>
        </div>
        <div class="row" id="bouton_inferieur">  <!-- gestion des bouton de bas de page -->
          <div class="col-6" >
            <input class="btn btn-primary" type="button" value="Retour" id="retour" onclick="window.location='myTasksManagement.php'">
          </div>
          <div class="col-6 offset-9" >
            <a class="btn btn-primary" type="button" id="sauvegardesManager" href ="#">Fichier en CSV</a>
          </div>
        </div>

        <?php
          //   $project_user_json = projectUser($project); // liste des users par rapport au projects
          $services_users_json = servicesUsers($user); // liste services par rapport au user
          $services_users_days_projects_json = servicesUsersDaysProjects($project,$date_begin,$date_end);
          $activity_users_days_projects_json = activityUsersDaysProjects($project,$date_begin,$date_end);
          //$manager_user_json = managerUser($user); 
        ?>

        <script type="text/javascript" >
          
          // test si la liste est vide ou non.
          function if_empty(listing)
          {
            if (listing && lifting.length )
            {
              // ok
            }
            else {
              alert( 'Empty');
            }
          }
          
          /*
          // fonction sur la validation du bouton de sauvegardes pour la page manager
          */
          $('#sauvegardesManager').click(function(){
            activity_user.downloadCSV();
            project_user.downloadCSV();
          });
 
        
          // src="public/js/modules/manager.js">
          /*
          // fonction Datatable pour le tableau1 des services associe au users et au jours par Projet
          */
          $(document).ready(function() {
            $('#tableau_services_users').DataTable({
              data: services_users_days_project,
                columns: [
                 { title: "Services" },
                 { title: "Users" },
                 { title: "Day" }
                ]
            });
          });

          /*
          // fonction Datatable pour le tableau2 des activitées associé au users et au jours par Projet
          */
          $(document).ready(function() {
            $('#tableau_activity_user').DataTable({ 
              data : activity_users_days_project,
                columns: [
                  { title: "Activity" },
                  { title: "Users" },
                  { title: "Day" } 
                ]                         
            });
          });

          /*
          // une fonction sur le nombre de jour effectué dans le service par l'user dans un tableau 
          */
          function userServicesDays(user, services, days){
            var datas = [];
            for (var i = 0; i < services.length; i++) {
              datas.push(0);
            }
            for (var i = 0; i < services.length; i++) {
              for (var j = 0; j < days.length; j++) {
                if ((user == days[j][1]) && (days[j][0] == services[i])) {
                    datas[i] += parseFloat(days[j][2]);
                }
              }
            }
            resultat = {name : user , data : datas};
            return resultat;
          }
        
          /*
          // trie d'une liste pour eviter les doublons ( pour l'affichage du graphe )
          */
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
          
          // ------------------------------------------------partie Services user jour ------------------------------------------------------------------
          
          // var services_users= <?php echo $services_users_json; ?>;
          // console.log(manager_project);
          var services_users_days_project = <?php echo $services_users_days_projects_json; ?>;
          // console.log(services_users_days_project);
          if_empty(services_users_days_project);


          // liste des services par project
          var services_project = [];
          for (var i =0 ;  i < services_users_days_project.length ; i++) {
            services_project.push(services_users_days_project[i][0])
          }
          //  console.log(services_project);
          services = cleanListe(services_project); // classement de la liste pour eviter les doublons
          //   console.log(services);
          
          var users_service = [];
          for (var i =0 ;  i < services_users_days_project.length ; i++) {
            users_service.push(services_users_days_project[i][1])
          }
          users_service= cleanListe(users_service); // classement de la liste pour eviter les doublons
          // console.log(users_service);
          
          // creation d'un tableau avec les jours effectuer de l'user par service
          services_user_day = [];
          for (var i = 0; i < users_service.length; i++) {
            services_user_day.push(userServicesDays(users_service[i],services,services_users_days_project));
            services_user= services_user_day;
          }
          // console.log(services_user);




          //----------------------------------partie activite user jour-----------------------------------------------------------

          var activity_users_days_project = <?php echo $activity_users_days_projects_json; ?>; // variable sur les activités , users et jours effectués par un projet
          //console.log(activity_users_days_project);
          if_empty(activity_users_days_project);

          var activity_project = [];
          for (var i =0 ;  i < activity_users_days_project.length ; i++) {
          //      console.log(activity_users_days_project[i]);
            activity_project.push(activity_users_days_project[i][0]);
          }
          a_project = cleanListe(activity_project);  // function pour eviter les doublons

          //  console.log(a_project);
          var user_activity = [];
          for (var i =0 ;  i < activity_users_days_project.length ; i++) {
            user_activity.push(activity_users_days_project[i][1]) // on creer une array liste des users pour chaque activité
          }
          user_activity = cleanListe(user_activity);

          // creation d'un tableau avec les jours effectuer de l'user par activite
          var activity_user_day = [];
          for (var i = 0; i < user_activity.length; i++) {
            activity_user_day.push(userServicesDays(user_activity[i],a_project,activity_users_days_project));
            activity_user = activity_user_day;
          }

          /*
          //graphe correspondant au utilisateur et les heures effectuée par service
          */
          var project_user = new Highcharts.chart('graph_service_user', {
            chart: {
              type: 'bar'
            },
            title: {
              text: 'Service -> user'
            },
            xAxis: {// nombre de service par nom
              categories: services
            },
            tooltip:{
              valueDecimals : 1,
              valueSuffix: ' day'
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
            series:services_user
          });
                  
           /*
          //graphe correspondant au utilisateur et les heures effectuée par activitées
          */
          var activity_user = new Highcharts.chart('graph_activity_user', {
            chart: {
              type: 'bar'
            },
            title: {
            text: 'Activity -> user'
            },
            xAxis: {
              categories: a_project
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
            tittle :{ text :"Activité"
            },
            series: activity_user
          });
        </script>
      </div> 
    </div>
  </body>
</html>

