<?php
session_start();
// Если пользователь уже вошел в систему (друзья запишут user_id в сессию), сразу пускаем в кабинет
if (isset($_SESSION['user_id'])) {
    header('Location: frontend/pages/dashboard.php');
    exit;
}
?>
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Task Flow — Управление задачами</title>
    <link rel="stylesheet" href="frontend/css/style.css">
</head>
<body class="landing-body">

    <!-- Верхняя панель с кнопками Sign In / Sign Up -->
    <header class="landing-header">
        <div class="auth-buttons">
            <button type="button" class="btn-link" onclick="openModal('modalSignIn')">sign in</button>
            <button type="button" class="btn-link" onclick="openModal('modalSignUp')">sign up</button>
        </div>
    </header>

    <!-- Центральный экран с карточкой Task Flow из твоего макета Figma -->
    <main class="landing-main">
        <div class="hero-card" onclick="openModal('modalSignIn')">
            <h1 class="hero-title">Task Flow</h1>
            <p class="hero-subtitle">Welcome!</p>
        </div>
        <p class="landing-hint">Для доступа к рабочему пространству необходимо войти или зарегистрироваться</p>
    </main>

    <!-- МОДАЛЬНОЕ ОКНО: SIGN IN (Вход) -->
    <div id="modalSignIn" class="modal-overlay" onclick="closeModalOnBg(event, 'modalSignIn')">
        <div class="modal-box">
            <button type="button" class="modal-close" onclick="closeModal('modalSignIn')">&times;</button>
            <h2 class="modal-title">Sign In</h2>
            
            <!-- Форма отправляет данные в PHP-файл друзей backend/auth/authentication.php -->
            <form action="backend/auth/authentication.php" method="POST" class="auth-form" id="formSignIn">
                <input type="hidden" name="action" value="login">
                
                <div class="form-group">
                    <label for="login-email">email</label>
                    <input type="email" id="login-email" name="email" placeholder="anna@taskflow.test" required>
                </div>

                <div class="form-group">
                    <label for="login-password">password</label>
                    <input type="password" id="login-password" name="password" placeholder="••••••••" required>
                </div>

                <button type="submit" class="btn-primary-glow">Continue</button>
            </form>

            <!-- Кнопка быстрого демо-входа (чтобы ты мог тестировать дизайн, пока друзья дописывают PHP) -->
            <button type="button" class="btn-demo" onclick="demoEnter()">Войти в демо-режим (без БД)</button>
        </div>
    </div>

    <!-- МОДАЛЬНОЕ ОКНО: SIGN UP (Регистрация) -->
    <div id="modalSignUp" class="modal-overlay" onclick="closeModalOnBg(event, 'modalSignUp')">
        <div class="modal-box">
            <button type="button" class="modal-close" onclick="closeModal('modalSignUp')">&times;</button>
            <h2 class="modal-title">Sign Up</h2>
            
            <form action="backend/auth/authentication.php" method="POST" class="auth-form" id="formSignUp">
                <input type="hidden" name="action" value="register">

                <div class="form-group">
                    <label for="reg-name">create new user name</label>
                    <input type="text" id="reg-name" name="full_name" placeholder="Иван Иванов" required>
                </div>

                <div class="form-group">
                    <label for="reg-email">email</label>
                    <input type="email" id="reg-email" name="email" placeholder="user@taskflow.test" required>
                </div>

                <div class="form-group">
                    <label for="reg-password">password</label>
                    <input type="password" id="reg-password" name="password" placeholder="••••••••" required>
                </div>

                <button type="submit" class="btn-primary-glow">Create Account</button>
            </form>
        </div>
    </div>

    <script src="frontend/js/app.js"></script>
</body>
</html>
