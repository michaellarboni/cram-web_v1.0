<?php
/**
 * Class de type Modèle gérant les langues
 * 
 * @author Michael Larboni
 * @version 1.0
 */
class MLanguage
{
    private $userLang;
    public  $lang = array();

    /**
     * Constructeur de la class Language
     * @access public
     * @param $_userLang
     */
    public function __construct($_userLang){

        $this->userLang = $_userLang;
        //construct lang file
        $langFile = '../Inc/lang/'. $this->userLang . '.ini';

        $this->lang = parse_ini_file($langFile, true, INI_SCANNER_NORMAL);

    } // __construct()

    public function arrayLang(){
        return $this->lang;
    }

} // MLanguage

