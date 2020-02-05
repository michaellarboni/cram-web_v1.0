<?php
include('../Inc/require.inc.php');

session_name('cram-web');
session_start();

$body = json_decode(file_get_contents('php://input'),true);

var_dump($body);

if ($_SESSION ['ADMIN'] == true)
{
    switch ($body['action']) {
        case 'setAdmin': setAdmin($body['data']);
            break;
        case 'setValid': setValid($body['data']);
            break;
        case'setDate' : setDate($body['data']);
            break;
    }
}

else {
    http_response_code(403);
}

/**
 * Set admin
 * @param $data
 *  data : {
 *      id,     //integer  - user id
 *  }
 */
function setAdmin($data)
{
    $musers = new MUsers();
    $musers->setIdUser($data['id']);
    $musers->setAdmin();
    http_response_code(201);
} //setAdmin($data)

/**
 * Set date
 * @param $data
 *  data : {
 *      id,     //integer  - user id
 *      date    //datetime - date
 *  }
 */
function setDate($data)
{
    $musers = new MUsers();
    $musers->setIdUser($data['id']);
    // recupere la date de la premiere tache
    $firstTaskDate = $musers->selectMinDate();

    $arrayA = explode('-', $data['userstartdate']);
    $arrayB = explode('-', $firstTaskDate['min']);

    //dates à comparer
    $dateA = mktime(0,0,0,$arrayA[2],$arrayA[1],$arrayA[0]);
    $dateB = mktime(0,0,0,$arrayB[2],$arrayB[1],$arrayB[0]);

    if($dateA < $dateB){
        $musers->setDate($data['userstartdate']);
        http_response_code(201);
    }
} //setDate($data)

/**
 * Set valid
 * @param $data
 *  data : {
 *      id,     //integer  - user id
 *  }
 */
function setValid($data)
{
    $musers = new MUsers();
    $musers->setIdUser($data['id']);
    $musers->setValid();
    http_response_code(201);
} //setValid($data)

