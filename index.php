<!DOCTYPE html>
<html>
<head>
<title>HextupleO - create project </title>

  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>
  <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>

<link rel="shortcut icon" type="image/png" href="favicon.png"/>

<style>
table {
    font-family: arial, sans-serif;
    border-collapse: collapse;
    width: 50%;
}

td, th {
    border: 1px solid #dddddd;
    text-align: left;
    padding: 8px;
}

tr:nth-child(even) {
    background-color: #dddddd;
}
</style>
</head>
<body>
<h1> HextupleO - Create Project</h1> 
<a href=index.php><img src="hextupleo-mini.png"></a>
 <a href=index.php> Home</a>
 <a href=admin.php target=_blank> Admin</a> <br>
<table>
<form action="index.php" method="POST">
<tr>
   <th>User:</th> 
   <th><input name="user" type="text" /></th>
</tr>
<tr>
  <th>Password:(don't get too fancy! it's a clear text) </th>
  <th><input name="password" type="text" /></th>
</tr>
<tr>
   <th>Controller Count:</th>
   <th><input type="radio" name="controller" value="1" checked> 1 <input type="radio" name="controller" value="3"> 3 </th>
</tr>
<tr>
   <th>Compute Count (max 3):</th>
   <th><input type="number" name="compute" min="0" max="3" value="1"></th>
</tr>
<tr>
   <th>Ceph Count (max 3): </th>
   <th><input type="number" name="ceph" min="0" max="3" value="0"></th>
</tr>
<tr>
   <th>OSP Version:</th>
   <th><input type="radio" name="osp" value="osp11" checked> osp11 <input type="radio" name="osp" value="osp10"> osp10 </th>
</tr>
<tr>
   <th>   <button type="button" class="btn btn-info" data-toggle="collapse" data-target="#advanced">Advanced</button> </th>
   <th> Collapse for more features </th>
</tr>
<tr>
   <th> <input type="submit" name="submit" value="Build Environment!"> </th>
</tr>


</table>

<div id="advanced" class="panel-collapse collapse">
<table>
<tr>
<th>
<b>Advanced Features </b>
</th>
</tr>

<tr>
<th>
HCI Count (max 3):
</th>

<th>
<input type="number" name="hci" min="0" max="3" value="0">
</th>
</tr>
</table>
</div>
</form>


</body>
</html>
<?php


function liveExecuteCommand($cmd)
{

    while (@ ob_end_flush()); // end all output buffers if any

    $proc = popen("$cmd 2>&1 ; echo Exit status : $?", 'r');

    $live_output     = "";
    $complete_output = "";

    while (!feof($proc))
    {
        $live_output     = fread($proc, 4096);
        $complete_output = $complete_output . $live_output ;
        echo "$live_output <br>";
        @ flush();
    }

    pclose($proc);

    // get exit status
    preg_match('/[0-9]+$/', $complete_output, $matches);

    // return exit status and intended output
    return array (
                    'exit_status'  => intval($matches[0]),
                    'output'       => str_replace("Exit status : " . $matches[0], '', $complete_output)
                 );
}



if((($_POST['user']) != '') && (($_POST['password']) != '')) {
#if(isset($_POST['user']) && isset($_POST['password'])) {
#if(empty($_POST['user']) && empty($_POST['password'])) {
  

#browse through the network file and break it down into array
 
   $delimiter = " ";
   $eoldelimiter = "\n";
   $fp = fopen("vars/networks", "r") or die("Unable to open file!");
   $loop = 0;
   while (!feof($fp)) {
    $line = stream_get_line($fp, 4096, $eoldelimiter); 

    if ($line[0] === '#') continue;  //Skip lines that start with #
    $loop++;
    $field[$loop] = explode ($delimiter, $line);
    $fp++;
                      }

   fclose($fp);
# save first available ip range to a variable

    $id = $field[1][0];
    $network = $field[1][1];
    $cidr = $field[1][2];
    $gateway = $field[1][3];
    $firstip = $field[1][4];
    $lastip = $field[1][5];
    $network_file = 'vars/networks';



# comment out the line that are in use and add name of the user at the end
    file_put_contents('vars/networks', str_replace($id . ' ', "#" . $id . ' ', file_get_contents('vars/networks')));
    file_put_contents('vars/networks', str_replace($lastip, $lastip . ' ' . $_POST['user'] . ' ', file_get_contents('vars/networks')));



    $data = '   project_name: ' . $_POST['user'] . "\n" . '   project_password: ' . $_POST['password'] . "\n" . '   controller_count: ' . $_POST['controller'] . "\n" . '   compute_count: ' . $_POST['compute'] . "\n" . '   ceph_count: ' . $_POST['ceph'] . "\n" . '   hci_count: ' . $_POST['hci'] . "\n" . '   osp: ' . $_POST['osp'] . "\n" . '   id: ' . "$id \n" . '   network_external: ' . "$network \n" . '   cidr: ' . "$cidr \n" . '   gateway: ' . "$gateway \n" . '   firstip: ' . "$firstip \n" . '   lastip: ' . "$lastip \n";

    $ret = file_put_contents('/var/www/html/hextupleo/vars/' . $_POST['user'] . '.yaml', $data, LOCK_EX);
    if($ret === false) {
        die('There was an error writing this file');
                       }
    else {
        echo "<b>Log on to Horizon with just created user and password: <a href=https://10.9.65.100/dashboard/auth/login/?next=/dashboard/ target=_blank> https://10.9.65.100/dashboard</a></b> <br><hr>";
        echo "<b>!!! This is still work in progress. Don't close this webpage until ansible playbook is done!!!</b> <br><hr>";
        $result = liveExecuteCommand('ansible-playbook nested-openstack/create-project.yaml  -e @vars/' . $_POST['user'] . '.yaml | tee logs/' . $_POST['user'] . '.log');
        #$result = liveExecuteCommand('ping -c 5 127.0.0.1');

        
          }
                                                          }
else {
   die('Nothing entered under user or password');
}

?>
