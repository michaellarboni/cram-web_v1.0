



function exportCSVFile(headers, items, fileTitle) {
  if (headers) {
      items.unshift(headers);
  }

  // Convert Object to JSON
  var jsonObject = JSON.stringify(items);

  var csv = this.convertToCSV(jsonObject);

  var exportedFilenmae = fileTitle + '.csv' || 'export.csv';

  var blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  if (navigator.msSaveBlob) { // IE 10+
      navigator.msSaveBlob(blob, exportedFilenmae);
  } else {
      var link = document.createElement("a");
      if (link.download !== undefined) { // feature detection
          // Browsers that support HTML5 download attribute
          var url = URL.createObjectURL(blob);
          link.setAttribute("href", url);
          link.setAttribute("download", exportedFilenmae);
          link.style.visibility = 'hidden';
          document.body.appendChild(link);
          link.click();
          document.body.removeChild(link);
      }
  }
}

function download(){
var headers = {
    services: "services", // remove commas to avoid errors
    Users: "users",
    Day: "day"

};

itemsNotFormatted = data;

var itemsFormatted = [];

// format the data
itemsNotFormatted.forEach((item) => {
    itemsFormatted.push({
        services: item.services.replace(/,/g, ''), // remove commas to avoid errors,
        users: item.users,
        day: item.day
    });
});

var fileTitle = 'Service => Users'; // or 'my-unique-title'

exportCSVFile(headers, itemsFormatted, fileTitle); // call the exportCSVFile() function to process the JSON and trigger the download
}

// reporting leader

// document.getElementById('project').options[document.getElementById('project').selectedIndex].text;

// document.getElementById('project').options[i].selected = true;


/*


var select = document.getElementById("select"),
      arr = leaderService(user);
for (var i = 0; i < arr.length; i++) {
  var option = document.createElement('option'),
      txt = document.createTextNode(arr[i]);
  option.appendChild(txt);
  option.setAttribute("value",arr[i]);
  select.insertBefore(option,select.lastChild);

}

*/



/*
     

table = $('#tableau3').DataTable({
  paging:false,
  searching: false
});
table.destroy();



$(document).ready(function() {
 
} );


$('#table').DataTable({
  paging:false
});





$(document).ready(function() {
  $('#table').DataTable({ 
       data: dataSet,
       columns: [
           { title: "Name" },
           { title: "Position" },
           { title: "Office" },
           { title: "Extn." },
           { title: "Start date" },
           { title: "Salary" }
       ]
   } );
} );
*/


// fonction pour voir une couleur au azard
  function getRandomColor() {
    var letters = '0123456789ABCDEF';
    var color = '#';
    for (var i = 0; i < 6; i++) {
        color += letters[Math.floor(Math.random() * 16)];
      }
      return color;
    }

/*
    // renvoie le mois suivant
function nextMonth($date_begin, $date_end) {
    $date_month = date (('m'),strtotime($date_end)."+1 months");
    $date_years = date (('Y'),strtotime($date_begin));

    if ($date_month >12) {
        $date_month =1;
        $date_years = date (('Y'),strtotime($date_begin)."+1 years");
      }

    $date_begin = date ($date_years.$date_month.'01');
    $date_end = date ($date_years.$date_month.'31');

// faire la conditon si le jour est 30 ou 31 avec l'annee
  return $date_begin. $date_end;

}
// renvoie le mois precedent
function previousMonth($date_begin, $date_end) {

    $date_end = date (('Y-m-d'),strtotime($date_end)."-1 months");

    $date_month = date (('m'),strtotime($date_end);

      if ($date_month <1) {
        $date_month =12;
        $date_years = date (('Y'),strtotime($date_begin)."-1 years");
      }
    $date_years = date (('Y'),strtotime($date_begin));

    $date_begin = date ($date_years.$date_month.'01');
    $date_end = date ($date_years.$date_month.'31');

 // FAIre  LE TESt DU JOUR SI 30 ou 31
  return $date_begin .$date_end;

}

*/



  //var date_new =  GetUrlParameter('previous_year');
  // console.log(date_new);






    var date_begin = "date - 1 mois";
    var date_end = "date + 1 mois"
    var date_begin_year = "date - 1 ans";
    var date_end_year = "date + 1 ans"

   /*
    $(document).ready(function(){
      $.ajax({

        type:'button',
        url:'reportingUserV3.php',
        data: 'result_date',
        success: function(reponse) {
          alert(data);
        }


      });

    });

*/
    // fonction pour la gestion des touche de selection mois annee et custom



/*
    $(document).ready(function(){
      $('#customDate').hide();
      $('#anneeDate').hide(); 
      
      // gestion du bouton du mois    
        $('#mois').click(function(){
          $('#monthDate').show();
          $('#customDate').hide();
          $('#anneeDate').hide(); 
          
      /*    
          
          event.preventDefault();
          $.post( 'reportingUserV3.php', date_begin=$('#result_date').val(),
            

          function(data){
              if ('<?php echo date_begin ' == true){

              }else $('#result_date').innerHTML = "<?php echo $date_begin ; ?>";

            },
            'text'
          );
        */
     /*    $('#result_date').html('coucou c\'est l\'annee 2019')

        });
      
      
     
        // gestion du bouton de l'annee
        $('#annee').click(function(){
          $('#customDate').hide();
          $('#monthDate').hide();
          $('#anneeDate').show();
        //  document.write('<span id="result_date">'+date_begin + ' ' + date_end_year +'</span>');
        });
      // gestion des choix de la date
        $('#custom').click(function(){
          $('#customDate').show();
          $('#anneeDate').hide();
          $('#monthDate').hide();
        });

      // $('#previous_month').click(function(){
     //   $('#result_date').text(date_begin);
        // recuperer les valeurs de date_begin et date_end pour les mettres
        // dans les valeur du get de la page 
     // });
     // $('#next_month').click(function(){
     //   $('#result_date').text(date_end);
        // recuperer les valeurs de date_begin et date_end pour les mettres
        // dans les valeur du get de la page 
     // });
      $('#previous_year').click(function(){
        $('#previous_year').slideUp(1000).delay(1000).slideDown(1000).fadeOut(1000).fadeToggle(1000).slideToggle(1000).toggle(1000);
        $('#result_date').text(date_begin_year);
        // recuperer les valeurs de date_begin et date_end pour les mettres
        // dans les valeur du get de la page 
      });
      $('#next_year').click(function(){
        $('#result_date').text(date_end_year);
        // recuperer les valeurs de date_begin et date_end pour les mettres
        // dans les valeur du get de la page 
      });
 
    });
 
   // parti Ajax utilisation

   function month(str) {
    if (str.length == 0) {
        document.getElementById("resultat_date").innerHTML = "coucou";
        return;
    } else {
        var xmlhttp = new XMLHttpRequest();
        xmlhttp.onreadystatechange = function() {
            if (this.readyState == 4 && this.status == 200) {
                document.getElementById("resultat_date").innerHTML = this.responseSubmit;
            }
        }
        xmlhttp.open("GET", "reportingUserV3.php?mois=mois?previous_month="+str,true);
        xmlhttp.send();
    }
    
}*/



