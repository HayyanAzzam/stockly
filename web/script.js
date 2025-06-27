// --- CONFIG & STATE ---
const FINNHUB_API_KEY = 'd1f7lvhr01qsg7davdsgd1f7lvhr01qsg7davdt0'; // Replace with your key if needed
const FINNHUB_BASE_URL = 'https://finnhub.io/api/v1';

let state = {
    user: {
        fullName: 'Fadi Abbara',
        email: 'demo@stockly.com',
        cash: 100000, // Starting cash for trading
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
    chartInstances: {
        main: null,
        portfolio: null
    },
    searchModal: null,
    tradeModal: null, // Bootstrap modal instance for trading
};

// --- API FUNCTIONS ---
async function apiRequest(endpoint, base = FINNHUB_BASE_URL, token = `&token=${FINNHUB_API_KEY}`) {
    try {
        const response = await fetch(`${base}${endpoint}${token}`);
        if (!response.ok) {
            const errorText = await response.text();
            console.error(`API request failed with status ${response.status}: ${errorText}`);
            throw new Error(`API request failed: ${response.statusText}`);
        }
        return await response.json();
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
    if (data && data.quote) {
        state.exchangeRates = data.quote;
    }
}
async function getCityFromCoords(lat, lon) {
    const endpoint = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}`;
    return apiRequest(endpoint, '', '');
}

// --- UTILITY & FORMATTING FUNCTIONS ---
function formatCurrency(value, currency = state.currency) {
    if (typeof value !== 'number') return '$--.--';
    const rate = state.exchangeRates[currency] || 1;
    const convertedValue = value * rate;
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: currency,
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    }).format(convertedValue);
}

function formatPercentage(value) {
    if (typeof value !== 'number') return '--%';
    return `${value.toFixed(2)}%`;
}

function getChangeClass(value) { return value >= 0 ? 'text-brand-green' : 'text-brand-red'; }
function getBGClass(value) { return value >= 0 ? 'bg-brand-green-light' : 'bg-brand-red-light'; }

// --- PAGE & CONTENT NAVIGATION ---
function navigateToPage(pageId) {
    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
    const newPage = document.getElementById(pageId);
    if (newPage) {
        newPage.classList.add('active');
        if (`#${pageId}` !== window.location.hash) {
            window.location.hash = pageId;
        }
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
    document.getElementById(targetId).style.display = 'block';

    document.querySelectorAll('.nav-link').forEach(link => {
        link.classList.toggle('active', link.dataset.target === targetId);
    });

    switch (targetId) {
        case 'markets-content':
            renderHomePageSummary();
            renderMarketsPage();
            break;
        case 'portfolio-content':
            renderPortfolioPage();
            break;
        case 'news-content':
            renderNewsPage();
            break;
        case 'profile-content':
            renderProfilePage();
            break;
        case 'wishlist-content':
            renderWishlistPage();
            break;
        case 'profile-edit-content':
            renderProfileEditPage();
            break;
    }
}

// --- RENDER FUNCTIONS ---
async function renderHomePageSummary() {
    let totalValue = 0;
    let openingTotalValue = 0;

    if (state.user.portfolio.length > 0) {
        const portfolioQuotes = await Promise.all(state.user.portfolio.map(async (holding) => {
            const quote = await getQuote(holding.ticker);
            return { ...quote, shares: holding.shares };
        }));
        
        portfolioQuotes.forEach(quote => {
            if(quote && quote.c) {
                totalValue += quote.c * quote.shares;
                openingTotalValue += quote.o * quote.shares;
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
        const quote = await getQuote(ticker);
        const profile = await getProfile(ticker.replace('^', ''));
        return { ...quote, ...profile, symbol: ticker };
    });

    const stocks = await Promise.all(promises);

    let content = ``;
    stocks.forEach(stock => {
        const change = stock.d;
        const isPositive = change >= 0;
        const name = stock.name || stock.symbol.replace('^', '');
        
        if (stock.c && name) {
            content += `
                <div class="col-6 col-md-3">
                    <a href="#" class="card-link" onclick="event.preventDefault(); showStockDetail('${stock.symbol}')">
                        <div class="card h-100 p-3 rounded-4 border-0 shadow-sm ${getBGClass(change)}">
                            <h4 class="h6 fw-bold text-body-emphasis">${name}</h4>
                            <div class="d-flex justify-content-between align-items-center">
                                <p class="h5 fw-bold mb-0 text-body-emphasis">${formatCurrency(stock.c)}</p>
                                <i class="bi ${isPositive ? 'bi-arrow-up-right' : 'bi-arrow-down-left'} fs-5"></i>
                            </div>
                        </div>
                    </a>
                </div>`;
        }
    });
    container.innerHTML = content || '<p class="col-12 text-secondary">Could not load market indices.</p>';
}

// --- PORTFOLIO PAGE ---
async function renderPortfolioPage() {
    const oldSelector = document.getElementById('portfolio-range-selector');
    if (oldSelector) {
        const newSelector = oldSelector.cloneNode(true);
        oldSelector.parentNode.replaceChild(newSelector, oldSelector);
    }
    
    document.querySelectorAll('#portfolio-range-selector button').forEach(button => {
        button.addEventListener('click', (e) => {
            const range = e.currentTarget.dataset.range;
            updatePortfolioView(range);
        });
    });

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
    
    const assetPromises = state.user.portfolio.map(async holding => {
        const quote = await getQuote(holding.ticker);
        const profile = await getProfile(holding.ticker);
        const value = (quote.c || 0) * holding.shares;
        return { ...profile, ...quote, value, shares: holding.shares, symbol: holding.ticker };
    });

    const assets = await Promise.all(assetPromises);
    
    let assetsContent = '';
    assets.sort((a, b) => b.value - a.value).forEach(asset => {
        assetsContent += `
            <a href="#" class="list-group-item list-group-item-action d-flex justify-content-between align-items-center" onclick="event.preventDefault(); showStockDetail('${asset.symbol}')">
                <div class="d-flex align-items-center">
                    <img src="${asset.logo}" class="asset-logo me-3 rounded-circle" alt="${asset.name}" onerror="this.src='https://placehold.co/40x40?text=${asset.symbol[0]}'">
                    <div>
                        <span class="fw-bold">${asset.symbol}</span>
                        <small class="d-block text-secondary">${asset.shares} shares</small>
                    </div>
                </div>
                <div class="text-end">
                    <p class="fw-bold mb-0">${formatCurrency(asset.value)}</p>
                    <small class="${getChangeClass(asset.d)}">${formatPercentage(asset.dp)}</small>
                </div>
            </a>`;
    });
    
    assetsListContainer.innerHTML = assetsContent;
}

async function updatePortfolioView(range) {
    document.querySelectorAll('#portfolio-range-selector button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.range === range);
    });
    
    const chartContainer = document.getElementById('portfolio-chart-container');
    const totalValueEl = document.getElementById('portfolio-total-value');
    const changeSummaryEl = document.getElementById('portfolio-change-summary');
    const trendIconEl = document.getElementById('portfolio-trend-icon');

    chartContainer.innerHTML = `<div class="d-flex justify-content-center align-items-center h-100"><div class="spinner-border" role="status"><span class="visually-hidden">Loading...</span></div></div>`;
    totalValueEl.innerText = '--';
    changeSummaryEl.innerText = 'Loading...';

    if (state.user.portfolio.length === 0) {
        chartContainer.innerHTML = `<p class="text-secondary text-center h-100 d-flex align-items-center justify-content-center">Add assets to see your portfolio chart.</p>`;
        totalValueEl.innerText = formatCurrency(0);
        changeSummaryEl.innerText = "No assets";
        trendIconEl.innerHTML = `<i class="bi bi-pie-chart"></i>`;
        return;
    }

    const now = Math.floor(Date.now() / 1000);
    let from, resolution, timeLabel;
    switch(range) {
        case 'Daily': from = now - (1 * 24 * 60 * 60); resolution = '15'; timeLabel = 'Today'; break;
        case 'Weekly': from = now - (7 * 24 * 60 * 60); resolution = '60'; timeLabel = 'This Week'; break;
        case 'Monthly': from = now - (30 * 24 * 60 * 60); resolution = 'D'; timeLabel = 'This Month'; break;
        case 'Yearly': from = now - (365 * 24 * 60 * 60); resolution = 'W'; timeLabel = 'This Year'; break;
        default: from = now - (7 * 24 * 60 * 60); resolution = '60'; timeLabel = 'This Week'; break;
    }

    try {
        const candlePromises = state.user.portfolio.map(h => 
            getCandles(h.ticker, resolution, from, now).then(c => ({...c, shares: h.shares, ticker: h.ticker}))
        );
        const allCandlesData = await Promise.all(candlePromises);

        const validCandles = allCandlesData.filter(c => c && c.s === 'ok' && c.c && c.c.length > 0);
        if (validCandles.length === 0) throw new Error("Could not fetch valid candle data for portfolio.");
        
        const stockDataMap = {};
        const allTimestamps = new Set();
        validCandles.forEach(stockData => {
            stockDataMap[stockData.ticker] = {};
            stockData.t.forEach((ts, i) => {
                allTimestamps.add(ts);
                stockDataMap[stockData.ticker][ts] = stockData.c[i];
            });
        });

        const sortedTimestamps = Array.from(allTimestamps).sort((a, b) => a - b);
        const portfolioHistory = {};
        const lastKnownPrices = {};
        state.user.portfolio.forEach(h => lastKnownPrices[h.ticker] = 0);
        
        sortedTimestamps.forEach(ts => {
            let totalValueAtTs = 0;
            state.user.portfolio.forEach(holding => {
                const stockData = stockDataMap[holding.ticker];
                let price = lastKnownPrices[holding.ticker];
                if (stockData && stockData[ts] !== undefined) {
                    price = stockData[ts];
                    lastKnownPrices[holding.ticker] = price;
                }
                totalValueAtTs += price * holding.shares;
            });
            portfolioHistory[ts] = totalValueAtTs;
        });

        const labels = sortedTimestamps.map(ts => new Date(ts * 1000));
        const data = sortedTimestamps.map(ts => portfolioHistory[ts]).filter(v => v > 0);
        if(data.length < 2) throw new Error("Not enough data to compute portfolio history.");
        
        const startValue = data[0];
        const endValue = data[data.length - 1];
        const changePercentage = startValue ? ((endValue - startValue) / startValue) * 100 : 0;
        
        totalValueEl.innerText = formatCurrency(endValue + state.user.cash);
        changeSummaryEl.innerText = `${changePercentage >= 0 ? '+' : ''}${changePercentage.toFixed(1)}% ${timeLabel}`;
        changeSummaryEl.className = `h5 fw-semibold ${getChangeClass(changePercentage)}`;

        trendIconEl.className = `fs-1 ${getChangeClass(changePercentage)}`;
        trendIconEl.innerHTML = `<i class="bi ${changePercentage >= 0 ? 'bi-graph-up' : 'bi-graph-down'}"></i>`;

        chartContainer.innerHTML = `<canvas id="portfolioChart"></canvas>`;
        createPortfolioChart(labels.slice(-data.length), data);

    } catch (error) {
        console.error("Error updating portfolio view:", error);
        totalValueEl.innerText = 'Error';
        changeSummaryEl.innerText = 'Could not load data';
        chartContainer.innerHTML = `<p class="text-secondary text-center h-100 d-flex align-items-center justify-content-center">Could not load portfolio chart.</p>`;
    }
}

function createPortfolioChart(labels, data) {
     const canvasEl = document.getElementById('portfolioChart');
     if (!canvasEl) return;
     if(state.chartInstances.portfolio) state.chartInstances.portfolio.destroy();

     const change = data[data.length - 1] - data[0];
     
     const ctx = canvasEl.getContext('2d');
     const gradient = ctx.createLinearGradient(0, 0, 0, canvasEl.offsetHeight);
     gradient.addColorStop(0, change >= 0 ? 'rgba(34, 197, 94, 0.4)' : 'rgba(239, 68, 68, 0.3)');
     gradient.addColorStop(1, 'rgba(0,0,0,0)');
     
     state.chartInstances.portfolio = new Chart(ctx, {
        type: 'line', 
        data: { labels, datasets: [{ data, borderColor: change >= 0 ? '#22c55e' : '#ef4444', borderWidth: 3, pointRadius: 0, tension: 0.4, fill: true, backgroundColor: gradient }] },
        options: { 
            responsive: true, maintainAspectRatio: false, 
            plugins: { legend: { display: false }, tooltip: { mode: 'index', intersect: false, callbacks: { label: (c) => `Value: ${formatCurrency(c.parsed.y)}` } } }, 
            scales: { x: { display: false }, y: { display: false } } 
        }
    });
}
// --- END OF PORTFOLIO FUNCTIONS ---

// --- OTHER RENDER FUNCTIONS ---
async function renderNewsPage() {
    const container = document.getElementById('news-content');
    container.innerHTML = `<div class="text-center p-5"><div class="spinner-border" role="status"><span class="visually-hidden">Loading...</span></div></div>`;

    const news = await getGeneralNews();
    if (!news || news.length === 0) {
        container.innerHTML = '<p class="text-secondary">Could not load news.</p>';
        return;
    }

    let content = `<h2 class="h3 fw-bold mb-4">Market News</h2><div class="row g-4">`;
    news.slice(0, 10).forEach(article => {
        content += `
            <div class="col-lg-6">
                <div class="card h-100 border-0 shadow-sm bg-body-tertiary">
                    ${article.image ? `<img src="${article.image}" class="card-img-top" alt="News Image" style="height: 200px; object-fit: cover;" onerror="this.style.display='none'">` : ''}
                    <div class="card-body d-flex flex-column">
                        <h5 class="card-title fw-bold">${article.headline}</h5>
                        <p class="card-text text-secondary small mb-3">${new Date(article.datetime * 1000).toLocaleDateString()}</p>
                        <a href="${article.url}" target="_blank" class="btn btn-sm btn-outline-primary mt-auto">Read More</a>
                    </div>
                </div>
            </div>`;
    });
    content += `</div>`;
    container.innerHTML = content;
}

function renderProfilePage() {
    const container = document.getElementById('profile-content');
    container.innerHTML = `
        <h2 class="h3 fw-bold mb-4">Account Settings</h2>
        <div class="card border-0 bg-body-tertiary rounded-4 p-4 mb-4">
            <div class="d-flex align-items-center mb-4">
                <img class="user-avatar-large rounded-circle" src="https://placehold.co/100x100/E2E8F0/4A5568?text=FA" alt="User profile picture">
                <div class="ms-3">
                    <h3 class="h5 fw-bold mb-0">${state.user.fullName}</h3>
                    <p class="text-secondary small mb-0">${state.user.email}</p>
                </div>
            </div>
            <button id="upgrade-btn" class="btn btn-warning fw-bold">Upgrade to Pro</button>
        </div>
        
        <div class="card border-0 bg-body-tertiary rounded-4 p-4 mb-4">
            <h4 class="h6 fw-bold mb-3">Settings</h4>
            <div class="d-flex justify-content-between align-items-center mb-3">
                <label for="theme-toggle" class="form-check-label">Dark Mode</label>
                <div class="form-check form-switch"><input type="checkbox" id="theme-toggle" class="form-check-input" role="switch"></div>
            </div>
             <div class="d-flex justify-content-between align-items-center">
                <label for="currency-select" class="form-label mb-0">Currency</label>
                <select id="currency-select" class="form-select w-auto"><option value="USD">USD ($)</option><option value="EUR">EUR (€)</option><option value="GBP">GBP (£)</option></select>
            </div>
        </div>

        <div class="card border-0 bg-body-tertiary rounded-4 p-4 mb-4">
            <h4 class="h6 fw-bold mb-3">Location</h4>
            <div id="location-info" class="text-secondary">Detecting location...</div>
        </div>
        
        <div class="d-grid"><button id="logout-button" class="btn btn-danger">Log Out</button></div>`;

    document.getElementById('theme-toggle').checked = document.documentElement.dataset.bsTheme === 'dark';
    document.getElementById('theme-toggle').addEventListener('change', toggleTheme);
    document.getElementById('logout-button').addEventListener('click', () => navigateToPage('welcome-page'));
    document.getElementById('upgrade-btn').addEventListener('click', () => navigateToPage('pro-page'));
    
    const currencySelect = document.getElementById('currency-select');
    currencySelect.value = state.currency;
    currencySelect.addEventListener('change', handleCurrencyChange);

    getUserLocation();
}

async function renderWishlistPage() {
    const container = document.getElementById('wishlist-content');
    container.innerHTML = `<div class="text-center p-5"><div class="spinner-border" role="status"><span class="visually-hidden">Loading...</span></div></div>`;

    if (state.user.wishlist.length === 0) {
        container.innerHTML = `
            <h2 class="h3 fw-bold mb-4">My Wishlist</h2>
            <p class="text-secondary">Your wishlist is empty. Search for stocks to add them.</p>
             <div class="mt-4">
                 <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#searchModal">Add Stock to Wishlist</button>
            </div>
        `;
        return;
    }

    const assetPromises = state.user.wishlist.map(async ticker => {
        const [profile, quote] = await Promise.all([getProfile(ticker), getQuote(ticker)]);
        return { ...profile, ...quote, symbol: ticker };
    });

    const assets = await Promise.all(assetPromises);

    let content = `
        <h2 class="h3 fw-bold mb-4">My Wishlist</h2>
        <div class="list-group">`;

    assets.forEach(asset => {
        content += `
            <a href="#" class="list-group-item list-group-item-action d-flex justify-content-between align-items-center" onclick="event.preventDefault(); showStockDetail('${asset.symbol}')">
                <div class="d-flex align-items-center">
                    <img src="${asset.logo}" class="asset-logo me-3 rounded-circle" alt="${asset.name}" onerror="this.src='https://placehold.co/40x40?text=${asset.symbol[0]}'">
                    <div>
                        <span class="fw-bold">${asset.symbol}</span>
                        <small class="d-block text-secondary">${asset.name || 'N/A'}</small>
                    </div>
                </div>
                <div class="text-end">
                    <p class="fw-bold mb-0">${formatCurrency(asset.c)}</p>
                    <small class="${getChangeClass(asset.d)}">${formatPercentage(asset.dp)}</small>
                </div>
            </a>`;
    });
    
    content += `</div>
        <div class="mt-4">
             <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#searchModal">Add Stock to Wishlist</button>
        </div>
    `;
    container.innerHTML = content;
}

function renderProfileEditPage() {
    const container = document.getElementById('profile-edit-content');
    container.innerHTML = `
        <h2 class="h3 fw-bold mb-4">Edit Profile</h2>
        <div class="card border-0 bg-body-tertiary rounded-4 p-4">
            <form id="profile-edit-form">
                <div class="text-center mb-4">
                    <img class="user-avatar-large rounded-circle mb-2" src="https://placehold.co/100x100/E2E8F0/4A5568?text=FA" alt="User profile picture">
                    <div><button type="button" class="btn btn-sm btn-link">Change Picture</button></div>
                </div>
                <div class="mb-3">
                    <label for="fullName" class="form-label">Full Name</label>
                    <input type="text" class="form-control" id="fullName" value="${state.user.fullName}">
                </div>
                <div class="mb-3">
                    <label for="email" class="form-label">Email address</label>
                    <input type="email" class="form-control" id="email" value="${state.user.email}">
                </div>
                <hr class="my-4">
                <h3 class="h5 fw-bold mb-3">Change Password</h3>
                <div class="mb-3">
                    <label for="currentPassword" class="form-label">Current Password</label>
                    <input type="password" class="form-control" id="currentPassword" placeholder="Enter current password">
                </div>
                <div class="mb-3">
                    <label for="newPassword" class="form-label">New Password</label>
                    <input type="password" class="form-control" id="newPassword" placeholder="Enter new password">
                </div>
                <div class="mb-3">
                    <label for="confirmPassword" class="form-label">Confirm New Password</label>
                    <input type="password" class="form-control" id="confirmPassword" placeholder="Confirm new password">
                </div>
                <button type="submit" class="btn btn-brand-green w-100 fw-semibold py-2 mt-3">Save Changes</button>
            </form>
        </div>
    `;

    document.getElementById('profile-edit-form').addEventListener('submit', (e) => {
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
    
    if (!profile || !quote) {
        contentArea.innerHTML = `<p class="text-secondary text-center">Could not load stock details.</p>`;
        return;
    }

    const holding = state.user.portfolio.find(h => h.ticker === ticker);
    const sharesOwned = holding ? holding.shares : 0;

    contentArea.innerHTML = `
        <header class="d-flex justify-content-between align-items-center mb-4">
            <button id="back-to-dashboard-btn-detail" class="btn btn-link p-2">
                <i class="bi bi-arrow-left fs-4"></i>
            </button>
            <h1 class="h5 fw-bold text-body-emphasis mb-0">${profile.ticker || ticker}</h1>
            <div id="watchlist-action-container" class="text-end" style="width: 40px;"></div>
        </header>
        <div class="max-w-xl mx-auto w-100">
            <div class="mb-4">
                <p class="text-secondary h5">${profile.name}</p>
                <div class="d-flex align-items-end gap-3">
                    <p class="display-4 fw-bold mb-0">${formatCurrency(quote.c)}</p>
                    <p class="h5 fw-semibold mb-2 ${getChangeClass(quote.d)}">${quote.d >= 0 ? '+' : ''}${quote.d.toFixed(2)} (${formatPercentage(quote.dp)})</p>
                </div>
            </div>
            <div class="chart-container-large mb-4"><canvas id="mainStockChart"></canvas></div>
            <div id="time-range-selector" class="btn-group w-100 mb-4" role="group">
                <button type="button" class="btn btn-outline-secondary" data-range="1D">1D</button>
                <button type="button" class="btn btn-outline-secondary" data-range="1M">1M</button>
                <button type="button" class="btn btn-outline-secondary" data-range="3M">3M</button>
                <button type="button" class="btn btn-outline-secondary active" data-range="1Y">1Y</button>
            </div>
            <div class="d-grid gap-3" style="grid-template-columns: 1fr 1fr;">
                <button class="btn btn-brand-green btn-lg fw-bold" onclick="openTradeModal('${ticker}', 'buy')">Buy</button>
                <button class="btn btn-brand-red btn-lg fw-bold" onclick="openTradeModal('${ticker}', 'sell')" ${!sharesOwned ? 'disabled' : ''}>Sell</button>
            </div>
            <div id="stock-news-container" class="mt-5">
                <h3 class="h4 fw-bold mb-3">Relevant News</h3>
                <div id="stock-news-list"></div>
            </div>
        </div>
    `;

    document.getElementById('back-to-dashboard-btn-detail').addEventListener('click', () => window.history.back());
    document.querySelectorAll('#time-range-selector button').forEach(button => {
        button.addEventListener('click', (e) => {
            document.querySelectorAll('#time-range-selector button').forEach(btn => btn.classList.remove('active'));
            e.currentTarget.classList.add('active');
            updateStockChart(e.currentTarget.dataset.range);
        });
    });

    updateStockChart('1Y');
    loadStockNews(ticker);
    renderWatchlistButton(ticker);
}

async function loadStockNews(ticker) {
    const container = document.getElementById('stock-news-list');
    if (!container) return;
    container.innerHTML = `<div class="spinner-border spinner-border-sm" role="status"><span class="visually-hidden">Loading...</span></div>`;
    const news = await getCompanyNews(ticker);
    if (!news || news.length === 0) {
        container.innerHTML = `<p class="text-secondary">No recent news found for ${ticker}.</p>`;
        return;
    }
    
    let content = '<div class="list-group">';
    news.slice(0, 5).forEach(article => {
        content += `
            <a href="${article.url}" target="_blank" class="list-group-item list-group-item-action">
                <p class="fw-bold mb-1">${article.headline}</p>
                <small class="text-secondary">${new Date(article.datetime * 1000).toLocaleDateString()}</small>
            </a>`;
    });
    container.innerHTML = content + '</div>';
}

function toggleWatchlist(ticker) {
    const watchlist = state.user.wishlist;
    const index = watchlist.indexOf(ticker);
    
    if (index > -1) {
        watchlist.splice(index, 1);
    } else {
        watchlist.push(ticker);
    }
    
    renderWatchlistButton(ticker);
}

function renderWatchlistButton(ticker) {
    const container = document.getElementById('watchlist-action-container');
    if (!container) return;
    
    const isInWatchlist = state.user.wishlist.includes(ticker);
    const btnClass = isInWatchlist ? 'text-brand-amber' : 'text-secondary';
    const iconClass = isInWatchlist ? 'bi-star-fill' : 'bi-star';
    
    container.innerHTML = `
        <button class="btn btn-link p-2" onclick="toggleWatchlist('${ticker}')">
            <i class="bi ${iconClass} fs-4 ${btnClass}"></i>
        </button>
    `;
}

// --- CHARTING ---
async function updateStockChart(range) {
    if (!state.currentStock) return;
    
    const now = Math.floor(Date.now() / 1000);
    let from, resolution;
    switch(range) {
        case '1D': from = now - (24 * 60 * 60); resolution = '15'; break;
        case '1M': from = now - (30 * 24 * 60 * 60); resolution = 'D'; break;
        case '3M': from = now - (90 * 24 * 60 * 60); resolution = 'D'; break;
        default: from = now - (365 * 24 * 60 * 60); resolution = 'W'; break;
    }

    const candles = await getCandles(state.currentStock, resolution, from, now);
    if(!candles || !candles.c || candles.c.length === 0) {
        console.error("Could not fetch candle data");
        const chartContainer = document.getElementById('mainStockChart')?.parentElement;
        if(chartContainer) chartContainer.innerHTML = `<p class="text-secondary text-center h-100 d-flex align-items-center justify-content-center">Could not load chart data.</p>`;
        return;
    }
    
    const isPositive = candles.c[candles.c.length - 1] > candles.c[0];
    createMainStockChart(candles.t.map(t => new Date(t*1000)), candles.c, isPositive);
}

function createMainStockChart(labels, data, isPositive) {
     const canvasEl = document.getElementById('mainStockChart');
     if (!canvasEl) return;
     if(state.chartInstances.main) state.chartInstances.main.destroy();
     
     const borderColor = isPositive ? 'rgba(34, 197, 94, 1)' : 'rgba(239, 68, 68, 1)';
     
     const ctx = canvasEl.getContext('2d');
     const gradient = ctx.createLinearGradient(0, 0, 0, canvasEl.offsetHeight);
     gradient.addColorStop(0, isPositive ? 'rgba(34, 197, 94, 0.4)' : 'rgba(239, 68, 68, 0.4)');
     gradient.addColorStop(1, 'rgba(0,0,0,0)');
     
     state.chartInstances.main = new Chart(ctx, {
        type: 'line', 
        data: { labels, datasets: [{ data, borderColor, borderWidth: 2, pointRadius: 0, tension: 0.3, fill: true, backgroundColor: gradient }] },
        options: { 
            responsive: true, maintainAspectRatio: false, 
            plugins: { legend: { display: false }, tooltip: { mode: 'index', intersect: false, callbacks: { label: (c) => `Price: ${formatCurrency(c.parsed.y)}` } } }, 
            scales: { x: { display: false }, y: { display: false } } 
        }
    });
}

// --- TRADE MODAL & LOGIC ---
async function openTradeModal(ticker, action) {
    const form = document.getElementById('trade-form');
    form.reset();
    form.classList.remove('was-validated');

    const quote = await getQuote(ticker);
    if (!quote || !quote.c) {
        alert("Could not fetch current price. Please try again.");
        return;
    }

    const currentPrice = quote.c;
    const holding = state.user.portfolio.find(h => h.ticker === ticker);
    const sharesOwned = holding ? holding.shares : 0;

    const modalTitle = document.getElementById('tradeModalLabel');
    const confirmBtn = document.getElementById('confirm-trade-btn');
    modalTitle.textContent = `${action === 'buy' ? 'Buy' : 'Sell'} ${ticker}`;
    confirmBtn.className = `btn ${action === 'buy' ? 'btn-brand-green' : 'btn-brand-red'}`;
    confirmBtn.textContent = `Confirm ${action === 'buy' ? 'Purchase' : 'Sale'}`;

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
    const sharesInput = document.getElementById('trade-shares');
    const shares = parseFloat(sharesInput.value);
    const price = parseFloat(document.getElementById('trade-price').value);

    if (!isNaN(shares) && !isNaN(price) && shares > 0) {
        const total = shares * price;
        document.getElementById('modal-estimated-total').textContent = formatCurrency(total);
    } else {
        document.getElementById('modal-estimated-total').textContent = formatCurrency(0);
    }
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
            errorDiv.textContent = `Insufficient funds. You need ${formatCurrency(cost)} but only have ${formatCurrency(state.user.cash)}.`;
            sharesInput.classList.add('is-invalid');
            return;
        }
        
        state.user.cash -= cost;
        const existingHolding = state.user.portfolio.find(h => h.ticker === ticker);
        if (existingHolding) {
            existingHolding.shares += shares;
        } else {
            state.user.portfolio.push({ ticker, shares });
        }

    } else { // sell action
        const existingHolding = state.user.portfolio.find(h => h.ticker === ticker);
        if (!existingHolding || shares > existingHolding.shares) {
            errorDiv.textContent = `You cannot sell more shares than you own (${existingHolding ? existingHolding.shares : 0}).`;
            sharesInput.classList.add('is-invalid');
            return;
        }

        const proceeds = shares * price;
        state.user.cash += proceeds;
        existingHolding.shares -= shares;

        if (existingHolding.shares === 0) {
            state.user.portfolio = state.user.portfolio.filter(h => h.ticker !== ticker);
        }
    }
    
    state.tradeModal.hide();
    showStockDetail(ticker);
    const activeContent = document.querySelector('.main-content-area[style*="block"]');
    if (activeContent) {
        showMainContent(activeContent.id);
    } else {
        renderHomePageSummary();
    }
}


// --- EVENT HANDLERS & OTHER LOGIC ---
function toggleTheme() {
    const isDark = document.documentElement.dataset.bsTheme === 'dark';
    document.documentElement.dataset.bsTheme = isDark ? 'light' : 'dark';
    localStorage.setItem('theme', document.documentElement.dataset.bsTheme);
    
    if(state.currentStock) {
        const activeRangeButton = document.querySelector('#time-range-selector .active');
        if (activeRangeButton) updateStockChart(activeRangeButton.dataset.range);
    }
    if (document.getElementById('portfolio-content').style.display === 'block') {
        const activePortfolioRange = document.querySelector('#portfolio-range-selector .active');
        if (activePortfolioRange) {
            updatePortfolioView(activePortfolioRange.dataset.range);
        }
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
    if (query.length < 2) {
        resultsContainer.innerHTML = '';
        return;
    }
    const searchData = await searchSymbols(query);
    if (!searchData || searchData.count === 0) {
        resultsContainer.innerHTML = '<p class="text-secondary">No results found.</p>';
        return;
    }
    
    let content = '<div class="list-group">';
    searchData.result.forEach(item => {
        content += `<a href="#" class="list-group-item list-group-item-action" data-ticker="${item.symbol}" onclick="event.preventDefault(); selectSearchResult(this.dataset.ticker)">
                <div class="fw-bold">${item.symbol}</div>
                <div class="small text-secondary">${item.description}</div>
            </a>`;
    });
    resultsContainer.innerHTML = content + '</div>';
}

function selectSearchResult(ticker) {
    state.searchModal.hide();
    showStockDetail(ticker);
}

function getUserLocation() {
    const container = document.getElementById('location-info');
    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
            async (position) => {
                const { latitude, longitude } = position.coords;
                const locationData = await getCityFromCoords(latitude, longitude);
                if (locationData && locationData.address) {
                    const { city, town, village, country } = locationData.address;
                    container.textContent = `${city || town || village || 'Unknown City'}, ${country || 'Unknown Country'}`;
                } else { container.textContent = "Could not retrieve city name."; }
            },
            (error) => {
                container.textContent = "Could not retrieve location.";
                console.error("Geolocation Error:", error);
            }
        );
    } else { container.textContent = "Geolocation is not supported by this browser."; }
}

function showPaymentPage() {
    const isYearly = document.getElementById('plan-toggle').checked;
    state.user.isYearlyPlan = isYearly;

    const monthlyPlan = document.getElementById('payment-monthly-plan');
    const yearlyPlan = document.getElementById('payment-yearly-plan');
    const buyNowBtn = document.getElementById('buy-now-btn');

    if (isYearly) {
        monthlyPlan.classList.add('d-none');
        yearlyPlan.classList.remove('d-none');
        buyNowBtn.classList.remove('btn-brand-green');
        buyNowBtn.classList.add('btn-warning');

    } else {
        monthlyPlan.classList.remove('d-none');
        yearlyPlan.classList.add('d-none');
        buyNowBtn.classList.add('btn-brand-green');
        buyNowBtn.classList.remove('btn-warning');
    }
    navigateToPage('payment-page');
}


// --- INITIALIZATION ---
document.addEventListener('DOMContentLoaded', () => {
    // --- Event Listeners ---
    document.getElementById('lets-go-btn').addEventListener('click', () => navigateToPage('auth-container'));
    document.getElementById('login-form').addEventListener('submit', (e) => { e.preventDefault(); navigateToPage('home-page'); });
    document.getElementById('register-form').addEventListener('submit', (e) => { e.preventDefault(); navigateToPage('home-page'); }); 
    
    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', (e) => { e.preventDefault(); showMainContent(link.dataset.target); });
    });

    document.getElementById('show-register').addEventListener('click', (e) => { e.preventDefault(); showAuthSubPage('register-page'); });
    document.getElementById('show-login-from-register').addEventListener('click', (e) => { e.preventDefault(); showAuthSubPage('login-page'); });
    
    document.getElementById('back-to-profile-btn').addEventListener('click', () => window.history.back());
    document.getElementById('back-to-pro-btn').addEventListener('click', () => navigateToPage('pro-page'));

    document.getElementById('plan-toggle').addEventListener('change', (e) => {
        const isYearly = e.currentTarget.checked;
        document.getElementById('monthly-plan').classList.toggle('d-none', isYearly);
        document.getElementById('yearly-plan').classList.toggle('d-none', !isYearly);
    });

    document.getElementById('upgrade-now-btn').addEventListener('click', showPaymentPage);
    document.getElementById('search-input').addEventListener('input', handleSearch);

    document.getElementById('trade-form').addEventListener('submit', handleTrade);
    document.getElementById('trade-shares').addEventListener('input', updateEstimatedTotal);

    // --- Theme Setup ---
    const savedTheme = localStorage.getItem('theme');
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    document.documentElement.dataset.bsTheme = savedTheme || (prefersDark ? 'dark' : 'light');

    // --- Bootstrap Modal instances ---
    state.searchModal = new bootstrap.Modal(document.getElementById('searchModal'));
    state.tradeModal = new bootstrap.Modal(document.getElementById('tradeModal'));
    
    // --- Initial Page Load ---
    getExchangeRates();
    document.getElementById('dashboard-username').innerText = state.user.fullName;

    window.addEventListener('popstate', (event) => {
        const pageId = window.location.hash.substring(1);
        if (pageId && document.getElementById(pageId)) {
           navigateToPage(pageId);
        } else {
           navigateToPage('welcome-page');
        }
    });

    const initialPage = window.location.hash.substring(1) || 'welcome-page';
    navigateToPage(initialPage);
    
    if (initialPage === 'home-page') {
        const activeLink = document.querySelector('.nav-link.active');
        if (activeLink) {
             showMainContent(activeLink.dataset.target || 'markets-content');
        } else {
             showMainContent('markets-content');
        }
    }
});
