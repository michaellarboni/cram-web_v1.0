  
<?php
session_start();
// include 'include/connexion.php';
$user_name = $_SESSION['username'];
include 'include/head2.php';
require 'controller/ControllerDate.php';
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
              <?php 
                echo nav_form($date_begin, $date_end, $_POST['choix'], $_POST['naviguer'] );
              ?>
              </div>
              <div class="col-6 offset-9"> 
                <div class="btn-group-vertical">
                  <input id="mois" name="choix" type="submit" class="btn btn-primary" value="mois"/>&nbsp;
                  <input id="annee" name="choix" type="submit" class="btn btn-primary" value="annee"/>&nbsp;
                  <input id="custom" name="choix" type="submit" class="btn btn-primary" value="custom">&nbsp;
                </div>
              </div>
            </form >
          </div>
        </div>
        <div class="row" id="partie-central">
          <div class="col-6" id="est">
            <div class="graph_projet" >
              <div id="my_chart_projet"></div> <!-- affichage du graphe des projets -->
            </div>
            <div>
              <p>Utilisateur : <?php echo $user_name ?></p>
              <p>Jour d'absence pris = 
                <?php 
                  echo holidays($user,$date_begin,$date_end); // recupere le resultat de la demande de requete dans la classe PdoBdd
                ?>
              </p>
            </div> 
            <div class="tableau_projet">
            <!-- creation du tableau1 des projets associe au activite -->
              <table class="display" id="tableau1" width="100%">
              </table>
            </div>
          </div>
          <div class ="col-6" id="west">
            <div class="graph_activite" >
              <div id="my_chart_activite"></div> <!-- affichage du graphe des activités -->
            </div>
            <div class="" id="tableau_activite">
              <!-- creation du tableau2 des activités associées au Projet -->
              <table class="display" id="tableau2" width="100%">
              </table>
            </div>
          </div>
        </div>
        <div class="row" id="bouton_inferieur">  <!-- gestion des bouton de bas de page -->
         
          <div class="col-6" >
            <input class="btn btn-primary" type="button" value="Retour" id="retour" onclick="window.location='myTasksManagement.php' ">
          </div>
          <div class="col-6 offset-9" >
            <a class="btn btn-primary" type="button" id="sauvegardesUser" href ="#">Fichier en CSV</a>
          </div>
        </div>
  
            <?php 
           // variable de demande de requete pour les graphes et tableaux

            // resultat sur le nombre de jour effectuer pour un projet a une date par user
            $result_project_jour = PdoBdd::projectNameDay($user,$date_begin,$date_end); 
            // var_dump($result_project_jour);
            $result_project_jour_json = json_encode($result_project_jour);

            // requete pour les activite associe au projet avec le nombre de jour associe a l'user a une date
            $req_activite_name_jour =  PdoBdd::activityNameJour($user,$date_begin,$date_end); 
            // var_dump($req_activite_name_jour);
            $result_activite_jour_json = json_encode($req_activite_name_jour); // transformer le tableau en json ( pour etre exploiter en javascrypt)
    
            // resultat sur le nombre de projet et activte par jour sur une date données
            $result_project_day_activity = PdoBdd::projectActivityJour($user,$date_begin,$date_end); 
            //var_dump($result_project_day_activity);
            $result_project_day_activity_json = json_encode($result_project_day_activity); // transformer le tableau en json ( pour etre exploiter en javascrypt)
            //  print_r($result_project_day_activity);

            // resultat sur le nombre d'activiter and the projets effectuer par jour sur une date données par rapport a l'user
            $req_activity_day_project = PdoBdd::activityProjectDay($user,$date_begin,$date_end); 
            $result_activity_day_project_json = json_encode($req_activity_day_project);
            ?>
 
        <script type="text/javascript">

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

          /*
          // fonction sur la validation du bouton de sauvegardes pour la page leader
          */
          $('#sauvegardesUser').click(function(){
            projects_days.downloadCSV();
            activities_days.downloadCSV();
          });

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

          //  --------------- partie Projets ---------------------------------

          var result_project_activity_json = <?php echo $result_project_day_activity_json; ?>;
          if_empty(result_project_activity_json);// affiche si la liste est vide

          var result_json= <?php echo $result_project_jour_json; ?>; // nombre de jour par projet.
          //console.log(resultjson);
          // modification  des keys du tableau result_json pour le graphe avec name : et y: 
          // création d'un nouveau tableau avec la methode map() pour remplacer les keys.
          result_projet_jour = result_json.map(({projectname : name, etp : y  }) => ({name , y }));
          // console.log(result_projet_jour);

          // --------------------parties activity-----------------------------

          var result_activity_day_project_json = <?php echo $result_activity_day_project_json; ?>;
          //console.log(result_activity_day_project_json);
          if_empty(result_activity_day_project_json);// affiche si la liste est vide
          var result_activite_jour_json = <?php echo $result_activite_jour_json; ?>;
          // console.log(result_activite_jour_json);
          // création d'un nouveau tableau avec la methode map() pour remplacer les keys.
          result_activity_jour = result_activite_jour_json.map(({activityname : name, etp : y  }) => ({name , y }));
          // console.log(result_activity_jour);

          //  graphe en cercle sur les jours effectués par projet
          var projects_days  =  Highcharts.chart('my_chart_projet', {
            chart: {
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false,
                type: 'pie'
            },
            title: {
                text: 'Projects Days'
            },
            tooltip: {
                pointFormat: '{series.name}: <b>{point.y} Days</b>'
            },
            plotOptions: {
                pie: {
                    allowPointSelect: true,
                    cursor: 'pointer',
                    dataLabels: {
                        enabled: true,
                        format: '<b>{point.name}</b>: {point.y} Days'
                    }
                }
            },
            series: [{
                name: 'Project',
                colorByPoint: true,
                data: result_projet_jour // array liste sur le nombre de projets avec les jours effecutés
            }]
          });

          // graphe en form de colone sur les jours effectués par activités
          var activities_days = Highcharts.chart('my_chart_activite', {
              chart: {
                  type: 'column'
              },
              title: {
                  text: 'Activities Days'
              },
              xAxis: {
                  type: 'category'
              },
              yAxis: {
                  title: {
                      text: 'Numbers of Days'
                  }
              },
              legend: {
                  enabled: false
              },
              plotOptions: {
                  series: {
                      borderWidth: 0,
                      dataLabels: {
                          enabled: true,
                          format: '{point.y:.1f} Days'
                      }
                  }
              },
              tooltip: {
                  headerFormat: '<span style="font-size:11px">{series.name}</span><br>',
                  pointFormat: '<span style="color:{point.color}">{point.name}</span>: <b>{point.y:.2f}</b> Days<br/>'
              },
              series: [
                  {
                      name: "Activity",
                      colorByPoint: true,
                      data: result_activity_jour  // array liste sur le nombre de jours par activités
                  }
              ]
          });

          /*
          / fonction pout retourner les parametre du tableau 1  et du tableau 2
          */
          $(document).ready(function() {
            $('#tableau1').DataTable({  // tableau 1 avec ses parametres correspondant au projet et activite jour
              data: result_project_activity_json,
                columns: [
                  { title: "Project" },
                  { title: "Activity" },
                  { title: "Day" }
                ]
              });

            $('#tableau2').DataTable({   // tableau2 avec ses parametres correspondant au activité et projet jour
              data : result_activity_day_project_json,
                columns: [
                  { title: "Activity" },
                  { title: "Project" },
                  { title: "Day" } 
                ]                         
              });
            });
        </script>
      </div> 
    </div>
  </body>
</html>

