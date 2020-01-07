<?php
include '../Inc/head2.php'; // pour les scripts supplémentaires
require '../Php/controllerDate.php'; // pour les methodes est les controles des variables

//objet language
$mlanguage = new MLanguage(isset($_SESSION['LANGUAGE']) ? $_SESSION['LANGUAGE'] : 'fr' );
//tableau de langue associé
$lang = $mlanguage->arrayLang();

$mdates = new MDates();
$musers = new MUsers();

$user = $_SESSION['ID'];
$url = 'reportingUser';
$user_name = $_SESSION['USERNAME'];
$choice = $_POST['choix'];
$navigate = $_POST['naviguer'];

?>
<div class="well">
    <!-- div de la partie du haut de la page avec les boutons -->
    <div class="responsive_embed">
        <div class="row justify-content-md-center" id="bouton_global">
            <form method="POST">
                <div class="row">
                    <div class="col-auto">
                        <?php
                        echo nav_form($date_begin, $date_end, $_POST['choix'], $_POST['naviguer']);
                        ?>
                    </div>
                    <div class="col-3">
                        <div class="btn-group">
                            <input id="mois"   name="choix" type="submit" class="btn btn-secondary" value="<?php echo $lang['month'] ?>"/>
                            <input id="annee"  name="choix" type="submit" class="btn btn-secondary" value="<?php echo $lang['year'] ?>"/>
                            <input id="custom" name="choix" type="submit" class="btn btn-secondary" value="<?php echo $lang['custom'] ?>">
                        </div>
                    </div>
                </div>
            </form >
        </div>
</div>

    <div class="row" id="partie-central">

        <div class="container">
            <div class="col-12 border" id="est">
                <div class="graph_projet">
                    <div id="my_chart_projet"></div> <!-- affichage du graphe des projets -->
                </div>
                <div class="tableau_projet">
                    <!-- creation du tableau1 des projets associe au activite -->
                    <table class="display" id="tableau1" style="width:100%;">
                    </table>
                </div>
                <div class="info-user">
                    <p><?php echo $lang['user'].': '.$user_name ?></p>
                    <p><?php echo $lang['daysOff']. holidays($user, $date_begin, $date_end); // recupere le resultat de la demande de requete dans la classe PdoBdd
                        ?>
                    </p>
                </div>
            </div>
        </div>

        <div class="container">
            <div class="col-12 border" id="west">
                <div class="graph_activite">
                    <div id="my_chart_activite"></div> <!-- affichage du graphe des activités -->
                </div>
                <div class="" id="tableau_activite">
                    <!-- creation du tableau2 des activités associées au Projet -->
                    <table class="display" id="tableau2" style="width:100%;">
                    </table>
                </div>
            </div>
        </div>
    </div>

    <?php
   // variable de demande de requete pour les graphes et tableaux

    // resultat sur le nombre de jour effectuer pour un projet a une date par user
    $result_project_jour = $musers->projectNameDay($user,$date_begin,$date_end);
    // var_dump($result_project_jour);
    $result_project_jour_json = json_encode($result_project_jour);

    // requete pour les activite associe au projet avec le nombre de jour associe a l'user a une date
    $req_activite_name_jour =  $musers->activityNameJour($user,$date_begin,$date_end);
    // var_dump($req_activite_name_jour);
    $result_activite_jour_json = json_encode($req_activite_name_jour); // transformer le tableau en json ( pour etre exploiter en javascrypt)

    // resultat sur le nombre de projet et activte par jour sur une date données
    $result_project_day_activity = $musers->projectActivityJour($user,$date_begin,$date_end);
    //var_dump($result_project_day_activity);
    $result_project_day_activity_json = json_encode($result_project_day_activity); // transformer le tableau en json ( pour etre exploiter en javascrypt)
    //  print_r($result_project_day_activity);

    // resultat sur le nombre d'activiter and the projets effectuer par jour sur une date données par rapport a l'user
    $req_activity_day_project = $musers->activityProjectDay($user,$date_begin,$date_end);
    $result_activity_day_project_json = json_encode($req_activity_day_project);
    ?>

    <script>

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
      $('#sauvegardesUserProjects').click(function(){
          projects_days.downloadCSV();
      });
      $('#sauvegardesUserActivities').click(function(){
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
          // alert( 'Empty');
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
            text: "<?php echo $lang['ProjectsDays']?>"
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
              text: "<?php echo $lang['ActivitiesDays']?>"
          },
          xAxis: {
              type: 'category'
          },
          yAxis: {
              title: {
                  text: "<?php echo $lang['NumbersOfDays']?>"
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
                      format: "{point.y:.1f} Days"
                  }
              }
          },
          tooltip: {
              headerFormat: '<span style="font-size:11px">{series.name}</span><br>',
              pointFormat: '<span style="color:{point.color}">{point.name}</span>: <b>{point.y:.2f}</b>Days<br/>'
          },
          series: [
              {
                  name: "<?php echo $lang['activity']?>",
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
              { title: "<?php echo $lang['project']?>" },
              { title: "<?php echo $lang['activity']?>" },
              { title: "<?php echo $lang['day']?>" }
            ]
          });

        $('#tableau2').DataTable({   // tableau2 avec ses parametres correspondant au activité et projet jour
          data : result_activity_day_project_json,
            columns: [
              { title: "<?php echo $lang['activity']?>" },
              { title: "<?php echo $lang['project']?>" },
              { title: "<?php echo $lang['day']?>" }
            ]
          });
        });
    </script>
</div>
