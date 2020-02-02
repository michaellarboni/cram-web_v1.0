<?php
include('../Inc/require.inc.php');

session_name('cram-web');
session_start();

$body = json_decode(file_get_contents('php://input'),true);

var_dump($body);

if ($_SESSION ['ADMIN'] == true)
{
    switch ($body['action']) {
        case 'deleteProject': deleteProject($body['data']);
            break;
    }
}

else {
    http_response_code(403);
}

/**
 * addProject
 * @param $data
 *  data : {
 *      projectName,     //string  - project name
 *      projectEndDate  //date     - project end date
 *  }
 */
function insertProject($data)
{
    $mprojects = new MProject($data['id']);
    $mprojects->modify('insert');
    http_response_code(201);
}

/**
 * deleteProject
 * @param $data
 *  data : {
 *      projectId,     //int  - project id
 *  }
 */
function deleteProject($data)
{
    $mprojects = new MProject($data['id']);
    $mprojects->modify('delete');
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
