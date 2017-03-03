<?php header('content-type: application/json'); 
include("db/db_config.php");
//date_default_timezone_set('Europe/London');

$user_image = $_REQUEST['user_image'];
$user_id = $_REQUEST['user_id'];
$idx_last_element_string = $_REQUEST['idx_last_element'];
$block_size_paging_string = $_REQUEST['block_size_paging'];

$today = date("d-m-Y-H:i:s");
	
	if($_POST['user_image'] !=""){

	$uploaddir = 'user_images/';
	$file = $today . '.jpg';
	$uploadfile = $uploaddir . $file;
	$image1 		= $_FILES['photo']['name'];		
	$image1temp		= $_FILES["photo"]["tmp_name"];
			
	move_uploaded_file($image1temp, $uploadfile);
	$full = 'URL of Image Uploading'.$file;
	
	mysql_query("INSERT INTO user_gallery (user_image,user_id) VALUES ('$full','$user_id')") or die(mysql_error());
	
	$total_array = array();
	$sql = mysql_query("SELECT * FROM user_gallery WHERE user_id = '$user_id'")or die(mysql_error());

	$total_elements =  mysql_num_rows($sql);

	$idx_last_element = intval($idx_last_element_string);
	$block_size_paging = intval($block_size_paging_string);
	$total_page = round($total_elements/$block_size_paging);

	while($row = mysql_fetch_array($sql)) {
	
	$arr['ImageUrl'] = $row['user_image'];
	array_push($total_array,$arr);	
	}
	
	$dictionary["idx_last_element"] = $idx_last_element;
	$dictionary["total_pages"] = $total_page;
	
	$index_inf = $idx_last_element;
	$total_array = array_slice($total_array, $index_inf, $block_size_paging, false);
	
	$dictionary["current_page"] = $total_page-round(intval(($total_elements-$idx_last_element)/$block_size_paging));
	$dictionary["message"] = 'Image Uploaded Successfully';
	$dictionary["objects"] = $total_array;
	//$dictionary["total"] = $total_elements;
	$json = json_encode($dictionary);
	
	echo $json;

	}

	else {
	
	$total_array = array();
	$sql = mysql_query("SELECT * FROM user_gallery WHERE user_id = '$user_id'")or die(mysql_error());

	$total_elements =  mysql_num_rows($sql);

	$idx_last_element = intval($idx_last_element_string);
	$block_size_paging = intval($block_size_paging_string);
	$total_page = round($total_elements/$block_size_paging);

	
	while($row = mysql_fetch_array($sql)) {
	
	$arr['ImageUrl'] = $row['user_image'];
	array_push($total_array,$arr);	
	}
	
	//$dictionary['ImageUploaded'] = "Image Uploaded Successfully";
	$dictionary["idx_last_element"] = $idx_last_element;
	$dictionary["total_pages"] = $total_page;
	
	$index_inf = $idx_last_element;
	$total_array = array_slice($total_array, $index_inf, $block_size_paging, false);
	
	$dictionary["current_page"] = $total_page-round(intval(($total_elements-$idx_last_element)/$block_size_paging));
	$dictionary["objects"] = $total_array;
	$json = json_encode($dictionary);
	
	echo $json;
	
	}

?>
