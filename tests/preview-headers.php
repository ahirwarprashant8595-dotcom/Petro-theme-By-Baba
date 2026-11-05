<?php
declare(strict_types=1);
$panel = $argv[1] ?? '';
if (!$panel) throw new RuntimeException('Pass a Panel path with installed vendor dependencies');
require $panel.'/vendor/autoload.php';
if (isset($argv[2])) require $argv[2];
$middleware = new Pterodactyl\Http\Middleware\SetSecurityHeaders();
$cases = [
    ['/', 'GET', true, 'SAMEORIGIN'], ['/account', 'GET', true, 'SAMEORIGIN'],
    ['/server/test', 'GET', true, 'SAMEORIGIN'], ['/', 'GET', false, 'DENY'],
    ['/', 'GET', null, 'DENY'], ['/', 'POST', true, 'DENY'],
    ['/api/client', 'GET', true, 'DENY'], ['/admin/users', 'GET', true, 'DENY'],
];
foreach ($cases as [$path, $method, $admin, $expected]) {
    $request = Illuminate\Http\Request::create('https://panel.example.test'.$path, $method);
    $request->setUserResolver(fn()=>$admin === null ? null : (object)['root_admin'=>$admin]);
    $response = $middleware->handle($request, fn()=>new Illuminate\Http\Response('preview-test'));
    if ($response->headers->get('X-Frame-Options') !== $expected) throw new RuntimeException('Wrong framing policy for '.$path.' '.$method);
    if ($expected === 'SAMEORIGIN' && $response->headers->get('Content-Security-Policy') !== "frame-ancestors 'self'") throw new RuntimeException('Missing same-origin CSP');
    if ($response->headers->get('X-Content-Type-Options') !== 'nosniff') throw new RuntimeException('Other protection lost');
}
echo "PASS: admin preview, ordinary/anonymous users, API, POST and admin-page framing policies.\n";
