<?php

/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
$db = new PDO('pgsql:dbname=cram_0; host=localhost; port=5432;', "cram", "CRAM_usage$0");
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$stmt = $db->query("SELECT current_date as today");
$rs = $stmt->fetchAll();

foreach ($rs as $value) 
{
    echo $value['today'].'<br />';
}
?>
