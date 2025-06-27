// --- STATE & MOCK DATA ---
let currentStockTicker = null;
let mainChartInstance = null;
let portfolioChartInstance = null;

const mockUser = { fullName: 'Fadi Abbara', email: 'fadi@stockly.com' };

const mockStockData = {
    'AAPL': { name: 'Apple Inc.', price: 238.45, change: 3.2, changePercent: 1.36, positive: true },
    'GOOGL': { name: 'Alphabet Inc.', price: 179.45, change: -1.80, changePercent: -1.0, positive: false },
    'TSLA': { name: 'Tesla Inc.', price: 183.01, change: 5.01, changePercent: 2.8, positive: true },
    'MSFT': { name: 'Microsoft Corp.', price: 449.78, change: 2.10, changePercent: 0.47, positive: true },
    'AMZN': { name: 'Amazon.com, Inc.', price: 183.66, change: -2.01, changePercent: -1.08, positive: false },
    'NVDA': { name: 'NVIDIA Corp.', price: 121.87, change: 1.12, changePercent: 0.93, positive: true },
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
    { id: 1, ticker: 'AAPL', timestamp: '3 hours ago', headline: 'Apple Reports Record Q4 Earnings, Beats Wall Street Expectations', imageUrl: 'https://images.unsplash.com/photo-1579548122080-c35fd6820ecb?auto=format&fit=crop&w=400&q=60' },
    { id: 2, ticker: 'TSLA', timestamp: '8 hours ago', headline: 'Tesla Stock Surges 8% on Autonomous Vehicle Breakthrough', imageUrl: 'https://images.unsplash.com/photo-1617704548623-34047b423862?auto=format&fit=crop&w=400&q=60' }
];

// --- PAGE ROUTING ---
const authPages = ['welcome-page', 'login-page', 'register-page'];
const mainAppPages = ['home-page', 'stock-detail-page', 'portfolio-page', 'news-page', 'pro-page', 'profile-settings-page'];

function showPage(pageId, navItem) {
    // Hide all pages
    authPages.forEach(id => document.getElementById(id).classList.add('hidden'));
    document.getElementById('main-app-wrapper').classList.add('hidden');
    mainAppPages.forEach(id => document.getElementById(id).classList.add('hidden'));

    if (authPages.includes(pageId)) {
        // Show an authentication page (welcome, login, etc.)
        document.getElementById(pageId).classList.remove('hidden');
    } else {
        // Show a main application page
        document.getElementById('main-app-wrapper').classList.remove('hidden');
        document.getElementById(pageId).classList.remove('hidden');
        updateActiveNav(navItem);
    }
    
    // Run initialization function for the shown page
    switch(pageId) {
        case 'home-page': initializeDashboard(); break;
        case 'portfolio-page': showPortfolioPage(); break;
        case 'news-page': showNewsPage(); break;
        case 'profile-settings-page': showProfileSettingsPage(); break;
    }
}

// --- INITIALIZATION FUNCTIONS ---
function initializeDashboard() {
    document.getElementById('home-username').innerText = mockUser.fullName;
    const portfolio = mockUserPortfolio.daily;
    document.getElementById('home-portfolio-card').innerHTML = `<p class="text-sm text-theme-secondary">Portfolio Value</p><p class="text-2xl font-bold text-theme-primary my-1">$${portfolio.value.toLocaleString('en-US')}</p><p class="text-sm font-semibold ${portfolio.positive ? 'text-green-custom' : 'text-red-custom'}">${portfolio.positive ? '+' : ''}${portfolio.changePercent}% Today</p>`;
    
    const trending = mockStockData['TSLA'];
    document.getElementById('home-trending-card').innerHTML = `<p class="text-sm text-theme-secondary">Trending</p><p class="text-lg font-bold text-theme-primary my-1">${trending.name}</p><div class="flex justify-between items-center"><p class="text-sm font-semibold text-theme-primary">$${trending.price}</p><p class="text-sm font-semibold ${trending.positive ? 'text-green-custom' : 'text-red-custom'}">${trending.changePercent}%</p></div>`;

    const indicesContainer = document.getElementById('market-indices-container');
    indicesContainer.innerHTML = '';
    Object.keys(mockStockData).slice(0, 4).forEach(ticker => {
        const stock = mockStockData[ticker];
        const cardColor = stock.positive ? 'bg-green-custom/10 border-green-custom/30' : 'bg-red-custom/10 border-red-custom/30';
        const textColor = stock.positive ? 'text-green-custom' : 'text-red-custom';
        indicesContainer.innerHTML += `<div class="p-3 rounded-xl border ${cardColor} cursor-pointer" onclick="showStockDetail('${ticker}')"><p class="font-bold text-theme-primary">${ticker}</p><p class="font-semibold ${textColor}">$${stock.price}</p></div>`;
    });
}

function showStockDetail(ticker, timeRange = '1D') {
    currentStockTicker = ticker;
    const stock = mockStockData[ticker];
    if (!stock) return;

    document.getElementById('detail-stock-ticker-header').innerText = ticker;
    document.getElementById('detail-stock-name').innerText = stock.name;
    document.getElementById('detail-stock-price').innerText = `$${stock.price.toFixed(2)}`;
    
    const changeEl = document.getElementById('detail-stock-change');
    changeEl.innerText = `${stock.positive ? '+' : ''}${stock.change.toFixed(2)} (${stock.changePercent}%)`;
    changeEl.className = `text-lg font-semibold ${stock.positive ? 'text-green-custom' : 'text-red-custom'}`;

    updateStockChart(timeRange);

    document.querySelectorAll('#time-range-selector .time-button').forEach(button => {
        button.classList.toggle('time-button-active', button.dataset.range === timeRange);
        button.classList.toggle('time-button-inactive', button.dataset.range !== timeRange);
    });
    
    showPage('stock-detail-page', 'nav-markets');
}

function showPortfolioPage() {
    updatePortfolioView('daily');
    const container = document.getElementById('portfolio-assets-container');
    container.innerHTML = '';
    mockUserPortfolio.assets.forEach(asset => {
        const isPositive = asset.changePercent >= 0;
        container.innerHTML += `<div class="flex items-center justify-between bg-theme-surface p-3 rounded-lg cursor-pointer" onclick="showStockDetail('${asset.ticker}')"><div><p class="font-bold text-theme-primary">${asset.ticker}</p><p class="text-sm text-theme-secondary">${asset.shares} shares</p></div><div><p class="font-semibold text-theme-primary text-right">$${asset.value.toLocaleString()}</p><p class="text-sm ${isPositive ? 'text-green-custom' : 'text-red-custom'} text-right">${isPositive ? '+' : ''}${asset.changePercent}%</p></div></div>`;
    });
}

function showNewsPage() {
    const articlesContainer = document.getElementById('news-articles-container');
    articlesContainer.innerHTML = '';
    mockNewsData.forEach(article => {
        articlesContainer.innerHTML += `
            <div class="bg-theme-surface rounded-xl overflow-hidden">
                <img src="${article.imageUrl}" alt="${article.headline}" class="w-full h-32 object-cover">
                <div class="p-4">
                    <div class="flex items-center space-x-2 text-xs mb-2">
                        <span class="px-2 py-0.5 font-bold rounded bg-green-custom text-white cursor-pointer" onclick="showStockDetail('${article.ticker}')">${article.ticker}</span>
                        <span class="text-theme-secondary">${article.timestamp}</span>
                    </div>
                    <h3 class="font-bold text-theme-primary mb-2">${article.headline}</h3>
                    <a href="#" class="text-sm font-semibold text-green-custom">Read more &rarr;</a>
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
     
     const ctx = canvasEl.getContext('2d');
     const borderColor = chartConfig.positive ? 'rgba(38, 166, 154, 1)' : 'rgba(239, 83, 80, 1)';
     const gradient = ctx.createLinearGradient(0, 0, 0, canvasEl.offsetHeight);
     gradient.addColorStop(0, chartConfig.positive ? 'rgba(38, 166, 154, 0.4)' : 'rgba(239, 83, 80, 0.4)');
     gradient.addColorStop(1, 'rgba(19, 23, 34, 0)');
     
     mainChartInstance = new Chart(ctx, {
        type: 'line', 
        data: { 
            labels: chartConfig.labels, 
            datasets: [{ 
                label: 'Price', 
                data: chartConfig.data, 
                borderColor: borderColor, 
                borderWidth: 3, 
                pointRadius: 0, 
                tension: 0.4, 
                fill: true, 
                backgroundColor: gradient 
            }] 
        },
        options: { 
            responsive: true, 
            maintainAspectRatio: false, 
            plugins: { 
                legend: { display: false },
                tooltip: { 
                    mode: 'index', 
                    intersect: false, 
                    displayColors: false,
                    callbacks: { label: (context) => `$${context.parsed.y.toFixed(2)}` }
                } 
            }, 
            scales: { 
                x: { display: false }, 
                y: { display: false } 
            } 
        }
    });
}

function createPortfolioChart(data, isPositive) {
    const canvasEl = document.getElementById('portfolioChart');
    if (!canvasEl) return;
    if (portfolioChartInstance) portfolioChartInstance.destroy();
    
    const ctx = canvasEl.getContext('2d');
    const borderColor = isPositive ? 'rgba(38, 166, 154, 1)' : 'rgba(239, 83, 80, 1)';
    
    portfolioChartInstance = new Chart(ctx, {
        type: 'line', 
        data: { 
            labels: data.map((_, i) => i), 
            datasets: [{ data: data, borderColor: borderColor, borderWidth: 2, pointRadius: 0, tension: 0.4 }] 
        },
        options: { 
            responsive: true, 
            maintainAspectRatio: false, 
            plugins: { legend: { display: false }, tooltip: { enabled: false } }, 
            scales: { x: { display: false }, y: { display: false } } 
        }
    });
}

// --- UPDATE FUNCTIONS ---
function updateActiveNav(activeItem) {
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.remove('nav-item-active');
    });
    if (activeItem) {
        document.getElementById(activeItem).classList.add('nav-item-active');
    }
}

function updateStockChart(timeRange) {
    if (!currentStockTicker) return;
    const stock = mockStockData[currentStockTicker];
    const chartData = mockChartData[timeRange];
    createMainStockChart(
        document.getElementById('mainStockChart'), 
        { ...chartData, positive: stock.positive }
    );
}

function updatePortfolioView(timespan) {
    const data = mockUserPortfolio[timespan];
    
    ['daily', 'weekly', 'monthly'].forEach(ts => {
        const btn = document.getElementById(`portfolio-btn-${ts}`);
        btn.classList.remove('bg-green-custom', 'bg-red-custom', 'text-white');
        btn.classList.add('text-theme-secondary');
    });
    
    const activeBtn = document.getElementById(`portfolio-btn-${timespan}`);
    activeBtn.classList.remove('text-theme-secondary');
    activeBtn.classList.add(data.positive ? 'bg-green-custom' : 'bg-red-custom', 'text-white');

    document.getElementById('portfolio-total-value').innerText = `$${data.value.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    
    const changeEl = document.getElementById('portfolio-change');
    const periodText = { 'daily': 'Today', 'weekly': 'This Week', 'monthly': 'This Month' }[timespan];
    changeEl.innerText = `${data.positive ? '+' : ''}${data.changePercent}% ${periodText}`;
    changeEl.className = `font-semibold ${data.positive ? 'text-green-custom' : 'text-red-custom'}`;
    
    createPortfolioChart(data.chartData, data.positive);
}


// --- THEME TOGGLE ---
const themeToggle = document.getElementById('theme-toggle');

function applyTheme(theme) {
    if (theme === 'dark') {
        document.documentElement.classList.remove('light-mode');
        document.documentElement.classList.add('dark-mode');
        themeToggle.checked = true;
    } else {
        document.documentElement.classList.remove('dark-mode');
        document.documentElement.classList.add('light-mode');
        themeToggle.checked = false;
    }
}

themeToggle.addEventListener('change', () => {
    const newTheme = themeToggle.checked ? 'dark' : 'light';
    localStorage.setItem('theme', newTheme);
    applyTheme(newTheme);
});


// --- INITIAL LOAD ---
document.addEventListener('DOMContentLoaded', () => {
    // Event listeners for stock chart time ranges
    document.querySelectorAll('#time-range-selector .time-button').forEach(button => {
        button.addEventListener('click', (e) => {
            const range = e.currentTarget.dataset.range;
            showStockDetail(currentStockTicker, range);
        });
    });

    // Load saved theme or default to dark
    const savedTheme = localStorage.getItem('theme') || 'dark';
    applyTheme(savedTheme);

    // Show initial page
    showPage('welcome-page');
});