// theme.js - Central theme management for dark/light mode
// This runs before page load to prevent flash

(function() {
    // Get saved theme or default to dark
    const savedTheme = localStorage.getItem('campus_lost_found_theme') || 'dark';
    
    // Apply theme immediately
    if (savedTheme === 'dark') {
        document.documentElement.classList.add('dark');
    } else {
        document.documentElement.classList.remove('dark');
    }
    
    // Listen for changes from other tabs/windows
    window.addEventListener('storage', (e) => {
        if (e.key === 'campus_lost_found_theme') {
            if (e.newValue === 'dark') {
                document.documentElement.classList.add('dark');
            } else {
                document.documentElement.classList.remove('dark');
            }
        }
    });
})();

