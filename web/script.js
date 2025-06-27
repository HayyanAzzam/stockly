// --- CONFIG & STATE ---
// !!! IMPORTANT: REPLACE WITH YOUR FINNHUB API KEY
const FINNHUB_API_KEY = 'd1f7lvhr01qsg7davdsgd1f7lvhr01qsg7davdt0';
const FINNHUB_BASE_URL = 'https://finnhub.io/api/v1';

let state = {
    user: {
        fullName: 'Fadi Abbara',
        email: 'demo@stockly.com',
        portfolio: ['AAPL', 'MSFT', 'TSLA', 'GOOGL']
    },
    currentStock: null,
    currency: 'USD',
    exchangeRates: {},
    chartInstances: {
        main: null
    },
    searchModal: null,
};

// --- API FUNCTIONS ---
async function apiRequest(endpoint, base = FINNHUB_BASE_URL, token = `&token=${FINNHUB_API_KEY}`) {
    try {
        const response = await fetch(`${base}${endpoint}${token}`);
        if (!response.ok) {
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
    const from = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]; // 30 days ago
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
    return apiRequest(endpoint, '', ''); // No base URL or token needed
}

// --- UTILITY & FORMATTING FUNCTIONS ---
function formatCurrency(value) {
    if (typeof value !== 'number') return '$--. L';
    const rate = state.exchangeRates[state.currency] || 1;
    const convertedValue = value * rate;
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: state.currency,
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
        // Update hash without causing a page jump if it's the same hash
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
    }
}

// --- RENDER FUNCTIONS ---
async function renderHomePageSummary() {
    let totalValue = 0;
    let openingTotalValue = 0;

    const portfolioQuotes = await Promise.all(state.user.portfolio.map(ticker => getQuote(ticker)));
    
    portfolioQuotes.forEach(quote => {
        if(quote && quote.c) {
            totalValue += quote.c * 10; // Assume 10 shares
            openingTotalValue += quote.o * 10;
        }
    });

    const totalChangeValue = totalValue - openingTotalValue;
    const percentageChange = openingTotalValue ? (totalChangeValue / openingTotalValue) * 100 : 0;

    document.getElementById('summary-portfolio-value').innerText = formatCurrency(totalValue);
    const portfolioChangeEl = document.getElementById('summary-portfolio-change');
    portfolioChangeEl.innerText = `${totalChangeValue >= 0 ? '+' : ''}${formatPercentage(percentageChange)} Today`;
    portfolioChangeEl.className = `fw-semibold mb-0 small ${getChangeClass(totalChangeValue)}`;

    const trendingTicker = 'AAPL'; // Example for trending
    const quote = await getQuote(trendingTicker);
    if(quote) {
        document.getElementById('summary-trending-stock').innerText = formatCurrency(quote.c);
        const trendingChangeEl = document.getElementById('summary-trending-change');
        trendingChangeEl.innerText = formatPercentage(quote.dp);
        trendingChangeEl.className = `fw-semibold mb-0 small ${getChangeClass(quote.dp)}`;
    }
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

async function renderPortfolioPage() {
    const container = document.getElementById('portfolio-content');
    container.innerHTML = `<div class="text-center p-5"><div class="spinner-border" role="status"><span class="visually-hidden">Loading...</span></div></div>`;
    
    let totalValue = 0;
    let totalChange = 0;

    const assetPromises = state.user.portfolio.map(async ticker => {
        const quote = await getQuote(ticker);
        const profile = await getProfile(ticker);
        const value = quote.c * 10; // Assuming 10 shares
        totalValue += value;
        totalChange += quote.d * 10;
        return { ...profile, ...quote, value, symbol: ticker };
    });

    const assets = await Promise.all(assetPromises);
    const isPositive = totalChange >= 0;

    let content = `
        <h2 class="h3 fw-bold mb-4">My Portfolio</h2>
        <div class="card bg-body-tertiary border-0 p-4 rounded-4 shadow-sm mb-5">
            <p class="text-secondary mb-0">Total Value</p>
            <p class="display-5 fw-bold">${formatCurrency(totalValue)}</p>
            <p class="h5 fw-semibold ${getChangeClass(totalChange)}">${isPositive ? '+' : ''}${formatCurrency(totalChange)} Today</p>
        </div>
        <h3 class="h5 fw-bold mb-3">Your Assets</h3>
        <div class="list-group">`;

    assets.forEach(asset => {
        content += `
            <a href="#" class="list-group-item list-group-item-action d-flex justify-content-between align-items-center" onclick="event.preventDefault(); showStockDetail('${asset.symbol}')">
                <div class="d-flex align-items-center">
                    <img src="${asset.logo}" class="asset-logo me-3 rounded-circle" alt="${asset.name}" onerror="this.src='https://placehold.co/40x40?text=${asset.symbol[0]}'">
                    <div>
                        <span class="fw-bold">${asset.symbol}</span>
                        <small class="d-block text-secondary">${asset.name}</small>
                    </div>
                </div>
                <div class="text-end">
                    <p class="fw-bold mb-0">${formatCurrency(asset.value)}</p>
                    <small class="${getChangeClass(asset.d)}">${formatPercentage(asset.dp)}</small>
                </div>
            </a>`;
    });
    
    content += `</div>`;
    container.innerHTML = content;
}

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

// --- STOCK DETAIL PAGE ---
async function showStockDetail(ticker) {
    state.currentStock = ticker;
    navigateToPage('stock-detail-page');
    
    document.getElementById('detail-stock-name').innerText = 'Loading...';
    document.getElementById('detail-stock-price').innerText = '';
    document.getElementById('detail-stock-change').innerText = '';

    const [quote, profile] = await Promise.all([getQuote(ticker), getProfile(ticker)]);
    
    document.getElementById('detail-stock-ticker-header').innerText = profile.ticker || ticker;
    document.getElementById('detail-stock-name').innerText = profile.name;
    document.getElementById('detail-stock-price').innerText = formatCurrency(quote.c);
    
    const changeEl = document.getElementById('detail-stock-change');
    changeEl.innerText = `${quote.d >= 0 ? '+' : ''}${quote.d.toFixed(2)} (${formatPercentage(quote.dp)})`;
    changeEl.className = `h5 fw-semibold mb-2 ${getChangeClass(quote.d)}`;

    const activeRangeButton = document.querySelector('#time-range-selector button.active') || document.querySelector('#time-range-selector button[data-range="1Y"]');
    activeRangeButton.click();
    
    loadStockNews(ticker);
}

async function loadStockNews(ticker) {
    const container = document.getElementById('stock-news-list');
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
    if(!candles || !candles.c) {
        console.error("Could not fetch candle data");
        return;
    }
    
    const isPositive = candles.c[candles.c.length - 1] > candles.c[0];
    createMainStockChart(candles.t.map(t => new Date(t*1000)), candles.c, isPositive);
}

function createMainStockChart(labels, data, isPositive) {
     const canvasEl = document.getElementById('mainStockChart');
     if (!canvasEl) return;
     if(state.chartInstances.main) state.chartInstances.main.destroy();

     const isDark = document.documentElement.dataset.bsTheme === 'dark';
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

// --- EVENT HANDLERS & OTHER LOGIC ---
function toggleTheme() {
    const isDark = document.documentElement.dataset.bsTheme === 'dark';
    document.documentElement.dataset.bsTheme = isDark ? 'light' : 'dark';
    localStorage.setItem('theme', document.documentElement.dataset.bsTheme);
    if(state.currentStock) {
        const activeRangeButton = document.querySelector('#time-range-selector .active');
        if (activeRangeButton) updateStockChart(activeRangeButton.dataset.range);
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

// --- INITIALIZATION ---
document.addEventListener('DOMContentLoaded', () => {
    // --- Event Listeners ---
    document.getElementById('lets-go-btn').addEventListener('click', () => navigateToPage('auth-container'));
    document.getElementById('login-form').addEventListener('submit', (e) => { e.preventDefault(); navigateToPage('home-page'); });
    document.getElementById('register-form').addEventListener('submit', (e) => { e.preventDefault(); navigateToPage('login-page'); });
    
    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', (e) => { e.preventDefault(); showMainContent(link.dataset.target); });
    });

    document.getElementById('show-register').addEventListener('click', (e) => { e.preventDefault(); showAuthSubPage('register-page'); });
    document.getElementById('show-login-from-register').addEventListener('click', (e) => { e.preventDefault(); showAuthSubPage('login-page'); });
    
    document.getElementById('back-to-dashboard-btn').addEventListener('click', () => window.history.back());
    document.getElementById('back-to-profile-btn').addEventListener('click', () => window.history.back());

    document.querySelectorAll('#time-range-selector button').forEach(button => {
        button.addEventListener('click', (e) => {
            document.querySelectorAll('#time-range-selector button').forEach(btn => btn.classList.remove('active'));
            e.currentTarget.classList.add('active');
            updateStockChart(e.currentTarget.dataset.range);
        });
    });

    document.getElementById('plan-toggle').addEventListener('change', (e) => {
        const isYearly = e.currentTarget.checked;
        document.getElementById('monthly-plan').classList.toggle('d-none', isYearly);
        document.getElementById('yearly-plan').classList.toggle('d-none', !isYearly);
    });

    document.getElementById('search-input').addEventListener('input', handleSearch);

    // --- Theme Setup ---
    const savedTheme = localStorage.getItem('theme');
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    document.documentElement.dataset.bsTheme = savedTheme || (prefersDark ? 'dark' : 'light');

    // --- Bootstrap Modal instance ---
    state.searchModal = new bootstrap.Modal(document.getElementById('searchModal'));
    
    // --- Initial Page Load ---
    getExchangeRates();
    document.getElementById('dashboard-username').innerText = state.user.fullName;

    // Handle history and initial page load
    window.addEventListener('popstate', () => {
        const pageId = window.location.hash.substring(1) || 'welcome-page';
        navigateToPage(pageId);
    });

    const initialPage = window.location.hash.substring(1) || 'welcome-page';
    navigateToPage(initialPage);
    // If loading into the main app, show default content
    if (initialPage === 'home-page') {
        showMainContent('markets-content');
    }
});
