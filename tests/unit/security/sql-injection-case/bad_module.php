<?php

$query = "SELECT * FROM users WHERE id = " . $_GET['id'];

Db::getInstance()->execute($query);

