<?php
/**
 *  Script mettant a jour la table CRAMUSER, en remplissant les noms, prénoms et email, si présent sur le serveur LDAP
 *  recupere les entrés ldap_get_entries et verifie la correspondance dans la table CRAMUSER
 */

require('../Inc/require.inc.php');
include('../Mod/MUsers.mod.php');
$musers = new MUsers();

$ldapconn = ldap_connect("ldaps://ldap.osupytheas.fr:636");
$ldaprdn  = 'ou=people,dc=pytheas,dc=fr';
$filter   = "(uid=*)"; // * pour requeter sur tous les utilisateurs LDAP
$these    = array("uid","sn","givenname","mail");
$search   = ldap_search($ldapconn, $ldaprdn,$filter,$these);
$entries  = ldap_get_entries($ldapconn, $search);

//boucle sur le tableau $info (retour de la requete LDAP)
foreach ($entries as $val){
    $entries['username']   = $val['uid'][0];
    $entries['lastname']   = $val['sn'][0];
    $entries['name']       = $val['givenname'][0];
    $entries['email']      = $val['mail'][0];
    $entries['userstatut'] = 'valid';

    // verifie si l'utilisateur LDAP est présent dans la bdd du CRAM
    $user = $musers->verifUser($val['uid'][0]);
    // si c'est le cas, on met à jour la base de données avec les valeurs récupérées de ldap_get_entries() // $entries[]
    if($user['username']){
        $musers->setValue($entries);
        $musers->update();
        $result = 'Done';
    }
}

if ($result == 'Done'){
    $allUsers = $musers->selectAll();
    // boucle sur tous les users
    foreach($allUsers as $val){
        // si le user n'a pas de nom ni de prénom (n'est pas inscrit LDAP)
        // on modifie le statut 'pending'
        if ($val['lastname'] == null and $val['name'] == null){
            $value['username'] = $val['username'];
            $value['lastname']   = null;
            $value['name']       = null;
            $value['email']      = null;
            $value['userstatut'] = 'pending';

            $musers->setValue($value);
            $musers->update();
        }
    }
}
echo $result.PHP_EOL;
