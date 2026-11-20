function openModal(id) {
    const el = document.getElementById(id);
    if (el) el.classList.add('active');
}

function closeModal(id) {
    const el = document.getElementById(id);
    if (el) el.classList.remove('active');
}

function closeModalOnBg(event, id) {
    if (event.target.id === id) closeModal(id);
}

function demoEnter() {
    window.location.href = 'frontend/pages/dashboard.php?demo=1';
}

function switchTab(tabId, btn) {
    document.querySelectorAll('.tab-section').forEach(sec => sec.classList.remove('active'));
    document.querySelectorAll('.nav-item').forEach(item => item.classList.remove('active'));
    const target = document.getElementById(tabId);
    if (target) target.classList.add('active');
    if (btn) btn.classList.add('active');
    renderAllCharts();
}

let tasksData = [
    { id: 1, title: 'Сверстать главную страницу', priority: 'High', status: 'In Progress', date: '2026-11-20', done: false },
    { id: 2, title: 'Создать базу данных taskflow', priority: 'Critical', status: 'Done', date: '2026-11-05', done: true },
    { id: 3, title: 'Исправить форму входа', priority: 'Medium', status: 'To Do', date: '2026-11-25', done: false },
    { id: 4, title: 'Подготовить рекламные баннеры', priority: 'Medium', status: 'Review', date: '2026-11-15', done: false },
    { id: 5, title: 'Составить медиаплан', priority: 'Low', status: 'To Do', date: '2026-12-01', done: false },
    { id: 6, title: 'Настроить адаптив для мобильных', priority: 'High', status: 'In Progress', date: '2026-11-20', done: false }
];

let currentTodoFilter = 'all';

function setTodoFilter(filterType, btn) {
    currentTodoFilter = filterType;
    document.querySelectorAll('.filter-chip').forEach(chip => chip.classList.remove('active'));
    if (btn) btn.classList.add('active');
    renderTodoList();
}

function renderTodoList() {
    const list = document.getElementById('todoListContainer');
    if (!list) return;

    const filteredTasks = tasksData.filter(task => {
        if (currentTodoFilter === 'active') return !task.done;
        if (currentTodoFilter === 'done') return task.done;
        return true;
    });

    list.innerHTML = '';
    if (filteredTasks.length === 0) {
        list.innerHTML = '<li class="stat-label">В этой категории задач нет</li>';
        updateDashboardStats();
        return;
    }

    filteredTasks.forEach(task => {
        const li = document.createElement('li');
        li.className = 'todo-item';
        li.innerHTML = `
            <div class="todo-left">
                <input type="checkbox" ${task.done ? 'checked' : ''} onchange="toggleTask(${task.id})">
                <span class="todo-text ${task.done ? 'done' : ''}">${task.title}</span>
            </div>
            <div class="todo-right">
                <span class="todo-tag ${task.priority}">${task.priority}</span>
                <button type="button" class="btn-del-task" onclick="deleteTask(${task.id})">&times;</button>
            </div>
        `;
        list.appendChild(li);
    });

    updateDashboardStats();
}

function toggleTask(id) {
    const task = tasksData.find(t => t.id === id);
    if (task) {
        task.done = !task.done;
        task.status = task.done ? 'Done' : 'In Progress';
        renderTodoList();
        renderDayTasks();
        renderAllCharts();
    }
}

function deleteTask(id) {
    tasksData = tasksData.filter(t => t.id !== id);
    renderTodoList();
    renderCalendar();
    renderAllCharts();
}

function addTodoTask(event) {
    event.preventDefault();
    const titleInput = document.getElementById('newTodoTitle');
    const prioritySelect = document.getElementById('newTodoPriority');
    const title = titleInput.value.trim();
    if (!title) return;

    const todayStr = new Date().toISOString().split('T').at(0);
    tasksData.unshift({
        id: Date.now(),
        title: title,
        priority: prioritySelect.value,
        status: 'To Do',
        date: todayStr,
        done: false
    });

    titleInput.value = '';
    renderTodoList();
    renderCalendar();
    renderAllCharts();
}

function updateDashboardStats() {
    const total = tasksData.length;
    const done = tasksData.filter(t => t.done).length;
    const progress = total > 0 ? Math.round((done / total) * 100) : 0;

    const doneEl = document.getElementById('dashDoneCount');
    const progEl = document.getElementById('dashAvgProgress');
    const countEl = document.getElementById('todoCounter');
    const sideText = document.getElementById('sidebarProgressText');
    const sideBar = document.getElementById('sidebarProgressBar');
    const dashBar = document.getElementById('dashDoneBar');

    if (doneEl) doneEl.textContent = `${done} / ${total}`;
    if (progEl) progEl.textContent = `${progress}%`;
    if (countEl) countEl.textContent = `${total} задач`;
    if (sideText) sideText.textContent = `${progress}%`;
    if (sideBar) sideBar.style.width = `${progress}%`;
    if (dashBar) dashBar.style.width = `${progress}%`;
}
let currentCalDate = new Date(2026, 10, 1);
let selectedDateStr = '2026-11-20';

const monthNames = new Array(
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
);

function renderCalendar() {
    const grid = document.getElementById('calendarDaysGrid');
    const header = document.getElementById('calendarMonthYear');
    if (!grid || !header) return;

    const year = currentCalDate.getFullYear();
    const month = currentCalDate.getMonth();
    header.textContent = `${monthNames.at(month)} ${year}`;
    grid.innerHTML = '';

    const firstDayIndex = (new Date(year, month, 1).getDay() + 6) % 7;
    const daysInMonth = new Date(year, month + 1, 0).getDate();

    for (let i = 0; i < firstDayIndex; i++) {
        const empty = document.createElement('div');
        empty.className = 'cal-day empty';
        grid.appendChild(empty);
    }

    for (let day = 1; day <= daysInMonth; day++) {
        const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
        const hasTasks = tasksData.some(t => t.date === dateStr);
        const isToday = dateStr === '2026-11-20';

        const cell = document.createElement('div');
        cell.className = `cal-day ${dateStr === selectedDateStr ? 'selected' : ''} ${isToday ? 'today' : ''}`;
        cell.innerHTML = `<span>${day}</span>${hasTasks ? '<span class="cal-dot"></span>' : ''}`;
        cell.onclick = () => selectCalendarDay(dateStr);
        grid.appendChild(cell);
    }

    renderDayTasks();
}

function changeMonth(step) {
    currentCalDate.setMonth(currentCalDate.getMonth() + step);
    renderCalendar();
}

function goToToday() {
    currentCalDate = new Date(2026, 10, 1);
    selectedDateStr = '2026-11-20';
    renderCalendar();
}

function selectCalendarDay(dateStr) {
    selectedDateStr = dateStr;
    renderCalendar();
}

function renderDayTasks() {
    const titleEl = document.getElementById('selectedDateTitle');
    const listEl = document.getElementById('dayTasksList');
    if (!titleEl || !listEl) return;

    titleEl.textContent = `Дата: ${selectedDateStr}`;
    const dayTasks = tasksData.filter(t => t.date === selectedDateStr);
    listEl.innerHTML = '';

    if (dayTasks.length === 0) {
        listEl.innerHTML = '<li class="stat-label">На этот день задач пока нет</li>';
        return;
    }

    dayTasks.forEach(task => {
        const li = document.createElement('li');
        li.className = 'todo-item';
        li.innerHTML = `
            <div class="todo-left">
                <input type="checkbox" ${task.done ? 'checked' : ''} onchange="toggleTask(${task.id})">
                <span class="todo-text ${task.done ? 'done' : ''}">${task.title}</span>
            </div>
            <div class="todo-right">
                <span class="todo-tag ${task.priority}">${task.priority}</span>
                <button type="button" class="btn-del-task" onclick="deleteTask(${task.id})">&times;</button>
            </div>
        `;
        listEl.appendChild(li);
    });
}

function addCalendarEvent(event) {
    event.preventDefault();
    const input = document.getElementById('calEventTitle');
    const prioSelect = document.getElementById('calEventPriority');
    const title = input.value.trim();
    if (!title) return;

    tasksData.push({
        id: Date.now(),
        title: title,
        priority: prioSelect ? prioSelect.value : 'Medium',
        status: 'To Do',
        date: selectedDateStr,
        done: false
    });

    input.value = '';
    renderTodoList();
    renderCalendar();
    renderAllCharts();
}

let focusSecondsLeft = 25 * 60;
let focusInterval = null;

function updateFocusDisplay() {
    const display = document.getElementById('focusTimerDisplay');
    if (!display) return;
    const mins = String(Math.floor(focusSecondsLeft / 60)).padStart(2, '0');
    const secs = String(focusSecondsLeft % 60).padStart(2, '0');
    display.textContent = `${mins}:${secs}`;
}

function toggleFocusTimer() {
    const btn = document.getElementById('focusStartBtn');
    if (focusInterval) {
        clearInterval(focusInterval);
        focusInterval = null;
        if (btn) { btn.textContent = 'Старт'; btn.classList.remove('running'); }
        return;
    }
    if (btn) { btn.textContent = 'Пауза'; btn.classList.add('running'); }
    focusInterval = setInterval(() => {
        if (focusSecondsLeft > 0) {
            focusSecondsLeft--;
            updateFocusDisplay();
        } else {
            resetFocusTimer();
            alert('Время фокусировки (25 минут) завершено!');
        }
    }, 1000);
}

function resetFocusTimer() {
    if (focusInterval) { clearInterval(focusInterval); focusInterval = null; }
    focusSecondsLeft = 25 * 60;
    updateFocusDisplay();
    const btn = document.getElementById('focusStartBtn');
    if (btn) { btn.textContent = 'Старт'; btn.classList.remove('running'); }
}
let visitsRangeMode = 'week';

function switchVisitsRange(mode, btn) {
    visitsRangeMode = mode;
    document.querySelectorAll('.chart-toggle').forEach(b => b.classList.remove('active'));
    if (btn) btn.classList.add('active');
    renderVisitsSvg();
}

function showChartTip(event, text) {
    const tip = document.getElementById('chartTooltip');
    if (!tip) return;
    tip.textContent = text;
    tip.style.left = event.clientX + 'px';
    tip.style.top = event.clientY + 'px';
    tip.classList.add('visible');
}

function hideChartTip() {
    const tip = document.getElementById('chartTooltip');
    if (tip) tip.classList.remove('visible');
}

function renderAllCharts() {
    renderVisitsSvg();
    renderStatusSvg();
    renderPrioritySvg();
    renderTrendSvg();
}

function renderVisitsSvg() {
    const box = document.getElementById('visitsChartContainer');
    if (!box) return;

    const isWeek = visitsRangeMode === 'week';
    const labels = isWeek ? new Array('Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс') : new Array('Нед 1', 'Нед 2', 'Нед 3', 'Нед 4', 'Нед 5', 'Нед 6', 'Нед 7');
    const values = isWeek ? new Array(1240, 1890, 1520, 2340, 2890, 2110, 3420) : new Array(6400, 8100, 7900, 10200, 11800, 13400, 14820);
    const coordsY = isWeek ? new Array(140, 105, 120, 75, 55, 85, 30) : new Array(145, 125, 130, 95, 70, 48, 25);
    const coordsX = new Array(40, 110, 180, 250, 320, 390, 460);

    let polyPts = '';
    let circlesHtml = '';
    let labelsHtml = '';

    for (let i = 0; i < coordsX.length; i++) {
        const x = coordsX.at(i);
        const y = coordsY.at(i);
        polyPts += `${x},${y} `;
        circlesHtml += `<circle class="svg-point" cx="${x}" cy="${y}" r="4.5" fill="#FFFFFF" onmousemove="showChartTip(event, '${labels.at(i)}: ${values.at(i)} визитов')" onmouseleave="hideChartTip()"/>`;
        labelsHtml += `<text x="${x - 10}" y="185" fill="#8E92A4" font-size="11">${labels.at(i)}</text>`;
    }

    box.innerHTML = `
        <svg viewBox="0 0 500 200" width="100%" height="100%">
            <defs><linearGradient id="visitGrad" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#FFFFFF" stop-opacity="0.32"/><stop offset="100%" stop-color="#FFFFFF" stop-opacity="0"/></linearGradient></defs>
            <line x1="30" y1="40" x2="480" y2="40" stroke="rgba(255,255,255,0.06)"/>
            <line x1="30" y1="95" x2="480" y2="95" stroke="rgba(255,255,255,0.06)"/>
            <line x1="30" y1="150" x2="480" y2="150" stroke="rgba(255,255,255,0.06)"/>
            <polygon points="${polyPts} 460,165 40,165" fill="url(#visitGrad)"/>
            <polyline fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" points="${polyPts}"/>
            ${circlesHtml}${labelsHtml}
        </svg>
    `;
}

function renderStatusSvg() {
    const box = document.getElementById('statusChartContainer');
    if (!box) return;
    const total = tasksData.length || 1;
    const done = tasksData.filter(t => t.status === 'Done').length;
    const prog = tasksData.filter(t => t.status === 'In Progress').length;
    const rev = tasksData.filter(t => t.status === 'Review').length;
    const todo = tasksData.filter(t => t.status === 'To Do').length;

    const c = 2 * Math.PI * 62;
    const dLen = (done / total) * c;
    const pLen = (prog / total) * c;
    const rLen = (rev / total) * c;
    const tLen = (todo / total) * c;

    box.innerHTML = `
        <svg viewBox="0 0 320 200" width="100%" height="100%">
            <g transform="translate(100,100) rotate(-90)">
                <circle r="62" cx="0" cy="0" fill="none" stroke="#1B1D24" stroke-width="18"/>
                <circle class="svg-bar" r="62" cx="0" cy="0" fill="none" stroke="#FFFFFF" stroke-width="18" stroke-dasharray="${dLen} ${c}" onmousemove="showChartTip(event, 'Done: ${done} задач')" onmouseleave="hideChartTip()"/>
                <circle class="svg-bar" r="62" cx="0" cy="0" fill="none" stroke="#3B82F6" stroke-width="18" stroke-dasharray="${pLen} ${c}" stroke-dashoffset="${-dLen}" onmousemove="showChartTip(event, 'In Progress: ${prog} задач')" onmouseleave="hideChartTip()"/>
                <circle class="svg-bar" r="62" cx="0" cy="0" fill="none" stroke="#8B5CF6" stroke-width="18" stroke-dasharray="${rLen} ${c}" stroke-dashoffset="${-(dLen + pLen)}" onmousemove="showChartTip(event, 'Review: ${rev} задач')" onmouseleave="hideChartTip()"/>
                <circle class="svg-bar" r="62" cx="0" cy="0" fill="none" stroke="#4B5563" stroke-width="18" stroke-dasharray="${tLen} ${c}" stroke-dashoffset="${-(dLen + pLen + rLen)}" onmousemove="showChartTip(event, 'To Do: ${todo} задач')" onmouseleave="hideChartTip()"/>
            </g>
            <text x="100" y="96" text-anchor="middle" fill="#FFFFFF" font-size="22" font-weight="700">${total}</text>
            <text x="100" y="114" text-anchor="middle" fill="#8E92A4" font-size="11">задач</text>
            <text x="195" y="65" fill="#FFFFFF" font-size="12">Done: ${done}</text>
            <text x="195" y="90" fill="#60A5FA" font-size="12">In Progress: ${prog}</text>
            <text x="195" y="115" fill="#A78BFA" font-size="12">Review: ${rev}</text>
            <text x="195" y="140" fill="#9CA3AF" font-size="12">To Do: ${todo}</text>
        </svg>
    `;
}

function renderPrioritySvg() {
    const box = document.getElementById('priorityChartContainer');
    if (!box) return;
    const low = tasksData.filter(t => t.priority === 'Low').length;
    const med = tasksData.filter(t => t.priority === 'Medium').length;
    const high = tasksData.filter(t => t.priority === 'High').length;
    const crit = tasksData.filter(t => t.priority === 'Critical').length;
    const maxVal = Math.max(low, med, high, crit, 1);

    const h1 = (low / maxVal) * 110 + 12;
    const h2 = (med / maxVal) * 110 + 12;
    const h3 = (high / maxVal) * 110 + 12;
    const h4 = (crit / maxVal) * 110 + 12;

    box.innerHTML = `
        <svg viewBox="0 0 360 200" width="100%" height="100%">
            <rect class="svg-bar" x="45" y="${155 - h1}" width="44" height="${h1}" rx="6" fill="#4B5563" onmousemove="showChartTip(event, 'Low: ${low} задач')" onmouseleave="hideChartTip()"/>
            <text x="67" y="${147 - h1}" text-anchor="middle" fill="#FFFFFF" font-size="12">${low}</text>
            <text x="67" y="178" text-anchor="middle" fill="#8E92A4" font-size="11">Low</text>
            <rect class="svg-bar" x="120" y="${155 - h2}" width="44" height="${h2}" rx="6" fill="#3B82F6" onmousemove="showChartTip(event, 'Medium: ${med} задач')" onmouseleave="hideChartTip()"/>
            <text x="142" y="${147 - h2}" text-anchor="middle" fill="#FFFFFF" font-size="12">${med}</text>
            <text x="142" y="178" text-anchor="middle" fill="#8E92A4" font-size="11">Medium</text>
            <rect class="svg-bar" x="195" y="${155 - h3}" width="44" height="${h3}" rx="6" fill="#8B5CF6" onmousemove="showChartTip(event, 'High: ${high} задач')" onmouseleave="hideChartTip()"/>
            <text x="217" y="${147 - h3}" text-anchor="middle" fill="#FFFFFF" font-size="12">${high}</text>
            <text x="217" y="178" text-anchor="middle" fill="#8E92A4" font-size="11">High</text>
            <rect class="svg-bar" x="270" y="${155 - h4}" width="44" height="${h4}" rx="6" fill="#FFFFFF" onmousemove="showChartTip(event, 'Critical: ${crit} задач')" onmouseleave="hideChartTip()"/>
            <text x="292" y="${147 - h4}" text-anchor="middle" fill="#FFFFFF" font-size="12">${crit}</text>
            <text x="292" y="178" text-anchor="middle" fill="#8E92A4" font-size="11">Critical</text>
        </svg>
    `;
}

function renderTrendSvg() {
    const box = document.getElementById('trendChartContainer');
    if (!box) return;
    const months = new Array('Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек');
    const xs = new Array(60, 175, 290, 405, 520, 635);
    const y2026 = new Array(145, 120, 95, 80, 55, 30);
    const y2025 = new Array(155, 140, 130, 115, 100, 85);
    const v2026 = new Array(45, 62, 84, 98, 124, 156);
    const v2025 = new Array(30, 38, 44, 52, 61, 74);

    let pts26 = '', pts25 = '', dotsHtml = '', labelsHtml = '';
    for (let i = 0; i < xs.length; i++) {
        const x = xs.at(i);
        pts26 += `${x},${y2026.at(i)} `;
        pts25 += `${x},${y2025.at(i)} `;
        dotsHtml += `<circle class="svg-point" cx="${x}" cy="${y2026.at(i)}" r="4.5" fill="#FFFFFF" onmousemove="showChartTip(event, '${months.at(i)} 2026: ${v2026.at(i)} задач')" onmouseleave="hideChartTip()"/>`;
        dotsHtml += `<circle class="svg-point" cx="${x}" cy="${y2025.at(i)}" r="4" fill="#3B82F6" onmousemove="showChartTip(event, '${months.at(i)} 2025: ${v2025.at(i)} задач')" onmouseleave="hideChartTip()"/>`;
        labelsHtml += `<text x="${x - 12}" y="195" fill="#8E92A4" font-size="12">${months.at(i)}</text>`;
    }

    box.innerHTML = `
        <svg viewBox="0 0 700 220" width="100%" height="100%">
            <line x1="40" y1="40" x2="660" y2="40" stroke="rgba(255,255,255,0.06)"/>
            <line x1="40" y1="100" x2="660" y2="100" stroke="rgba(255,255,255,0.06)"/>
            <line x1="40" y1="160" x2="660" y2="160" stroke="rgba(255,255,255,0.06)"/>
            <polyline fill="none" stroke="#3B82F6" stroke-width="2.5" stroke-dasharray="5,5" points="${pts25}"/>
            <polyline fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" points="${pts26}"/>
            ${dotsHtml}${labelsHtml}
            <text x="520" y="22" fill="#FFFFFF" font-size="12">— 2026 (Текущий год)</text>
            <text x="350" y="22" fill="#60A5FA" font-size="12">--- 2025 (Прошлый год)</text>
        </svg>
    `;
}

document.addEventListener('DOMContentLoaded', () => {
    renderTodoList();
    renderCalendar();
    renderAllCharts();
});
// =========================================
// БЫСТРЫЕ ЗАМЕТКИ И СПИСОК ДЕДЛАЙНОВ
// =========================================
function saveQuickNote() {
    const area = document.getElementById('quickNotesArea');
    const status = document.getElementById('notesSavedStatus');
    if (!area) return;
    localStorage.setItem('taskflow_notes', area.value);
    if (status) {
        status.textContent = 'Сохранено';
    }
}

function loadQuickNote() {
    const area = document.getElementById('quickNotesArea');
    if (!area) return;
    const saved = localStorage.getItem('taskflow_notes');
    if (saved) area.value = saved;
}

function renderUpcomingTasks() {
    const box = document.getElementById('upcomingTasksList');
    if (!box) return;
    const upcoming = tasksData.filter(t => !t.done);
    box.innerHTML = '';

    if (upcoming.length === 0) {
        box.innerHTML = '<li class="stat-label">Все задачи выполнены!</li>';
        return;
    }

    upcoming.forEach(task => {
        const li = document.createElement('li');
        li.className = 'todo-item';
        li.innerHTML = `
            <span class="todo-text">${task.title}</span>
            <span class="todo-tag ${task.priority}">${task.date}</span>
        `;
        box.appendChild(li);
    });
}

document.addEventListener('DOMContentLoaded', () => {
    loadQuickNote();
    renderUpcomingTasks();
});
