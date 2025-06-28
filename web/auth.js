// This file handles all authentication logic

function initAuth(onAuthStateChangedCallback) {
    auth.onAuthStateChanged(onAuthStateChangedCallback);
}

async function handleRegister(event) {
    event.preventDefault();
    const name = document.getElementById('register-name').value;
    const email = document.getElementById('register-email').value;
    const password = document.getElementById('register-password').value;

    try {
        const userCredential = await auth.createUserWithEmailAndPassword(email, password);
        const user = userCredential.user;
        await createUserInDB(user.uid, name, email);
        // The onAuthStateChanged listener in script.js will handle the rest.
    } catch (error) {
        alert(`Registration failed: ${error.message}`);
        console.error("Registration error:", error);
    }
}

async function handleLogin(event) {
    event.preventDefault();
    const email = document.getElementById('login-email').value;
    const password = document.getElementById('login-password').value;

    try {
        await auth.signInWithEmailAndPassword(email, password);
        // The onAuthStateChanged listener in script.js will handle the rest.
    } catch (error) {
        alert(`Login failed: ${error.message}`);
        console.error("Login error:", error);
    }
}

async function handleLogout() {
    try {
        await auth.signOut();
        // The onAuthStateChanged listener will redirect to the welcome page.
        state.user = null;
        navigateToPage('welcome-page');
    } catch (error) {
        console.error("Logout error:", error);
    }
}

async function handleProfileUpdate(event) {
    event.preventDefault();
    const newFullName = document.getElementById('fullName').value;
    const newPassword = document.getElementById('newPassword').value;
    const confirmPassword = document.getElementById('confirmPassword').value;

    try {
        // Update full name in Firestore
        if (newFullName !== state.user.fullName) {
            await updateUserInDB(auth.currentUser.uid, { fullName: newFullName });
            state.user.fullName = newFullName;
            document.getElementById('dashboard-username').innerText = newFullName;
             alert("Profile updated successfully!");
        }

        // Update password in Firebase Auth
        if (newPassword) {
            if (newPassword !== confirmPassword) {
                alert("Passwords do not match.");
                return;
            }
            await auth.currentUser.updatePassword(newPassword);
            alert("Password updated successfully!");
        }

        showMainContent('profile-content');

    } catch (error) {
        alert(`Update failed: ${error.message}`);
        console.error("Profile update error:", error);
    }
}


// Add listeners after DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('register-form').addEventListener('submit', handleRegister);
    document.getElementById('login-form').addEventListener('submit', handleLogin);
});
