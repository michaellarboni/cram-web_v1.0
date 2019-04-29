<?php
include('include/head.php');
if (!isset($_SESSION['id'])) {
    header('Location: index.php');
}
if (!isset($_SESSION['startDate'])) {
    $_SESSION['startDate'] = PdoBdd::getStartDate($_SESSION['id']);
}
?>
<html>
    <body>
        <!--Menu-->
        <nav class="navbar navbar-inner">
            <div class="container">
                <p class="navbar-text pull-right">
                    Logged in as <a href="include/deconnexion.php" title="Logout" class="navbar-link"><b><?php echo $_SESSION['username']; ?> <i class="icon-black icon-off"></i></b></a>
                </p>
                <ul class="nav">
                    <?php
                    echo '<li> <a href="myTasksManagement.php">' . $myTasks . '</a> </li>';
                    echo '<li class="dropdown"> <a class="dropdown-toggle" data-toggle="dropdown" href="#">' . $userConfig . '<b class="caret"></b> </a>
                            <ul class="dropdown-menu">
                              <li><a href="userConfiguration.php">' . $projects . '</a></li>
                              <li><a href="userConfigurationActivities.php">' . $activities . '</a></li>
                            </ul>
                          </li>';
                    ?>
                </ul>
            </div>
        </nav>
        <!--insertion du calendrier-->
        <script>
            var today           = moment();
            var calendar        = null;
            var events          = [];
            var index           = 0;
            
            var parts           = {
                am: {
                    hour_start: 8,
                    hour_end: 12
                },
                pm: {
                    hour_start: 13,
                    hour_end: 17
                }
            };
                
            $(document).ready(function () {
                //option du calendrier
                var calendar = $('#calendar').fullCalendar({
                    weekends: false,
                    fixedWeekCount: false,
                    defaultView: "month",
                    today: function(date, jsEvent, view, resourceObj) {

                        alert('Date: ' + date.format());
                        alert('Resource ID: ' + resourceObj.id);

                    }
                });
                loadData();
                initSelectable();
                initAjaxForm();
                                
                $(document).on('click',".fc-toolbar .fc-right", function(){
                    loadData();
                });
            });
            
            
            
            
            
            function loadData() {
                var start_date  = $('#calendar').fullCalendar('getView').start; 
                var end_date    = $('#calendar').fullCalendar('getView').end; 

                $.ajax({
                    url: "include/chTasks.php",
                    type: 'POST',
                    datatype: "jsonp",
                    data: { date_min: moment(start_date._d).format("YYYY/MM/DD"), date_max: moment(end_date._d).format("YYYY/MM/DD")} ,
                    success: function(d) {
                        var e           = JSON.parse(d);
                        events          = [];
                        
                        var sources     = $('#calendar').fullCalendar("clientEvents");
                        for(var i = 0; i < sources.length; i++){
                            $('#calendar').fullCalendar('removeEvents', sources[i].id);
                        }

                        var empty_cells = generateEmptyCells();
                        for (var i = 0; i < empty_cells.length; i++) {
                            events.push(empty_cells[i]);
                        }
                        
                        for (var i in e) {
                            var t       = e[i];

                            var title   = (t.taskdayoff)?"Congé":t.projectname + " - " + t.activityname;
                            var data    = createEvent(t, title);
                            
                            for(var i= 0; i < events.length; i++){
                                var empty_cell = events[i];
                                
                                if(moment(empty_cell.start).isSame(data.start)){
                                    empty_cell.ajax_obj     = data.ajax_obj;
                                    empty_cell.title        = data.title;
                                    empty_cell.className    = "cram-nb-"+empty_cell.id;
                                    if(t.taskdayoff){
                                        empty_cell.className= empty_cell.className+" cram-holiday";
                                    }
                                    events[i]               = empty_cell;
                                }
                            }
                        }
                        $('#calendar').fullCalendar('addEventSource', events);
                    }
                });
            }

            function createEvent(j, title) {
                var id    = index++;
                var event = {
                    id: id,
                    start: "",
                    end: "",
                    title: title,
                    className: "cram-nb-"+id,
                    ajax_obj:{}
                };
                
                event.ajax_obj  = j;
                event.start     = moment(j.taskdate + " " + parts.pm.hour_start + ":00:00");
                event.end       = moment(j.taskdate + " " + parts.pm.hour_end + ":00:00");
                
                
                if (j.taskam === "am") {
                    event.start = moment(j.taskdate + " 0" + parts.am.hour_start + ":00:00");
                    event.end   = moment(j.taskdate + " " + parts.am.hour_end + ":00:00");
                }
                return event;
            }

            function generateEmptyCells() {
                var cells = [];

                $('.fc-day').each(function (v, k) {
                    var e = $(k);

                    var t_am        = {taskam: "am", taskdate: e.attr('data-date')};
                    var t_pm        = {taskam: "pm", taskdate: e.attr('data-date')};
                    var t_am_date   = moment(t_am.taskdate+ " 0" + parts.am.hour_start + ":00:00");
                    var t_pm_date   = moment(t_pm.taskdate+ " " + parts.pm.hour_start + ":00:00");
                        
                    var add_t_am = true;
                    var add_t_pm = true;
                    
                    for (var i = 0; i < events.length; i++) {
                        var f           = events[i];
                        if(add_t_am && moment(f.start).isSame(t_am_date)){
                            add_t_am = false;
                        }
                        if(add_t_pm && moment(f.start).isSame(t_pm_date)){
                            add_t_pm = false;
                        }
                    }

                    if(moment(t_am_date).isBefore(today)){
                        if(add_t_am){
                            event = createEvent(t_am, "am");
                            event.className = event.className+" fc-disabled";
                            cells.push(event);
                        }
                        if(add_t_pm){
                            event = createEvent(t_pm, "pm");
                            event.className = event.className+" fc-disabled";
                            cells.push(event);
                        }
                    }
                });
 
                return cells;
            }
            
            function initSelectable(){
                var objs            = [];
                $("#board").selectable({
                    filter: ".fc-event",
                    selected: function (event, ui) {
                        for(var i = 0; i < $(ui).length; i++){
                            ui              = $(ui)[i].selected;
                            var id_ui       = parseInt($(ui).attr("class").match(/(\d+)/g));
                            var obj         = $('#calendar').fullCalendar("clientEvents", id_ui)[0];
                            objs[obj.id]    = obj;
                        }
                    },
                    unselected: function (event, ui) {
                        $.fancybox.close();
                    },
                    start:function(){
                        objs            = [];
                        $('#dates').html("");
                        $('#myform textarea').val("");
                        $('#holiday').prop('checked', false);
                        $('#myform input[name="dates[]"]').remove();
                    },
                    stop: function( event, ui ) {
                        var ids = [];
                        for (var k in objs){
                            var id = objs[k].id;
                            
                            if(parseInt(id)<10){
                                id = "0"+id;
                            }
                            ids.push(id);
                        }
                        ids.sort();
                        
                        var show_del_button = false;
                        
                        for(var i = 0; i < ids.length; i++){
                            var obj         = objs[parseInt(ids[i])];

                            if(obj.title !== "pm" && obj.title !== "am"){
                                show_del_button = true;
                            }
                            
                            var mj_start    = moment(obj.start._d).format("YYYY/MM/DD");
                            var mh_start    = moment(obj.start._d).format("HH:mm");
                            var mh_end      = moment(obj.end._d).format("HH:mm");

                            $('#myform').append($("<input/>").attr("name","dates[]").attr('type', 'hidden').val(moment(obj.start._d).format("YYYY/MM/DD HH:mm")));
                            
                            var elm = $('#dates li[data-id="'+(obj.id-1)+'"]');
                            if(elm.length === 1){
                                elm.attr('data-id', obj.id);
                                elm.html(elm.attr("data-date")+" "+elm.attr("data-hour")+" > "+mj_start+" "+mh_end);
                            }
                            else{
                                $('#dates').append($("<li/>").attr('data-date', mj_start).attr('data-hour', mh_start).attr('data-id', obj.id).html(mj_start+" "+mh_start+" > "+mh_end));
                            }
                        }
                        openFancyBox(); 
                        
                        if(ids.length===1){
                            var obj         = objs[parseInt(ids[0])];
                            
                            var opt_activity = $('#dialog-form select[name="activity"] option[label="'+obj.ajax_obj.activityname+'"]');
                            var opt_project = $('#dialog-form select[name="projet"] option[label="'+obj.ajax_obj.projectname+'"]');
                            if(opt_activity.length===1){
                                opt_activity.attr('selected', "selected");
                            }
                            if(opt_project.length===1){
                                opt_project.attr('selected', "selected");
                            }
                            
                            $('#holiday').removeProp("checked", "checked");
                            if(obj.ajax_obj.taskdayoff){
                                $('#holiday').prop("checked", "checked");
                            }
                            
                            $('#myform textarea').val(obj.ajax_obj.taskcomment);
                        }
                        
                        $('#dialog-form input[name="delete"]').removeAttr("disabled");
                        if(!show_del_button){
                            $('#dialog-form input[name="delete"]').attr("disabled", "disabled");
                        }
                    }
                });
                openFancyBox(); 
            }
            
            function openFancyBox(){
                if($('#dates li').length > 0){
                    $.fancybox($("#dialog-form"), {
                        autoCenter: true,
                        minWidth: 500
                    });
                }
            }
            
            function initAjaxForm(){
                $('#dialog-form input[name="delete"]').on('click', function(e){
                    if(confirm("Are you sure to delete ?")){
                        $('#myform').attr('action', "include/deleteMultiTasks.php");
                        $('#myform').submit();
                    }
                    e.preventDefault();
                });
                $('#dialog-form input[name="valid"]').on('click', function(e){
                    $('#myform').attr('action', "include/saveMultiTasks.php");
                    $('#myform').submit();
                    e.preventDefault();
                });
                $('#myform').ajaxForm({
                    success:    function() { 
                        $.fancybox.close();
                        loadData();
                    } 
                });
            }
        </script>
        <div id="board" class="row-fluid">
            <div class="well">
                <div class="container" align="center">
                    <div id='calendar' class="calendar">           
                    </div>
                </div>
                <div id="infos"></div>
            </div>
        </div>
        <div id="dialog-form">
            <form action="include/saveMultiTasks.php" method="POST" id="myform">
                <div class="row-fluid">
                    <div class="span12">
                        <label for="name">Dates</label>
                        <ul id="dates"></ul>
                    </div>
                </div>
                <div class="row-fluid">
                    <div class="span2">
                        <label for="holiday">En congé</label>
                    </div>
                    <div class="span10">
                        <input name="holiday" id="holiday" type="checkbox"/>
                    </div>
                </div>
                <div class="row-fluid">
                    <label for="projet">Projet</label>
                    <select name="projet">
                        <?php 
                            $projects = PdoBdd::getAllProjects($_SESSION['id']);
                            foreach($projects as $p){
                                if($p['flag']):
                        ?>
                        <option value="<?php echo $p['projectid']; ?>" label="<?php echo $p['name']; ?>"><?php echo $p['name']; ?></option>
                        <?php 
                                 endif;
                            }
                        ?>
                    </select>
                </div>
                <div class="row-fluid">
                    <label for="activity">Activité</label>
                    <select name="activity">
                        <?php 
                            $activities = PdoBdd::getAllActivities($_SESSION['id']);
                            foreach($activities as $a){
                                if($a['flag']):
                        ?>
                        <option value="<?php echo $a['activityid']; ?>" label="<?php echo $a['activityname']; ?>"><?php echo $a['activityname']; ?></option>
                        <?php 
                                endif;
                            }
                        ?>
                    </select>
                </div>
                <div class="row-fluid">
                    <label for="comment">Commentaire</label>
                    <textarea name="comment" id="comment"></textarea>
                </div>
                <div class="row-fluid">
                    <div style="text-align:center;">
                        <input type="submit" class="btn btn-primary" name="valid" value="Valider" />
                        <input type="submit" class="btn btn-danger" name="delete" value="Supprimer"/>
                    </div>
                    <input type="hidden" value="add" name="action" />
                </div>
            </form>
        </div>
    </body>
</html>
