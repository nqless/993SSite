<?php
// Общие функции авторизации. Подключается в каждом защищённом файле.

function start_session(): void
{
    if (session_status() === PHP_SESSION_ACTIVE) {
        return;
    }
    session_set_cookie_params([
        'lifetime' => 0,           // кука живёт до закрытия браузера
        'path'     => '/',
        'httponly' => true,        // JS не видит куку сессии
        'samesite' => 'Lax',
        'secure'   => !empty($_SERVER['HTTPS']),
    ]);
    session_start();
}

function is_logged_in(): bool
{
    start_session();
    return !empty($_SESSION['user_id']);
}

// Для страниц: не вошёл — отправляем на главную. $loginUrl — путь до index.php
function require_login_page(string $loginUrl): void
{
    if (!is_logged_in()) {
        header('Location: ' . $loginUrl);
        exit;
    }
    // чтобы после «Выйти» кнопка «Назад» не показывала кабинет из кэша
    header('Cache-Control: no-store, no-cache, must-revalidate');
}

// Для JSON-API: не вошёл — 401
function require_login_api(): int
{
    if (!is_logged_in()) {
        json_out(['error' => 'Требуется вход'], 401);
    }
    return (int) $_SESSION['user_id'];
}

function csrf_token(): string
{
    start_session();
    if (empty($_SESSION['csrf'])) {
        $_SESSION['csrf'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf'];
}

function check_csrf(?string $token): bool
{
    start_session();
    return !empty($_SESSION['csrf']) && is_string($token) && hash_equals($_SESSION['csrf'], $token);
}

function json_out(array $data, int $code = 200): void
{
    http_response_code($code);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}
