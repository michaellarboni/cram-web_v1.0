
<?php
include './include/connexion.php';
include './include/queries.php'; // pour les requetes a la base de données

if (!isset($_POST['naviguer'])) {
    $_POST['naviguer'] = '=';
}         
if (!isset($_POST['choix'])) {
    $_POST['choix'] = 'mois';
}
if (!isset($_POST['date_begin'])) {
    $_POST['date_begin'] = date('Y-m-01');
}
if (!isset($_POST['date_end'])) {
    $_POST['date_end'] = date('Y-m-d');
}
if (!isset($_POST['service'])) {
    $liste = leaderService($user);
    if (empty($liste)){
        $_POST['service']= ' ';
    }
    else {
        $_POST['service']= $liste[0]['label'];
    }
}
if (!isset($_POST['project'])) {
    $liste = managerProject($user);
    if (empty($liste)){
        $_POST['project']= ' ';
    }
    else {
        $_POST['project']= $liste[0]['projectname'];
    }
}
$project = $_POST['project'];
$service = $_POST['service'];
$date_begin = get_begin($_POST['date_begin'], $_POST['choix'], $_POST['naviguer']);
$date_end = get_end($_POST['date_begin'], $_POST['date_end'], $_POST['choix'],$_POST['naviguer']);
//echo '<br>date begin = '.$date_begin; 
//echo '<br>date end   = '.$date_end ; 
$date_month = date (('m'),strtotime($_POST['date_end']));
$date_year = date (('Y'),strtotime($_POST['date_end']));

/*
/ methode pour la date de debut en fonction des choix 
*/
function get_begin($date, $choix, $naviguer="=") {
    $year = date('Y',strtotime($date));
    $month = date('m',strtotime($date));
    if ($choix == 'mois') { 
        if ($naviguer == "<") {
            $month--;
        }
        elseif ($naviguer ==  ">"){
            $month++;
            if ($month > date('m') and $year >= date('Y')){
                $month --;
                $year = date('Y');
            }
        }
        if ($month == 0){
            $month=12;
            $year--;
        }
        if ($month == 13){
            $month=1;
            $year++;
        }
        return date('Y-m-01', strtotime($year.'-'.$month.'-01'));
    }
    elseif( $choix == "annee") {
        if ($year >date('Y')){
            $year = date('Y');
        }
        if ($naviguer == "<") {
            $year--;
        }
        elseif ($naviguer ==  ">") {
            $year++;
            if ($year >= date('Y')){
                $year = date('Y');
            }
        }
        return date('Y-01-01', strtotime($year.'-01-01'));
    }
    else {
        return $date; 
    }
}

/*
/ methode pour la date de fin en fonction des choix 
*/
function get_end($date1,$date2, $choix, $naviguer="=") {
    $year = date('Y',strtotime($date1));
    $month = date('m',strtotime($date1));
    if ($choix == 'mois') {
        if ($naviguer == "<") {
            $month--;
        }
        elseif ($naviguer ==  ">"){
            $month++;
        }
        if ($month == 0){
            $month=12;
            $year--;
        }
        if ($month == 13){
            $month=1;
            $year++;
        }
        return date('Y-m-t', strtotime($year.'-'.$month.'-01'));
    }
    elseif( $choix == "annee") {
        if ($naviguer == "<") {
            $year--;
        }
        elseif ($naviguer ==  ">") {
            $year++;
            if ($year >= date('Y')){
                $year = date('Y');
            }
        }
        return date('Y-12-31', strtotime($year.'-12-31'));
    } 
    else {
        return $date2; 
    }
}

/*
/ methode pour afficher le formulaire de vavigation des touches avancer et retour ainsi que le choix des dates
*/
function nav_form($date1, $date2, $choix,$service) {
    $year = date('Y',strtotime($date1));
    $month = date('m',strtotime($date1));
    $r = '';
    if ($choix == 'custom') {
        $max = date('Y-m-d');
        $r .= 'Date de début <input type="date" name="date_begin" value="'. $date1.'" max="'.$max.'" /> ';
        $r .= '<input type="submit"  value="Enter" class="btn btn-primary" /> ';
        $r .= 'Date de fin <input type="date"    name="date_end" value="'. $date2.'" max="'.$max.'" />';
        $r .= '<input type="hidden"  name="choix" value="custom" />';
    } 
    else {
        $r .= '   <input type="submit" name="naviguer" value="<" class="btn btn-primary"/> ';
        $r .= '   <input type="hidden" name="date_begin" value="'.$date1.'"> ';
        $r .= '   <input type="hidden" name="date_end" value="'.$date2.'"> ';
        if ($choix == 'mois') {
           $r .= '   <input type="hidden" name="choix" value="mois"> ';
           $r .= '   <span id="result_date">'.date('M',strtotime($date1)).' '.$year.'</span>';
        } 
        elseif ($choix == 'annee') {
            $r .= '   <input type="hidden" name="choix" value="annee"> ';
            $r .= '   <span id="result_date">'.$year.'</span>';
        } 
        $r .= '   <input type="hidden" name="service" value="'.$service.'"/> '; 
        $r .= '   <input type="submit" name="naviguer" value=">" class="btn btn-primary"/> ';
    }
    return $r;   
}

/*
/fonction sur la liste des services correspondant a l'user avec ses selections
*/
function service($user,$service){
    $services = leaderService($user);
    $result = '<select name="service" id="service">';
    foreach ($services as $value){
        if  ($service == $value['label']){
            $result .='<option   value="'.$service.'" selected="selected">'.$service.'</option>';
        }
        elseif ( $service == '') {
            $service = $value['label'];
            $result .='<option   value="'.$service.'" selected="selected">'.$service.'</option>';
        }
        else {
            $result .='<option  value="'.$value['label'].'">'.$value['label'].'</option>';
        }
    }
    $result .= '</select>';
    return $result;
}

/*
/fonction sur la liste des projects correspondant a l'user avec ses selections
*/
function project($user,$project){
    $manager_project = managerProject($user);
    $result = '<select name="project" id="project">';
    foreach ($manager_project as $value){
        if ($project == $value['projectname']){
            $result .='<option value="'.$project.'" selected="selected">'.$project.'</option>';    
        }
        elseif ($project == '') {
            $project = $value['projectname'];
            $result .= '<option value="'.$project.'" selected="selected">'.$project.'</option>';  
        }
        else{
        $result .='<option value="'.$value['projectname'].'">'.$value['projectname'].'</option>';
        }
    }
    $result .= '</select>';
    return $result;
}

/*
//fonction sur le nombre de conge pris par rapport a une periode ( date de debut et date de fin )
*/
function holidays($user,$date_begin,$date_end){
    $holidays = holidaysDay($user,$date_begin,$date_end);
    return $holidays;
}

?>