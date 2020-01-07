          // fonction datatable pour le tableau1 des projets associe au activité et au jours 
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

          // fonction Datatable pour le tableau2 des activitées associé au projets et au jours
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

          // fonction sur le nombre de jour effectuer dans le service par l'user dans un tableau 
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

            // -----------------partie correpondante au project par manager--------------------

      //    var services_users= <?php echo $services_users_json; ?>;
          // console.log(manager_project);
          var services_users_days_project = "<?php echo $services_users_days_projects_json; ?>";
          // console.log(services_users_days_project);
      
            // ------------------------------------------------partie Services user jour ------------------------------------------------------------------

          // liste des services par project
          var services_project = [];
          for (var i =0 ;  i < services_users_days_project.length ; i++) {
            services_project.push(services_users_days_project[i][0])
          }
          //  console.log(services_project);
          services = cleanListe(services_project); // function pour eviter les doublons
          //   console.log(services);
          var users_service = [];
          for (var i =0 ;  i < services_users_days_project.length ; i++) {
            users_service.push(services_users_days_project[i][1])
          }
          users_service= cleanListe(users_service);
          // console.log(users_service);
          
          // creation d'un tableau avec les jours effectuer de l'user par service
          services_user_day = [];
          for (var i = 0; i < users_service.length; i++) {
            services_user_day.push(userServicesDays(users_service[i],services,services_users_days_project));
            services_user= services_user_day;
          }
          // console.log(services_user);

          //----------------------------------partie activite user jour-----------------------------------------------------------

          var activity_users_days_project = "<?php echo $activity_users_days_projects_json; ?>"; // variable sur les activités , users et jours effectués par un projet
          //console.log(activity_users_days_project);
          var activity_project = [];
          for (var i =0 ;  i < activity_users_days_project.length ; i++) {
          //      console.log(activity_users_days_project[i]);
            activity_project.push(activity_users_days_project[i][0]);
          }
          a_project = cleanListe(activity_project);  // function pour eviter les doublons
          var user_activity = [];
          for (var i =0 ;  i < activity_users_days_project.length ; i++) {
            user_activity.push(activity_users_days_project[i][1]) // on creer une array liste des users pour chaque activité
          }
          u_activity = cleanListe(user_activity);
          var activity_user_day = [];
          for (var i = 0; i < u_activity.length; i++) {
            activity_user_day.push(userServicesDays(u_activity[i],a_project,activity_users_days_project));
            activity_user = activity_user_day;
          }

          Highcharts.chart('graph_project_user', {
            chart: {
              type: 'bar'
            },
            title: {
              text: 'Service -> user'
            },
            xAxis: {// nombre de projet par nom
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
                  
          // affichage de l'activite  user
          Highcharts.chart('graph_activity_user', {
            chart: {
              type: 'bar'
            },
            title: {
            text: 'Activity -> user'
            },
            xAxis: {
              categories: activity_project
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