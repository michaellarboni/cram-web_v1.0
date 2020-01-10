<?php
include('../Inc/require.inc.php');

session_name('cram-web');
session_start();

$body = json_decode(file_get_contents('php://input'),true);

debug($body);

if ($_SESSION ['ADMIN'] == true)
{
    switch ($body['action']) {
        case 'deleteActivity': deleteActivity($body['data']);
            break;
    }
}

else {
    http_response_code(403);
}

/**
 * addActivity
 * @param $data
 *  data : {
 *      activityName,     //string  - activity name
 *  }
 */
function insertActivity($data)
{
    $mactivity = new MActivity($data['id']);
    $mactivity->modify('insert');
    http_response_code(201);
}

/**
 * deleteActivity
 * @param $data
 *  data : {
 *      activityId,     //int  - activity id
 *  }
 */
function deleteActivity($data)
{
    $mactivity = new MActivity($data['id']);
    $mactivity->modify('delete');
    http_response_code(201);
}

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
//    $musers = new MUsers();
//    $musers->SetIdUser($data['id']);
//    $musers->setAdmin();
//    http_response_code(201);
}


//echo $verif;
