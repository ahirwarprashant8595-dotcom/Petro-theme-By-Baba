<?php
declare(strict_types=1);
// Installer-only helper. Secrets arrive through the environment, never command arguments.
[$script, $action, $panel] = $argv;
if ($action === 'environment') {
    if (is_file($panel.'/.env')) throw new RuntimeException('Refusing to replace an existing .env');
    $values = [
        'APP_ENV'=>'production', 'APP_DEBUG'=>'false', 'APP_KEY'=>'',
        'APP_ENVIRONMENT_ONLY'=>'false',
        'APP_URL'=>getenv('BABA_APP_URL'), 'APP_TIMEZONE'=>getenv('BABA_TIMEZONE'),
        'APP_SERVICE_AUTHOR'=>getenv('BABA_EMAIL'), 'APP_LOCALE'=>'en',
        'DB_CONNECTION'=>'mysql', 'DB_HOST'=>'127.0.0.1', 'DB_PORT'=>'3306',
        'DB_DATABASE'=>'baba_panel', 'DB_USERNAME'=>'baba_panel', 'DB_PASSWORD'=>getenv('BABA_DB_PASSWORD'),
        'CACHE_DRIVER'=>'redis', 'SESSION_DRIVER'=>'redis', 'QUEUE_CONNECTION'=>'redis',
        'REDIS_HOST'=>'127.0.0.1', 'REDIS_PASSWORD'=>'null', 'REDIS_PORT'=>'6379',
        'MAIL_MAILER'=>'log', 'MAIL_FROM_ADDRESS'=>getenv('BABA_EMAIL'), 'MAIL_FROM_NAME'=>'BABA HOST',
        'APP_TELEMETRY_ENABLED'=>'false',
    ];
    if (!in_array($values['APP_TIMEZONE'], DateTimeZone::listIdentifiers(), true)) throw new RuntimeException('Invalid timezone');
    $text = file_get_contents($panel.'/.env.example');
    foreach ($values as $key=>$value) {
        if ($value === false) throw new RuntimeException('Missing installer value: '.$key);
        $line = $key.'='.json_encode($value, JSON_UNESCAPED_SLASHES|JSON_THROW_ON_ERROR);
        if (preg_match('/^'.preg_quote($key, '/').'=/m', $text)) $text = preg_replace_callback('/^'.preg_quote($key, '/').'=.*$/m', fn()=>$line, $text);
        else $text .= "\n".$line;
    }
    if (file_put_contents($panel.'/.env', $text."\n", LOCK_EX) === false) throw new RuntimeException('Cannot write environment');
    chmod($panel.'/.env', 0640);
} elseif ($action === 'admin') {
    require $panel.'/vendor/autoload.php';
    $app = require $panel.'/bootstrap/app.php';
    $app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
    $password = getenv('BABA_ADMIN_PASSWORD');
    if ($password === false || $password === '') throw new RuntimeException('Admin password cannot be blank');
    require __DIR__.'/admin-user.php';
    createInstallerAdministrator((string)getenv('BABA_EMAIL'), (string)getenv('BABA_USERNAME'), $password);
    echo "Administrator created.\n";
} else throw new RuntimeException('Unknown installer action');
