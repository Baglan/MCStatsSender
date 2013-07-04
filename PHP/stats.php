<?php
    // Read the raw data
    $fp = fopen('php://input', 'rb');
    $post = stream_get_contents($fp);
    
    $data = json_decode($post, true);
    $data['time']	= date('Y-m-d H:i:s');
    $data['product'] = $_SERVER['HTTP_X_MCSTATSSENDER_PRODUCT'];
    $data['system'] = $_SERVER['HTTP_X_MCSTATSSENDER_SYSTEM'];
    $data['device'] = $_SERVER['HTTP_X_MCSTATSSENDER_DEVICE'];
    $data['screenSize'] = $_SERVER['HTTP_X_MCSTATSSENDER_SCREEN_SIZE'];
    $data['uniqueId'] = $_SERVER['HTTP_X_MCSTATSSENDER_UNIQUEID'];
    $data['machineName'] = $_SERVER['HTTP_X_MCSTATSSENDER_MACHINE_NAME'];
    $data['compromized'] = $_SERVER['HTTP_X_MCSTATSSENDER_COMPROMIZED'];
    $data['reachability'] = $_SERVER['HTTP_X_MCSTATSSENDER_REACHABILITY'];
    
    $fd = fopen('log.txt', 'ab');
    fwrite($fd, json_encode($data)."\n");
    fclose($fd);