<?php
session_start();

// Подключаем настройки базы данных, которые уже создали твои друзья
require_once __DIR__ . '/../database.php';

$action = $_POST['action'] ?? '';
$email = trim($_POST['email'] ?? '');
$password = $_POST['password'] ?? '';
$fullName = trim($_POST['full_name'] ?? '');

if (empty($email) || empty($password)) {
    die('Ошибка: заполните email и пароль. <a href="../../index.php">Вернуться</a>');
}

try {
    // 1. ЕСЛИ ПОЛЬЗОВАТЕЛЬ НАЖАЛ "SIGN UP" (РЕГИСТРАЦИЯ)
    if ($action === 'register') {
        if (empty($fullName)) {
            die('Ошибка: введите имя пользователя. <a href="../../index.php">Вернуться</a>');
        }

        // Проверяем, не занят ли email
        $checkStmt = $pdo->prepare('SELECT id FROM users WHERE email = ?');
        $checkStmt->execute([$email]);
        if ($checkStmt->fetch()) {
            die('Этот email уже зарегистрирован! <a href="../../index.php">Войти</a>');
        }

        // Шифруем пароль и записываем нового пользователя в таблицу users
        $passwordHash = password_hash($password, PASSWORD_DEFAULT);
        $insertStmt = $pdo->prepare('INSERT INTO users (full_name, email, password_hash) VALUES (?, ?, ?)');
        $insertStmt->execute([$fullName, $email, $passwordHash]);

        // Сразу авторизуем и пускаем в кабинет
        $_SESSION['user_id'] = $pdo->lastInsertId();
        $_SESSION['full_name'] = $fullName;

        header('Location: ../../frontend/pages/dashboard.php');
        exit;
    }

    // 2. ЕСЛИ ПОЛЬЗОВАТЕЛЬ НАЖАЛ "SIGN IN" (ВХОД)
    if ($action === 'login') {
        $stmt = $pdo->prepare('SELECT id, full_name, password_hash FROM users WHERE email = ?');
        $stmt->execute([$email]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        // Проверяем существование пользователя и сверяем пароль
        if ($user && password_verify($password, $user['password_hash'])) {
            $_SESSION['user_id'] = $user['id'];
            $_SESSION['full_name'] = $user['full_name'];

            header('Location: ../../frontend/pages/dashboard.php');
            exit;
        } else {
            die('Неверный email или пароль! <a href="../../index.php">Попробовать снова</a>');
        }
    }

} catch (PDOException $e) {
    die('Ошибка базы данных: ' . $e->getMessage());
}