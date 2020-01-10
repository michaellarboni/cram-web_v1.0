<?php

$musers = new MUsers();
$user = $_SESSION['ID'];

//objet language
$mlanguage = new MLanguage(isset($_SESSION['LANGUAGE']) ? $_SESSION['LANGUAGE'] : 'fr' );
//tableau de langue associé
$lang = $mlanguage->arrayLang();

if (!isset($_POST['naviguer'])) {
    $_POST['naviguer'] = '=';
}         
if (!isset($_POST['choix'])) {
    $_POST['choix'] = $lang['month'];
}
if (!isset($_POST['date_begin'])) {
    $_POST['date_begin'] = date('Y-m-01');
}
if (!isset($_POST['date_end'])) {
    $_POST['date_end'] = date('d-m-Y');
}
if (!isset($_POST['service'])) {
    $liste = $musers->leaderService($user);
    if (empty($liste)){
        $_POST['service']= ' ';
    }
    else {
        $_POST['service']= $liste[0]['label'];
    }
}
if (!isset($_POST['project'])) {
    $liste = $musers->managerProject($user);
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
$date_month = date (('m'),strtotime($_POST['date_end']));
$date_year = date (('Y'),strtotime($_POST['date_end']));

/**
 * methode pour la date de debut en fonction des choix
 * @param $date
 * @param $choix
 * @param string $naviguer
 * @return false|string
 */
function get_begin($date, $choix, $naviguer="=") {
    //objet language
    $mlanguage = new MLanguage(isset($_SESSION['LANGUAGE']) ? $_SESSION['LANGUAGE'] : 'fr' );
    //tableau de langue associé
    $lang = $mlanguage->arrayLang();

    $year = date('Y',strtotime($date));
    $month = date('m',strtotime($date));
    if ($choix == $lang['month']) {
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
    elseif( $choix == $lang['year']) {
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

} //get_begin($date, $choix, $naviguer="=")

/**
 * methode pour la date de fin en fonction des choix
 * @param $date1
 * @param $date2
 * @param $choix
 * @param string $naviguer
 * @return false|string
 */
function get_end($date1,$date2, $choix, $naviguer="=") {

    //objet language
    $mlanguage = new MLanguage(isset($_SESSION['LANGUAGE']) ? $_SESSION['LANGUAGE'] : 'fr' );
    //tableau de langue associé
    $lang = $mlanguage->arrayLang();

    $year = date('Y',strtotime($date1));
    $month = date('m',strtotime($date1));
    if ($choix == $lang['month']) {
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
    elseif( $choix == $lang['year']) {
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

} //get_end($date1,$date2, $choix, $naviguer="=")

/**
 * Communes au manager Leader et USER
 * methode pour afficher le formulaire de navigation des touches avancer et retour ainsi que le choix des dates
 * @param $date1
 * @param $date2
 * @param $choix
 * @param $service
 * @return string
 */
function nav_form($date1, $date2, $choix,$service) {
    //objet language
    $mlanguage = new MLanguage(isset($_SESSION['LANGUAGE']) ? $_SESSION['LANGUAGE'] : 'fr' );
    //tableau de langue associé
    $lang = $mlanguage->arrayLang();

    $year  = date('Y',strtotime($date1));
    $month = date('M',strtotime($date2));
    $row   = '';
    if ($choix == $lang['custom'])
    {
        $max = date('Y-m-d');
        $row = '<div class="col">
                    <label for="date_begin">'.$lang['beginDate'].'</label>
                    <input type="date" id="date_begin" name="date_begin" value="'. $date1.'" max="'.$max.'" />
                    <label for="date_end">'.$lang['endDate'].'</label>
                    <input type="date" id="date_end" name="date_end" value="'. $max.'" max="'.$max.'" />
                    <input type="hidden"  name="choix" value="'.$lang['custom'].'" />
                    <input type="submit"  value="'.$lang['enter'].'" class="btn btn-secondary" />
                </div>';

    }
    else
    {
        $row .= '   <input type="submit" name="naviguer" value="<" class="btn btn-secondary"/> ';
        $row .= '   <input type="hidden" name="date_begin" value="'.$date1.'"> ';
        $row .= '   <input type="hidden" name="date_end" value="'.$date2.'"> ';
        if ($choix == $lang['month'])
        {
            $row .= '   <input type="hidden" name="choix" value="'.$lang['month'].'"> ';
            $row .= '   <span id="result_date">'.$month.' '.$year.'</span>';
        }
        elseif ($choix == $lang['year'])
        {
            $row .= '   <input type="hidden" name="choix" value="'.$lang['year'].'"> ';
            $row .= '   <span id="result_date">'.$year.'</span>';
        }
        $row .= '   <input type="hidden" name="service" value="'.$service.'"/> ';
        $row .= '   <input type="submit" name="naviguer" value=">" class="btn btn-secondary"/> ';
    }
    return $row;

} // nav_form($date1, $date2, $choix,$service)

/**
 *fonction sur la liste des services correspondant a l'user avec ses selections
 * @param $user
 * @param $service
 * @return string
 */
function service($user,$service){
    $musers = new MUsers();
    $services = $musers->leaderService($user);
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

} //service($user,$service)

/**
 * fonction sur la liste des projects correspondant a l'user avec ses selections
 * @param $user
 * @param $project
 * @return string
 */
function project($user,$project){

    $musers = new MUsers();
    $manager_project = $musers->managerProject($user);
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

} //project($user,$project)

/**
 *fonction sur le nombre de conge pris par rapport a une periode ( date de debut et date de fin )
 * @param $user
 * @param $date_begin
 * @param $date_end
 * @return
 */
function holidays($user,$date_begin,$date_end){

    $musers = new MUsers();
    $holidays = $musers->holiday($user,$date_begin,$date_end);
    return $holidays;

} //holidays($user,$date_begin,$date_end)
