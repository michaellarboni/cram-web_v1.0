<?php
/**
 * Fichier de classe de type Vue
 * pour l'affichage des fichiers html ou html.php
 * @author Michael Larboni
 * @version 1.0
 */
 
/**
 * Classe pour l'affichage des fichiers html ou html.php
 */
class VHtml
{
  /**
   * Constructeur de la classe VHtml
   * @access public
   *        
   * @return void
   */
  public function __construct(){}
  
  /**
   * Destructeur de la classe VHtml
   * @access public
   *        
   * @return void
   */
  public function __destruct(){}
  
  /**
   * Affichage du fichier html ou html.php
   * @access public
   * @param string fichier html ou html.php à affificher
   *
   * @return void
   */
  public function showHtml($_html)
  {
    // Affichage du fichier $_html s'il existe
    // sinon affichage du fichier unknown.html
    (file_exists($_html)) ? include($_html) : include('../Html/unknown.html');
    
    return;
    
  } // showHtml($_html)
  
} // VHtml
