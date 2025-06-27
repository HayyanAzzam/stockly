// --- CONFIG & STATE ---
// Use 'var' to prevent "already declared" errors if the script is accidentally loaded twice.
var FINNHUB_API_KEY = 'd1f7lvhr01qsg7davdsgd1f7lvhr01qsg7davdt0';
const FINNHUB_BASE_URL = 'https://finnhub.io/api/v1';

let state = {
    user: {
        fullName: 'Fadi Abbara',
        email: 'demo@stockly.com',
        cash: 100000,
        portfolio: [
            { ticker: 'AAPL', shares: 50 },
            { ticker: 'GOOGL', shares: 25 },
            { ticker: 'TSLA', shares: 80 },
        ],
        wishlist: ['NVDA', 'AMD', 'MSFT'],
        isYearlyPlan: false,
    },
    currentStock: null,
    currency: 'USD',
    exchangeRates: {},
    chartInstances: { main: null, portfolio: null },
    searchModal: null,
    tradeModal: null,
};

// A flag to ensure the app initializes only once
let isAppInitialized = false;

// --- API FUNCTIONS ---
async function apiRequest(endpoint, base = FINNHUB_BASE_URL, token = `&token=${FINNHUB_API_KEY}`) {
    try {
        const response = await fetch(`${base}${endpoint}${token}`);
        if (!response.ok) {
            const errorText = await response.text();
            console.error(`API request failed with status ${response.status}: ${errorText}`);
            throw new Error(`API request failed: ${response.statusText}`);
        }
        const text = await response.text();
        return text ? JSON.parse(text) : null;
    } catch (error) {
        console.error("API Error:", error);
        return null;
    }
}

async function getQuote(ticker) { return apiRequest(`/quote?symbol=${ticker}`); }
async function getProfile(ticker) { return apiRequest(`/stock/profile2?symbol=${ticker}`); }
async function getGeneralNews() { return apiRequest(`/news?category=general`); }
async function getCompanyNews(ticker) {
    const to = new Date().toISOString().split('T')[0];
    const from = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    return apiRequest(`/company-news?symbol=${ticker}&from=${from}&to=${to}`);
}
async function searchSymbols(query) { return apiRequest(`/search?q=${query}`); }
async function getCandles(ticker, resolution, from, to) {
    return apiRequest(`/stock/candle?symbol=${ticker}&resolution=${resolution}&from=${from}&to=${to}`);
}
async function getExchangeRates() {
    const data = await apiRequest('/forex/rates?base=USD');
    if (data && data.quote) state.exchangeRates = data.quote;
}
async function getCityFromCoords(lat, lon) {
    const endpoint = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}`;
    return apiRequest(endpoint, '', '');
}

// --- UTILITY & FORMATTING FUNCTIONS ---
function getOnlineLogo(ticker) {
    const logoMap = {
        'AAPL': 'https://i.ibb.co/Y4fYhPGt/apfel.png',
        'GOOGL': 'https://i.ibb.co/qYyvsYs3/google.png',
        'MSFT': 'https://i.ibb.co/r232vB4H/microsoft.png',
        'NVDA': 'https://i.ibb.co/cKKKvvD5/nvidia.png',
        'AMZN': 'https://i.ibb.co/TxzZ0fqQ/amazon.png',
        'BTC-USD': 'https://i.ibb.co/67nvv1H5/bitcoin.png',
        'TSLA': 'https://i.ibb.co/994Jc99/tesla.png',
        'AMD': 'https://i.ibb.co/3kL4T5v/amd.png'
    };
    return logoMap[ticker] || `https://placehold.co/40x40/ccc/000?text=${ticker ? ticker[0] : '?'}`;
}

function formatCurrency(value, currency = state.currency) {
    if (typeof value !== 'number') return '$--.--';
    const rate = state.exchangeRates[currency] || 1;
    const convertedValue = value * rate;
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: currency, minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(convertedValue);
}

function formatPercentage(value) {
    if (typeof value !== 'number') return '--%';
    return `${value.toFixed(2)}%`;
}

function getChangeClass(value) { return value >= 0 ? 'text-brand-green' : 'text-brand-red'; }
function getBGClass(value) { return value >= 0 ? 'bg-brand-green-light' : 'bg-brand-red-light'; }

function generateFakeCandles(basePrice, numPoints, range) {
    const candles = { c: [], t: [] };
    const now = Math.floor(Date.now() / 1000);
    let from;
    switch (range) {
        case '1D': from = now - (1 * 24 * 60 * 60); break;
        case '1W': from = now - (7 * 24 * 60 * 60); break;
        case '1M': from = now - (30 * 24 * 60 * 60); break;
        default: from = now - (365 * 24 * 60 * 60); break;
    }
    const timeStep = (now - from) / numPoints;
    let currentPrice = basePrice * (1 + (Math.random() - 0.6) * 0.2);
    for (let i = 0; i < numPoints; i++) {
        candles.t.push(from + i * timeStep);
        currentPrice += (Math.random() - 0.49) * currentPrice * 0.05;
        candles.c.push(currentPrice);
    }
    candles.c[candles.c.length - 1] = basePrice;
    return candles;
}

// --- PAGE & CONTENT NAVIGATION ---
function navigateToPage(pageId) {
    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
    const newPage = document.getElementById(pageId);
    if (newPage) {
        newPage.classList.add('active');
        const newHash = `#${pageId}`;
        if (window.location.hash !== newHash) window.history.pushState({ page: pageId }, `Page ${pageId}`, newHash);
        window.scrollTo(0, 0);
    }
}

function showAuthSubPage(subPageId) {
    navigateToPage('auth-container');
    document.querySelectorAll('.auth-sub-page').forEach(p => p.classList.add('d-none'));
    document.getElementById(subPageId)?.classList.remove('d-none');
}

function showMainContent(targetId) {
    document.querySelectorAll('.main-content-area').forEach(area => area.style.display = 'none');
    const targetElement = document.getElementById(targetId);
    if (targetElement) targetElement.style.display = 'block';
    document.querySelectorAll('.nav-link').forEach(link => link.classList.toggle('active', link.dataset.target === targetId));
    switch (targetId) {
        case 'markets-content': renderHomePageSummary(); renderMarketsPage(); break;
        case 'portfolio-content': renderPortfolioPage(); break;
        case 'news-content': renderNewsPage(); break;
        case 'profile-content': renderProfilePage(); break;
        case 'wishlist-content': renderWishlistPage(); break;
        case 'profile-edit-content': renderProfileEditPage(); break;
    }
}

// --- RENDER FUNCTIONS ---
async function renderHomePageSummary() {
    let totalValue = 0, openingTotalValue = 0;
    if (state.user.portfolio.length > 0) {
        const portfolioQuotes = await Promise.all(state.user.portfolio.map(h => getQuote(h.ticker)));
        portfolioQuotes.forEach((quote, i) => {
            if (quote && quote.c) {
                totalValue += quote.c * state.user.portfolio[i].shares;
                openingTotalValue += quote.o * state.user.portfolio[i].shares;
            }
        });
    }
    const totalChangeValue = totalValue - openingTotalValue;
    const percentageChange = openingTotalValue ? (totalChangeValue / openingTotalValue) * 100 : 0;
    document.getElementById('summary-portfolio-value').innerText = formatCurrency(totalValue);
    const portfolioChangeEl = document.getElementById('summary-portfolio-change');
    portfolioChangeEl.innerText = `${totalChangeValue >= 0 ? '+' : ''}${formatPercentage(percentageChange)} Today`;
    portfolioChangeEl.className = `fw-semibold mb-0 small ${getChangeClass(totalChangeValue)}`;
    document.getElementById('summary-available-cash').innerText = formatCurrency(state.user.cash);
}

async function renderMarketsPage() {
    const container = document.getElementById('market-indices-container');
    container.innerHTML = `<div class="text-center p-5 col-12"><div class="spinner-border" role="status"><span class="visually-hidden">Loading...</span></div></div>`;
    const tickers = ['^GSPC', '^IXIC', 'AAPL', 'BA'];
    const promises = tickers.map(async (ticker) => {
        const [quote, profile] = await Promise.all([getQuote(ticker), getProfile(ticker.replace('^', ''))]);
        return { ...quote, ...profile, symbol: ticker };
    });
    const stocks = await Promise.all(promises);
    let content = stocks.map(stock => {
        if (!stock.c || !stock.name) return '';
        const change = stock.d, isPositive = change >= 0;
        return `<div class="col-6 col-md-3"><a href="#" class="card-link" onclick="event.preventDefault(); showStockDetail('${stock.symbol}')"><div class="card h-100 p-3 rounded-4 border-0 shadow-sm ${getBGClass(change)}"><h4 class="h6 fw-bold text-body-emphasis">${stock.name}</h4><div class="d-flex justify-content-between align-items-center"><p class="h5 fw-bold mb-0 text-body-emphasis">${formatCurrency(stock.c)}</p><i class="bi ${isPositive ? 'bi-arrow-up-right' : 'bi-arrow-down-left'} fs-5"></i></div></div></a></div>`;
    }).join('');
    container.innerHTML = content || '<p class="col-12 text-secondary">Could not load market indices.</p>';
}

// --- PORTFOLIO PAGE ---
async function renderPortfolioPage() {
    const oldSelector = document.getElementById('portfolio-range-selector');
    if (oldSelector) {
        const newSelector = oldSelector.cloneNode(true);
        oldSelector.parentNode.replaceChild(newSelector, oldSelector);
    }
    document.querySelectorAll('#portfolio-range-selector button').forEach(button => button.addEventListener('click', e => updatePortfolioView(e.currentTarget.dataset.range)));
    document.getElementById('portfolio-available-cash').innerText = formatCurrency(state.user.cash);
    await renderPortfolioAssets();
    const activeRange = document.querySelector('#portfolio-range-selector button.active')?.dataset.range || 'Weekly';
    updatePortfolioView(activeRange);
}

async function renderPortfolioAssets() {
    const assetsListContainer = document.getElementById('portfolio-assets-list');
    if (!assetsListContainer) return;
    if (state.user.portfolio.length === 0) {
        assetsListContainer.innerHTML = `<p class="text-secondary text-center p-4">Your portfolio is empty.</p>`;
        return;
    }
    const assetPromises = state.user.portfolio.map(async h => ({ ...await getProfile(h.ticker), ...await getQuote(h.ticker), value: ((await getQuote(h.ticker))?.c || 0) * h.shares, shares: h.shares, symbol: h.ticker }));
    const assets = await Promise.all(assetPromises);
    assetsListContainer.innerHTML = assets.sort((a, b) => b.value - a.value).map(asset => `<a href="#" class="list-group-item list-group-item-action d-flex justify-content-between align-items-center" onclick="event.preventDefault(); showStockDetail('${asset.symbol}')"><div class="d-flex align-items-center"><img src="${getOnlineLogo(asset.symbol)}" class="asset-logo me-3 rounded-circle" alt="${asset.name}" onerror="this.src='https://placehold.co/40x40?text=${asset.symbol[0]}'"><div><span class="fw-bold">${asset.symbol}</span><small class="d-block text-secondary">${asset.shares} shares</small></div></div><div class="text-end"><p class="fw-bold mb-0">${formatCurrency(asset.value)}</p><small class="${getChangeClass(asset.d)}">${formatPercentage(asset.dp)}</small></div></a>`).join('');
}

async function updatePortfolioView(range) {
    document.querySelectorAll('#portfolio-range-selector button').forEach(btn => btn.classList.toggle('active', btn.dataset.range === range));
    const chartContainer = document.getElementById('portfolio-chart-container');
    const totalValueEl = document.getElementById('portfolio-total-value');
    const changeSummaryEl = document.getElementById('portfolio-change-summary');
    const trendIconEl = document.getElementById('portfolio-trend-icon');
    chartContainer.innerHTML = `<div class="d-flex justify-content-center align-items-center h-100"><div class="spinner-border" role="status"><span class="visually-hidden">Loading...</span></div></div>`;
    totalValueEl.innerText = '--';
    changeSummaryEl.innerText = 'Loading...';
    trendIconEl.innerHTML = `<i class="bi bi-hourglass-split"></i>`;

    if (state.user.portfolio.length === 0) {
        chartContainer.innerHTML = `<p class="text-secondary text-center h-100 d-flex align-items-center justify-content-center">Add assets to see your portfolio chart.</p>`;
        totalValueEl.innerText = formatCurrency(0);
        changeSummaryEl.innerText = "No assets";
        trendIconEl.innerHTML = `<i class="bi bi-pie-chart"></i>`;
        return;
    }

    const now = Math.floor(Date.now() / 1000);
    let from, resolution, timeLabel;
    switch (range) {
        case 'Daily': from = now - 1 * 24 * 3600; resolution = '15'; timeLabel = 'Today'; break;
        case 'Weekly': from = now - 7 * 24 * 3600; resolution = '60'; timeLabel = 'This Week'; break;
        case 'Monthly': from = now - 30 * 24 * 3600; resolution = 'D'; timeLabel = 'This Month'; break;
        default: from = now - 365 * 24 * 3600; resolution = 'W'; timeLabel = 'This Year'; break;
    }

    try {
        const candlePromises = state.user.portfolio.map(h => getCandles(h.ticker, resolution, from, now).then(c => ({ ...c, shares: h.shares, ticker: h.ticker })));
        const allCandlesData = await Promise.all(candlePromises);
        const validCandles = allCandlesData.filter(c => c && c.s === 'ok' && c.c?.length > 0 && c.t?.length > 0);
        if (validCandles.length === 0) throw new Error("API failed to return real data.");

        const stockDataMap = {}, allTimestamps = new Set();
        validCandles.forEach(stockData => {
            stockDataMap[stockData.ticker] = {};
            stockData.t.forEach((ts, i) => { allTimestamps.add(ts); stockDataMap[stockData.ticker][ts] = stockData.c[i]; });
        });
        const sortedTimestamps = Array.from(allTimestamps).sort((a, b) => a - b);
        const portfolioHistory = {}, lastKnownPrices = {};
        state.user.portfolio.forEach(h => lastKnownPrices[h.ticker] = 0);
        sortedTimestamps.forEach(ts => {
            let totalValueAtTs = 0;
            state.user.portfolio.forEach(h => {
                const stockData = stockDataMap[h.ticker];
                let price = lastKnownPrices[h.ticker];
                if (stockData && stockData[ts] !== undefined) {
                    price = stockData[ts];
                    lastKnownPrices[h.ticker] = price;
                }
                totalValueAtTs += price * h.shares;
            });
            portfolioHistory[ts] = totalValueAtTs;
        });
        const portfolioDataPoints = sortedTimestamps.map(ts => ({ timestamp: new Date(ts * 1000), value: portfolioHistory[ts] })).filter(p => p.value > 0);
        if (portfolioDataPoints.length < 2) throw new Error("Not enough data for chart.");

        const labels = portfolioDataPoints.map(p => p.timestamp);
        const data = portfolioDataPoints.map(p => p.value);
        const startValue = data[0], endValue = data[data.length - 1];
        const changePercentage = startValue ? ((endValue - startValue) / startValue) * 100 : 0;
        totalValueEl.innerText = formatCurrency(endValue + state.user.cash);
        changeSummaryEl.innerText = `${changePercentage >= 0 ? '+' : ''}${changePercentage.toFixed(1)}% ${timeLabel}`;
        changeSummaryEl.className = `h5 fw-semibold ${getChangeClass(changePercentage)}`;
        trendIconEl.className = `fs-1 ${getChangeClass(changePercentage)}`;
        trendIconEl.innerHTML = `<i class="bi ${changePercentage >= 0 ? 'bi-graph-up' : 'bi-graph-down'}"></i>`;
        chartContainer.innerHTML = `<canvas id="portfolioChart"></canvas>`;
        createPortfolioChart(labels, data);
    } catch (error) {
        console.warn("Real portfolio data failed, generating fake. Reason:", error.message);
        try {
            let totalValue = (await Promise.all(state.user.portfolio.map(h => getQuote(h.ticker)))).reduce((acc, q, i) => acc + (q && q.c ? q.c * state.user.portfolio[i].shares : 0), 0);
            if (totalValue > 0) {
                const fakeCandles = generateFakeCandles(totalValue, 50, range);
                const labels = fakeCandles.t.map(t => new Date(t * 1000));
                const data = fakeCandles.c;
                const changePercentage = ((data[data.length - 1] - data[0]) / data[0]) * 100;
                totalValueEl.innerText = formatCurrency(data[data.length - 1] + state.user.cash);
                changeSummaryEl.innerText = `${changePercentage >= 0 ? '+' : ''}${changePercentage.toFixed(1)}% ${timeLabel}`;
                changeSummaryEl.className = `h5 fw-semibold ${getChangeClass(changePercentage)}`;
                trendIconEl.innerHTML = `<i class="bi ${changePercentage >= 0 ? 'bi-graph-up' : 'bi-graph-down'}"></i>`;
                chartContainer.innerHTML = `<canvas id="portfolioChart"></canvas>`;
                createPortfolioChart(labels, data);
            } else throw new Error("Could not get current portfolio value for fake data.");
        } catch (fakeDataError) {
            console.error("Failed to generate fake portfolio data:", fakeDataError);
            chartContainer.innerHTML = `<div class="d-flex align-items-center justify-content-center h-100 text-center text-danger p-3">Could not load portfolio chart.</div>`;
        }
    }
}

function createPortfolioChart(labels, data) {
    const canvasEl = document.getElementById('portfolioChart');
    if (!canvasEl) return;
    if (state.chartInstances.portfolio) state.chartInstances.portfolio.destroy();
    const change = data.length > 1 ? data[data.length - 1] - data[0] : 0;
    const ctx = canvasEl.getContext('2d');
    const gradient = ctx.createLinearGradient(0, 0, 0, canvasEl.offsetHeight);
    gradient.addColorStop(0, change >= 0 ? 'rgba(34, 197, 94, 0.4)' : 'rgba(239, 68, 68, 0.3)');
    gradient.addColorStop(1, 'rgba(0,0,0,0)');
    state.chartInstances.portfolio = new Chart(ctx, {
        type: 'line',
        data: { labels, datasets: [{ data, borderColor: change >= 0 ? '#22c55e' : '#ef4444', borderWidth: 3, pointRadius: 0, tension: 0.4, fill: true, backgroundColor: gradient }] },
        options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false }, tooltip: { mode: 'index', intersect: false, callbacks: { label: c => `Value: ${formatCurrency(c.parsed.y)}` } } }, scales: { x: { type: 'time', time: { unit: 'day' }, display: false }, y: { display: false } } }
    });
}

// --- OTHER RENDER FUNCTIONS ---
async function renderNewsPage() {
    const container = document.getElementById('news-content');
    container.innerHTML = `<div class="text-center p-5"><div class="spinner-border" role="status"><span class="visually-hidden">Loading...</span></div></div>`;
    const news = await getGeneralNews();
    if (!news || news.length === 0) {
        container.innerHTML = '<p class="text-secondary">Could not load news.</p>';
        return;
    }
    container.innerHTML = `<h2 class="h3 fw-bold mb-4">Market News</h2><div class="row g-4">${news.slice(0,10).map(article => `<div class="col-lg-6"><div class="card h-100 border-0 shadow-sm bg-body-tertiary">${article.image?`<img src="${article.image}" class="card-img-top" alt="News Image" style="height:200px;object-fit:cover" onerror="this.style.display='none'">`:''}<div class="card-body d-flex flex-column"><h5 class="card-title fw-bold">${article.headline}</h5><p class="card-text text-secondary small mb-3">${new Date(article.datetime*1000).toLocaleDateString()}</p><a href="${article.url}" target="_blank" class="btn btn-sm btn-outline-primary mt-auto">Read More</a></div></div></div>`).join('')}</div>`;
}

function renderProfilePage() {
    document.getElementById('profile-content').innerHTML = `<h2 class="h3 fw-bold mb-4">Account Settings</h2><div class="card border-0 bg-body-tertiary rounded-4 p-4 mb-4"><div class="d-flex align-items-center mb-4"><img class="user-avatar-large rounded-circle" src="https://placehold.co/100x100/E2E8F0/4A5568?text=FA" alt="User profile picture"><div class="ms-3"><h3 class="h5 fw-bold mb-0">${state.user.fullName}</h3><p class="text-secondary small mb-0">${state.user.email}</p></div></div><button id="upgrade-btn" class="btn btn-warning fw-bold">Upgrade to Pro</button></div><div class="card border-0 bg-body-tertiary rounded-4 p-4 mb-4"><h4 class="h6 fw-bold mb-3">Settings</h4><div class="d-flex justify-content-between align-items-center mb-3"><label for="theme-toggle" class="form-check-label">Dark Mode</label><div class="form-check form-switch"><input type="checkbox" id="theme-toggle" class="form-check-input" role="switch"></div></div><div class="d-flex justify-content-between align-items-center"><label for="currency-select" class="form-label mb-0">Currency</label><select id="currency-select" class="form-select w-auto"><option value="USD">USD ($)</option><option value="EUR">EUR (€)</option><option value="GBP">GBP (£)</option></select></div></div><div class="card border-0 bg-body-tertiary rounded-4 p-4 mb-4"><h4 class="h6 fw-bold mb-3">Location</h4><div id="location-info" class="text-secondary">Detecting location...</div></div><div class="d-grid"><button id="logout-button" class="btn btn-danger">Log Out</button></div>`;
    document.getElementById('theme-toggle').checked = document.documentElement.dataset.bsTheme === 'dark';
    document.getElementById('theme-toggle').addEventListener('change', toggleTheme);
    document.getElementById('logout-button').addEventListener('click', () => navigateToPage('welcome-page'));
    document.getElementById('upgrade-btn').addEventListener('click', () => navigateToPage('pro-page'));
    document.getElementById('currency-select').value = state.currency;
    document.getElementById('currency-select').addEventListener('change', handleCurrencyChange);
    getUserLocation();
}

async function renderWishlistPage() {
    const container = document.getElementById('wishlist-content');
    container.innerHTML = `<div class="text-center p-5"><div class="spinner-border" role="status"><span class="visually-hidden">Loading...</span></div></div>`;
    if (state.user.wishlist.length === 0) {
        container.innerHTML = `<h2 class="h3 fw-bold mb-4">My Wishlist</h2><p class="text-secondary">Your wishlist is empty.</p><div class="mt-4"><button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#searchModal">Add Stock</button></div>`;
        return;
    }
    const assets = await Promise.all(state.user.wishlist.map(async ticker => ({...await getProfile(ticker),...await getQuote(ticker), symbol: ticker})));
    container.innerHTML = `<h2 class="h3 fw-bold mb-4">My Wishlist</h2><div class="list-group">${assets.map(asset => `<a href="#" class="list-group-item list-group-item-action d-flex justify-content-between align-items-center" onclick="event.preventDefault(); showStockDetail('${asset.symbol}')"><div class="d-flex align-items-center"><img src="${getOnlineLogo(asset.symbol)}" class="asset-logo me-3 rounded-circle" alt="${asset.name}"><div class="fw-bold">${asset.symbol}<small class="d-block text-secondary">${asset.name||'N/A'}</small></div></div><div class="text-end"><p class="fw-bold mb-0">${formatCurrency(asset.c)}</p><small class="${getChangeClass(asset.d)}">${formatPercentage(asset.dp)}</small></div></a>`).join('')}</div><div class="mt-4"><button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#searchModal">Add Stock</button></div>`;
}

function renderProfileEditPage() {
    document.getElementById('profile-edit-content').innerHTML = `<h2 class="h3 fw-bold mb-4">Edit Profile</h2><div class="card border-0 bg-body-tertiary rounded-4 p-4"><form id="profile-edit-form"><div class="text-center mb-4"><img class="user-avatar-large rounded-circle mb-2" src="https://placehold.co/100x100/E2E8F0/4A5568?text=FA" alt="User profile picture"><div><button type="button" class="btn btn-sm btn-link">Change Picture</button></div></div><div class="mb-3"><label for="fullName" class="form-label">Full Name</label><input type="text" class="form-control" id="fullName" value="${state.user.fullName}"></div><div class="mb-3"><label for="email" class="form-label">Email address</label><input type="email" class="form-control" id="email" value="${state.user.email}"></div><hr class="my-4"><h3 class="h5 fw-bold mb-3">Change Password</h3><div class="mb-3"><label for="currentPassword" class="form-label">Current Password</label><input type="password" class="form-control" id="currentPassword"></div><div class="mb-3"><label for="newPassword" class="form-label">New Password</label><input type="password" class="form-control" id="newPassword"></div><div class="mb-3"><label for="confirmPassword" class="form-label">Confirm New Password</label><input type="password" class="form-control" id="confirmPassword"></div><button type="submit" class="btn btn-brand-green w-100 fw-semibold py-2 mt-3">Save</button></form></div>`;
    document.getElementById('profile-edit-form').addEventListener('submit', e => {
        e.preventDefault();
        state.user.fullName = document.getElementById('fullName').value;
        state.user.email = document.getElementById('email').value;
        document.getElementById('dashboard-username').innerText = state.user.fullName;
        showMainContent('profile-content');
    });
}

// --- STOCK DETAIL PAGE ---
async function showStockDetail(ticker) {
    state.currentStock = ticker;
    navigateToPage('stock-detail-page');
    const contentArea = document.querySelector('#stock-detail-page .container-fluid');
    contentArea.innerHTML = `<div class="text-center p-5"><div class="spinner-border" role="status"><span class="visually-hidden">Loading...</span></div></div>`;
    const [quote, profile] = await Promise.all([getQuote(ticker), getProfile(ticker)]);
    if (!profile || !quote || !quote.c) {
        contentArea.innerHTML = `<p class="text-secondary text-center">Could not load stock details.</p><button id="back-to-dashboard-btn-detail" class="btn btn-link">Back</button>`;
        document.getElementById('back-to-dashboard-btn-detail').addEventListener('click', () => window.history.back());
        return;
    }
    const sharesOwned = state.user.portfolio.find(h => h.ticker === ticker)?.shares || 0;
    contentArea.innerHTML = `<header class="d-flex justify-content-between align-items-center mb-4"><button id="back-to-dashboard-btn-detail" class="btn btn-link p-2"><i class="bi bi-arrow-left fs-4"></i></button><h1 class="h5 fw-bold text-body-emphasis mb-0">${profile.ticker||ticker}</h1><div id="watchlist-action-container" class="text-end" style="width:40px"></div></header><div class="max-w-xl mx-auto w-100"><div class="mb-4"><p class="text-secondary h5">${profile.name}</p><div class="d-flex align-items-end gap-3"><p class="display-4 fw-bold mb-0">${formatCurrency(quote.c)}</p><p class="h5 fw-semibold mb-2 ${getChangeClass(quote.d)}">${quote.d>=0?'+':''}${quote.d.toFixed(2)} (${formatPercentage(quote.dp)})</p></div></div><div class="chart-container-large mb-4"><canvas id="mainStockChart"></canvas></div><div id="time-range-selector" class="btn-group w-100 mb-4" role="group"><button type="button" class="btn btn-outline-secondary" data-range="1D">1D</button><button type="button" class="btn btn-outline-secondary" data-range="1W">1W</button><button type="button" class="btn btn-outline-secondary" data-range="1M">1M</button><button type="button" class="btn btn-outline-secondary active" data-range="1Y">1Y</button></div><div class="d-grid gap-3" style="grid-template-columns:1fr 1fr"><button class="btn btn-brand-green btn-lg fw-bold" onclick="openTradeModal('${ticker}','buy')">Buy</button><button class="btn btn-brand-red btn-lg fw-bold" onclick="openTradeModal('${ticker}','sell')" ${!sharesOwned?'disabled':''}>Sell</button></div><div id="stock-news-container" class="mt-5"><h3 class="h4 fw-bold mb-3">Relevant News</h3><div id="stock-news-list"></div></div></div>`;
    document.getElementById('back-to-dashboard-btn-detail').addEventListener('click', () => window.history.back());
    document.querySelectorAll('#time-range-selector button').forEach(button => button.addEventListener('click', e => {
        document.querySelectorAll('#time-range-selector button').forEach(btn => btn.classList.remove('active'));
        e.currentTarget.classList.add('active');
        updateStockChart(e.currentTarget.dataset.range, quote.c);
    }));
    updateStockChart('1Y', quote.c);
    loadStockNews(ticker);
    renderWatchlistButton(ticker);
}

async function loadStockNews(ticker) {
    const container = document.getElementById('stock-news-list');
    if (!container) return;
    container.innerHTML = `<div class="spinner-border spinner-border-sm" role="status"><span class="visually-hidden">Loading...</span></div>`;
    const news = await getCompanyNews(ticker);
    if (!news || news.length === 0) {
        container.innerHTML = `<p class="text-secondary">No recent news for ${ticker}.</p>`;
        return;
    }
    container.innerHTML = `<div class="list-group">${news.slice(0,5).map(article=>`<a href="${article.url}" target="_blank" class="list-group-item list-group-item-action"><p class="fw-bold mb-1">${article.headline}</p><small class="text-secondary">${new Date(article.datetime*1000).toLocaleDateString()}</small></a>`).join('')}</div>`;
}

function toggleWatchlist(ticker) {
    const index = state.user.wishlist.indexOf(ticker);
    if (index > -1) state.user.wishlist.splice(index, 1);
    else state.user.wishlist.push(ticker);
    renderWatchlistButton(ticker);
}

function renderWatchlistButton(ticker) {
    const container = document.getElementById('watchlist-action-container');
    if (!container) return;
    const isInWatchlist = state.user.wishlist.includes(ticker);
    container.innerHTML = `<button class="btn btn-link p-2" onclick="toggleWatchlist('${ticker}')"><i class="bi ${isInWatchlist ? 'bi-star-fill text-brand-amber' : 'bi-star text-secondary'} fs-4"></i></button>`;
}

// --- CHARTING ---
async function updateStockChart(range, currentPrice) {
    if (!state.currentStock) return;
    const chartContainer = document.getElementById('mainStockChart')?.parentElement;
    if (chartContainer) chartContainer.innerHTML = `<div class="d-flex justify-content-center align-items-center h-100"><div class="spinner-border" role="status"><span class="visually-hidden">Loading...</span></div></div>`;

    const now = Math.floor(Date.now() / 1000);
    let from, resolution;
    switch (range) {
        case '1D': from = now - 1 * 24 * 3600; resolution = '15'; break;
        case '1W': from = now - 7 * 24 * 3600; resolution = '60'; break;
        case '1M': from = now - 30 * 24 * 3600; resolution = 'D'; break;
        default: from = now - 365 * 24 * 3600; resolution = 'W'; break;
    }

    let candles = await getCandles(state.currentStock, resolution, from, now);
    if (!candles || !candles.c || candles.c.length === 0) {
        console.warn(`Real chart data failed for ${state.currentStock}. Generating fake.`);
        candles = generateFakeCandles(currentPrice, 50, range);
    }
    if (chartContainer) chartContainer.innerHTML = `<canvas id="mainStockChart"></canvas>`;
    const isPositive = candles.c[candles.c.length - 1] > candles.c[0];
    createMainStockChart(candles.t.map(t => new Date(t * 1000)), candles.c, isPositive);
}

function createMainStockChart(labels, data, isPositive) {
    const canvasEl = document.getElementById('mainStockChart');
    if (!canvasEl) return;
    if (state.chartInstances.main) state.chartInstances.main.destroy();
    const borderColor = isPositive ? 'rgba(34,197,94,1)' : 'rgba(239,68,68,1)';
    const ctx = canvasEl.getContext('2d');
    const gradient = ctx.createLinearGradient(0, 0, 0, canvasEl.offsetHeight);
    gradient.addColorStop(0, isPositive ? 'rgba(34,197,94,0.4)' : 'rgba(239,68,68,0.4)');
    gradient.addColorStop(1, 'rgba(0,0,0,0)');
    state.chartInstances.main = new Chart(ctx, {
        type: 'line',
        data: { labels, datasets: [{ data, borderColor, borderWidth: 2, pointRadius: 0, tension: 0.3, fill: true, backgroundColor: gradient }] },
        options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false }, tooltip: { mode: 'index', intersect: false, callbacks: { label: c => `Price: ${formatCurrency(c.parsed.y)}` } } }, scales: { x: { type: 'time', time: { unit: 'day' }, display: false }, y: { display: false } } }
    });
}

// --- TRADE MODAL & LOGIC ---
async function openTradeModal(ticker, action) {
    const form = document.getElementById('trade-form');
    form.reset();
    form.classList.remove('was-validated');
    const quote = await getQuote(ticker);
    if (!quote || !quote.c) { console.error("Could not fetch current price."); return; }
    const currentPrice = quote.c;
    const sharesOwned = state.user.portfolio.find(h => h.ticker === ticker)?.shares || 0;
    document.getElementById('tradeModalLabel').textContent = `${action==='buy'?'Buy':'Sell'} ${ticker}`;
    const confirmBtn = document.getElementById('confirm-trade-btn');
    confirmBtn.className = `btn ${action==='buy'?'btn-brand-green':'btn-brand-red'}`;
    confirmBtn.textContent = `Confirm ${action==='buy'?'Purchase':'Sale'}`;
    document.getElementById('trade-ticker').value = ticker;
    document.getElementById('trade-action').value = action;
    document.getElementById('trade-price').value = currentPrice;
    document.getElementById('modal-current-price').textContent = formatCurrency(currentPrice);
    document.getElementById('modal-shares-owned').textContent = `${sharesOwned} shares`;
    document.getElementById('modal-available-cash').textContent = formatCurrency(state.user.cash);
    document.getElementById('modal-estimated-total').textContent = formatCurrency(0);
    state.tradeModal.show();
}

function updateEstimatedTotal() {
    const shares = parseFloat(document.getElementById('trade-shares').value);
    const price = parseFloat(document.getElementById('trade-price').value);
    document.getElementById('modal-estimated-total').textContent = formatCurrency((!isNaN(shares) && !isNaN(price) && shares > 0) ? shares * price : 0);
}

async function handleTrade(event) {
    event.preventDefault();
    const form = event.target;
    const ticker = form.querySelector('#trade-ticker').value;
    const action = form.querySelector('#trade-action').value;
    const shares = parseInt(form.querySelector('#trade-shares').value);
    const price = parseFloat(form.querySelector('#trade-price').value);
    const sharesInput = document.getElementById('trade-shares');
    const errorDiv = sharesInput.nextElementSibling;
    sharesInput.classList.remove('is-invalid');
    if (isNaN(shares) || shares <= 0) {
        errorDiv.textContent = "Please enter a valid number of shares.";
        sharesInput.classList.add('is-invalid');
        return;
    }
    if (action === 'buy') {
        const cost = shares * price;
        if (cost > state.user.cash) {
            errorDiv.textContent = `Insufficient funds.`;
            sharesInput.classList.add('is-invalid');
            return;
        }
        state.user.cash -= cost;
        const existingHolding = state.user.portfolio.find(h => h.ticker === ticker);
        if (existingHolding) existingHolding.shares += shares;
        else state.user.portfolio.push({ ticker, shares });
    } else {
        const existingHolding = state.user.portfolio.find(h => h.ticker === ticker);
        if (!existingHolding || shares > existingHolding.shares) {
            errorDiv.textContent = `You cannot sell more shares than you own.`;
            sharesInput.classList.add('is-invalid');
            return;
        }
        state.user.cash += shares * price;
        existingHolding.shares -= shares;
        if (existingHolding.shares === 0) state.user.portfolio = state.user.portfolio.filter(h => h.ticker !== ticker);
    }
    state.tradeModal.hide();
    const currentPage = window.location.hash.substring(1);
    if (currentPage === 'stock-detail-page' && state.currentStock === ticker) showStockDetail(ticker);
    const activeContent = document.querySelector('.main-content-area[style*="block"]');
    if (activeContent) showMainContent(activeContent.id);
    else renderHomePageSummary();
}

// --- EVENT HANDLERS & OTHER LOGIC ---
function toggleTheme() {
    const isDark = document.documentElement.dataset.bsTheme === 'dark';
    document.documentElement.dataset.bsTheme = isDark ? 'light' : 'dark';
    localStorage.setItem('theme', document.documentElement.dataset.bsTheme);
    if (document.getElementById('stock-detail-page').classList.contains('active')) {
        const activeRangeButton = document.querySelector('#time-range-selector .active');
        if (activeRangeButton) updateStockChart(activeRangeButton.dataset.range);
    }
    if (document.getElementById('portfolio-content')?.style.display === 'block') {
        const activePortfolioRange = document.querySelector('#portfolio-range-selector .active');
        if (activePortfolioRange) updatePortfolioView(activePortfolioRange.dataset.range);
    }
}

function handleCurrencyChange(event) {
    state.currency = event.target.value;
    const activeContent = document.querySelector('.main-content-area[style*="block"]');
    if (activeContent) showMainContent(activeContent.id);
}

async function handleSearch(event) {
    const query = event.target.value;
    const resultsContainer = document.getElementById('search-results');
    if (query.length < 2) { resultsContainer.innerHTML = ''; return; }
    const searchData = await searchSymbols(query);
    if (!searchData || searchData.count === 0) {
        resultsContainer.innerHTML = '<p class="text-secondary">No results found.</p>';
        return;
    }
    resultsContainer.innerHTML = `<div class="list-group">${searchData.result.map(item => `<a href="#" class="list-group-item list-group-item-action" data-ticker="${item.symbol}" onclick="event.preventDefault(); selectSearchResult(this.dataset.ticker)"><div class="fw-bold">${item.symbol}</div><div class="small text-secondary">${item.description}</div></a>`).join('')}</div>`;
}

function selectSearchResult(ticker) {
    state.searchModal.hide();
    showStockDetail(ticker);
}

function getUserLocation() {
    const container = document.getElementById('location-info');
    if (!navigator.geolocation) {
        container.textContent = "Geolocation is not supported.";
        return;
    }
    navigator.geolocation.getCurrentPosition(
        async (position) => {
            const { latitude, longitude } = position.coords;
            const locData = await getCityFromCoords(latitude, longitude);
            if (locData && locData.address) {
                const { city, town, village, country } = locData.address;
                container.textContent = `${city||town||village||'Unknown'}, ${country||'Unknown'}`;
            } else container.textContent = "Could not retrieve city name.";
        },
        (error) => {
            container.textContent = "Could not retrieve location.";
            console.error("Geolocation Error:", error);
        }
    );
}

function showPaymentPage() {
    const isYearly = document.getElementById('plan-toggle').checked;
    state.user.isYearlyPlan = isYearly;
    document.getElementById('payment-monthly-plan').classList.toggle('d-none', isYearly);
    document.getElementById('payment-yearly-plan').classList.toggle('d-none', !isYearly);
    navigateToPage('payment-page');
}

// --- INITIALIZATION ---
document.addEventListener('DOMContentLoaded', () => {
    if (isAppInitialized) return;
    isAppInitialized = true;

    document.getElementById('lets-go-btn').addEventListener('click', () => showAuthSubPage('login-page'));
    document.getElementById('login-form').addEventListener('submit', (e) => { e.preventDefault(); navigateToPage('home-page'); });
    document.getElementById('register-form').addEventListener('submit', (e) => { e.preventDefault(); navigateToPage('home-page'); });
    document.querySelectorAll('.nav-link').forEach(link => link.addEventListener('click', (e) => { e.preventDefault(); showMainContent(link.dataset.target); }));
    document.getElementById('show-register').addEventListener('click', (e) => { e.preventDefault(); showAuthSubPage('register-page'); });
    document.getElementById('show-login-from-register').addEventListener('click', (e) => { e.preventDefault(); showAuthSubPage('login-page'); });
    document.getElementById('back-to-profile-btn')?.addEventListener('click', () => window.history.back());
    document.getElementById('back-to-pro-btn')?.addEventListener('click', () => navigateToPage('pro-page'));
    document.getElementById('plan-toggle')?.addEventListener('change', e => {
        const isYearly = e.currentTarget.checked;
        document.getElementById('monthly-plan').classList.toggle('d-none', isYearly);
        document.getElementById('yearly-plan').classList.toggle('d-none', !isYearly);
    });
    document.getElementById('upgrade-now-btn')?.addEventListener('click', showPaymentPage);
    document.getElementById('search-input').addEventListener('input', handleSearch);
    document.getElementById('trade-form').addEventListener('submit', handleTrade);
    document.getElementById('trade-shares').addEventListener('input', updateEstimatedTotal);

    const savedTheme = localStorage.getItem('theme') || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
    document.documentElement.dataset.bsTheme = savedTheme;

    // FIX: Corrected initialization of Bootstrap Modals
    state.searchModal = new bootstrap.Modal(document.getElementById('searchModal'));
    state.tradeModal = new bootstrap.Modal(document.getElementById('tradeModal'));

    getExchangeRates();
    document.getElementById('dashboard-username').innerText = state.user.fullName;

    window.addEventListener('popstate', (event) => {
        const pageId = event.state?.page || window.location.hash.substring(1) || 'welcome-page';
        if (pageId && document.getElementById(pageId)) navigateToPage(pageId);
        else navigateToPage('welcome-page');
    });

    const initialHash = window.location.hash.substring(1);
    if (initialHash && document.getElementById(initialHash)) {
        navigateToPage(initialHash);
        if (initialHash === 'home-page') showMainContent('markets-content');
    } else {
        navigateToPage('welcome-page');
    }
});
