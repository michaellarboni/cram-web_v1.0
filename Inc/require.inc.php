<?php
/**
 * Fichier d'inclusion des constantes et des fonctions
 * dont à besoin l'application en particulier l'Autoload
 * @author Michael Larboni
 * @version 1.0
 */

// Debuggage
define('DEBUG', true);
// Contrôle LDAP; true ou false
define('LDAP', false);

// Connexion Base de Données
define('DATABASE', 'pgsql:host=localhost;port=5432;dbname=cram_0');
define('LOGIN', 'cram');
define('PASSWORD', 'MOT_DE_PASSE');

/**
 * Chargement automatique des class
 * @param string class appelée
 *
 * @return void
 */
function my_autoloader($class)
{
    switch ($class[0])
        {
            // Inclusion des class de type View
            case 'V' : require_once('../View/'.$class.'.view.php');
                       break;
            // Inclusion des class de type Mod
            case 'M' : require_once('../Mod/'.$class.'.mod.php');
                       break;
            // Inclusion des class de type Class
//            case 'C' : require_once('../Class/'.$class.'.class.php');
//                       break;
        }

} // my_autoloader($class)

spl_autoload_register('my_autoloader');

/**
 * Mise en forme des chaînes de caractères pour un tableau
 * @param array $val tableau de chaînes à convertir
 *
 * @return void
 */
function strip_xss(&$val)
{
    // Teste si $val est un tableau
    if (is_array($val)) {
        // Si $val est un tableau, on réapplique la fonction strip_xss()
        array_walk($val, 'strip_xss');
    } else if (is_string($val)) {
        // Si $val est une string, on filtre avec strip_tags()
        $val = strip_tags($val, '<strong>');
    }
    return;

} // strip_xss(&$val)

// Visualisation des erreurs
if (!DEBUG) {
    // desactive l'affichage des erreurs
    ini_set('display_errors', 0);
} else {
    // Retourne toutes les erreurs
    error_reporting(E_ALL);
    // Autorise l'affichage des erreurs
    ini_set('display_errors', 1);

    /**
     * Fonction de debug pour les tableaux
     * @param array tableau à débugguer
     *
     * @return void
     */
    function debug($Tab)
    {
        echo '<pre>';
        print_r($Tab);
        echo '</pre>';

        return;

    } // debug($Tab)

}

function ErrorSQL($result)
{
    $error = '<div style="text-align: center;">
                <h1>Une erreur est survenue, contacter un administrateur</h1>
                <a href="../Php/index.php?EX=myTasksManagement">Retour</a>
              </div>';

    if (!DEBUG) return $error;

    // Récupère le tableau des erreurs
    $error = $result->errorInfo();

    echo 'TYPE_ERROR = ' . $error[0] . '<br />';
    echo 'CODE_ERROR = ' . $error[1] . '<br />';
    echo 'MSG_ERROR = ' . $error[2] . '<br />';

    return $error;

} // ErrorSQL($result)
