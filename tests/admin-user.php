<?php
declare(strict_types=1);
// Optional integration test against a disposable, migrated Panel database.
$panel = $argv[1] ?? '';
if (!$panel || getenv('BABA_DISPOSABLE_DB') !== '1') throw new RuntimeException('Run only with a disposable Panel database and BABA_DISPOSABLE_DB=1');
require $panel.'/vendor/autoload.php';
$app = require $panel.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
$expectedDatabase = getenv('DB_DATABASE');
if (!$expectedDatabase || !preg_match('/^baba_password_test_[0-9]+$/', $expectedDatabase) || config('database.connections.mysql.database') !== $expectedDatabase) throw new RuntimeException('Disposable database configuration not active');
require __DIR__.'/../scripts/admin-user.php';
Illuminate\Support\Facades\Notification::fake();
$connection = Illuminate\Support\Facades\DB::connection();
$initialLevel = $connection->transactionLevel();
$initialCount = Pterodactyl\Models\User::count();
$connection->beginTransaction();
try {
    foreach (['a', '123', '0', 'lowercase', '  literal $\\ spaces  '] as $password) {
        $suffix = bin2hex(random_bytes(6));
        $user = createInstallerAdministrator('test-'.$suffix.'@example.invalid', 'baba_test_'.$suffix, $password);
        if (!$user->root_admin || !Illuminate\Support\Facades\Hash::check($password, $user->fresh()->password)) throw new RuntimeException('Admin password round trip failed');
    }
    try {
        createInstallerAdministrator('blank@example.invalid', 'blank_test', '');
        throw new LogicException('Blank password unexpectedly accepted');
    } catch (RuntimeException $e) {
        if ($e->getMessage() !== 'Admin password cannot be blank') throw $e;
    }
} finally {
    while ($connection->transactionLevel() > $initialLevel) $connection->rollBack();
}
if (Pterodactyl\Models\User::count() !== $initialCount) throw new RuntimeException('Test did not roll back');
echo "PASS: real admin creation and hash verification for five password formats; blank rejected; test users rolled back.\n";
