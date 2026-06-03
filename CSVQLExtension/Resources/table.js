'use strict';

// ─── State ──────────────────────────────────────────────────────
var allRows = [];          // original rows (arrays of strings)
var filteredRows = [];     // rows after search filter
var sortColIndex = -1;
var sortAsc = true;
var totalFileRows = 0;     // total rows in file (may exceed displayed rows)
var ROW_H = 28;            // px — must match CSS --row-height
var WINDOW = 60;           // rendered rows in DOM at once
var scrollTop = 0;
var startIdx = 0;          // first rendered row index in filteredRows
var searchTimer = null;
var colCount = 0;

// ─── Entry point (called by Swift after page load) ───────────────
function initTable(headers, rows, totalRows, isDark, fileName) {
  document.body.classList.remove('theme-light', 'theme-dark');
  document.body.classList.add(isDark ? 'theme-dark' : 'theme-light');

  allRows = rows;
  filteredRows = rows;
  totalFileRows = totalRows;
  colCount = headers.length;

  document.getElementById('file-name').textContent = fileName;

  buildHeader(headers);
  updateStatus();
  renderWindow(0);

  var container = document.getElementById('table-container');
  container.addEventListener('scroll', onScroll, { passive: true });

  var searchInput = document.getElementById('search-input');
  searchInput.addEventListener('input', onSearchInput);
  searchInput.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') { searchInput.value = ''; applyFilter(''); }
  });

  if (totalFileRows > rows.length) {
    var notice = document.getElementById('truncation-notice');
    if (notice) {
      notice.textContent = 'Showing first ' + fmt(rows.length) + ' of ' + fmt(totalFileRows) + ' rows';
      notice.style.display = 'block';
    }
  }
}

// ─── Header ─────────────────────────────────────────────────────
function buildHeader(headers) {
  var thead = document.getElementById('csv-thead');
  var tr = document.createElement('tr');

  // Row number column
  var th0 = document.createElement('th');
  th0.className = 'row-num-col';
  th0.textContent = '#';
  tr.appendChild(th0);

  headers.forEach(function(h, i) {
    var th = document.createElement('th');
    th.textContent = h || ('Column ' + (i + 1));
    th.title = h;
    th.dataset.col = i;
    th.addEventListener('click', function() { sortBy(i, th); });
    tr.appendChild(th);
  });

  thead.appendChild(tr);
}

// ─── Virtual scroll ──────────────────────────────────────────────
function totalHeight() {
  return filteredRows.length * ROW_H;
}

function renderWindow(newStart) {
  newStart = Math.max(0, Math.min(newStart, Math.max(0, filteredRows.length - WINDOW)));
  startIdx = newStart;

  var endIdx = Math.min(startIdx + WINDOW, filteredRows.length);
  var tbody = document.getElementById('csv-tbody');

  // Top spacer
  document.getElementById('top-spacer').style.height = (startIdx * ROW_H) + 'px';
  // Bottom spacer
  var remaining = filteredRows.length - endIdx;
  document.getElementById('bottom-spacer').style.height = (remaining * ROW_H) + 'px';

  // Build rows
  var html = '';
  for (var i = startIdx; i < endIdx; i++) {
    var row = filteredRows[i];
    html += '<tr>';
    // Row number
    html += '<td class="row-num-col">' + (i + 1) + '</td>';
    for (var j = 0; j < colCount; j++) {
      var cell = row[j] !== undefined ? escapeHtml(row[j]) : '';
      html += '<td title="' + cell + '">' + cell + '</td>';
    }
    html += '</tr>';
  }
  tbody.innerHTML = html;
}

function onScroll() {
  var container = document.getElementById('table-container');
  var newScrollTop = container.scrollTop;
  scrollTop = newScrollTop;
  var newStart = Math.floor(scrollTop / ROW_H) - 10;
  renderWindow(newStart);
}

// ─── Sort ────────────────────────────────────────────────────────
function sortBy(colIndex, thEl) {
  // Toggle direction
  if (sortColIndex === colIndex) {
    sortAsc = !sortAsc;
  } else {
    sortColIndex = colIndex;
    sortAsc = true;
  }

  // Clear all sort classes
  var headers = document.querySelectorAll('#csv-thead th');
  headers.forEach(function(th) { th.classList.remove('sort-asc', 'sort-desc'); });
  thEl.classList.add(sortAsc ? 'sort-asc' : 'sort-desc');

  var col = colIndex;
  var asc = sortAsc;

  filteredRows.sort(function(a, b) {
    var va = a[col] || '';
    var vb = b[col] || '';

    // Numeric sort if both parse as numbers
    var na = parseFloat(va);
    var nb = parseFloat(vb);
    if (!isNaN(na) && !isNaN(nb) && va.trim() !== '' && vb.trim() !== '') {
      return asc ? na - nb : nb - na;
    }

    // String sort
    var cmp = va.localeCompare(vb, undefined, { sensitivity: 'base', numeric: true });
    return asc ? cmp : -cmp;
  });

  // Reset scroll
  document.getElementById('table-container').scrollTop = 0;
  scrollTop = 0;
  renderWindow(0);
  updateStatus();
}

// ─── Search / filter ─────────────────────────────────────────────
function onSearchInput(e) {
  clearTimeout(searchTimer);
  var q = e.target.value;
  searchTimer = setTimeout(function() { applyFilter(q); }, 150);
}

function applyFilter(query) {
  document.getElementById('search-input').value = query;

  if (!query.trim()) {
    filteredRows = allRows;
  } else {
    var q = query.toLowerCase();
    filteredRows = allRows.filter(function(row) {
      return row.some(function(cell) { return cell.toLowerCase().includes(q); });
    });
  }

  // Re-sort if active sort
  if (sortColIndex >= 0) {
    var col = sortColIndex;
    var asc = sortAsc;
    filteredRows.sort(function(a, b) {
      var va = a[col] || '';
      var vb = b[col] || '';
      var na = parseFloat(va), nb = parseFloat(vb);
      if (!isNaN(na) && !isNaN(nb) && va.trim() && vb.trim()) return asc ? na - nb : nb - na;
      var cmp = va.localeCompare(vb, undefined, { sensitivity: 'base', numeric: true });
      return asc ? cmp : -cmp;
    });
  }

  document.getElementById('table-container').scrollTop = 0;
  scrollTop = 0;
  renderWindow(0);
  updateStatus();
}

// ─── Status bar ──────────────────────────────────────────────────
function updateStatus() {
  var el = document.getElementById('status-text');
  if (!el) return;
  var showing = filteredRows.length;
  var total = allRows.length;
  var cols = colCount;
  var parts = [];

  if (showing < total) {
    parts.push(fmt(showing) + ' of ' + fmt(total) + ' rows');
  } else {
    parts.push(fmt(total) + ' row' + (total !== 1 ? 's' : ''));
  }
  parts.push(cols + ' col' + (cols !== 1 ? 's' : ''));
  el.textContent = parts.join(' · ');
}

// ─── Utilities ───────────────────────────────────────────────────
function fmt(n) {
  return n.toLocaleString();
}

function escapeHtml(s) {
  if (!s) return '';
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}
