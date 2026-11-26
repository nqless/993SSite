<?php
session_start();

$isDemo = isset($_GET['demo']) && $_GET['demo'] == '1';
if (!isset($_SESSION['user_id']) && !$isDemo) {
    header('Location: ../../index.php');
    exit;
}

$userName = $_SESSION['full_name'] ?? 'ЛЕХА ФИЛЮШИН';
?>
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Task Flow — Workspace</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body class="app-body">

    <div class="app-layout">
        <aside class="sidebar">
            <div class="sidebar-logo">
                <span class="logo-dot"></span>
                <span>Task Flow</span>
            </div>

            <div class="sidebar-section-label">МЕНЮ</div>
            <nav class="sidebar-nav">
                <button type="button" class="nav-item active" onclick="switchTab('tab-dashboard', this)">
                    <span class="nav-icon">&#9638;</span> Dashboard
                </button>
                <button type="button" class="nav-item" onclick="switchTab('tab-calendar', this)">
                    <span class="nav-icon">&#128197;</span> Calendar
                </button>
                <button type="button" class="nav-item" onclick="switchTab('tab-charts', this)">
                    <span class="nav-icon">&#9636;</span> Charts
                </button>
            </nav>

            <div class="sidebar-sprint-box">
                <div class="sprint-top">
                    <span>Sprint #4</span>
                    <span id="sidebarProgressText">17%</span>
                </div>
                <div class="progress-track">
                    <div class="progress-fill" id="sidebarProgressBar" style="width: 17%"></div>
                </div>
                <span class="sprint-sub">Активный спринт команды</span>
            </div>
            <div class="sidebar-focus-box">
                <div class="focus-header">
                    <span class="focus-label">FOCUS TIMER</span>
                    <span class="focus-mode-badge" id="focusModeLabel">25m</span>
                </div>
                <div class="focus-display" id="focusTimerDisplay">25:00</div>
                <div class="focus-controls">
                    <button type="button" class="btn-focus primary" id="focusStartBtn" onclick="toggleFocusTimer()">Старт</button>
                    <button type="button" class="btn-focus" onclick="resetFocusTimer()">Сброс</button>
                </div>
            </div>

            <div class="sidebar-footer">
                <div class="user-badge">
                    <div class="user-avatar"><?php echo mb_substr($userName, 0, 1); ?></div>
                    <div class="user-info">
                        <span class="user-name"><?php echo htmlspecialchars($userName); ?></span>
                        <span class="user-role"><?php echo $isDemo ? 'Demo Workspace' : 'Team Member'; ?></span>
                    </div>
                </div>
                <a href="../../index.php" class="btn-logout">Выйти из аккаунта</a>
            </div>
        </aside>

        <main class="main-content">
            <section id="tab-dashboard" class="tab-section active">
                <header class="page-header flex-between">
                    <div>
                        <h1 class="page-title">Welcome back, <?php echo htmlspecialchars($userName); ?></h1>
                        <p class="page-subtitle">Сводка посещений платформы, прогресс спринта и задачи</p>
                    </div>
                    <div class="header-pill">
                        <span class="status-pulse"></span> Система активна
                    </div>
                </header>

                <div class="stats-grid">
                    <div class="card stat-card">
                        <div class="stat-top">
                            <span class="stat-label">Total Visits</span>
                            <span class="stat-badge green">+12.4%</span>
                        </div>
                        <div class="stat-value">14 820</div>
                        <div class="mini-bars">
                            <span style="height:40%"></span><span style="height:65%"></span>
                            <span style="height:50%"></span><span style="height:80%"></span>
                            <span style="height:70%"></span><span style="height:95%"></span>
                        </div>
                    </div>

                    <div class="card stat-card">
                        <div class="stat-top">
                            <span class="stat-label">Page Views</span>
                            <span class="stat-badge green">+8.1%</span>
                        </div>
                        <div class="stat-value">42 390</div>
                        <div class="mini-bars">
                            <span style="height:55%"></span><span style="height:45%"></span>
                            <span style="height:75%"></span><span style="height:60%"></span>
                            <span style="height:85%"></span><span style="height:100%"></span>
                        </div>
                    </div>

                    <div class="card stat-card">
                        <div class="stat-top">
                            <span class="stat-label">Done Tasks</span>
                            <span class="stat-badge blue">Sprint</span>
                        </div>
                        <div class="stat-value" id="dashDoneCount">1 / 6</div>
                        <div class="progress-track sm">
                            <div class="progress-fill" id="dashDoneBar" style="width: 17%"></div>
                        </div>
                    </div>

                    <div class="card stat-card">
                        <div class="stat-top">
                            <span class="stat-label">Avg Progress</span>
                            <span class="stat-badge purple">Live</span>
                        </div>
                        <div class="stat-value" id="dashAvgProgress">17%</div>
                        <span class="stat-trend">Синхронизировано с Todo</span>
                    </div>
                </div>

                <div class="dashboard-split">
                    <div class="card chart-card">
                        <div class="card-header">
                            <div>
                                <h3>Site Visits & Activity</h3>
                                <span class="card-sub">Уникальные сессии за неделю</span>
                            </div>
                                                       <div class="chart-toggle-group">
                                <button type="button" class="chart-toggle active" onclick="switchVisitsRange('week', this)">7 дней</button>
                                <button type="button" class="chart-toggle" onclick="switchVisitsRange('month', this)">30 дней</button>
                            </div>

                        </div>
                        <div class="svg-chart-box" id="visitsChartContainer"></div>
                    </div>

                    <div class="card todo-card">
                        <div class="card-header">
                            <div>
                                <h3>Todo Lists</h3>
                                <span class="card-sub">Задачи проекта с приоритетами</span>
                            </div>
                            <span class="badge-dark" id="todoCounter">6 задач</span>
                        </div>

                        <form class="todo-add-form" onsubmit="addTodoTask(event)">
                            <input type="text" id="newTodoTitle" placeholder="Добавить задачу..." required>
                            <select id="newTodoPriority">
                                <option value="Low">Low</option>
                                <option value="Medium" selected>Medium</option>
                                <option value="High">High</option>
                                <option value="Critical">Critical</option>
                            </select>
                            <button type="submit" class="btn-add">+</button>
                        </form>
                        <div class="todo-filters">
                            <button type="button" class="filter-chip active" onclick="setTodoFilter('all', this)">All</button>
                            <button type="button" class="filter-chip" onclick="setTodoFilter('active', this)">Active</button>
                            <button type="button" class="filter-chip" onclick="setTodoFilter('done', this)">Done</button>
                        </div>

                        
                        <ul class="todo-list" id="todoListContainer"></ul>
                    </div>
                </div>
            </section>
                    <div class="dashboard-bottom-grid">
                    <div class="card">
                        <div class="card-header">
                            <div>
                                <h3>Team Members</h3>
                                <span class="card-sub">Участники разработки Task Flow</span>
                            </div>
                            <span class="badge-dark">4 онлайн</span>
                        </div>
                        <div class="team-list">
                            <div class="team-row">
                                <div class="team-left">
                                    <span class="team-ava">А</span>
                                    <div>
                                        <div class="team-name"><?php echo htmlspecialchars($userName); ?></div>
                                        <div class="team-role">Frontend </div>
                                    </div>
                                </div>
                                <span class="online-tag">Online</span>
                            </div>
                            <div class="team-row">
                                <div class="team-left">
                                    <span class="team-ava">Д</span>
                                    <div>
                                        <div class="team-name">Максим Гульчинский</div>
                                        <div class="team-role">PHP Backend</div>
                                    </div>
                                </div>
                                <span class="online-tag">Online</span>
                            </div>
                            <div class="team-row">
                                <div class="team-left">
                                    <span class="team-ava">С</span>
                                    <div>
                                        <div class="team-name">СЛАВИКК ЗАЛОГИН</div>
                                        <div class="team-role">MySQL Database</div>
                                    </div>
                                </div>
                                <span class="online-tag">Online</span>
                            </div>
                            <div class="team-row">
                                <div class="team-left">
                                    <span class="team-ava">Д</span>
                                    <div>
                                        <div class="team-name">Денчик Игнатьев</div>
                                        <div class="team-role">PHP Backend</div>
                                    </div>
                                </div>
                                <span class="online-tag">Online</span>
                            </div>

                        </div>
                    </div>

                    <div class="card">
                        <div class="card-header">
                            <div>
                                <h3>Quick Notes</h3>
                                <span class="card-sub">Личный черновик для идей и ссылок</span>
                            </div>
                            <span class="badge-dark" id="notesSavedStatus">Сохранено</span>
                        </div>
                        <textarea id="quickNotesArea" class="notes-textarea" placeholder="Запишите сюда заметку по проекту..." oninput="saveQuickNote()"></textarea>
                    </div>
                </div>
       
            <section id="tab-calendar" class="tab-section">
                <header class="page-header flex-between">
                    <div>
                        <h1 class="page-title">Calendar</h1>
                        <p class="page-subtitle">Планирование дедлайнов и задач по дням</p>
                    </div>
                    <button type="button" class="btn-secondary" onclick="goToToday()">Сегодня</button>
                </header>

                <div class="calendar-layout">
                    <div class="card calendar-box">
                        <div class="calendar-controls">
                            <button type="button" class="btn-icon" onclick="changeMonth(-1)">&#8592;</button>
                            <h2 id="calendarMonthYear">Ноябрь 2026</h2>
                            <button type="button" class="btn-icon" onclick="changeMonth(1)">&#8594;</button>
                        </div>

                        <div class="calendar-weekdays">
                            <div>Пн</div><div>Вт</div><div>Ср</div><div>Чт</div><div>Пт</div><div>Сб</div><div>Вс</div>
                        </div>

                        <div class="calendar-days" id="calendarDaysGrid"></div>
                    </div>

                    <div class="card day-details-box">
                        <div class="card-header">
                            <div>
                                <h3 id="selectedDateTitle">Дата: 2026-11-20</h3>
                                <span class="card-sub">План задач на выбранный день</span>
                            </div>
                        </div>

                        <form class="calendar-add-form" onsubmit="addCalendarEvent(event)">
                            <input type="text" id="calEventTitle" placeholder="Название задачи или цели..." required>
                            <select id="calEventPriority">
                                <option value="Low">Приоритет: Low</option>
                                <option value="Medium" selected>Приоритет: Medium</option>
                                <option value="High">Приоритет: High</option>
                                <option value="Critical">Приоритет: Critical</option>
                            </select>
                            <button type="submit" class="btn-primary-glow full-width">Добавить на эту дату</button>
                        </form>

                        <div class="day-tasks-wrapper">
                            <span class="stat-label">Задачи на день:</span>
                            <ul class="todo-list" id="dayTasksList"></ul>
                        </div>
                    </div>
                                            <div class="upcoming-box">
                            <span class="stat-label">Все ближайшие задачи:</span>
                            <ul class="todo-list compact" id="upcomingTasksList"></ul>
                        </div>
                        <div class="upcoming-box">
                            <span class="stat-label">Все ближайшие задачи:</span>
                            <ul class="todo-list compact" id="upcomingTasksList"></ul>
                        </div>

                </div>
            </section>

            <section id="tab-charts" class="tab-section">
                <header class="page-header">
                    <h1 class="page-title">Charts & Analytics</h1>
                    <p class="page-subtitle">Визуальная аналитика статусов, приоритетов и роста</p>
                </header>
                <div class="stats-grid">
                    <div class="card stat-card">
                        <span class="stat-label">Team Velocity</span>
                        <div class="stat-value">94%</div>
                        <span class="stat-trend positive">+6% к прошлому спринту</span>
                    </div>
                    <div class="card stat-card">
                        <span class="stat-label">Avg Task Time</span>
                        <div class="stat-value">1.4 дн.</div>
                        <span class="stat-trend">Среднее время закрытия</span>
                    </div>
                    <div class="card stat-card">
                        <span class="stat-label">Active Sprints</span>
                        <div class="stat-value">3</div>
                        <span class="stat-trend">В работе у команды</span>
                    </div>
                    <div class="card stat-card">
                        <span class="stat-label">SLA Compliance</span>
                        <div class="stat-value">98.2%</div>
                        <span class="stat-trend positive">Соблюдение сроков</span>
                    </div>
                </div>

                <div class="charts-legend-bar card">
                    <div class="legend-item"><span class="dot dot-white"></span> Done (Выполнено)</div>
                    <div class="legend-item"><span class="dot dot-blue"></span> In Progress (В работе)</div>
                    <div class="legend-item"><span class="dot dot-purple"></span> Review (На проверке)</div>
                    <div class="legend-item"><span class="dot dot-gray"></span> To Do (В очереди)</div>
                </div>

                <div class="charts-grid">
                    <div class="card chart-card">
                        <div class="card-header">
                            <div>
                                <h3>Задачи по статусам</h3>
                                <span class="card-sub">Распределение текущего спринта</span>
                            </div>
                        </div>
                        <div class="svg-chart-box" id="statusChartContainer"></div>
                    </div>

                    <div class="card chart-card">
                        <div class="card-header">
                            <div>
                                <h3>Приоритеты задач</h3>
                                <span class="card-sub">Количество задач по важности</span>
                            </div>
                        </div>
                        <div class="svg-chart-box" id="priorityChartContainer"></div>
                    </div>

                    <div class="card chart-card wide-card">
                        <div class="card-header">
                            <div>
                                <h3>Динамика посещений и закрытых задач (2025 vs 2026)</h3>
                                <span class="card-sub">Сравнение активности по месяцам</span>
                            </div>
                        </div>
                        <div class="svg-chart-box tall" id="trendChartContainer"></div>
                    </div>
                </div>
            </section>

        </main>
    </div>

    <!-- Всплывающая подсказка при наведении на точки графиков -->
    <div id="chartTooltip" class="chart-tooltip"></div>

    <script src="../js/app.js"></script>
</body>
</html>
