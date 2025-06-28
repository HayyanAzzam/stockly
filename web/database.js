// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
  const firebaseConfig = {
  apiKey: "AIzaSyB1cIOe77y9yUaogvsy_RVmdIUcjiAiEoM",
  authDomain: "stockly-5019f.firebaseapp.com",
  projectId: "stockly-5019f",
  storageBucket: "stockly-5019f.firebasestorage.app",
  messagingSenderId: "4941036939",
  appId: "1:4941036939:web:57fb91535a3ae4c4f9838e"
};

 // Initialize Firebase
    // Check if Firebase is already initialized to avoid errors
    if (!firebase.apps.length) {
        firebase.initializeApp(firebaseConfig);
    }
    const db = firebase.firestore();
    const auth = firebase.auth();

    // --- Database User Functions ---

    async function createUserInDB(userId, fullName, email) {
        return await db.collection("users").doc(userId).set({
            uid: userId,
            fullName: fullName,
            email: email,
            cash: 100000, // Starting cash
            portfolio: [],
            wishlist: [],
            isPro: false, // Default to not being a pro member
            createdAt: firebase.firestore.FieldValue.serverTimestamp()
        });
    }

    async function getUserData(userId) {
        const userDoc = await db.collection("users").doc(userId).get();
        return userDoc.exists ? userDoc.data() : null;
    }

    async function updateUserInDB(userId, dataToUpdate) {
        if(!userId) userId = auth.currentUser.uid;
        if(!userId) return;
        return await db.collection("users").doc(userId).update(dataToUpdate);
    }


    // --- Database Seeding (for initial setup) ---

    // Note: This part is for demonstration.
    // In a real app, you wouldn't manage users this way.
    // Passwords are not stored in Firestore, they are managed by Firebase Auth.
    async function seedInitialUsers() {
        const initialUsers = [
            // UPDATED: Changed password to be 6 characters to meet Firebase requirements.
            { email: 'fadi@stockly.com', password: '123456', fullName: 'Fadi Abbara' },
            { email: 'anas@stockly.com', password: '123456', fullName: 'Anas' },
            { email: 'baraa@stockly.com', password: '123456', fullName: 'Baraa' },
            { email: 'hayyan@stockly.com', password: '123456', fullName: 'Hayyan' }
        ];

        for (const user of initialUsers) {
            try {
                // Check if user already exists
                const existingUser = await auth.fetchSignInMethodsForEmail(user.email);
                if (existingUser.length === 0) {
                    const userCredential = await auth.createUserWithEmailAndPassword(user.email, user.password);
                    await createUserInDB(userCredential.user.uid, user.fullName, user.email);
                    console.log(`Created user: ${user.email}`);
                }
            } catch (error) {
                // This will catch password errors and other issues.
                if (error.code !== 'auth/email-already-in-use') {
                    console.error(`Error seeding user ${user.email}:`, error.message);
                }
            }
        }
    }

    // Seed initial users on load (for first-time setup)
    seedInitialUsers();
