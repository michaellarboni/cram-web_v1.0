<?php
/**
 * Fichier de mise en page
 * @author Michael Larboni
 * @version 1.0
 */

global $content;
$vnav = new VNav();
$vcontent = new $content['class']();

?>
<!DOCTYPE html>
<html lang="fr" xml:lang="fr">
    <head>
        <meta charset="utf-8" />
        <title><?=$content['title']?></title>

        <link href='../libs/fullcalendar/dist/fullcalendar.css' rel='stylesheet' />
        <link href='../libs/fullcalendar/dist/fullcalendar.print.css' rel='stylesheet' media='print' />
        <link href='../libs/fontawesome/css/font-awesome.min.css' rel='stylesheet' />
        <link href="../libs/jquery-ui/themes/redmond/jquery-ui.min.css" rel="stylesheet" type="text/css">
        <link href="../libs/fancybox/source/jquery.fancybox.css?v=2.1.5" rel="stylesheet" type="text/css" media="screen" />
        <link href='../Css/style.css' rel='stylesheet' />
        <link href='../Css/monStyle.css' rel='stylesheet' />

        <script src='../libs/jquery/jquery.min.js'></script>
        <script src='../libs/jquery-ui/ui/minified/jquery-ui.min.js'></script>
        <script src='../libs/moment/min/moment.min.js'></script>
        <script src='../libs/fancybox/source/jquery.fancybox.pack.js?v=2.1.5'></script>
        <script src='../libs/jquery.form/jquery.form.js'></script>

    </head>
    <body class="bg-light">

        <header>
            <?php (isset($_SESSION['ID'])) ? $vnav->showNav() : '';?>
        </header>

        <div id="content">
            <?php $vcontent->{$content['method']}($content['arg'])?>
        </div><!-- id="content" -->
</body>
</html>
