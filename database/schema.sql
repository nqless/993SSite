-- =====================================================================
--  TaskFlow — веб-приложение для управления задачами
--  Возможности: создание задач, распределение между участниками команды,
--  отслеживание прогресса выполнения.
--  СУБД: MySQL 8.0 (нужна версия 8.0.16+ из-за CHECK-ограничений)
--  Интерфейс: Bulma Admin Dashboard Template (mazipan)
--
--  backend/config/database.php:
--     db_host = 'MySQL-8.0', db_name = 'taskflow', db_user = 'root', db_pass = ''
--  Импорт:  mysql -u root < taskflow.sql   (или через phpMyAdmin)
--  Внимание: скрипт пересоздаёт базу taskflow с нуля.
-- =====================================================================

SET NAMES utf8mb4;

DROP DATABASE IF EXISTS taskflow;
CREATE DATABASE taskflow
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE taskflow;

-- ---------------------------------------------------------------------
-- 1. СПРАВОЧНИКИ
-- ---------------------------------------------------------------------

-- Роли в системе (колонка "Grup" в таблицах шаблона)
CREATE TABLE roles (
  id          TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name        VARCHAR(50)  NOT NULL,
  description VARCHAR(255) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_roles_name (name)
) ENGINE=InnoDB;

-- Отделы (поле "Department" в форме обратной связи)
CREATE TABLE departments (
  id   SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_departments_name (name)
) ENGINE=InnoDB;

-- Статусы задач (колонки канбан-доски)
CREATE TABLE task_statuses (
  id         TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name       VARCHAR(50) NOT NULL,
  sort_order TINYINT UNSIGNED NOT NULL DEFAULT 0,
  is_final   TINYINT(1) NOT NULL DEFAULT 0,       -- 1 = задача завершена
  PRIMARY KEY (id),
  UNIQUE KEY uq_task_statuses_name (name)
) ENGINE=InnoDB;

-- Приоритеты задач
CREATE TABLE task_priorities (
  id    TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name  VARCHAR(50) NOT NULL,
  level TINYINT UNSIGNED NOT NULL,                -- чем больше, тем важнее
  PRIMARY KEY (id),
  UNIQUE KEY uq_task_priorities_name (name)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. ПОЛЬЗОВАТЕЛИ И КОМАНДЫ
-- ---------------------------------------------------------------------
CREATE TABLE users (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  role_id       TINYINT UNSIGNED NOT NULL,
  department_id SMALLINT UNSIGNED NULL,
  full_name     VARCHAR(120) NOT NULL,
  email         VARCHAR(150) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,            -- результат password_hash() из PHP
  phone         VARCHAR(30)  NULL,
  city          VARCHAR(100) NULL,
  country       VARCHAR(100) NULL,
  birth_date    DATE NULL,
  avatar_url    VARCHAR(255) NULL,
  is_active     TINYINT(1) NOT NULL DEFAULT 1,
  last_login_at DATETIME NULL,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email),
  KEY idx_users_role (role_id),
  KEY idx_users_department (department_id),
  CONSTRAINT fk_users_role
    FOREIGN KEY (role_id) REFERENCES roles (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_users_department
    FOREIGN KEY (department_id) REFERENCES departments (id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- Команды
CREATE TABLE teams (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name        VARCHAR(120) NOT NULL,
  description VARCHAR(500) NULL,
  lead_id     INT UNSIGNED NULL,                  -- руководитель команды
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_teams_name (name),
  KEY idx_teams_lead (lead_id),
  CONSTRAINT fk_teams_lead
    FOREIGN KEY (lead_id) REFERENCES users (id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- Участники команд (многие-ко-многим)
CREATE TABLE team_members (
  team_id     INT UNSIGNED NOT NULL,
  user_id     INT UNSIGNED NOT NULL,
  member_role ENUM('lead','member','viewer') NOT NULL DEFAULT 'member',
  joined_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (team_id, user_id),
  KEY idx_tm_user (user_id),
  CONSTRAINT fk_tm_team
    FOREIGN KEY (team_id) REFERENCES teams (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_tm_user
    FOREIGN KEY (user_id) REFERENCES users (id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. ПРОЕКТЫ
-- ---------------------------------------------------------------------
CREATE TABLE projects (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  team_id     INT UNSIGNED NOT NULL,              -- какая команда работает над проектом
  owner_id    INT UNSIGNED NOT NULL,
  name        VARCHAR(150) NOT NULL,
  description TEXT NULL,
  status      ENUM('planned','active','on_hold','completed','archived')
              NOT NULL DEFAULT 'active',
  start_date  DATE NULL,
  end_date    DATE NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_projects_team (team_id),
  KEY idx_projects_owner (owner_id),
  KEY idx_projects_status (status),
  CONSTRAINT fk_projects_team
    FOREIGN KEY (team_id) REFERENCES teams (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_projects_owner
    FOREIGN KEY (owner_id) REFERENCES users (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_projects_dates
    CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. ЗАДАЧИ
-- ---------------------------------------------------------------------
CREATE TABLE tasks (
  id               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  project_id       INT UNSIGNED NOT NULL,
  parent_task_id   INT UNSIGNED NULL,             -- подзадача (необязательно)
  title            VARCHAR(200) NOT NULL,
  description      TEXT NULL,
  status_id        TINYINT UNSIGNED NOT NULL,
  priority_id      TINYINT UNSIGNED NOT NULL,
  creator_id       INT UNSIGNED NOT NULL,         -- кто создал задачу
  due_date         DATE NULL,                     -- срок выполнения
  estimated_hours  DECIMAL(6,2) NULL,
  spent_hours      DECIMAL(6,2) NOT NULL DEFAULT 0,
  progress_percent TINYINT UNSIGNED NOT NULL DEFAULT 0,   -- прогресс 0..100
  completed_at     DATETIME NULL,
  created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_tasks_project (project_id),
  KEY idx_tasks_parent (parent_task_id),
  KEY idx_tasks_status (status_id),
  KEY idx_tasks_priority (priority_id),
  KEY idx_tasks_creator (creator_id),
  KEY idx_tasks_due (due_date),
  CONSTRAINT fk_tasks_project
    FOREIGN KEY (project_id) REFERENCES projects (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_tasks_parent
    FOREIGN KEY (parent_task_id) REFERENCES tasks (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_tasks_status
    FOREIGN KEY (status_id) REFERENCES task_statuses (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_tasks_priority
    FOREIGN KEY (priority_id) REFERENCES task_priorities (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_tasks_creator
    FOREIGN KEY (creator_id) REFERENCES users (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_tasks_progress CHECK (progress_percent BETWEEN 0 AND 100)
) ENGINE=InnoDB;

-- Распределение задач между участниками (одна задача — несколько исполнителей)
CREATE TABLE task_assignees (
  task_id     INT UNSIGNED NOT NULL,
  user_id     INT UNSIGNED NOT NULL,
  assigned_by INT UNSIGNED NULL,                  -- кто назначил
  assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (task_id, user_id),
  KEY idx_ta_user (user_id),
  CONSTRAINT fk_ta_task
    FOREIGN KEY (task_id) REFERENCES tasks (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_ta_user
    FOREIGN KEY (user_id) REFERENCES users (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_ta_assigned_by
    FOREIGN KEY (assigned_by) REFERENCES users (id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- Чек-лист внутри задачи (из него можно считать прогресс)
CREATE TABLE task_checklist_items (
  id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  task_id      INT UNSIGNED NOT NULL,
  title        VARCHAR(200) NOT NULL,
  is_done      TINYINT(1) NOT NULL DEFAULT 0,
  sort_order   SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  done_by      INT UNSIGNED NULL,
  done_at      DATETIME NULL,
  PRIMARY KEY (id),
  KEY idx_tci_task (task_id),
  CONSTRAINT fk_tci_task
    FOREIGN KEY (task_id) REFERENCES tasks (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_tci_user
    FOREIGN KEY (done_by) REFERENCES users (id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- История смены статусов и прогресса (отслеживание выполнения)
CREATE TABLE task_status_history (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  task_id         INT UNSIGNED NOT NULL,
  old_status_id   TINYINT UNSIGNED NULL,
  new_status_id   TINYINT UNSIGNED NOT NULL,
  old_progress    TINYINT UNSIGNED NULL,
  new_progress    TINYINT UNSIGNED NULL,
  changed_by      INT UNSIGNED NULL,
  changed_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_tsh_task (task_id, changed_at),
  CONSTRAINT fk_tsh_task
    FOREIGN KEY (task_id) REFERENCES tasks (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_tsh_old
    FOREIGN KEY (old_status_id) REFERENCES task_statuses (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_tsh_new
    FOREIGN KEY (new_status_id) REFERENCES task_statuses (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_tsh_user
    FOREIGN KEY (changed_by) REFERENCES users (id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE task_comments (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  task_id    INT UNSIGNED NOT NULL,
  user_id    INT UNSIGNED NOT NULL,
  body       TEXT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_tc_task (task_id),
  KEY idx_tc_user (user_id),
  CONSTRAINT fk_tc_task
    FOREIGN KEY (task_id) REFERENCES tasks (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_tc_user
    FOREIGN KEY (user_id) REFERENCES users (id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE tags (
  id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name  VARCHAR(50) NOT NULL,
  color VARCHAR(7) NOT NULL DEFAULT '#3273dc',
  PRIMARY KEY (id),
  UNIQUE KEY uq_tags_name (name)
) ENGINE=InnoDB;

CREATE TABLE task_tags (
  task_id INT UNSIGNED NOT NULL,
  tag_id  INT UNSIGNED NOT NULL,
  PRIMARY KEY (task_id, tag_id),
  CONSTRAINT fk_tt_task
    FOREIGN KEY (task_id) REFERENCES tasks (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_tt_tag
    FOREIGN KEY (tag_id) REFERENCES tags (id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE attachments (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  task_id     INT UNSIGNED NOT NULL,
  uploaded_by INT UNSIGNED NOT NULL,
  file_name   VARCHAR(255) NOT NULL,
  file_path   VARCHAR(500) NOT NULL,
  file_size   INT UNSIGNED NULL,
  mime_type   VARCHAR(100) NULL,
  uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_att_task (task_id),
  CONSTRAINT fk_att_task
    FOREIGN KEY (task_id) REFERENCES tasks (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_att_user
    FOREIGN KEY (uploaded_by) REFERENCES users (id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. ОБРАТНАЯ СВЯЗЬ (страница Forms шаблона), УВЕДОМЛЕНИЯ, ЖУРНАЛ
-- ---------------------------------------------------------------------
CREATE TABLE feedback_messages (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id       INT UNSIGNED NULL,
  department_id SMALLINT UNSIGNED NULL,
  sender_name   VARCHAR(120) NULL,
  sender_phone  VARCHAR(30)  NULL,
  is_member     TINYINT(1) NOT NULL DEFAULT 0,    -- "Already a member?"
  subject       VARCHAR(200) NOT NULL,
  question      TEXT NOT NULL,
  sentiment     ENUM('positive','negative','neutral') NOT NULL DEFAULT 'neutral',
  status        ENUM('new','in_progress','answered','closed') NOT NULL DEFAULT 'new',
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_fb_user (user_id),
  KEY idx_fb_department (department_id),
  KEY idx_fb_sentiment (sentiment),
  CONSTRAINT fk_fb_user
    FOREIGN KEY (user_id) REFERENCES users (id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_fb_department
    FOREIGN KEY (department_id) REFERENCES departments (id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE notifications (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id    INT UNSIGNED NOT NULL,
  message    VARCHAR(255) NOT NULL,
  link       VARCHAR(255) NULL,
  is_read    TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_notif_user_read (user_id, is_read),
  CONSTRAINT fk_notif_user
    FOREIGN KEY (user_id) REFERENCES users (id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE activity_log (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id     INT UNSIGNED NULL,
  action      VARCHAR(50) NOT NULL,
  entity_type VARCHAR(50) NOT NULL,
  entity_id   INT UNSIGNED NULL,
  details     JSON NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_log_user (user_id),
  KEY idx_log_entity (entity_type, entity_id),
  CONSTRAINT fk_log_user
    FOREIGN KEY (user_id) REFERENCES users (id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- =====================================================================
--  ТЕСТОВЫЕ ДАННЫЕ
--  Вместо CHANGE_ME_HASH вставьте реальные хэши, например в PHP:
--     echo password_hash('admin123', PASSWORD_DEFAULT);
-- =====================================================================

INSERT INTO roles (name, description) VALUES
  ('Admin',   'Полный доступ к системе'),
  ('Manager', 'Создаёт проекты и задачи, распределяет их между участниками'),
  ('User',    'Выполняет назначенные задачи и отмечает прогресс');

INSERT INTO departments (name) VALUES
  ('Business development'), ('Marketing'), ('Sales');

INSERT INTO task_statuses (name, sort_order, is_final) VALUES
  ('To Do', 1, 0), ('In Progress', 2, 0), ('Review', 3, 0), ('Done', 4, 1);

INSERT INTO task_priorities (name, level) VALUES
  ('Low', 1), ('Medium', 2), ('High', 3), ('Critical', 4);

INSERT INTO users
  (role_id, department_id, full_name, email, password_hash, phone, city, country, birth_date)
VALUES
  (1, 1, 'Анна Смирнова',  'anna@taskflow.test',  'CHANGE_ME_HASH', '+79000000001', 'Москва', 'Россия', '1995-08-12'),
  (2, 2, 'Иван Петров',    'ivan@taskflow.test',  'CHANGE_ME_HASH', '+79000000002', 'Казань', 'Россия', '1996-12-25'),
  (3, 3, 'Мария Иванова',  'maria@taskflow.test', 'CHANGE_ME_HASH', NULL,           'Москва', 'Россия', '1998-01-20'),
  (3, 3, 'Олег Сидоров',   'oleg@taskflow.test',  'CHANGE_ME_HASH', NULL,           'Тверь',  'Россия', '1999-11-09'),
  (3, 2, 'Елена Кузнецова','elena@taskflow.test', 'CHANGE_ME_HASH', NULL,           'Казань', 'Россия', '2001-01-11');

INSERT INTO teams (name, description, lead_id) VALUES
  ('Разработка', 'Команда веб-разработки', 1),
  ('Маркетинг',  'Команда продвижения',    2);

INSERT INTO team_members (team_id, user_id, member_role) VALUES
  (1, 1, 'lead'), (1, 3, 'member'), (1, 4, 'member'),
  (2, 2, 'lead'), (2, 5, 'member');

INSERT INTO projects (team_id, owner_id, name, description, status, start_date, end_date) VALUES
  (1, 1, 'Website Redesign', 'Обновление корпоративного сайта', 'active', '2026-09-01', '2026-12-31'),
  (2, 2, 'Marketing Q4',     'Рекламная кампания на 4 квартал', 'active', '2026-10-01', '2026-12-31');

INSERT INTO tags (name, color) VALUES
  ('bug', '#ff3860'), ('feature', '#23d160'), ('design', '#3273dc');

INSERT INTO tasks
  (project_id, title, description, status_id, priority_id, creator_id,
   due_date, estimated_hours, spent_hours, progress_percent, completed_at)
VALUES
  (1, 'Сверстать главную страницу', 'Адаптивная вёрстка на Bulma',           2, 3, 1, '2026-11-20', 12, 5, 40,  NULL),
  (1, 'Создать базу данных taskflow','Спроектировать и импортировать схему', 4, 4, 1, '2026-11-05', 6,  6, 100, '2026-11-04 18:00:00'),
  (1, 'Исправить форму входа',       'Не проходит валидация e-mail',         1, 2, 1, '2026-11-25', 3,  0, 0,   NULL),
  (2, 'Подготовить рекламные баннеры','Три формата для соцсетей',            3, 2, 2, '2026-11-15', 8,  7, 85,  NULL),
  (2, 'Составить медиаплан',         'План размещения на декабрь',           1, 1, 2, '2026-12-01', 4,  0, 0,   NULL);

INSERT INTO task_assignees (task_id, user_id, assigned_by) VALUES
  (1, 3, 1), (1, 4, 1),
  (2, 4, 1),
  (3, 3, 1),
  (4, 5, 2),
  (5, 5, 2);

INSERT INTO task_checklist_items (task_id, title, is_done, sort_order, done_by, done_at) VALUES
  (1, 'Шапка и меню',         1, 1, 3, '2026-11-03 12:00:00'),
  (1, 'Блок с карточками',    1, 2, 4, '2026-11-05 15:30:00'),
  (1, 'Подвал сайта',         0, 3, NULL, NULL),
  (1, 'Адаптив под телефон',  0, 4, NULL, NULL);

INSERT INTO task_status_history
  (task_id, old_status_id, new_status_id, old_progress, new_progress, changed_by, changed_at)
VALUES
  (2, 1, 2, 0,  30,  4, '2026-11-01 10:00:00'),
  (2, 2, 4, 30, 100, 4, '2026-11-04 18:00:00');

INSERT INTO task_tags (task_id, tag_id) VALUES (1,3), (1,2), (2,2), (3,1), (4,3);

INSERT INTO task_comments (task_id, user_id, body) VALUES
  (1, 1, 'Начни с мобильной версии.'),
  (3, 3, 'Воспроизвела баг, исправлю на этой неделе.');

INSERT INTO feedback_messages
  (user_id, department_id, sender_name, sender_phone, is_member, subject, question, sentiment, status)
VALUES
  (3,    3, 'Мария Иванова', '+79000000003', 1, 'Вопрос по задачам', 'Как добавить исполнителя к задаче?', 'neutral',  'answered'),
  (NULL, 2, 'Гость',         NULL,           0, 'Отзыв о сервисе',  'Очень удобный интерфейс, спасибо!',   'positive', 'new');

INSERT INTO notifications (user_id, message, link) VALUES
  (3, 'Вам назначена задача «Сверстать главную страницу»',       '/tasks/1'),
  (5, 'Вам назначена задача «Подготовить рекламные баннеры»',   '/tasks/4');

INSERT INTO activity_log (user_id, action, entity_type, entity_id, details) VALUES
  (1, 'create', 'project', 1, JSON_OBJECT('name', 'Website Redesign')),
  (1, 'create', 'task',    2, JSON_OBJECT('title', 'Создать базу данных taskflow'));

-- =====================================================================
--  ТРИГГЕРЫ (создаются после тестовых данных, чтобы не мешать импорту)
-- =====================================================================

-- При переводе задачи в финальный статус: прогресс = 100 %, ставим дату
-- завершения; при возврате в работу дата завершения сбрасывается.
CREATE TRIGGER trg_tasks_before_update
BEFORE UPDATE ON tasks
FOR EACH ROW
SET NEW.progress_percent =
      IF((SELECT is_final FROM task_statuses WHERE id = NEW.status_id) = 1, 100, NEW.progress_percent),
    NEW.completed_at =
      IF((SELECT is_final FROM task_statuses WHERE id = NEW.status_id) = 1,
         COALESCE(NEW.completed_at, NOW()), NULL);

-- Автоматическая запись в историю при изменении статуса или прогресса.
-- (changed_by приложение может обновить отдельно, либо вести через activity_log)
CREATE TRIGGER trg_tasks_after_update
AFTER UPDATE ON tasks
FOR EACH ROW
INSERT INTO task_status_history
  (task_id, old_status_id, new_status_id, old_progress, new_progress)
SELECT NEW.id, OLD.status_id, NEW.status_id, OLD.progress_percent, NEW.progress_percent
FROM DUAL
WHERE OLD.status_id <> NEW.status_id
   OR OLD.progress_percent <> NEW.progress_percent;

-- =====================================================================
--  ПРЕДСТАВЛЕНИЯ — готовые запросы для страниц сайта
-- =====================================================================

-- Список задач с исполнителями и прогрессом (таблица задач / канбан)
CREATE VIEW v_task_overview AS
SELECT
  t.id,
  t.title,
  p.name   AS project,
  tm.name  AS team,
  s.name   AS status,
  pr.name  AS priority,
  t.progress_percent,
  t.due_date,
  (t.due_date < CURDATE() AND s.is_final = 0) AS is_overdue,
  cr.full_name AS creator,
  GROUP_CONCAT(u.full_name ORDER BY u.full_name SEPARATOR ', ') AS assignees
FROM tasks t
JOIN projects        p  ON p.id  = t.project_id
JOIN teams           tm ON tm.id = p.team_id
JOIN task_statuses   s  ON s.id  = t.status_id
JOIN task_priorities pr ON pr.id = t.priority_id
JOIN users           cr ON cr.id = t.creator_id
LEFT JOIN task_assignees ta ON ta.task_id = t.id
LEFT JOIN users      u  ON u.id  = ta.user_id
GROUP BY t.id, t.title, p.name, tm.name, s.name, pr.name, t.progress_percent,
         t.due_date, s.is_final, cr.full_name;

-- Прогресс по проектам
CREATE VIEW v_project_progress AS
SELECT
  p.id,
  p.name AS project,
  tm.name AS team,
  COUNT(t.id) AS total_tasks,
  COALESCE(SUM(s.is_final = 1), 0) AS done_tasks,
  COALESCE(ROUND(AVG(t.progress_percent), 1), 0) AS avg_progress,
  COALESCE(SUM(s.is_final = 0 AND t.due_date < CURDATE()), 0) AS overdue_tasks
FROM projects p
JOIN teams tm ON tm.id = p.team_id
LEFT JOIN tasks t ON t.project_id = p.id
LEFT JOIN task_statuses s ON s.id = t.status_id
GROUP BY p.id, p.name, tm.name;

-- Нагрузка и результативность участников команд
CREATE VIEW v_user_workload AS
SELECT
  u.id,
  u.full_name,
  r.name AS role,
  COUNT(t.id) AS assigned_tasks,
  COALESCE(SUM(s.is_final = 0), 0) AS open_tasks,
  COALESCE(SUM(s.is_final = 1), 0) AS done_tasks,
  COALESCE(ROUND(AVG(t.progress_percent), 1), 0) AS avg_progress
FROM users u
JOIN roles r ON r.id = u.role_id
LEFT JOIN task_assignees ta ON ta.user_id = u.id
LEFT JOIN tasks t ON t.id = ta.task_id
LEFT JOIN task_statuses s ON s.id = t.status_id
GROUP BY u.id, u.full_name, r.name;

-- Диаграмма «задачи по статусам»
CREATE VIEW v_tasks_by_status AS
SELECT s.name AS status, COUNT(t.id) AS cnt
FROM task_statuses s
LEFT JOIN tasks t ON t.status_id = s.id
GROUP BY s.id, s.name, s.sort_order
ORDER BY s.sort_order;

-- Карточки Dashboard
CREATE VIEW v_dashboard_stats AS
SELECT
  (SELECT COUNT(*) FROM tasks)                                           AS total_tasks,
  (SELECT COUNT(*) FROM tasks t JOIN task_statuses s ON s.id = t.status_id
     WHERE s.is_final = 1)                                               AS done_tasks,
  (SELECT COUNT(*) FROM tasks t JOIN task_statuses s ON s.id = t.status_id
     WHERE s.is_final = 0 AND t.due_date < CURDATE())                    AS overdue_tasks,
  (SELECT COALESCE(ROUND(AVG(progress_percent), 1), 0) FROM tasks)       AS avg_progress,
  (SELECT COUNT(*) FROM projects WHERE status = 'active')                AS active_projects,
  (SELECT COUNT(*) FROM teams)                                           AS teams_count,
  (SELECT COUNT(*) FROM users WHERE is_active = 1)                       AS active_users,
  (SELECT COUNT(*) FROM feedback_messages WHERE sentiment = 'positive')  AS feedback_positive,
  (SELECT COUNT(*) FROM feedback_messages WHERE sentiment = 'negative')  AS feedback_negative;
