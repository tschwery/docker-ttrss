#!/usr/bin/env php7
<?php
// Taken from clue/docker-ttrss and modified
$confpath = '/var/www/config.php';

$config = array();

// path to ttrss
$config['SELF_URL_PATH'] = env('SELF_URL_PATH', 'http://localhost');

$config['PHP_EXECUTABLE'] = env('PHP_EXECUTABLE', '/usr/bin/php7');

if (getenv('DB_TYPE') !== false) {
    $config['DB_TYPE'] = getenv('DB_TYPE');
}

if (getenv('DB_PORT') === false) {
    error('The env DB_PORT does not exist. Make sure to run with "--link mypostgresinstance:DB"');
}

if (is_numeric(getenv('DB_PORT')) && getenv('DB_HOST') !== false) {
    // numeric DB_PORT provided; assume port number passed directly
    $config['DB_HOST'] = env('DB_HOST');
    $config['DB_PORT'] = env('DB_PORT');
}

if (empty($config['DB_TYPE'])) {
    switch ($config['DB_PORT']) {
        case 3306:
            $config['DB_TYPE'] = 'mysql';
            break;
        case 5432:
            $config['DB_TYPE'] = 'pgsql';
            break;
        default:
            error('Database on non-standard port ' . $config['DB_PORT'] . ' and env DB_TYPE not present');
    }
}

// database credentials for this instance
//   database name (DB_NAME) can be supplied or detaults to "ttrss"
//   database user (DB_USER) can be supplied or defaults to database name
//   database pass (DB_PASS) can be supplied or defaults to database user
$config['DB_NAME'] = env('DB_NAME', 'ttrss');
$config['DB_USER'] = env('DB_USER', $config['DB_NAME']);
$config['DB_PASS'] = env('DB_PASS', $config['DB_USER']);

$count = 0;
while (!dbcheck($config)) {
    sleep(5);
    
    if ($count++ > 6) {
        error('Database connection failed.');
    }
}

$pdo = dbconnect($config);
try {
    $pdo->query('SELECT 1 FROM ttrss_feeds');
    // reached this point => table found, assume db is complete
} catch (PDOException $e) {
    echo 'Database table not found, applying schema... ' . PHP_EOL;
    $schema = file_get_contents('schema/ttrss_schema_' . $config['DB_TYPE'] . '.sql');
    $schema = preg_replace('/--(.*?);/', '', $schema);
    $schema = preg_replace('/[\r\n]/', ' ', $schema);
    $schema = trim($schema, ' ;');
    foreach (explode(';', $schema) as $stm) {
        $pdo->exec($stm);
    }
    unset($pdo);
}

$contents = file_get_contents($confpath);
foreach ($config as $name => $value) {
    $contents = preg_replace('/(define\s*\(\'' . $name . '\',\s*)(.*)(\);)/', '$1"' . $value . '"$3', $contents);
}
file_put_contents($confpath, $contents);

function env($name, $default = null) {
    $v = getenv($name) ?: $default;
    
    if ($v === null) {
        error('The env ' . $name . ' does not exist');
    }
    
    return $v;
}

function error($text) {
    echo 'Error: ' . $text . PHP_EOL;
    exit(1);
}

function dbconnect($config) {
    $map = array('host' => 'HOST', 'port' => 'PORT', 'dbname' => 'NAME');
    $dsn = $config['DB_TYPE'] . ':';
    foreach ($map as $d => $h) {
        if (isset($config['DB_' . $h])) {
            $dsn .= $d . '=' . $config['DB_' . $h] . ';';
        }
    }
    $pdo = new \PDO($dsn, $config['DB_USER'], $config['DB_PASS']);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    return $pdo;
}

function dbcheck($config) {
    try {
        dbconnect($config);
        return true;
    }
    catch (PDOException $e) {
        return false;
    }
}
