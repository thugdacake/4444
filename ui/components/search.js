// Tokyo Box Search Component
// This component handles search functionality

class TokyoBoxSearch {
    constructor() {
        // State variables
        this.searchResults = [];
        this.searchTimeout = null;
        this.minSearchLength = 2;
    }
    
    // Initialize search
    init() {
        // Setup search input event listeners
        this.setupEventListeners();
    }
    
    // Setup event listeners
    setupEventListeners() {
        const searchInput = document.getElementById('search-input');
        const clearButton = document.getElementById('clear-search');
        
        if (searchInput) {
            // Input event for real-time search
            searchInput.addEventListener('input', () => {
                this.handleSearchInput(searchInput.value);
            });
            
            // Enter key to submit search immediately
            searchInput.addEventListener('keydown', (e) => {
                if (e.key === 'Enter') {
                    this.performSearch(searchInput.value);
                }
            });
        }
        
        if (clearButton) {
            // Clear search button
            clearButton.addEventListener('click', () => {
                this.clearSearch();
            });
        }
    }
    
    // Handle search input (with debounce)
    handleSearchInput(query) {
        const clearButton = document.getElementById('clear-search');
        
        // Toggle clear button visibility
        if (clearButton) {
            if (query.trim() === '') {
                clearButton.classList.add('hidden');
            } else {
                clearButton.classList.remove('hidden');
            }
        }
        
        // Debounce search to avoid too many requests
        clearTimeout(this.searchTimeout);
        
        if (query.trim().length >= this.minSearchLength) {
            this.searchTimeout = setTimeout(() => {
                this.performSearch(query);
            }, 500); // Wait 500ms after typing stops
        } else {
            // Clear results if query is too short
            this.clearResults();
        }
    }
    
    // Perform the search
    performSearch(query) {
        if (query.trim().length < this.minSearchLength) return;
        
        // Show loading state
        document.getElementById('search-results').innerHTML = 
            '<div class="loading">Buscando...</div>';
        
        // In FiveM implementation, this will send a message to the server
        $.post('https://tokyo_box/searchTracks', JSON.stringify({
            query: query.trim()
        }));
    }
    
    // Clear search
    clearSearch() {
        const searchInput = document.getElementById('search-input');
        const clearButton = document.getElementById('clear-search');
        
        if (searchInput) {
            searchInput.value = '';
        }
        
        if (clearButton) {
            clearButton.classList.add('hidden');
        }
        
        this.clearResults();
    }
    
    // Clear search results
    clearResults() {
        document.getElementById('search-results').innerHTML = '';
        this.searchResults = [];
    }
    
    // Set search results
    setSearchResults(results) {
        this.searchResults = results;
        this.renderSearchResults();
    }
    
    // Render search results in UI
    renderSearchResults() {
        const container = document.getElementById('search-results');
        if (!container) return;
        
        let html = '';
        
        if (this.searchResults.length === 0) {
            html = '<p class="empty-message">Nenhum resultado encontrado. Tente outra busca.</p>';
        } else {
            this.searchResults.forEach(track => {
                html += this.createTrackItemHtml(track);
            });
        }
        
        container.innerHTML = html;
        
        // Attach event listeners
        this.attachTrackEventListeners();
        
        // Refresh Feather icons
        if (window.feather) {
            feather.replace();
        }
    }
    
    // Create HTML for a track item
    createTrackItemHtml(track) {
        const thumbStyle = track.thumbnail 
            ? `background-image: url('${track.thumbnail}')`
            : `background-color: var(--background-light)`;
        
        return `
            <div class="track-item" data-id="${track.id}">
                <div class="track-thumbnail" style="${thumbStyle}"></div>
                <div class="track-details">
                    <div class="track-title">${track.title}</div>
                    <div class="track-artist">${track.artist || 'Artista Desconhecido'}</div>
                </div>
                <div class="track-options">
                    <i data-feather="more-vertical"></i>
                </div>
            </div>
        `;
    }
    
    // Attach event listeners to track items
    attachTrackEventListeners() {
        const trackItems = document.querySelectorAll('#search-results .track-item');
        
        trackItems.forEach(item => {
            // Play on click
            item.addEventListener('click', (e) => {
                if (!e.target.closest('.track-options')) {
                    const trackId = item.getAttribute('data-id');
                    this.playTrack(trackId);
                }
            });
            
            // Options menu
            const optionsBtn = item.querySelector('.track-options');
            if (optionsBtn) {
                optionsBtn.addEventListener('click', (e) => {
                    e.stopPropagation();
                    const trackId = item.getAttribute('data-id');
                    this.showTrackOptions(trackId);
                });
            }
        });
    }
    
    // Play a track
    playTrack(trackId) {
        if (!trackId) return;
        
        // Find the track in search results
        const track = this.searchResults.find(t => t.id == trackId);
        if (!track) return;
        
        // In FiveM implementation, this will send a message to the server
        $.post('https://tokyo_box/playTrack', JSON.stringify({
            trackId: trackId
        }));
    }
    
    // Show track options
    showTrackOptions(trackId) {
        if (!trackId) return;
        
        // Find the track in search results
        const track = this.searchResults.find(t => t.id == trackId);
        if (!track) return;
        
        // Call the global showTrackOptionsModal function if it exists
        if (typeof window.showTrackOptionsModal === 'function') {
            window.showTrackOptionsModal(track);
        }
    }
}

// Create global search instance
const tokyoBoxSearch = new TokyoBoxSearch();

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    tokyoBoxSearch.init();
});