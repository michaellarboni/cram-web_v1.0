<?php
/**
 * Fichier de classe de type Vue
 * pour l'affichage de l'administration
 * @author Michael Larboni
 * @version 1.0
 */

/**
 * Classe pour l'affichage des Managements
 */
class VAdminManagements
{

    /**
     * Constructeur de la classe VAdminManagements
     * @access public
     *
     */
    public function __construct(){}

    /**
     * Destructeur de la classe VAdminManagements
     * @access public
     *
     * @return void
     */
    public function __destruct(){}

    /**
     * Affichage du UserManagement
     * @access public
     *
     * @param $_data
     * @return void
     */

    public function showUsersManagement($_data)
    {
        //objet language
        $mlanguage = new MLanguage(isset($_SESSION['LANGUAGE']) ? $_SESSION['LANGUAGE'] : 'fr' );
        //tableau de langue associé
        $lang = $mlanguage->arrayLang();

        $tr = '';

        foreach ($_data as $val) {
            $useradmin       = ($val['useradmin'] == '1') ? 'yes' : 'no';
            $checkedAdmin    = ($useradmin == 'yes' ) ? 'checked' : '';
            $checkedStatut   = ($val['userstatut'] == 'valid' ) ? 'checked' : '';

            $tr .= '
                    <tr>
                      <td id="' . $val['lastname'] . '" data-id="' . $val['userid'] . '">' . $val['lastname'] . '</td>
                      <td id="' . $val['name'] . '" data-id="' . $val['userid'] . '">' . $val['name'] . '</td>
                      <td id="' . $val['username'] . '" data-id="' . $val['userid'] . '">' . $val['username'] . '</td>
                      
                      <td><span>'.$val['userstatut'].'</span>
                        <input id="valBtn'.$val['userid'].'" class="tgl tgl-flat setValidBtn" data-id="' . $val['userid'] . '" type = "checkbox" '.$checkedStatut.'>
                        <label for="valBtn'.$val['userid'].'" class="tgl-btn labelStatut"> </label>
                      </td>
                      
                      <td><span>'.$useradmin.'</span>
                        <input id="admBtn'.$val['userid'].'" data-id="' . $val['userid'] . '" class="tgl tgl-flat setAdminBtn" type = "checkbox" '.$checkedAdmin.'>
                        <label for="admBtn'.$val['userid'].'" class="tgl-btn"> </label>
                      </td>
                      
                      <td><span style="display: none">'.$val['userstartdate'].'</span>
                          <div class="container">
                            <input class="col inputDate" type="date" id="userstartdate" name="userstartdate" class="form-control" value="'.$val['userstartdate'].'" style="cursor: pointer" >
                            <button class="col btn btn-primary btn-rounded btn-sm setValidDate hidden" data-id="'.$val['userid'].'">'.$lang['changeDate'].'</button>
                          </div>
                      </td>
                    </tr>';
        }
?>

<!-- Font Awesome -->
<link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.11.2/css/all.css">
<!-- MDBootstrap Datatables  -->
<link href="../Css/datatables.min.css" rel="stylesheet">
<link href="../Css/datatables.css" rel="stylesheet">

<h3 class="card-header text-center font-weight-bold text-uppercase py-4"><?php echo $lang['managementUsers']?></h3>
<div class="container-fluid card table-adminUsers">

    <table id="table" class="table table-striped table-bordered" style="border-spacing:0;">
        <thead>
            <tr>
                <th class="col-md-3"><?php echo $lang['lastName']?></th>
                <th class="col-md-3"><?php echo $lang['name']?></th>
                <th class="col-md-3"><?php echo $lang['username']?></th>
                <th class="col-md-3"><?php echo $lang['statut']?></th>
                <th class="col-md-2"><?php echo $lang['admin']?></th>
                <th class="col-md-3"><?php echo $lang['startDate']?></th>
            </tr>
        </thead>
        <tbody>
            <?php echo $tr ?>
        </tbody>
     </table>
 </div>

<script src="../Js/adminManagementUsers.js"></script>

<!-- jQuery -->
<script src="../Js/jquery.min.js"></script>
<!-- Bootstrap tooltips -->
<script src="../Js/popper.min.js"></script>
<!-- Bootstrap core JavaScript -->
<script src="../Js/bootstrap.min.js"></script>
<!-- MDB core JavaScript -->
<script src="../Js/mdb.min.js"></script>
<!-- MDBootstrap Datatables  -->
<script src="../Js/datatables.min.js"></script>
<script src="../Js/datatables.js"></script>

<?php

    } //showUsersManagement($_data)


    /**
     * Affichage du ProjectsManagement
     * @access public
     *
     * @param $_data
     * @return void
     */
    public function showProjectsManagement($_data)
    {
        //objet language
        $mlanguage = new MLanguage(isset($_SESSION['LANGUAGE']) ? $_SESSION['LANGUAGE'] : 'fr' );
        //tableau de langue associé
        $lang = $mlanguage->arrayLang();

        $tr = '';
        $divModalDelete   = '';
        $divModalEdit     = '';
        $divModalListUsers  = '';
        $divModalListManagers = '';

        $mproject = new MProject();
        $data_projectsList = $mproject->listProject();
        $musers = new MUsers();
        $data_usersList = $musers->selectAll();

        $optionsManager = '';

        //boucle sur le tableau des projets et instancie les variables pour construction table
        foreach ($_data as $val) {

            $mproject = new MProject($val['projectid']);

            // recupere le nom complet du projet avec ses parents
            $parentProject = $mproject->fullProjectName();

            /**
             * colonne manager
             */

            // Retourne les infos du manager
            $managerNameProject = $mproject->managerNameProject();
            // si il y a au moins 2 managers on affiche ' [...]'
            $plus = (isset($managerNameProject[1]['lastname'])) ? ' [...]' : '';
            // si le nom de famille (lastname) n'est pas connu, on affiche son username
            if (isset($managerNameProject[0]['lastname']) == null) {
                $name = isset($managerNameProject[0]['username']) ? $managerNameProject[0]['username'] : '';
            } else {
                $name = ucfirst(strtolower($managerNameProject[0]['lastname']));
            }
            $managersBtn = ($managerNameProject) ?
                '<div><button class="btn-secondary btn-rounded btn-sm" data-toggle="modal" data-target="#modalListManagers' . $val['projectid'] . '">' . $name . $plus . '</button></div>' : '';

            // boucle sur les noms des managers pour creation element <li>
            $managerList = '';
            foreach ($managerNameProject as $val1) {
                $managerList .= ($val1['name'] == null) ? '<li>' . $val1['username'] . '</li>' : '<li>' . $val1['lastname'] . ' ' . $val1['name'] . '</li>';
            }

            // boucle sur la liste complete des users
            //todo remplacer username par lastname.name (si bdd purgée des users non LDAP)
            //todo permettre la suppression et modification des managers existants
            foreach ($data_usersList as $val1){
                $userid = $val1['userid'];
                $username = $val1['username'];
                $selected = '';
                foreach ($managerNameProject as $val2) {
                    $selected =  ($userid == $val2['userid']) ? 'selected="selected"' : '';
                }
                $optionsManager .= '<option '.$selected.' name="'.$username.'" value="'.$userid.'">'.$username.'</option>';

            }

            /**
             * colonne utilisateur actifs
             */

            //retourne les noms des utilisateurs ayant declarés une tache sur le projet et crée un boutton liste
            $usernameTaskProject = $mproject->usernameTaskProject();
            // si il y a au moins 2 users on affiche ' [...]'
            $plus = (isset($usernameTaskProject[1]['lastname'])) ? ' [...]' : '';
            // si le nom de famille (lastname) n'est pas connu, on affiche son username
            if (isset($usernameTaskProject[0]['lastname']) == null) {
                $name = isset($usernameTaskProject[0]['username']) ? $usernameTaskProject[0]['username'] : '';
            } else {
                $name = $usernameTaskProject[0]['lastname'];
            }
            $userBtn = ($usernameTaskProject) ? '<div><button class="btn-secondary btn-rounded btn-sm" data-toggle="modal" data-target="#modalListUsers'.$val['projectid'].'">'.$name.$plus.'</button></div>' : '';

            // boucle sur les noms des utilisateurs pour creation element <li>
            $projectuser = '';
            foreach ($usernameTaskProject as $val1) {
                $projectuser .= ($val1['name'] == null) ? '<li>' . $val1['username'] . '</li>' : '<li>' . $val1['lastname'] . ' ' . $val1['name'] . '</li>';
            }

            /**
             * pour le formulaire d'edition
             */
            $optionsProjects = '';
            // boucle sur la liste complete des projets
            // verifie si le projet est le meme que celui du parent du projet actuel et ajoute un selected pour l'option
            foreach ($data_projectsList as $val2) {
                if ($val['projectparentid'] == $val2['projectid']) {

                    $optionsProjects .= '<option selected="selected" name="' . $val2['projectid'] . '" value="' . $val2['projectid'] . '">' . $val2['projectname'] . '</option>';
                } else {
                    $optionsProjects .= '<option name="' . $val2['projectid'] . '" value="' . $val2['projectid'] . '">' . $val2['projectname'] . '</option>';
                }
            }

            /**
             * colonne edition
             */
            // attribut disabled (pour rendre inactif le bouton supprimer)
            // si au moins un utilisateur a declaré une tache sur le projet
            $disabled = ($usernameTaskProject) ? 'disabled' : '';

            /**
             *
             */
            $tr .= '
                    <tr>
                      <td>' . $val['projectname'] . '</td>
                      <td>'.$parentProject['full_projectname'].'</td>
                      <td>' . $val['projectenddate'] . '</td>
                      <td>'.$managersBtn.'</td>
                      <td>'.$userBtn.'</td>
                      <td>
                         <button class="btn btn-danger btn-sm btn-rounded buttonDelete" data-toggle="modal" data-target="#modalDelete'.$val['projectid'].'" '.$disabled.'><i class="fas fa-times ml-1"></i></button>
                          <button class="btn btn-info btn-rounded btn-sm buttonEdit" data-toggle="modal" data-target="#modalEdit'.$val['projectid'].'"><i class="fas fa-pencil-square-o ml-1"></i></button>
                      </td>
                    </tr>';

            $divModalDelete .= '<!-- Formulaire de suppression-->
                <div class="modal fade" id="modalDelete'.$val['projectid'].'" tabindex="-1" role="dialog" aria-labelledby="modalDelete'.$val['projectid'].'" aria-hidden="true">
                    <div class="modal-dialog" role="document">
                        <div class="modal-content">
                            <div class="modal-header text-center">
                                <h4 class="modal-title w-100 font-weight-bold text-danger">'.$lang['suppression'].'</h4>
                                    <button type="button" class="close text-danger" data-dismiss="modal" aria-label="Close">
                                    <span aria-hidden="true">&times;</span>
                                </button>
                            </div>
                            <div class="modal-body mx-3">
                             <p class="text-center h4">'.$lang['confirmDelete'].$val['projectname'].'</p>
                            </div>
                            <div class="modal-footer d-flex justify-content-center deleteButtonsWrapper">
                                <button type="button" class="btn btn-danger btnYesClass deleteProject" data-dismiss="modal" data-id="'.$val['projectid'].'">'.$lang['confirm'].'</button>
                                <button type="button" class="btn btn-primary btnNoClass" data-dismiss="modal">'.$lang['cancel'].'</button>
                            </div>
                        </div>
                    </div>
                </div>';

            $divModalEdit .= '
                <!-- Formulaire d\'edition-->
                <div class="modal fade modalEditClass" id="modalEdit'.$val['projectid'].'" tabindex="-1" role="dialog" aria-hidden="true">
                    <div class="modal-dialog" role="document">
                        <form action="../Php/index.php?EX=update_project&amp;projectid='.$val['projectid'].'" method="post" enctype="multipart/form-data">
                            <div class="modal-content">
                                <div class="modal-header text-center">
                                    <h4 class="modal-title w-100 font-weight-bold text-secondary">'.$lang['editForm'].'</h4>
                                    <button type="button" class="close text-primary" data-dismiss="modal" aria-label="Close">
                                         <span aria-hidden="true">&times;</span>
                                    </button>
                                </div>
                                <div class="modal-body mx-3">
                                    <!--Nom du projet-->
                                    <div class="md-form mb-5">
                                        <label data-error="wrong" data-success="right" for="projectname'.$val['projectid'].'">'.$lang['projectname'].'</label>
                                        <input type="text" id="projectname'.$val['projectid'].'" name="projectname" class="form-control validate" value="'.$val['projectname'].'">
                                    </div>
                                    <!--Full project name-->
                                    <div class="md-form mb-5">
                                         <label data-error="wrong" data-success="right" for="projectParent'.$val['projectid'].'">'.$lang['parent'].'</label>
                                        <select type="text" id="projectparentid'.$val['projectid'].'" name="projectparentid" class="form-control validate">
                                            <option value="" selected disabled>'.$lang['addProjectParent'].'</option>
                                            '.$optionsProjects.'
                                        </select>
                                    </div>
                                    <!-- Date de fin de projet-->
                                    <div class="md-form mb-5">
                                        <label data-error="wrong" data-success="right" for="projectenddate'.$val['projectid'].'">'.$lang['projectEndDate'].'</label>
                                        <input type="date" id="projectenddate'.$val['projectid'].'" name="projectenddate" class="form-control" value="'.$val['projectenddate'].'">
                                    </div>
                                </div>
                                <!--Bouton de validation-->
                                <div class="modal-footer d-flex justify-content-center editInsideWrapper">
                                     <button class="btn btn-outline-secondary btn-block editInside">'.$lang['edit'].'</button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>';

            $divModalListUsers .= '
                <!-- Liste des utilisateurs du projet-->
                <div class="modal fade" id="modalListUsers'.$val['projectid'].'" tabindex="-1" role="dialog" aria-labelledby="modalListUsers" aria-hidden="true">
                    <div class="modal-dialog" role="document">
                        <div class="modal-content">
                            <div class="modal-header text-center">
                            <h4 class="modal-title w-100 font-weight-bold text-primary">'.$lang['listingUsers'].'</h4>
                            </div>
                            <div class="modal-body mx-3">
                                <div class="md-form mb-5">
                                    <ul>
                                        '.$projectuser.'
                                    </ul>
                                </div>
                            </div>                                          
                        </div>
                    </div>
                </div>';
            
            $divModalListManagers .= '
                <!-- Liste des utilisateurs du projet-->
                <div class="modal fade" id="modalListManagers'.$val['projectid'].'" tabindex="-1" role="dialog" aria-labelledby="modalListManagers" aria-hidden="true">
                    <div class="modal-dialog" role="document">
                        <div class="modal-content">
                            <div class="modal-header text-center">
                            <h4 class="modal-title w-100 font-weight-bold text-primary">'.$lang['listingManagers'].'</h4>
                            </div>
                            <div class="modal-body mx-3">
                                <div class="md-form mb-5">
                                    <ul>
                                        '.$managerList.'
                                    </ul>
                                </div>
                                <div>
                                    <p class="text-center"><a href="../Php/index.php?EX=formManagerProject&amp;PROJECT_ID='.$val['projectid'].'">Ajouter ou supprimer un manager</a></p>
                                </div>  
                            </div>                                          
                        </div>
                    </div>
                </div>';

        }

?>
<!--     Affichage des projets-->

<!-- Font Awesome -->
<link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.11.2/css/all.css">
<!-- MDBootstrap Datatables  -->
<link href="../Css/datatables.min.css" rel="stylesheet">
<link href="../Css/datatables.css" rel="stylesheet">
<!--Select_pure-->
<link rel="stylesheet" href="../Css/select_pure.css"/>

<h3 class="card-header text-center font-weight-bold text-uppercase py-4"><?php echo $lang['managementProjects'] ?></h3>

<div class="container-fluid card table-adminProjects">

    <div class="row d-flex justify-content-center modalWrapper">
        <!--Boutons ajouter-->
        <div class="text-center">
            <a href="../Php/index.php?EX=form_project" class="btn btn-info btn-rounded btn-sm"><?php echo $lang['add']?><i class="fas fa-plus-square ml-1"> </i></a>
        </div>
        <?php echo
        $divModalEdit.
        $divModalDelete.
        $divModalListUsers.
        $divModalListManagers
        ?>
    </div>

    <!--Table-->
    <table id="table" class="table table-bordered table-responsive-md table-striped text-center">
        <thead>
            <tr>
                <th class="text-center"><?php echo $lang['projectname']?></th>
                <th class="text-center"><?php echo $lang['parent']?></th>
                <th class="text-center"><?php echo $lang['projectEndDate']?></th>
                <th class="text-center"><?php echo $lang['manager']?></th>
                <th class="text-center"><?php echo $lang['activeUsers']?></th>
                <th class="text-center"><?php echo $lang['edit']?></th>
            </tr>
        </thead>
        <tbody>
            <?php echo $tr?>
        </tbody>
    </table>

</div>

<!-- jQuery -->
<script src="../Js/jquery.min.js"></script>
<!-- Bootstrap tooltips -->
<script src="../Js/popper.min.js"></script>
<!-- Bootstrap core JavaScript -->
<script src="../Js/bootstrap.min.js"></script>
<!-- MDB core JavaScript -->
<script src="../Js/mdb.min.js"></script>
<!-- MDBootstrap Datatables  -->
<script src="../Js/datatables.min.js"></script>
<script src="../Js/datatables.js"></script>

<script src="../Js/adminManagementProjects.js"></script>
<script src="../Js/bundle.min.js"></script>
<script>
            var customIcon = document.createElement('img');
            customIcon.src = './icon.svg';

            var json_user = <?php echo json_encode($data_usersList, JSON_PRETTY_PRINT)?> ;
            const myOptions2 = json_user;
            const myOptions = [
                {
                    label: "Barbina",
                    value: "ba",
                },
                {
                    label: "Bigoli",
                    value: "bg",
                },
                {
                    label: "Bucatini",
                    value: "bu",
                },
                {
                    label: "Busiate",
                    value: "bus",
                },
                {
                    label: "Capellini",
                    value: "cp",
                },
                {
                    label: "Fedelini",
                    value: "fe",
                },
                {
                    label: "Maccheroni",
                    value: "ma",
                },
                {
                    label: "Spaghetti",
                    value: "sp",
                },
            ];

            var autocomplete = new SelectPure(".autocomplete-select", {
                options: myOptions2,
                value: ["ma"],
                multiple: true,
                autocomplete: true,
                icon: "fa fa-times",
                onChange: value => { console.log(value); },
                placeholder: 'Select a manager',
                classNames: {
                    select: "select-pure__select",
                    dropdownShown: "select-pure__select--opened",
                    multiselect: "select-pure__select--multiple",
                    label: "select-pure__label",
                    placeholder: "select-pure__placeholder",
                    dropdown: "select-pure__options",
                    option: "select-pure__option",
                    autocompleteInput: "select-pure__autocomplete",
                    selectedLabel: "select-pure__selected-label",
                    selectedOption: "select-pure__option--selected",
                    placeholderHidden: "select-pure__placeholder--hidden",
                    optionHidden: "select-pure__option--hidden",
                }
            });
</script>
<?php

    } //showProjectsManagement($_data)

    /**
     * Affichage du ActivitiesManagement
     * @access public
     *
     * @param $_data
     * @return void
     */
    public function showActivitiesManagement($_data)
    {
        //objet language
        $mlanguage = new MLanguage(isset($_SESSION['LANGUAGE']) ? $_SESSION['LANGUAGE'] : 'fr' );
        //tableau de langue associé
        $lang = $mlanguage->arrayLang();

        $tr             = '';
        $divModalDelete = '';
        $divModalEdit   = '';
        $divModalAdd    = '';
        $divModalListUsers  = '';

        //boucle sur le tableau des activités et instancie les variables pour construction table
        /**
         * @array $_data (['activityid'],
         *                ['activityname'])
         */
        foreach ($_data as $val) {

            $activityid   = $val['activityid'];
            $activityname = $val['activityname'];

            $mactivity = new MActivity($activityid);

            /**
             * colonne utilisateur actifs
             * @array $usernameTaskActivity // ['username']
             *                              // ['name']
             *                              // ['lastname']
             */

            //retourne les noms des utilisateurs ayant declarés une tache sur l'activité et crée un boutton liste
            $usernameTaskActivity = $mactivity->usernameTaskActivity();
            // si il y a au moins 2 users on affiche ' [...]'
            $plus = (isset($usernameTaskActivity[1]['lastname'])) ? ' [...]' : '';
            // si le nom de famille (lastname) n'est pas connu, on affiche son username
            if (isset($usernameTaskActivity[0]['lastname']) == null) {
                $name = isset($usernameTaskActivity[0]['username']) ? $usernameTaskActivity[0]['username'] : '';
            } else {
                $name = $usernameTaskActivity[0]['lastname'];
            }
            $userBtn = ($usernameTaskActivity) ? '<div><button class="btn-secondary btn-rounded btn-sm" data-toggle="modal" data-target="#modalListUsers'.$val['activityid'].'">'.$name.$plus.'</button></div>' : '';

            // boucle sur les noms des utilisateurs pour creation element <li>
            $activityuser = '';
            foreach ($usernameTaskActivity as $val1) {
                $activityuser .= ($val1['name'] == null) ? '<li>' . $val1['username'] . '</li>' : '<li>' . $val1['lastname'] . ' ' . $val1['name'] . '</li>';
            }

            /**
             *
             */
            // construit la chaine de caractère a afficher
            $disabled     = ($usernameTaskActivity) ? 'disabled' : '';

            $tr .= ' <tr>
                       <td>' . $activityname . '</td>
                       <td>' . $userBtn . '</td>
                         <td>
                            <button class="btn btn-danger btn-sm btn-rounded buttonDelete" data-toggle="modal" data-target="#modalDelete'.$activityid.'" '.$disabled.'><i class="fas fa-times ml-1"> </i></button>
                            <button class="btn btn-info btn-rounded btn-sm buttonEdit" data-toggle="modal" data-target="#modalEdit'.$activityid.'"><i class="fas fa-pencil-square-o ml-1"> </i></button>
                         </td>
                     </tr>';

            $divModalDelete .= '
                <!-- Formulaire de suppression-->
                <div class="modal fade" id="modalDelete'.$activityid.'" tabindex="-1" role="dialog" aria-labelledby="modalDelete'.$activityid.'" aria-hidden="true">
                    <div class="modal-dialog" role="document">
                        <div class="modal-content">
                            <div class="modal-header text-center">
                                <h4 class="modal-title w-100 font-weight-bold text-danger">'.$lang['delete'].'</h4>
                                    <button type="button" class="close text-danger" data-dismiss="modal" aria-label="Close">
                                    <span aria-hidden="true">&times;</span>
                                </button>
                            </div>
                            <div class="modal-body mx-3">
                             <p class="text-center h4">'.$lang['confirmDelete'].$activityname.'</p>
                            </div>
                            <div class="modal-footer d-flex justify-content-center deleteButtonsWrapper">
                                <button type="button" class="btn btn-danger btnYesClass deleteActivity" data-dismiss="modal" data-id="'.$activityid.'">'.$lang['confirm'].'</button>
                                <button type="button" class="btn btn-primary btnNoClass" data-dismiss="modal">'.$lang['cancel'].'</button>
                            </div>
                        </div>
                    </div>
                </div>';

            $divModalEdit .= '
                <!-- Formulaire d\'edition-->
                <div class="modal fade modalEditClass" id="modalEdit'.$activityid.'" tabindex="-1" role="dialog" aria-hidden="true">
                    <div class="modal-dialog" role="document">
                        <form action="../Php/index.php?EX=update_activity&amp;activityid='.$activityid.'" method="post" enctype="multipart/form-data">
                            <div class="modal-content">
                                <div class="modal-header text-center">
                                    <h4 class="modal-title w-100 font-weight-bold text-secondary">'.$lang['editForm'].'</h4>
                                    <button type="button" class="close text-primary" data-dismiss="modal" aria-label="Close">
                                         <span aria-hidden="true">&times;</span>
                                    </button>
                                </div>
                                <div class="modal-body mx-3">
                                    <div class="md-form mb-5">
                                        <label data-error="wrong" data-success="right" for="activityname'.$activityid.'">'.$lang['name'].'</label>
                                        <input type="text" id="activityname'.$activityid.'" name="activityname" class="form-control validate" value="'.$activityname.'">
                                    </div>
                                </div>
                                <div class="modal-footer d-flex justify-content-center editInsideWrapper">
                                     <button class="btn btn-outline-secondary btn-block editInside">'.$lang['edit'].'</button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>';

            $divModalAdd = '
                <!-- Formulaire d\'ajout-->
                <div class="modal fade addNewInputs" id="modalAdd" tabindex="-1" role="dialog" aria-labelledby="modalAdd" aria-hidden="true">
                    <div class="modal-dialog" role="document">
                        <form action="../Php/index.php?EX=insert_activity" method="post" enctype="multipart/form-data">
                            <div class="modal-content">
                                <div class="modal-header text-center">
                                    <h4 class="modal-title w-100 font-weight-bold text-primary">'.$lang['addActivity'].'</h4>
                                    <button type="button" class="close text-primary" data-dismiss="modal" aria-label="Close">
                                        <span aria-hidden="true">&times;</span>
                                    </button>
                                </div>
                                <div class="modal-body mx-3">
                                    <div class="md-form mb-5">
                                        <label data-error="wrong" data-success="right" for="activityname">'.$lang['name'].'</label>
                                        <input type="text" id="activityname" name="activityname" class="form-control validate">
                                    </div>
                                </div>
                                <div class="modal-footer d-flex justify-content-center buttonAddFormWrapper">
                                    <button type="submit" class="btn btn-outline-primary btn-block">'.$lang['add'].'</button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>';

            $divModalListUsers .= '
                <!-- Liste des utilisateurs de l\'activité-->
                <div class="modal fade" id="modalListUsers'.$val['activityid'].'" tabindex="-1" role="dialog" aria-labelledby="modalListUsers" aria-hidden="true">
                    <div class="modal-dialog" role="document">
                        <div class="modal-content">
                            <div class="modal-header text-center">
                            <h4 class="modal-title w-100 font-weight-bold text-primary">'.$lang['listingUsers'].'</h4>
                            </div>
                            <div class="modal-body mx-3">
                                <div class="md-form mb-5">
                                    <ul>
                                        '.$activityuser.'
                                    </ul>
                                </div>
                            </div>                                          
                        </div>
                    </div>
                </div>';

        }

        ?>

<!-- Font Awesome -->
<link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.11.2/css/all.css">
<!-- MDBootstrap Datatables  -->
<link href="../Css/datatables.min.css" rel="stylesheet">
<link href="../Css/datatables.css" rel="stylesheet">

<h3 class="card-header text-center font-weight-bold text-uppercase py-4"><?php echo $lang['managementActivities']?></h3>
<div class="container-fluid card table-adminActivities">

    <div class="row d-flex justify-content-center modalWrapper">
        <!--Boutons ajouter-->
        <div class="text-center">
            <a href="" class="btn btn-info btn-rounded btn-sm" data-toggle="modal" data-target="#modalAdd"><?php echo $lang['add']?><i class="fas fa-plus-square ml-1"> </i></a>
        </div>
        <?php
        echo $divModalEdit;
        echo $divModalDelete;
        echo $divModalAdd;
        echo $divModalListUsers;
        ?>
    </div>

    <!--Table-->
    <table id="table" class="table table-bordered table-responsive-md table-striped text-center">
        <thead>
            <tr>
                <th class="text-center"><?php echo $lang['activitieName']?></th>
                <th class="text-center"><?php echo $lang['activeUsers']?></th>
                <th class="text-center"><?php echo $lang['edit']?></th>
            </tr>
        </thead>
        <tbody>
            <?php echo $tr?>
        </tbody>
    </table>

</div>

<!-- jQuery -->
<script src="../Js/jquery.min.js"></script>
<!-- Bootstrap tooltips -->
<script src="../Js/popper.min.js"></script>
<!-- Bootstrap core JavaScript -->
<script src="../Js/bootstrap.min.js"></script>
<!-- MDB core JavaScript -->
<script src="../Js/mdb.min.js"></script>
<!-- MDBootstrap Datatables  -->
<script src="../Js/datatables.min.js"></script>
<script src="../Js/datatables.js"></script>

<script src="../Js/adminManagementActivities.js"></script>
<?php


    } //showActivitiesManagement($_data)

    /**
     *  Formulaire project
     */
    public function showFormProject()
    {
        //objet language
        $mlanguage = new MLanguage(isset($_SESSION['LANGUAGE']) ? $_SESSION['LANGUAGE'] : 'fr' );
        //tableau de langue associé
        $lang = $mlanguage->arrayLang();

        $mproject         = new MProject();
        $data_projectsList  = $mproject->listProject();

        $optionsProjects = '';
        // boucle sur la liste complete des projets
        foreach ($data_projectsList as $val){
            $optionsProjects .= '<option name="'.$val['projectid'].'" value="'.$val['projectid'].'">'.$val['projectname'].'</option>';
        }

        ?>
<style>
    .form{
        max-width: 500px;
        margin-top: 50px;
    }
</style>
        <!-- Formulaire d\'ajout-->
        <div class="card container form" role="document">
            <form action="../Php/index.php?EX=insert_project" method="post" enctype="multipart/form-data">
                <div class="">
                    <div class="text-center">
                        <a href="../Php/index.php?EX=adminManagementProjects" type="button" class="close text-danger" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </a>
                        <h4 class="w-100 font-weight-bold text-primary"><?php echo $lang['addProject']?></h4>
                    </div>
                    <div class="modal-body mx-3">
                        <div class="md-form mb-5">
                            <label data-error="wrong" data-success="right" for="projectname"><?php echo $lang['projectname']?></label>
                            <input type="text" id="projectname" name="projectname" class="form-control validate">
                        </div>
                        <div class="md-form mb-5">
                            <label data-error="wrong" data-success="right" for="projectparentid"><?php echo $lang['parent']?></label>
                            <select type="text" id="projectparentid" name="projectparentid" class="form-control validate">
                                <option selected="selected" disabled="disabled"><?php echo $lang['addProjectParent']?></option>
                                <?php echo $optionsProjects?>
                            </select>
                        </div>
                        <div class="md-form mb-5">
                            <label data-error="wrong" data-success="right" for="projectenddate"><?php echo $lang['projectEndDate']?></label>
                            <input type="date" id="projectenddate" name="projectenddate" class="form-control">
                        </div>
                    </div>
                    <div class="modal-footer d-flex justify-content-center buttonAddFormWrapper">
                        <button type="submit" class="btn btn-outline-primary btn-block"><?php echo $lang['add']?></button>
                    </div>
                </div>
            </form>
        </div>

<?php
        return;
    } //formProject()

} // VAdminManagements
