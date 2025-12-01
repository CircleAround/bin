#!/usr/bin/env node
// git-wt-web.js - Web UI for git-wt status monitoring

const http = require('http');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PORT = process.env.PORT || 3456;

// Get repository info from git
function getRepoInfo() {
  try {
    const root = execSync('git worktree list | head -n1 | awk \'{print $1}\'', { encoding: 'utf8' }).trim();
    const repo = path.basename(root);
    const wroot = path.join(path.dirname(root), `${repo}.worktrees`);
    return { root, repo, wroot };
  } catch (e) {
    return null;
  }
}

// Get worktree info
function getWorktreeInfo(wroot, num) {
  const worktreePath = path.join(wroot, String(num));
  if (!fs.existsSync(worktreePath)) return null;

  let branch = '-';
  try {
    branch = execSync(`git -C "${worktreePath}" rev-parse --abbrev-ref HEAD`, { encoding: 'utf8' }).trim();
  } catch (e) {}

  return { path: worktreePath, branch };
}

// Read status file
function readStatus(wroot, num) {
  const statusFile = path.join(wroot, '.status', `${num}.json`);
  if (!fs.existsSync(statusFile)) return null;

  try {
    return JSON.parse(fs.readFileSync(statusFile, 'utf8'));
  } catch (e) {
    return null;
  }
}

// Format relative time
function formatRelativeTime(timestamp) {
  if (!timestamp) return '';
  const then = new Date(timestamp.replace(' ', 'T'));
  const now = new Date();
  const diff = Math.floor((now - then) / 1000);

  if (diff < 60) return 'now';
  if (diff < 3600) return `${Math.floor(diff / 60)}分前`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}時間前`;
  return `${Math.floor(diff / 86400)}日前`;
}

// Get status icon and label
function getStatusDisplay(status) {
  switch (status) {
    case 'asking': return { icon: '🙋', label: '選択待ち', class: 'asking' };
    case 'waiting': return { icon: '⏳', label: '入力待ち', class: 'waiting' };
    case 'active': return { icon: '●', label: '作業中', class: 'active' };
    case 'done': return { icon: '✓', label: '完了', class: 'done' };
    default: return { icon: '', label: '', class: '' };
  }
}

// Generate HTML
function generateHTML(repoInfo) {
  const { root, repo, wroot } = repoInfo;

  let mainBranch = '-';
  try {
    mainBranch = execSync(`git -C "${root}" rev-parse --abbrev-ref HEAD`, { encoding: 'utf8' }).trim();
  } catch (e) {}

  let worktreesHTML = '';

  // Main repo
  worktreesHTML += `
    <div class="worktree main">
      <div class="header">
        <span class="num">[0]</span>
        <span class="branch">${mainBranch}</span>
        <span class="label">(main)</span>
      </div>
    </div>
  `;

  // Worktrees 1-9
  for (let num = 1; num <= 9; num++) {
    const wtInfo = getWorktreeInfo(wroot, num);
    if (!wtInfo) continue;

    const status = readStatus(wroot, num) || {};
    const statusDisplay = getStatusDisplay(status.status);
    const relativeTime = formatRelativeTime(status.updated);

    worktreesHTML += `
    <div class="worktree ${statusDisplay.class}">
      <div class="header">
        <span class="num">[${num}]</span>
        <span class="branch">${wtInfo.branch}</span>
        ${statusDisplay.icon ? `<span class="status-badge ${statusDisplay.class}">${statusDisplay.icon} ${statusDisplay.label}</span>` : ''}
        ${relativeTime ? `<span class="time">${relativeTime}</span>` : ''}
      </div>
      ${status.first_task ? `<div class="first-task"><span class="icon">📋</span> ${escapeHtml(status.first_task)}</div>` : ''}
      ${status.last_task && status.last_task !== status.first_task ? `<div class="last-task"><span class="icon">└─</span> ${escapeHtml(status.last_task)}</div>` : ''}
      ${status.claude_msg ? `<div class="claude-msg"><span class="icon">🤖</span> ${escapeHtml(status.claude_msg)}</div>` : ''}
    </div>
    `;
  }

  if (worktreesHTML.split('class="worktree"').length <= 2) {
    worktreesHTML += '<div class="no-worktrees">(ワークツリーなし)</div>';
  }

  return `<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="refresh" content="2">
  <title>git-wt status - ${repo}</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      background: #1a1a2e;
      color: #eee;
      padding: 20px;
      min-height: 100vh;
    }
    h1 {
      font-size: 1.5rem;
      margin-bottom: 20px;
      color: #888;
      border-bottom: 1px solid #333;
      padding-bottom: 10px;
    }
    h1 span { color: #4fc3f7; }
    .worktree {
      background: #16213e;
      border-radius: 8px;
      padding: 16px;
      margin-bottom: 12px;
      border-left: 4px solid #333;
      transition: all 0.2s;
    }
    .worktree.main { border-left-color: #888; opacity: 0.7; }
    .worktree.active { border-left-color: #4caf50; }
    .worktree.waiting { border-left-color: #ff9800; }
    .worktree.asking { border-left-color: #e91e63; }
    .worktree.done { border-left-color: #2196f3; }
    .header {
      display: flex;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
    }
    .num {
      font-weight: bold;
      color: #888;
      font-family: monospace;
    }
    .branch {
      font-weight: bold;
      color: #4fc3f7;
      font-family: monospace;
    }
    .label { color: #666; font-size: 0.9rem; }
    .status-badge {
      font-size: 0.85rem;
      padding: 2px 8px;
      border-radius: 4px;
      background: #333;
    }
    .status-badge.active { background: #1b5e20; color: #a5d6a7; }
    .status-badge.waiting { background: #e65100; color: #ffcc80; }
    .status-badge.asking { background: #880e4f; color: #f48fb1; }
    .status-badge.done { background: #0d47a1; color: #90caf9; }
    .time {
      color: #666;
      font-size: 0.85rem;
      margin-left: auto;
    }
    .first-task, .last-task, .claude-msg {
      margin-top: 8px;
      padding-left: 24px;
      font-size: 0.95rem;
      line-height: 1.5;
    }
    .first-task { color: #fff; }
    .last-task { color: #aaa; font-size: 0.9rem; }
    .claude-msg { color: #81c784; font-size: 0.9rem; }
    .icon { margin-right: 8px; }
    .no-worktrees {
      color: #666;
      text-align: center;
      padding: 40px;
    }
    .footer {
      margin-top: 20px;
      text-align: center;
      color: #444;
      font-size: 0.8rem;
    }
  </style>
</head>
<body>
  <h1>git-wt status <span>${repo}</span></h1>
  ${worktreesHTML}
  <div class="footer">Auto-refresh: 2s | ${new Date().toLocaleTimeString('ja-JP')}</div>
</body>
</html>`;
}

function escapeHtml(text) {
  if (!text) return '';
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// Start server
const repoInfo = getRepoInfo();
if (!repoInfo) {
  console.error('Error: Not a git repository');
  process.exit(1);
}

const server = http.createServer((req, res) => {
  if (req.url === '/' || req.url === '/index.html') {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(generateHTML(repoInfo));
  } else if (req.url === '/api/status') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    const statuses = {};
    for (let num = 1; num <= 9; num++) {
      const status = readStatus(repoInfo.wroot, num);
      if (status) statuses[num] = status;
    }
    res.end(JSON.stringify(statuses));
  } else {
    res.writeHead(404);
    res.end('Not Found');
  }
});

server.listen(PORT, () => {
  console.log(`git-wt web UI running at http://localhost:${PORT}`);
  console.log(`Repository: ${repoInfo.repo}`);
  console.log('Press Ctrl+C to stop');
});
