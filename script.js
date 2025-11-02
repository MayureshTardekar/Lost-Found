// Client-side JavaScript for Lost & Found app using localStorage
// Utility functions for password validation and logout

// Password strength and confirm password logic
function initPasswordValidation() {
  const password = document.getElementById('password');
  const confirmPassword = document.getElementById('confirmPassword');
  const splitBar = document.getElementById('splitBar');
  const strengthLabel = document.getElementById('strengthLabel');
  const matchMsg = document.getElementById('matchMsg');

  if (!password || !confirmPassword || !splitBar || !strengthLabel || !matchMsg) return;

  password.addEventListener('input', () => {
    const val = password.value.trim();

    let width = '0%';
    let text = '';
    let color = '#888';

    if (val.length === 0) {
      width = '0%';
      text = '';
      color = '#888';
    } else if (val.length <= 5) {
      width = '30%';
      text = 'Weak';
      color = '#ff4d4d';
    } else if (val.length <= 8 && /[A-Z]/.test(val) && /\d/.test(val)) {
      width = '60%';
      text = 'Medium';
      color = '#feca57';
    } else if (val.length > 8 && /[A-Z]/.test(val) && /\d/.test(val) && /[^A-Za-z0-9]/.test(val)) {
      width = '100%';
      text = 'Strong';
      color = '#1dd1a1';
    } else {
      width = '40%';
      text = 'Weak';
      color = '#ff4d4d';
    }

    splitBar.style.width = width;
    strengthLabel.textContent = text;
    strengthLabel.style.color = color;
  });

  confirmPassword.addEventListener('input', () => {
    if (confirmPassword.value === password.value) {
      matchMsg.textContent = 'Passwords match';
      matchMsg.className = 'match-success';
    } else {
      matchMsg.textContent = 'Passwords do not match';
      matchMsg.className = 'match-error';
    }
  });
}

// Logout functionality
function logout() {
  localStorage.removeItem('campus_lost_found_current_user');
  alert('Logged out successfully!');
  window.location.href = 'home.html';
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
  const registerForm = document.getElementById('register-form');
  if (registerForm) {
    initPasswordValidation();
  }

  const logoutBtn = document.getElementById('logout-btn');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', logout);
  }
});
