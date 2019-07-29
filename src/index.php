<?php
$Langue="fr";
include ('include/head.php');
?>
<body>
    <center>
        <h2>Cram-web</h2>
        <form class="well " method="post" action="include/authentification.php">
            <?php
            //On vérifie s'il y a des erreurs (en cas d'échec de connexion)
            if (isset($_GET['erreur']))
            {
                if ($_GET['erreur'] == 'connexion')
                {
                    echo "<font color = 'red'>".$failedConnection."</font>";
                }
                else if ($_GET['erreur'] == 'champs')
                {
                    echo "<font color = 'red'>".$forgottenTextField."</font>";
                }
                else
                {
                    echo "<font color = 'red'>".$permission."</font>";
                }
            }
            ?>
            <table>
                <br /><br />
                <tr>
                    <td>
                        <?php echo "<h5>".$user." :&nbsp; </h5>"; ?>
                    </td>
                    <td>
                        <input type="text" name="user" style="height: 30px;">
                    </td>
                </tr>
                <tr>
                    <td>
                        <?php echo "<h5>".$password." :&nbsp;</h5>"; ?>
                    </td>
                    <td>
                        <input type="password" name="pwd" style="height: 30px;" >
                    </td>
                </tr>
                <tr>
                    <td>
                        <?php echo "<h5>".$language." :&nbsp;</h5>"; ?>
                    </td>
                    <td>
                        <?php
                        if (in_array('lang', $_SESSION) && $_SESSION['lang'] == "en")
                        {
                            echo '<INPUT type= "radio" name="language" value="en" checked>&nbsp; EN';
                            echo '&nbsp;&nbsp;&nbsp;&nbsp;';
                            echo '<INPUT type= "radio" name="language" value="fr">&nbsp; FR ';
                        }
                        else
                        {
                            echo '<INPUT type= "radio" name="language" value="en">&nbsp; EN';
                            echo '&nbsp;&nbsp;&nbsp;&nbsp;';
                            echo '<INPUT type= "radio" name="language" value="fr" checked>&nbsp; FR ';
                        }
                        ?>
                    </td>
                </tr>
             </table><br />
             <?php echo '<button class="btn btn-info btn-large" type="submit">'.$connect.' <i class="icon-white icon-ok-sign"></i></button>'; ?>
        </form>
    </center>
</body>
    
