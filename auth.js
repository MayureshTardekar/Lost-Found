// auth.js - Client-side authentication using localStorage
// This file handles user registration, login, logout, and authentication checks
// Designed to be easily replaceable with backend API calls later

// Page protection: Redirect to login if not logged in and accessing protected pages
(function() {
  const allowedPages = ["home.html", "login.html", "register.html"];
  const currentPage = window.location.pathname.split("/").pop();
  const currentUser = localStorage.getItem("campus_lost_found_current_user");
  const loginTimestamp = localStorage.getItem("campus_lost_found_login_time");

  // Check session timeout (24 hours = 86400000 milliseconds)
  const SESSION_TIMEOUT = 24 * 60 * 60 * 1000;
  if (currentUser && loginTimestamp) {
    const now = Date.now();
    const loginTime = parseInt(loginTimestamp);
    
    if (now - loginTime > SESSION_TIMEOUT) {
      // Session expired - auto logout
      localStorage.removeItem("campus_lost_found_current_user");
      localStorage.removeItem("campus_lost_found_login_time");
      
      if (!allowedPages.includes(currentPage)) {
        alert('Session expired. Please login again.');
        window.location.href = "login.html";
      }
      return;
    }
  }

  // Only check for protected pages
  if (!currentUser && !allowedPages.includes(currentPage)) {
    window.location.href = "login.html";
  }

  // If logged in and on login.html or register.html, redirect to browse page
  if (currentUser && (currentPage === "login.html" || currentPage === "register.html")) {
    window.location.href = "index.html";
  }
})();

class Auth {
    constructor() {
        this.usersKey = 'campus_lost_found_users';
        this.currentUserKey = 'campus_lost_found_current_user';
        this.init();
    }

    // Initialize localStorage if not exists
    init() {
        if (!localStorage.getItem(this.usersKey)) {
            localStorage.setItem(this.usersKey, JSON.stringify([]));
        }
    }

    // Get all users from localStorage
    getUsers() {
        return JSON.parse(localStorage.getItem(this.usersKey)) || [];
    }

    // Save users to localStorage
    saveUsers(users) {
        localStorage.setItem(this.usersKey, JSON.stringify(users));
    }

    // Register a new user
    register(userData) {
        const users = this.getUsers();

        // Check if user already exists
        const existingUser = users.find(user => user.email === userData.email || user.ucid === userData.ucid);
        if (existingUser) {
            throw new Error('User with this email or UCID already exists');
        }

        // Create new user object
        const newUser = {
            id: Date.now(), // Simple ID generation
            name: userData.name,
            email: userData.email,
            ucid: userData.ucid,
            password: userData.password, // In production, this should be hashed
            role: 'user', // Default role
            createdAt: new Date().toISOString(),
            joinedDate: new Date().toISOString() // Add joinedDate for profile display
        };

        // Add to users array
        users.push(newUser);
        this.saveUsers(users);

        return newUser;
    }

    // Login user
    login(email, password) {
        const users = this.getUsers();
        const user = users.find(u => u.email === email && u.password === password);

        if (!user) {
            throw new Error('Invalid email or password');
        }

        // Set current user and login timestamp
        localStorage.setItem(this.currentUserKey, JSON.stringify(user));
        localStorage.setItem('campus_lost_found_login_time', Date.now().toString());
        return user;
    }

    // Logout user
    logout() {
        localStorage.removeItem(this.currentUserKey);
        localStorage.removeItem('campus_lost_found_login_time');
    }

    // Get current logged-in user
    getCurrentUser() {
        const userStr = localStorage.getItem(this.currentUserKey);
        return userStr ? JSON.parse(userStr) : null;
    }

    // Check if user is logged in
    isLoggedIn() {
        return this.getCurrentUser() !== null;
    }

    // Check if current page requires authentication
    requiresAuth() {
        const protectedPages = ['report.html', 'myposts.html'];
        const currentPage = window.location.pathname.split('/').pop();
        return protectedPages.includes(currentPage);
    }

    // Redirect to login if not authenticated and page requires auth
    checkAuthAndRedirect() {
        if (this.requiresAuth() && !this.isLoggedIn()) {
            window.location.href = 'login.html';
        }
    }

    // Redirect to home if already logged in (for login/register pages)
    redirectIfLoggedIn() {
        if (this.isLoggedIn()) {
            window.location.href = 'index.html'; // Main app page
        }
    }
}

// Create global auth instance
const auth = new Auth();

// Auto-check authentication on page load
document.addEventListener('DOMContentLoaded', () => {
    auth.checkAuthAndRedirect();
});
