<?php
include_once 'connexion.php';
session_start();
$_SESSION['lang'] = $_POST['language'];

if ($_POST['user'] != null && $_POST['pwd'] != null) 
{
    include_once ("/include/head.php");
    $id=$_POST['user'];
    // Eléments d'authentification LDAP
    $ldaprdn  = 'uid='.$id.',ou=people,dc=pytheas,dc=fr';     // DN ou RDN LDAP
    $ldappass = $_POST['pwd'];  // Mot de passe associé

    // Connexion au serveur LDAP
    $ldapconn = ldap_connect("ldaps://ldap-pytheas.oamp.fr:636") /*ldap_connect("ldaps://ldap-pytheas.oamp.fr:636")*/
        or die("Impossible de se connecter au serveur LDAP.");

    if ($ldapconn)
    {

        // Connexion au serveur LDAP
        $ldapbind = ldap_bind($ldapconn, $ldaprdn, $ldappass);

        // Vérification de l'authentification
        if ($ldapbind) {
            $user = PdoBdd::connexionBDD($id);
            $_SESSION['id'] = $user['id'];
            $_SESSION['username'] = $user['username'];
            if (isset($_SESSION['id']))
            {
                header("Location: ../myTasksManagement.php");
            }
            else
            {
                header("Location: ../index.php?erreur=autorisation");
            }
            
        } else {
            header("Location: ../index.php?erreur=connexion");
        }

    }
}
else
{
    header("Location: ../index.php?erreur=champs");
}



?>
