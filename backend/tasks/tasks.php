<?php
// JSON-API задач. Каждый пользователь видит и меняет только СВОИ задачи.
//   GET  ?action=list
//   POST ?action=create   {title, priority, date}
//   POST ?action=toggle   {id}
//   POST ?action=delete   {id}
// POST-запросы требуют заголовок X-CSRF-Token.
require_once __DIR__ . '/../database.php';
require_once __DIR__ . '/../auth/session.php';

$userId = require_login_api();
$action = $_GET['action'] ?? '';
$method = $_SERVER['REQUEST_METHOD'];

const PRIORITY_TO_DB = ['Low' => 'low', 'Medium' => 'medium', 'High' => 'high'];
const PRIORITY_TO_JS = ['low' => 'Low', 'medium' => 'Medium', 'high' => 'High'];
const STATUS_TO_JS   = ['todo' => 'To Do', 'in_progress' => 'In Progress', 'done' => 'Done'];

function task_to_js(array $r): array
{
    return [
        'id'       => (int) $r['id'],
        'title'    => $r['title'],
        'priority' => PRIORITY_TO_JS[$r['priority']],
        'status'   => STATUS_TO_JS[$r['status']],
        'date'     => $r['due_date'],
        'done'     => $r['status'] === 'done',
    ];
}

function fetch_task(PDO $pdo, int $id, int $userId): ?array
{
    $stmt = $pdo->prepare('SELECT id, title, priority, status, due_date FROM tasks WHERE id = ? AND user_id = ?');
    $stmt->execute([$id, $userId]);
    $row = $stmt->fetch();
    return $row ? task_to_js($row) : null;
}

$in = [];
if ($method === 'POST') {
    if (!check_csrf($_SERVER['HTTP_X_CSRF_TOKEN'] ?? null)) {
        json_out(['error' => 'Неверный CSRF-токен'], 403);
    }
    $in = json_decode(file_get_contents('php://input'), true);
    if (!is_array($in)) {
        json_out(['error' => 'Ожидался JSON'], 400);
    }
}

try {
    $pdo = db();

    if ($method === 'GET' && $action === 'list') {
        $stmt = $pdo->prepare('SELECT id, title, priority, status, due_date FROM tasks WHERE user_id = ? ORDER BY due_date DESC, id DESC');
        $stmt->execute([$userId]);
        json_out(['tasks' => array_map('task_to_js', $stmt->fetchAll())]);
    }

    if ($method === 'POST' && $action === 'create') {
        $title    = trim((string) ($in['title'] ?? ''));
        $priority = PRIORITY_TO_DB[$in['priority'] ?? 'Medium'] ?? null;
        $date     = (string) ($in['date'] ?? '');
        $d        = DateTime::createFromFormat('Y-m-d', $date);

        if ($title === '' || mb_strlen($title) > 200) {
            json_out(['error' => 'Название: от 1 до 200 символов'], 422);
        }
        if (!$priority) {
            json_out(['error' => 'Неверный приоритет'], 422);
        }
        if (!$d || $d->format('Y-m-d') !== $date) {
            json_out(['error' => 'Неверная дата'], 422);
        }

        $pdo->prepare('INSERT INTO tasks (user_id, title, priority, due_date) VALUES (?, ?, ?, ?)')
            ->execute([$userId, $title, $priority, $date]);
        json_out(['task' => fetch_task($pdo, (int) $pdo->lastInsertId(), $userId)], 201);
    }

    if ($method === 'POST' && $action === 'toggle') {
        $id = (int) ($in['id'] ?? 0);
        // done -> in_progress, иначе -> done (completed_at ставит триггер в БД)
        $pdo->prepare("UPDATE tasks SET status = IF(status = 'done', 'in_progress', 'done') WHERE id = ? AND user_id = ?")
            ->execute([$id, $userId]);
        $task = fetch_task($pdo, $id, $userId);
        if (!$task) {
            json_out(['error' => 'Задача не найдена'], 404);
        }
        json_out(['task' => $task]);
    }

    if ($method === 'POST' && $action === 'delete') {
        $stmt = $pdo->prepare('DELETE FROM tasks WHERE id = ? AND user_id = ?');
        $stmt->execute([(int) ($in['id'] ?? 0), $userId]);
        if ($stmt->rowCount() === 0) {
            json_out(['error' => 'Задача не найдена'], 404);
        }
        json_out(['ok' => true]);
    }

    json_out(['error' => 'Неизвестное действие'], 400);
} catch (PDOException $e) {
    error_log('TaskFlow DB error: ' . $e->getMessage());
    json_out(['error' => 'Ошибка базы данных'], 500);
}
