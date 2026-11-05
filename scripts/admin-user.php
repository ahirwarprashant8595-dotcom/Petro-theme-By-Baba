<?php
declare(strict_types=1);

function createInstallerAdministrator(string $email, string $username, string $password): Pterodactyl\Models\User
{
    if ($password === '') throw new RuntimeException('Admin password cannot be blank');
    return Illuminate\Support\Facades\DB::transaction(function () use ($email, $username, $password) {
        // Upstream treats the literal "0" as empty. Create safely, then store its real hash.
        $user = app(Pterodactyl\Services\Users\UserCreationService::class)->handle([
            'email'=>$email, 'username'=>$username, 'name_first'=>'Panel', 'name_last'=>'Admin',
            'password'=>$password === '0' ? bin2hex(random_bytes(32)) : $password,
            'root_admin'=>true,
        ]);
        if ($password === '0') {
            $user->password = Illuminate\Support\Facades\Hash::make($password);
            $user->saveOrFail();
        }
        return $user;
    });
}
