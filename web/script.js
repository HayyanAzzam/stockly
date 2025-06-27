// --- STATE & MOCK DATA ---
let currentStockTicker = null;
let mainChartInstance = null;
let portfolioChartInstance = null;

const mockUser = { fullName: 'Fadi Abbara', email: 'fadi@stockly.com' };

const mockStockData = {
    'AAPL': { name: 'Apple Inc.', price: 238.45, change: 3.2, changePercent: 1.36, positive: true, logo: 'https://i.ibb.co/bM8LHkTz/8.jpg'},
    'GOOGL': { name: 'Alphabet Inc.', price: 179.45, change: -1.80, changePercent: -1.0, positive: false, logo: 'https://i.ibb.co/cKp0HYBp/7.jpg'},
    'TSLA': { name: 'Tesla Inc.', price: 183.01, change: 5.01, changePercent: 2.8, positive: true, logo: 'https://i.ibb.co/k3CBgB9/stockly-logo.png' },
    'MSFT': { name: 'Microsoft Corp.', price: 449.78, change: 2.10, changePercent: 0.47, positive: true, logo: 'https://i.ibb.co/s9DtwFG6/3.jpg'},
    'AMZN': { name: 'Amazon.com, Inc.', price: 183.66, change: -2.01, changePercent: -1.08, positive: false, logo: 'https://i.ibb.co/nNGXMBTp/5.jpg'},
    'NVDA': { name: 'NVIDIA Corp.', price: 121.87, change: 1.12, changePercent: 0.93, positive: true, logo: 'https://i.ibb.co/fzwV969j/4.jpg'},
};

const mockChartData = {
    '1D': { labels: ['-6h', '-5h', '-4h', '-3h', '-2h', '-1h', 'now'], data: [220, 225, 223, 230, 228, 235, 238.45] },
    '1W': { labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'], data: [210, 215, 220, 228, 238.45] },
    '1M': { labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'], data: [200, 220, 215, 238.45] },
    '1Y': { labels: ['Q1', 'Q2', 'Q3', 'Q4'], data: [150, 170, 190, 238.45] },
};

const mockUserPortfolio = {
    daily: { value: 156842.50, change: 3764.22, changePercent: 2.4, positive: true, chartData: [152000, 153000, 152500, 154000, 155500, 156842.50] },
    weekly: { value: 156842.50, change: 9724.25, changePercent: 6.2, positive: true, chartData: [147000, 149000, 152500, 151000, 154000, 156842.50] },
    monthly: { value: 156842.50, change: -22758.16, changePercent: -14.5, positive: false, chartData: [179000, 172000, 162500, 168000, 154000, 156842.50] },
    assets: [
        { ticker: 'AAPL', shares: 100, value: 23845.00, changePercent: 1.36 },
        { ticker: 'MSFT', shares: 150, value: 67467.00, changePercent: 0.47 },
        { ticker: 'TSLA', shares: 350, value: 64053.50, changePercent: 2.8 },
    ]
};

const mockNewsData = [
    { id: 1, ticker: 'AAPL', timestamp: '3 hours ago', headline: 'Apple Reports Record Q4 Earnings', imageUrl: 'https://images.unsplash.com/photo-1579548122080-c35fd6820ecb?auto=format&fit=crop&w=400&q=60' },
    { id: 2, ticker: 'TSLA', timestamp: '8 hours ago', headline: 'Tesla Stock Surges on Autonomous Vehicle Breakthrough', imageUrl: 'https://images.unsplash.com/photo-1617704548623-34047b423862?auto=format&fit=crop&w=400&q=60' }
];

// --- PAGE ROUTING & NAVIGATION ---
function navigateToPage(pageId) {
    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
    document.getElementById(pageId)?.classList.add('active');
    document.body.style.overflow = pageId === 'home-page' ? 'auto' : 'hidden';
}

function showAuthSubPage(subPageId) {
    navigateToPage('auth-container');
    document.querySelectorAll('.auth-sub-page').forEach(p => p.classList.add('hidden'));
    document.getElementById(subPageId)?.classList.remove('hidden');
}

function showMainContent(targetId) {
    document.querySelectorAll('.main-content-area').forEach(area => {
        area.classList.toggle('active', area.id === targetId);
    });
    document.querySelectorAll('.nav-link').forEach(link => {
        link.classList.toggle('active', link.dataset.target === targetId);
    });
    
    switch(targetId) {
        case 'markets-content': initializeDashboard(); break;
        case 'portfolio-content': showPortfolioPage(); break;
        case 'news-content': showNewsPage(); break;
        case 'profile-content': showProfileSettingsPage(); break;
    }
}

// --- INITIALIZATION & PAGE RENDERING ---
function initializeDashboard() {
    document.getElementById('dashboard-username').innerText = mockUser.fullName;
    
    // Portfolio Value Card
    const portfolio = mockUserPortfolio.daily;
    document.getElementById('dashboard-portfolio-value').innerText = `$${portfolio.value.toLocaleString('en-US')}`;
    const portfolioChangeEl = document.getElementById('dashboard-portfolio-change');
    portfolioChangeEl.innerText = `${portfolio.positive ? '+' : ''}${portfolio.changePercent}% Today`;
    portfolioChangeEl.className = `text-sm font-semibold mt-1 ${portfolio.positive ? 'text-brand-green' : 'text-brand-red'}`;

    // Trending Card (using Tesla as an example)
    const trending = mockStockData['TSLA'];
    document.getElementById('dashboard-trending-name').innerText = trending.name;
    document.getElementById('dashboard-trending-price').innerText = `$${trending.price}`;
    const trendingChangeEl = document.getElementById('dashboard-trending-change');
    trendingChangeEl.innerText = `${trending.changePercent}%`;
    trendingChangeEl.className = `text-sm font-semibold mt-1 ${trending.positive ? 'text-brand-green' : 'text-brand-red'}`;
    document.getElementById('dashboard-trending-chart').innerHTML = `<svg class="w-12 h-8 ${trending.positive ? 'text-brand-green' : 'text-brand-red'}" viewBox="0 0 100 40"><path d="M0 25 L15 15 L30 20 L45 5 L60 15 L75 10 L90 25 L100 20" fill="none" stroke="currentColor" stroke-width="3"/></svg>`;

    // Total Gain/Loss Card
    const gainLossEl = document.getElementById('dashboard-gain-loss');
    gainLossEl.innerText = `${portfolio.positive ? '+' : ''}$${portfolio.change.toLocaleString('en-US', {minimumFractionDigits: 2})}`;
    gainLossEl.className = `text-3xl font-bold mt-1 ${portfolio.positive ? 'text-brand-green' : 'text-brand-red'}`;
    
    // Market Indices
    const indicesContainer = document.getElementById('market-indices-container');
    indicesContainer.innerHTML = '';
    ['AAPL', 'MSFT', 'NVDA', 'TSLA'].forEach(ticker => {
        const stock = mockStockData[ticker];
        const cardColor = stock.positive ? 'bg-green-100 dark:bg-green-900/40' : 'bg-red-100 dark:bg-red-900/40';
        const textColor = stock.positive ? 'text-green-800 dark:text-green-300' : 'text-red-800 dark:text-red-300';
        const chartColor = stock.positive ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400';
        indicesContainer.innerHTML += `
            <div class="${cardColor} p-3 rounded-xl cursor-pointer" onclick="showStockDetail('${ticker}')">
                <p class="font-bold ${textColor}">${ticker}</p>
                <div class="flex justify-between items-end mt-2">
                    <p class="text-lg font-bold ${textColor}">$${stock.price}</p>
                    <svg class="w-10 h-6 ${chartColor}" viewBox="0 0 100 40"><path d="${stock.positive ? 'M0 30 L20 20 L40 25 L60 10 L80 15 L100 5' : 'M0 10 L20 20 L40 15 L60 30 L80 25 L100 35'}" fill="none" stroke="currentColor" stroke-width="4"/></svg>
                </div>
            </div>`;
    });

    // Stocks Container
    const stocksContainer = document.getElementById('stocks-container');
    stocksContainer.innerHTML = '';
    Object.values(mockStockData).forEach(stock => {
        stocksContainer.innerHTML += `
            <div class="bg-light-card dark:bg-dark-card p-4 rounded-xl shadow flex justify-center items-center h-24 lg:h-28 cursor-pointer" onclick="showStockDetail('${Object.keys(mockStockData).find(key => mockStockData[key] === stock)}')">
                <img src="${stock.logo}" alt="${stock.name} Logo" class="w-12 h-12 object-contain">
            </div>`;
    });
    
    // Recommended Investments
    const recommendedContainer = document.getElementById('recommended-investments-container');
    recommendedContainer.innerHTML = '';
    mockUserPortfolio.assets.forEach(asset => {
        const stock = mockStockData[asset.ticker];
        const cardColor = stock.positive ? 'bg-green-100 dark:bg-green-900/40' : 'bg-red-100 dark:bg-red-900/40';
        const textColor = stock.positive ? 'text-green-800 dark:text-green-300' : 'text-red-800 dark:text-red-300';
        recommendedContainer.innerHTML +=`
            <div class="${cardColor} p-4 rounded-xl cursor-pointer" onclick="showStockDetail('${asset.ticker}')">
               <span class="font-bold ${textColor}">${stock.name} (${asset.ticker})</span>
            </div>`;
    });
}

function showStockDetail(ticker, timeRange = '1D') {
    currentStockTicker = ticker;
    const stock = mockStockData[ticker];
    if (!stock) return;

    navigateToPage('stock-detail-page');

    document.getElementById('detail-stock-ticker-header').innerText = ticker;
    document.getElementById('detail-stock-name').innerText = stock.name;
    document.getElementById('detail-stock-price').innerText = `$${stock.price.toFixed(2)}`;
    
    const changeEl = document.getElementById('detail-stock-change');
    changeEl.innerText = `${stock.positive ? '+' : ''}${stock.change.toFixed(2)} (${stock.changePercent}%)`;
    changeEl.className = `text-lg font-semibold ${stock.positive ? 'text-brand-green' : 'text-brand-red'}`;

    updateStockChart(timeRange);

    document.querySelectorAll('#time-range-selector .time-button').forEach(button => {
        button.classList.toggle('active', button.dataset.range === timeRange);
    });
}

function showPortfolioPage() {
    updatePortfolioView('daily');
    const container = document.getElementById('portfolio-assets-container');
    container.innerHTML = '';
    mockUserPortfolio.assets.forEach(asset => {
        const stock = mockStockData[asset.ticker];
        const isPositive = asset.changePercent >= 0;
        container.innerHTML += `
            <div class="bg-light-card dark:bg-dark-card p-4 rounded-xl shadow flex justify-between items-center cursor-pointer" onclick="showStockDetail('${asset.ticker}')">
               <div>
                   <p class="font-bold text-light-text dark:text-dark-text">${asset.ticker}</p>
                   <p class="text-sm text-light-text-secondary dark:text-dark-text-secondary">${asset.shares} shares</p>
               </div>
               <div class="text-right">
                   <p class="font-bold text-light-text dark:text-dark-text">$${asset.value.toLocaleString()}</p>
                   <p class="text-sm font-semibold ${isPositive ? 'text-brand-green' : 'text-brand-red'}">${isPositive ? '+' : ''}${asset.changePercent}%</p>
               </div>
            </div>`;
    });
}

function showNewsPage() {
    const articlesContainer = document.getElementById('news-articles-container');
    articlesContainer.innerHTML = '';
    mockNewsData.forEach(article => {
        articlesContainer.innerHTML += `
            <div class="bg-light-card dark:bg-dark-card rounded-2xl shadow-lg overflow-hidden">
                <img src="${article.imageUrl}" alt="${article.headline}" class="w-full h-48 object-cover">
                <div class="p-6">
                    <div class="flex items-center text-sm mb-2">
                        <span class="px-2 py-1 bg-green-200 dark:bg-green-900/60 text-green-800 dark:text-green-300 rounded-md font-semibold cursor-pointer" onclick="showStockDetail('${article.ticker}')">${article.ticker}</span>
                        <span class="ml-3 text-light-text-secondary dark:text-dark-text-secondary">${article.timestamp}</span>
                    </div>
                    <h3 class="text-xl font-bold mb-2 text-light-text dark:text-dark-text">${article.headline}</h3>
                    <a href="#" class="font-semibold text-brand-green hover:underline">Read More &rarr;</a>
                </div>
            </div>`;
    });
}

function showProfileSettingsPage() {
    document.getElementById('profile-fullname').innerText = mockUser.fullName;
    document.getElementById('profile-email').innerText = mockUser.email;
}

// --- CHARTING FUNCTIONS ---
function createMainStockChart(canvasEl, chartConfig) {
     if (!canvasEl) return;
     if(mainChartInstance) mainChartInstance.destroy();
     const isDark = document.documentElement.classList.contains('dark');
     
     const ctx = canvasEl.getContext('2d');
     const borderColor = chartConfig.positive ? 'rgba(34, 197, 94, 1)' : 'rgba(239, 68, 68, 1)';
     const gradient = ctx.createLinearGradient(0, 0, 0, canvasEl.offsetHeight);
     gradient.addColorStop(0, chartConfig.positive ? 'rgba(34, 197, 94, 0.4)' : 'rgba(239, 68, 68, 0.4)');
     gradient.addColorStop(1, isDark ? 'rgba(18, 18, 18, 0)' : 'rgba(243, 244, 246, 0)');
     
     mainChartInstance = new Chart(ctx, {
        type: 'line', 
        data: { labels: chartConfig.labels, datasets: [{ label: 'Price', data: chartConfig.data, borderColor: borderColor, borderWidth: 3, pointRadius: 0, tension: 0.4, fill: true, backgroundColor: gradient }] },
        options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false }, tooltip: { mode: 'index', intersect: false, displayColors: false, callbacks: { label: (context) => `$${context.parsed.y.toFixed(2)}` } } }, scales: { x: { display: false }, y: { display: false } } }
    });
}

function createPortfolioChart(data, isPositive) {
    const canvasEl = document.getElementById('portfolioChart');
    if (!canvasEl) return;
    if (portfolioChartInstance) portfolioChartInstance.destroy();
    
    const ctx = canvasEl.getContext('2d');
    const borderColor = isPositive ? 'rgba(34, 197, 94, 1)' : 'rgba(239, 68, 68, 1)';
    
    portfolioChartInstance = new Chart(ctx, {
        type: 'line', 
        data: { labels: data.map((_, i) => i), datasets: [{ data: data, borderColor: borderColor, borderWidth: 2, pointRadius: 0, tension: 0.4 }] },
        options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false }, tooltip: { enabled: false } }, scales: { x: { display: false }, y: { display: false } } }
    });
}

// --- UPDATE FUNCTIONS ---
function updateStockChart(timeRange) {
    if (!currentStockTicker) return;
    const stock = mockStockData[currentStockTicker];
    const chartData = mockChartData[timeRange];
    createMainStockChart(document.getElementById('mainStockChart'), { ...chartData, positive: stock.positive });
}

function updatePortfolioView(timespan) {
    const data = mockUserPortfolio[timespan];
    
    document.querySelectorAll('.portfolio-timespan-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.span === timespan);
    });

    document.getElementById('portfolio-total-value').innerText = `$${data.value.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    
    const changeEl = document.getElementById('portfolio-change');
    const periodText = { 'daily': 'Today', 'weekly': 'This Week', 'monthly': 'This Month' }[timespan];
    changeEl.innerText = `${data.positive ? '+' : ''}${data.changePercent}% ${periodText}`;
    changeEl.className = `font-semibold ${data.positive ? 'text-brand-green' : 'text-brand-red'}`;
    
    createPortfolioChart(data.chartData, data.positive);
}

// --- THEME TOGGLE ---
function setTheme(isDark) {
    document.documentElement.classList.toggle('dark', isDark);
    document.getElementById('theme-toggle').checked = isDark;
    // Redraw charts on theme change to update gradients
    if (currentStockTicker) updateStockChart(document.querySelector('#time-range-selector .active')?.dataset.range || '1D');
    if (document.querySelector('.main-content-area#portfolio-content.active')) {
        updatePortfolioView(document.querySelector('.portfolio-timespan-btn.active')?.dataset.span || 'daily');
    }
}

// --- INITIAL LOAD ---
document.addEventListener('DOMContentLoaded', () => {
    // --- Event Listeners ---
    document.getElementById('lets-go-btn').addEventListener('click', () => showAuthSubPage('login-page'));
    document.getElementById('login-form').addEventListener('submit', (e) => { e.preventDefault(); navigateToPage('home-page'); });
    document.getElementById('register-form').addEventListener('submit', (e) => { e.preventDefault(); showAuthSubPage('login-page'); });
    
    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', (e) => { e.preventDefault(); showMainContent(link.dataset.target); });
    });

    document.getElementById('show-register').addEventListener('click', (e) => { e.preventDefault(); showAuthSubPage('register-page'); });
    document.getElementById('show-login-from-register').addEventListener('click', (e) => { e.preventDefault(); showAuthSubPage('login-page'); });
    
    document.getElementById('back-to-dashboard-btn').addEventListener('click', () => navigateToPage('home-page'));
    document.getElementById('logout-button').addEventListener('click', () => navigateToPage('welcome-page'));

    document.querySelectorAll('#time-range-selector .time-button').forEach(button => {
        button.addEventListener('click', (e) => updateStockChart(e.currentTarget.dataset.range));
    });

    document.querySelectorAll('.portfolio-timespan-btn').forEach(button => {
        button.addEventListener('click', (e) => updatePortfolioView(e.currentTarget.dataset.span));
    });

    // --- Theme Setup ---
    const themeToggle = document.getElementById('theme-toggle');
    const savedTheme = localStorage.getItem('theme');
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    const isDarkMode = savedTheme === 'dark' || (savedTheme === null && prefersDark);
    setTheme(isDarkMode);

    themeToggle.addEventListener('change', () => {
        const isDark = document.documentElement.classList.toggle('dark');
        localStorage.setItem('theme', isDark ? 'dark' : 'light');
        setTheme(isDark);
    });

    // --- Initial Page Load ---
    navigateToPage('welcome-page');
    showMainContent('markets-content'); // Pre-initialize dashboard
});