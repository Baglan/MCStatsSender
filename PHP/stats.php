<?php
    // Read raw data
    $fp = fopen('php://input', 'rb');
    $post = stream_get_contents($fp);
    
    $data = json_decode($post, true);
    $data['time']	= date('Y-m-d H:i:s');
    $data['bundle'] = $_SERVER['HTTP_X_MCSTATSSENDER_NAME'];
    $data['version'] = $_SERVER['HTTP_X_MCSTATSSENDER_VERSION'];
    $data['uniqueId'] = $_SERVER['HTTP_X_MCSTATSSENDER_UNIQUEID'];
    
    $fd = fopen('log.txt', 'ab');
    fwrite($fd, json_encode($data)."\n");
    fclose($fd);