// This file handles the logic for the shopping cart page and interactions.

// --- Cart Database Functions ---

async function getCart(id) { // id can be sessionId or userId
    const cartDoc = await db.collection("carts").doc(id).get();
    return cartDoc.exists ? cartDoc.data() : { items: [] };
}

async function updateCart(id, cartData) {
    return await db.collection("carts").doc(id).set(cartData);
}

async function addToCart(id, item) {
    const cart = await getCart(id);
    const existingItemIndex = cart.items.findIndex(i => i.ticker === item.ticker);

    if (existingItemIndex > -1) {
        cart.items[existingItemIndex].shares += item.shares;
    } else {
        cart.items.push(item);
    }
    await updateCart(id, cart);
    alert(`${item.shares} shares of ${item.ticker} added to cart!`);
}

async function removeFromCart(id, ticker) {
    const cart = await getCart(id);
    const itemIndex = cart.items.findIndex(i => i.ticker === ticker);

    if (itemIndex > -1) {
        cart.items.splice(itemIndex, 1);
        await updateCart(id, cart);
        await renderShoppingCartPage(); // Re-render the cart
    }
}

async function updateCartItem(id, ticker, newShares) {
    if (newShares <= 0) {
        await removeFromCart(id, ticker);
        return;
    }
    const cart = await getCart(id);
    const itemIndex = cart.items.findIndex(i => i.ticker === ticker);

    if (itemIndex > -1) {
        cart.items[itemIndex].shares = newShares;
        await updateCart(id, cart);
        await renderShoppingCartPage();
    }
}

async function mergeSessionCart(sessionId, userId) {
    const sessionCart = await getCart(sessionId);
    if (sessionCart.items.length > 0) {
        const userCart = await getCart(userId);
        
        sessionCart.items.forEach(sessionItem => {
            const userItemIndex = userCart.items.findIndex(i => i.ticker === sessionItem.ticker);
            if (userItemIndex > -1) {
                userCart.items[userItemIndex].shares += sessionItem.shares;
            } else {
                userCart.items.push(sessionItem);
            }
        });

        await updateCart(userId, userCart);
        await db.collection("carts").doc(sessionId).delete(); // Clear session cart
        localStorage.removeItem('sessionId');
    }
}


// --- Main App Integration ---

async function handleAddToCart() {
    if (!state.user && !state.sessionId) {
        alert("An error occurred. Please refresh the page.");
        return;
    }
    const ticker = document.getElementById('trade-ticker').value;
    const shares = parseInt(document.getElementById('trade-shares').value);
    const price = parseFloat(document.getElementById('trade-price').value);

    if (isNaN(shares) || shares <= 0) {
        alert("Please enter a valid number of shares.");
        return;
    }

    const item = { ticker, shares, price };
    const id = state.user ? state.user.uid : state.sessionId;
    
    await addToCart(id, item);
    state.tradeModal.hide();
}

async function renderShoppingCartPage() {
    const id = state.user ? state.user.uid : state.sessionId;
     if (!id) return;

    const cart = await getCart(id);
    const container = document.getElementById('cart-content');
    
    if (!cart || cart.items.length === 0) {
        container.innerHTML = `<h2 class="h3 fw-bold mb-4">Shopping Cart</h2><p class="text-secondary">Your cart is empty.</p>`;
        return;
    }

    let total = 0;
    let itemsHtml = cart.items.map(item => {
        const itemTotal = item.price * item.shares;
        total += itemTotal;
        return `
            <div class="cart-item">
                <div>
                    <h5 class="fw-bold">${item.ticker}</h5>
                    <p class="mb-0 text-secondary">
                        <input type="number" value="${item.shares}" min="1" class="form-control form-control-sm cart-item-shares" data-ticker="${item.ticker}" style="width: 70px; display: inline-block;">
                         shares @ ${formatCurrency(item.price)}
                    </p>
                </div>
                <div class="d-flex align-items-center">
                    <h5 class="fw-bold me-3 mb-0">${formatCurrency(itemTotal)}</h5>
                    <button class="btn btn-sm btn-outline-danger remove-from-cart-btn" data-ticker="${item.ticker}"><i class="bi bi-trash"></i></button>
                </div>
            </div>
        `;
    }).join('');

    container.innerHTML = `
        <h2 class="h3 fw-bold mb-4">Shopping Cart</h2>
        <div class="card bg-body-tertiary border-0 rounded-4 p-2">
            ${itemsHtml}
        </div>
        <div class="card bg-body-tertiary border-0 p-3 mt-4">
             <div class="d-flex justify-content-between align-items-center">
                <h4>Total:</h4>
                <h4 id="cart-total" class="text-brand-green">${formatCurrency(total)}</h4>
            </div>
            <hr>
            <button id="checkout-btn" class="btn btn-brand-green btn-lg w-100" ${cart.items.length === 0 ? 'disabled' : ''}>Checkout</button>
        </div>
    `;

    document.querySelectorAll('.remove-from-cart-btn').forEach(button => {
        button.addEventListener('click', (e) => {
            const ticker = e.currentTarget.dataset.ticker;
            removeFromCart(id, ticker);
        });
    });

    document.querySelectorAll('.cart-item-shares').forEach(input => {
        input.addEventListener('change', (e) => {
            const ticker = e.currentTarget.dataset.ticker;
            const newShares = parseInt(e.currentTarget.value);
            updateCartItem(id, ticker, newShares);
        });
    });


    document.getElementById('checkout-btn').addEventListener('click', () => handleCheckout(id, cart));
}


async function handleCheckout(id, cart) {
    if (!state.user) {
        alert("Please log in to check out.");
        navigateToPage('auth-container');
        return;
    }

    const totalCost = cart.items.reduce((acc, item) => acc + (item.price * item.shares), 0);
    
    if (totalCost > state.user.cash) {
        alert("Insufficient funds to complete purchase.");
        return;
    }

    const newPortfolio = [...state.user.portfolio];
    cart.items.forEach(item => {
        const existingHolding = newPortfolio.find(h => h.ticker === item.ticker);
        if (existingHolding) {
            existingHolding.shares += item.shares;
        } else {
            newPortfolio.push({ ticker: item.ticker, shares: item.shares });
        }
    });

    const newCash = state.user.cash - totalCost;

    // Update database
    await updateUserInDB(state.user.uid, { cash: newCash, portfolio: newPortfolio });
    await db.collection("carts").doc(id).delete(); // Clear cart

    // Update local state
    state.user.cash = newCash;
    state.user.portfolio = newPortfolio;
    
    alert("Purchase successful!");
    renderShoppingCartPage(); // Re-render to show empty cart
    renderHomePageSummary(); // Update dashboard summary
}
