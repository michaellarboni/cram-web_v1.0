<?php
/**
 * Fichier de classe de type Vue
 * pour l'affichage du formulaire de connexion et d'inscription
 */
class VForm
{
    /**
    * Constructeur de la classe VForm
    * @access public
    *
    * @return void
    */
    public function __construct(){}
    public function __destruct(){}

    /**
     * Affichage du formulaire de connexion et d'inscription
     * @access public
     *
     * @param $erreur
     * @return void
     */
    public function showForm($erreur)
    {
        //objet language
        $mlanguage = new MLanguage(isset($_SESSION['LANGUAGE']) ? $_SESSION['LANGUAGE'] : 'fr' );
        //tableau de langue associé
        $lang = $mlanguage->arrayLang();

        if (isset($_SESSION['LANGUAGE'])) {
                $checkedFR = ($_SESSION['LANGUAGE'] == 'fr') ? 'checked' : '' ;
                $checkedEN = ($_SESSION['LANGUAGE'] == 'en') ? 'checked' : '' ;
        }
        else{
            $checkedFR = 'checked';
            $checkedEN = '';
        }

        // actions des formulaires
        $actionConnexion = '../Php/index.php?EX=ldap';
        $actionRegister  = '../Php/index.php?EX=inscription';

        $connect      = $lang['connect'];
        $signIn       = $lang['signIn'];
        $user         = $lang['user'];
        $password     = $lang['password'];
        $help         = $lang['help'];
        $enterCaptcha = $lang['enterCaptcha'];
        $class        = ($erreur == $lang['securityCodeCorrect']) ? 'alert-info' : 'alert-danger';

        echo <<<HERE

<link href="//maxcdn.bootstrapcdn.com/bootstrap/3.3.0/css/bootstrap.min.css" rel="stylesheet" id="bootstrap-css">
<script src="//maxcdn.bootstrapcdn.com/bootstrap/3.3.0/js/bootstrap.min.js"></script>
<script src="//code.jquery.com/jquery-1.11.1.min.js"></script>

<style>
body {
    background:#e2e2e2 ;
}
.panel-login {
	border-color: #ccc;
	-webkit-box-shadow: 0 2px 3px 0 rgba(0,0,0,0.2);
	-moz-box-shadow: 0 2px 3px 0 rgba(0,0,0,0.2);
	box-shadow: 0 2px 3px 0 rgba(0,0,0,0.2);
}
.panel-login>.panel-heading {
	color: #00415d;
	background-color: #fff;
	border-color: #fff;
	text-align:center;
}
.panel-login>.panel-heading a{
	text-decoration: none;
	color: #666;
	font-weight: bold;
	font-size: 15px;
	-webkit-transition: all 0.1s linear;
	-moz-transition: all 0.1s linear;
	transition: all 0.1s linear;
}
.panel-login>.panel-heading a.active{
	color: #5390bc;
	font-size: 18px;
}
.panel-login>.panel-heading hr{
	margin-top: 10px;
	margin-bottom: 0;
	clear: both;
	border: 0;
	height: 1px;
	background-image: -webkit-linear-gradient(left,rgba(0, 0, 0, 0),rgba(0, 0, 0, 0.15),rgba(0, 0, 0, 0));
	background-image: -moz-linear-gradient(left,rgba(0,0,0,0),rgba(0,0,0,0.15),rgba(0,0,0,0));
	background-image: -ms-linear-gradient(left,rgba(0,0,0,0),rgba(0,0,0,0.15),rgba(0,0,0,0));
	background-image: -o-linear-gradient(left,rgba(0,0,0,0),rgba(0,0,0,0.15),rgba(0,0,0,0));
}
.panel-login input[type="text"],.panel-login input[type="email"],.panel-login input[type="password"] {
	height: 45px;
	border: 1px solid #ddd;
	font-size: 16px;
	-webkit-transition: all 0.1s linear;
	-moz-transition: all 0.1s linear;
	transition: all 0.1s linear;
}
.panel-login input:hover,
.panel-login input:focus {
	outline:none;
	-webkit-box-shadow: none;
	-moz-box-shadow: none;
	box-shadow: none;
	border-color: #ccc;
}
.btn-login {
	background-color: #59B2E0;
	outline: none;
	color: #fff;
	font-size: 14px;
	height: auto;
	font-weight: normal;
	padding: 14px 0;
	text-transform: uppercase;
	border-color: #59B2E6;
}
.btn-login:hover,
.btn-login:focus {
	color: #fff;
	background-color: #53A3CD;
	border-color: #53A3CD;
}
.forgot-password {
	text-decoration: underline;
	color: #888;
}
.forgot-password:hover,
.forgot-password:focus {
	text-decoration: underline;
	color: #666;
}

.btn-register {
	background-color: #1CB94E;
	outline: none;
	color: #fff;
	font-size: 14px;
	height: auto;
	font-weight: normal;
	padding: 14px 0;
	text-transform: uppercase;
	border-color: #1CB94A;
}
.btn-register:hover,
.btn-register:focus {
	color: #fff;
	background-color: #1CA347;
	border-color: #1CA347;
}

</style>

<script>
$(function() {

    $('#login-form-link').click(function(e) {
		$("#login-form").delay(100).fadeIn(100);
 		$("#register-form").fadeOut(100);
		$('#register-form-link').removeClass('active');
		$(this).addClass('active');
		e.preventDefault();
	});
	$('#register-form-link').click(function(e) {
		$("#register-form").delay(100).fadeIn(100);
 		$("#login-form").fadeOut(100);
		$('#login-form-link').removeClass('active');
		$(this).addClass('active');
		e.preventDefault();
	});
    $('#inputEnglish').click(function() {
        window.location="../Php/index.php?EX=home&LANG=en";
    });
    $('#inputFrench').click(function() {
        window.location="../Php/index.php?EX=home&LANG=fr";        
    });

});

</script>

<div class="container vertical-center">
    	<div class="row">
            <div class="panel panel-login container text-center col-xs-8 col-sm-10 col-md-7 col-lg-5">
                <h4 class="container-fluid $class">$erreur</h4>
                <div class="panel-heading">
                    <div class="row">
                        <h2 class="col text-uppercase">CRAM-web</h2>
                    </div>
                    <div class="row">
                        <div class="col-xs-6">
                            <a href="#" class="active" id="login-form-link">$connect</a>
                        </div>
                        <div class="col-xs-6">
                            <a href="#" id="register-form-link">$signIn</a>
                        </div>
                    </div>
                    <hr>
                </div>
                <div class="panel-body">
						<div class="row">
							<div class="col-lg-12">
                                <div class="text-center">
                                    <div class="form-check form-check-inline">
                                        <input class="form-check-input" type="radio" name="LANGUAGE" id="inputEnglish" value="en" $checkedEN>
                                        <label class="form-check-label" for="inputEnglish">English</label>
                                    </div>
                                    <div class="form-check form-check-inline">
                                        <input class="form-check-input" type="radio" name="LANGUAGE" id="inputFrench" value="fr" $checkedFR>
                                        <label class="form-check-label" for="inputFrench">Français</label>
                                    </div>
                                </div>				
                                <!-- Formulaire de connexion-->
								<form id="login-form" action="$actionConnexion" method="post" style="display: block;">
									<div class="form-group">
										<input type="text" name="username" tabindex="1" class="form-control" placeholder="$user" value="" required>
									</div>
									<div class="form-group">
										<input type="password" name="userpwd" tabindex="2" class="form-control" placeholder="$password" required>
									</div>
									
									<div class="form-group">
										<div class="row">
											<div class="col-sm-12">
												<input type="submit" name="login-submit" id="login-submit" tabindex="4" class="btn btn-lg btn-primary btn-block" value="$connect">
											</div>
										</div>
									</div>
									<div class="form-group">
										<div class="row">
											<div class="col-lg-12">
												<div class="text-center">
													<p tabindex="5" class="info">$help</p>
												</div>
											</div>
										</div>
									</div>
								</form>
								
								<!-- Formulaire d'inscription-->
								<form id="register-form" action="$actionRegister" method="post" style="display: none;">
									<div class="form-group">
										<input type="text" name="username" tabindex="1" class="form-control" placeholder="$user" value="" required>
									</div>
									<div class="form-group">
										<input type="password" name="userpwd" tabindex="2" class="form-control" placeholder="$password" required>
									</div>
									<!-- <div class="form-group">
										<input type="password" name="confirm-password" id="confirm-password" tabindex="2" class="form-control" placeholder="Confirm $password">
									</div> -->
                                    <div class="form-group">
										<input type="email" name="email" id="inputEmail" tabindex="3" class="form-control" placeholder="Email" value="" required>
									</div>
									
									<div class="form-group">
                                        <input type="text" name="captcha_code" tabindex="4" maxlength="6" class="form-control" placeholder="$enterCaptcha" required>
                                    </div>
                                    <div class="row">    
                                        <div class="col-12">
                                            <div class="text-center">
                                                <img id="captcha" src="../securimage/securimage_show.php" alt="CAPTCHA Image" />
                                            </div>                                        
                                        </div>
                                    </div>
                                    <div class="row">
                                        <div class="col-12 text-center">
                                            <a class="text-center forgot-password" href="#" onclick="document.getElementById('captcha').src = '../securimage/securimage_show.php?' + Math.random(); return false">
                                                <img src="../securimage/images/refresh.png" alt="Change Image">
                                            </a>
                                        </div>                                        
                                    </div>
                                    
									<div class="form-group">
										<div class="row">
											<div class="col-sm-12">
												<input type="submit" name="register-submit" id="register-submit" tabindex="4" class="btn btn-lg btn-primary btn-block" value="$signIn">
											</div>
										</div>
									</div>
									<div class="form-group">
										<div class="row">
											<div class="col-lg-12">
												<div class="text-center">
													<p tabindex="5" class="info">$help</p>
												</div>
											</div>
										</div>
									</div>
								</form>
								
							</div>
						</div>
					</div>
            </div>
		</div>
	</div>

HERE;

    } // showForm

} // VForm
