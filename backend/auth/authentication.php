<?php
// Регистрация, вход и выход.
//   POST action=login     login, password
//   POST action=register  username, email, password, full_name
//   GET  action=logout
require_once __DIR__ . '/../database.php';
require_once __DIR__ . '/session.php';

start_session();

const HOME      = '../../index.php';
const DASHBOARD = '../../frontend/pages/dashboard.php';
const MAX_FAILS = 5;     // попыток входа
const LOCK_SECS = 300;   // блокировка на 5 минут

function back(string $modal, string $error): void
{
    $_SESSION['flash'] = ['modal' => $modal, 'error' => $error];
    header('Location: ' . HOME);
    exit;
}

function login_user(array $u): void
{
    session_regenerate_id(true);   // защита от подмены сессии
    $_SESSION['user_id']   = (int) $u['id'];
    $_SESSION['username']  = $u['username'];
    $_SESSION['full_name'] = $u['full_name'] ?: $u['username'];
    header('Location: ' . DASHBOARD);
    exit;
}

$action = $_POST['action'] ?? $_GET['action'] ?? '';

// ---------- ВЫХОД ----------
if ($action === 'logout') {
    $_SESSION = [];
    if (ini_get('session.use_cookies')) {
        $p = session_get_cookie_params();
        setcookie(session_name(), '', time() - 3600, $p['path'], $p['domain'], $p['secure'], $p['httponly']);
    }
    session_destroy();
    header('Location: ' . HOME);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: ' . HOME);
    exit;
}

// ---------- ВХОД: только логин + пароль ----------
if ($action === 'login') {
    $login    = trim($_POST['login'] ?? '');
    $password = $_POST['password'] ?? '';

    if (($_SESSION['lock_until'] ?? 0) > time()) {
        back('modalSignIn', 'Слишком много попыток. Подождите несколько минут.');
    }
    if ($login === '' || $password === '') {
        back('modalSignIn', 'Введите логин и пароль.');
    }

    $stmt = db()->prepare('SELECT id, username, full_name, password_hash FROM users WHERE username = ?');
    $stmt->execute([$login]);
    $user = $stmt->fetch();

    // Если логина нет — всё равно тратим столько же времени, чтобы ответ не выдавал «такого логина нет»
    $hash = $user['password_hash'] ?? password_hash('dummy', PASSWORD_DEFAULT);

    if (!$user || !password_verify($password, $hash)) {
        $_SESSION['fails'] = ($_SESSION['fails'] ?? 0) + 1;
        if ($_SESSION['fails'] >= MAX_FAILS) {
            $_SESSION['lock_until'] = time() + LOCK_SECS;
            $_SESSION['fails'] = 0;
        }
        back('modalSignIn', 'Неверный логин или пароль.');
    }

    // пароль верный: обновляем хэш до актуального алгоритма и время входа
    if (password_needs_rehash($user['password_hash'], PASSWORD_DEFAULT)) {
        db()->prepare('UPDATE users SET password_hash = ? WHERE id = ?')
            ->execute([password_hash($password, PASSWORD_DEFAULT), $user['id']]);
    }
    db()->prepare('UPDATE users SET last_login_at = NOW() WHERE id = ?')->execute([$user['id']]);

    unset($_SESSION['fails'], $_SESSION['lock_until']);
    login_user($user);
}

// ---------- РЕГИСТРАЦИЯ ----------
if ($action === 'register') {
    $username = trim($_POST['username'] ?? '');
    $email    = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';
    $fullName = trim($_POST['full_name'] ?? '');

    if (!preg_match('/^[A-Za-z0-9_]{3,50}$/', $username)) {
        back('modalSignUp', 'Логин: 3–50 символов, только латиница, цифры и _.');
    }
    if (!filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($email) > 150) {
        back('modalSignUp', 'Некорректный e-mail.');
    }
    if (strlen($password) < 8) {
        back('modalSignUp', 'Пароль должен быть не короче 8 символов.');
    }
    if (mb_strlen($fullName) > 120) {
        back('modalSignUp', 'Имя слишком длинное.');
    }

    try {
        $stmt = db()->prepare(
            'INSERT INTO users (username, email, password_hash, full_name) VALUES (?, ?, ?, ?)'
        );
        $stmt->execute([$username, $email, password_hash($password, PASSWORD_DEFAULT), $fullName ?: null]);
    } catch (PDOException $e) {
        if ($e->getCode() === '23000') {   // нарушение UNIQUE
            back('modalSignUp', 'Такой логин или e-mail уже занят.');
        }
        throw $e;
    }

    login_user([
        'id'        => db()->lastInsertId(),
        'username'  => $username,
        'full_name' => $fullName,
    ]);
}

header('Location: ' . HOME);
