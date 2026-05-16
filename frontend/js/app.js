const API = '/api';

/* =========================
   THEME MANAGEMENT
========================= */

function getPreferredTheme() {
    const stored = localStorage.getItem('skillpulse-theme');
    if (stored) return stored;

    return window.matchMedia('(prefers-color-scheme: dark)').matches
        ? 'dark'
        : 'light';
}

function applyTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('skillpulse-theme', theme);

    const btn = document.getElementById('theme-toggle');
    if (btn) {
        btn.textContent = theme === 'dark' ? '☀️' : '🌙';
    }
}

/* =========================
   STATE
========================= */

let skills = [];
let dashboard = {};
let currentLogSkillId = null;

/* =========================
   DOM
========================= */

const statsContainer = document.getElementById('stats');
const skillsGrid = document.getElementById('skills-grid');

const addSkillModal = document.getElementById('add-skill-modal');
const logSessionModal = document.getElementById('log-session-modal');

const addSkillForm = document.getElementById('add-skill-form');
const logSessionForm = document.getElementById('log-session-form');

/* =========================
   INIT
========================= */

document.addEventListener('DOMContentLoaded', () => {
    applyTheme(getPreferredTheme());

    const toggleBtn = document.getElementById('theme-toggle');
    if (toggleBtn) {
        toggleBtn.addEventListener('click', () => {
            const current = document.documentElement.getAttribute('data-theme');
            applyTheme(current === 'dark' ? 'light' : 'dark');
        });
    }

    loadDashboard();
    loadSkills();

    updateDateTime();
    setInterval(updateDateTime, 60000);
});

/* =========================
   LIVE DATE/TIME (UI ONLY)
========================= */

function formatDateTime() {
    const now = new Date();

    const options = {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        hour12: true
    };

    return `[${now.toLocaleString('en-GB', options)}]`;
}

function updateDateTime() {
    const el = document.getElementById("current-datetime");
    if (el) el.textContent = formatDateTime();
}

/* =========================
   API CALLS
========================= */

async function loadDashboard() {
    try {
        const res = await fetch(`${API}/dashboard`);
        dashboard = await res.json();
        renderStats();
    } catch (err) {
        console.error("Dashboard load failed", err);
    }
}

async function loadSkills() {
    try {
        const res = await fetch(`${API}/skills`);
        skills = await res.json();
        renderSkills();
    } catch (err) {
        console.error("Skills load failed", err);
    }
}

async function createSkill(data) {
    const res = await fetch(`${API}/skills`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    });

    if (!res.ok) throw new Error("Create skill failed");
    return res.json();
}

async function deleteSkill(id) {
    const res = await fetch(`${API}/skills/${id}`, {
        method: 'DELETE'
    });

    if (!res.ok) throw new Error("Delete failed");
    return res.json();
}

async function logSession(skillId, data) {
    const res = await fetch(`${API}/skills/${skillId}/log`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    });

    if (!res.ok) throw new Error("Log session failed");
    return res.json();
}

/* =========================
   RENDER
========================= */

function renderStats() {
    statsContainer.innerHTML = `
        <div class="stat-card">
            <div class="label">Total Skills</div>
            <div class="value">${dashboard.total_skills || 0}</div>
        </div>
        <div class="stat-card">
            <div class="label">Hours Logged</div>
            <div class="value">${(dashboard.total_hours || 0).toFixed(1)}</div>
        </div>
        <div class="stat-card">
            <div class="label">Sessions</div>
            <div class="value">${dashboard.total_logs || 0}</div>
        </div>
        <div class="stat-card">
            <div class="label">Top Skill</div>
            <div class="value">${dashboard.top_skill || 'N/A'}</div>
        </div>
    `;
}

function renderSkills() {
    if (!skills.length) {
        skillsGrid.innerHTML = `
            <div class="empty-state" style="grid-column:1/-1">
                <h3>No skills yet</h3>
                <p>Click Add Skill to start tracking.</p>
            </div>
        `;
        return;
    }

    skillsGrid.innerHTML = skills.map(skill => {
        const progress = skill.target_hours > 0
            ? Math.min((skill.total_hours / skill.target_hours) * 100, 100)
            : 0;

        return `
            <div class="skill-card">
                <div class="skill-header">
                    <span class="skill-name">${escapeHtml(skill.name)}</span>
                    ${skill.category ? `<span class="skill-category">${escapeHtml(skill.category)}</span>` : ''}
                </div>

                <div class="progress-bar">
                    <div class="fill" style="width:${progress}%"></div>
                </div>

                <div class="progress-text">
                    <span>${skill.total_hours.toFixed(1)} hrs</span>
                    <span>${skill.target_hours || 'No goal'}</span>
                </div>

                <div class="skill-actions">
                    <button onclick="openLogModal(${skill.id}, '${escapeHtml(skill.name)}')">
                        + Log
                    </button>

                    <button onclick="handleDelete(${skill.id})">
                        Delete
                    </button>
                </div>
            </div>
        `;
    }).join('');
}

/* =========================
   MODALS
========================= */

function openAddModal() {
    addSkillForm.reset();
    addSkillModal.classList.add('active');
}

function closeAddModal() {
    addSkillModal.classList.remove('active');
}

function openLogModal(id, name) {
    currentLogSkillId = id;

    document.getElementById('log-skill-name').textContent = name;
    document.getElementById('log-date').value = new Date().toISOString().split('T')[0];

    logSessionForm.reset();
    logSessionModal.classList.add('active');
}

function closeLogModal() {
    logSessionModal.classList.remove('active');
    currentLogSkillId = null;
}

/* =========================
   EVENTS
========================= */

addSkillForm.addEventListener('submit', async (e) => {
    e.preventDefault();

    try {
        await createSkill({
            name: document.getElementById('skill-name').value,
            category: document.getElementById('skill-category').value,
            target_hours: parseInt(document.getElementById('skill-target').value) || 0,
        });

        closeAddModal();
        loadDashboard();
        loadSkills();
    } catch (err) {
        console.error(err);
    }
});

logSessionForm.addEventListener('submit', async (e) => {
    e.preventDefault();

    try {
        await logSession(currentLogSkillId, {
            hours: parseFloat(document.getElementById('log-hours').value),
            notes: document.getElementById('log-notes').value,
            log_date: document.getElementById('log-date').value,
        });

        closeLogModal();
        loadDashboard();
        loadSkills();
    } catch (err) {
        console.error(err);
    }
});

/* =========================
   DELETE
========================= */

async function handleDelete(id) {
    if (!confirm("Delete this skill?")) return;

    try {
        await deleteSkill(id);
        loadDashboard();
        loadSkills();
    } catch (err) {
        console.error(err);
    }
}

/* =========================
   UTILS
========================= */

function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}

/* =========================
   CLOSE MODAL CLICK OUTSIDE
========================= */

document.querySelectorAll('.modal-backdrop').forEach(el => {
    el.addEventListener('click', (e) => {
        if (e.target === el) {
            el.classList.remove('active');
        }
    });
});
