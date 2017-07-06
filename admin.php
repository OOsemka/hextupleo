<!DOCTYPE html>
<html>
<head>
<title>HextupleO - delete project </title>
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
<h1> HextupleO - Delete Project</h1> <img src="hextupleo-mini.png">
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

# browse vars directory for created users
$dir    = 'vars';
$files = scandir($dir);
#print_r($files);

echo "<table>";
echo "<form action=\"admin.php\" method=\"POST\">";
$loop = 0;
$files_count = count ($files);
while ($files_count >= $loop) {
   if (strpos($files[$loop], '.yaml') !== false) {
      $output = shell_exec('cat vars/' . $files[$loop]);
      echo "<tr>";
      echo "<th>delete: <input type=\"submit\" name=\"delete\" value=\"$files[$loop]\"></th>";
      echo "<th><pre>$output</pre></th>";
      echo "</tr>";

      #echo "$files[$loop]";
                                                 }
   $loop++;
                               }
      echo "</table>";

#if((($_POST['user']) != '') && (($_POST['password']) != '')) {
if(isset($_POST['delete'])) {
#if(empty($_POST['user']) && empty($_POST['password'])) {
  
$user_file = ($_POST['delete']);
#echo $data;

#browse through the user file and break it down into array
 
   $delimiter = " ";
   $eoldelimiter = "\n";
   $fp = fopen("vars/$user_file", "r") or die("Unable to open file!");
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
#print_r($field);
    $user = $field[1][4];
    $id = $field[7][4];
    #$network = $field[1][1];
    #$cidr = $field[1][2];
    #$gateway = $field[1][3];
    #$firstip = $field[1][4];
    #$lastip = $field[1][5];
    #$network_file = 'vars/networks';



# comment out the line that are in use and add name of the user at the end
    file_put_contents('vars/networks', str_replace("#" . $id . ' ',$id . ' ', file_get_contents('vars/networks')));
    file_put_contents('vars/networks', str_replace(" " . $user . " "," ", file_get_contents('vars/networks')));



    #$data = '   project_name: ' . $_POST['user'] . "\n" . '   project_password: ' . $_POST['password'] . "\n" . '   controller_count: ' . $_POST['controller'] . "\n" . '   compute_count: ' . $_POST['compute'] . "\n" . '   ceph_count: ' . $_POST['ceph'] . "\n" . '   osp: ' . $_POST['osp'] . "\n" . '   id: ' . "$id \n" . '   network_external: ' . "$network \n" . '   cidr: ' . "$cidr \n" . '   gateway: ' . "$gateway \n" . '   firstip: ' . "$firstip \n" . '   lastip: ' . "$lastip \n";

    #$ret = file_put_contents('/var/www/html/hextupleo/vars/' . $_POST['user'] . '.yaml', $data, LOCK_EX);
    #if($ret === false) {
    #    die('There was an error writing this file');
    #                   }
    #else {
        echo "<b>Deleting OpenStack for user $user. Don't close your webbrowser before ansible job finish</b> <br><hr>";
        $result = liveExecuteCommand('time ansible-playbook nested-openstack/cleanup-project.yaml  -e @vars/' . $user . '.yaml | tee logs/' . $user . '-delete.log');
        rename('vars/' . $user . '.yaml','vars/oldclouds/' . $user . '.yaml');
        #$result = liveExecuteCommand('ping -c 5 127.0.0.1');

        
    #      }
                                                          }
else {
   die('Ready for action');
}

?>

</body>
</html>
