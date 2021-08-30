<?php

/**
 * Autoloader for t-test application classes.
 */
spl_autoload_register(function (string $className) {
	if ("\\" === $className[0]) {
		$className = substr($className, 1);
	}

	$path = __DIR__ . "/" . str_replace("\\", "/", $className) . ".php";

	if (is_file($path) && is_readable($path)) {
		include $path;
	}
});
