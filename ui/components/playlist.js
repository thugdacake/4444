// Tokyo Box Playlist Component
// This component handles playlist functionality

class TokyoBoxPlaylists {
    constructor() {
        // State variables
        this.playlists = [];
        this.currentPlaylist = null;
        this.favorites = [];
    }
    
    // Initialize playlists
    init() {
        // Setup event listeners for playlist actions
        this.setupEventListeners();
    }
    
    // Setup event listeners
    setupEventListeners() {
        // Event delegation for playlist actions
        document.addEventListener('click', (e) => {
            // Create playlist button
            if (e.target.closest('.create-playlist')) {
                this.showCreatePlaylistModal();
            }
            
            // Playlist item
            const playlistItem = e.target.closest('.playlist-item:not(.create-playlist)');
            if (playlistItem) {
                const playlistId = playlistItem.getAttribute('data-id');
                if (playlistId) {
                    this.openPlaylist(playlistId);
                }
            }
        });
        
        // Playlist back button
        const backButton = document.getElementById('playlist-back');
        if (backButton) {
            backButton.addEventListener('click', () => {
                this.goBackFromPlaylist();
            });
        }
    }
    
    // Set playlists data
    setPlaylists(playlists) {
        this.playlists = playlists;
        this.renderPlaylists();
    }
    
    // Render playlists in UI
    renderPlaylists() {
        // For Home view (limited to 5 recent playlists)
        const homeContainer = document.getElementById('user-playlists');
        if (homeContainer) {
            let homeHtml = '';
            
            // Always add Create Playlist button first
            homeHtml += `
                <div class="playlist-item create-playlist">
                    <div class="playlist-cover">
                        <i data-feather="plus"></i>
                    </div>
                    <div class="playlist-name">Nova Playlist</div>
                </div>
            `;
            
            // Add playlists (limit to 5 for home view)
            const recentPlaylists = this.playlists.slice(0, 5);
            recentPlaylists.forEach(playlist => {
                homeHtml += this.createPlaylistItemHtml(playlist);
            });
            
            homeContainer.innerHTML = homeHtml;
        }
        
        // For Library view (all playlists)
        const libraryContainer = document.getElementById('library-playlists');
        if (libraryContainer) {
            let libraryHtml = '';
            
            if (this.playlists.length === 0) {
                libraryHtml = '<p class="empty-message">Você não tem playlists. Crie uma!</p>';
            } else {
                this.playlists.forEach(playlist => {
                    libraryHtml += this.createPlaylistItemHtml(playlist);
                });
            }
            
            libraryContainer.innerHTML = libraryHtml;
        }
        
        // Refresh Feather icons
        if (window.feather) {
            feather.replace();
        }
        
        // Add event listeners for playlist items
        this.attachPlaylistEventListeners();
    }
    
    // Attach event listeners to playlist items
    attachPlaylistEventListeners() {
        document.querySelectorAll('.playlist-item:not(.create-playlist)').forEach(item => {
            item.addEventListener('click', () => {
                const playlistId = item.getAttribute('data-id');
                if (playlistId) {
                    this.openPlaylist(playlistId);
                }
            });
        });
    }
    
    // Create HTML for a playlist item
    createPlaylistItemHtml(playlist) {
        const coverStyle = playlist.cover_url 
            ? `background-image: url('${playlist.cover_url}')`
            : `background-image: linear-gradient(${this.getRandomGradient()})`;
            
        return `
            <div class="playlist-item" data-id="${playlist.id}">
                <div class="playlist-cover" style="${coverStyle}"></div>
                <div class="playlist-name">${playlist.name}</div>
            </div>
        `;
    }
    
    // Get a random gradient for playlist covers
    getRandomGradient() {
        const gradients = [
            '45deg, #6225E6, #4DC5FF',
            '45deg, #8A5DE8, #4DFFA3',
            '45deg, #FF4D6A, #8A5DE8',
            '45deg, #4DC5FF, #FFB74D',
            '45deg, #4DFFA3, #6225E6'
        ];
        
        return gradients[Math.floor(Math.random() * gradients.length)];
    }
    
    // Show create playlist modal
    showCreatePlaylistModal() {
        const modal = document.getElementById('create-playlist-modal');
        if (modal) {
            // Clear inputs
            document.getElementById('playlist-name').value = '';
            document.getElementById('playlist-description').value = '';
            
            // Show modal
            modal.classList.add('visible');
        }
    }
    
    // Hide create playlist modal
    hideCreatePlaylistModal() {
        const modal = document.getElementById('create-playlist-modal');
        if (modal) {
            modal.classList.remove('visible');
        }
    }
    
    // Create a new playlist
    createPlaylist(name, description = '') {
        if (!name || name.trim().length < 3) {
            showNotification('O nome da playlist deve ter pelo menos 3 caracteres', 'error');
            return;
        }
        
        // In FiveM implementation, this will send a message to the server
        $.post('https://tokyo_box/createPlaylist', JSON.stringify({
            name: name.trim(),
            description: description.trim()
        }));
        
        // Hide modal
        this.hideCreatePlaylistModal();
    }
    
    // Delete a playlist
    deletePlaylist(playlistId) {
        if (!playlistId) return;
        
        // In FiveM implementation, this will send a message to the server
        $.post('https://tokyo_box/deletePlaylist', JSON.stringify({
            playlistId: playlistId
        }));
    }
    
    // Open a playlist
    openPlaylist(playlistId) {
        if (!playlistId) return;
        
        // Find the playlist
        const playlist = this.playlists.find(p => p.id == playlistId);
        if (!playlist) return;
        
        // Set as current playlist
        this.currentPlaylist = playlist;
        
        // Update UI
        document.getElementById('current-playlist-name').textContent = playlist.name;
        document.getElementById('current-playlist-info').textContent = 
            `${playlist.songCount || 0} músicas`;
        
        // Set cover image
        const coverEl = document.getElementById('current-playlist-cover');
        if (coverEl) {
            if (playlist.cover_url) {
                coverEl.style.backgroundImage = `url('${playlist.cover_url}')`;
            } else {
                coverEl.style.backgroundImage = `linear-gradient(${this.getRandomGradient()})`;
            }
        }
        
        // Get tracks for this playlist
        this.loadPlaylistTracks(playlistId);
        
        // Show playlist view
        this.showPlaylistView();
    }
    
    // Load tracks for a playlist
    loadPlaylistTracks(playlistId) {
        // Show loading state
        document.getElementById('playlist-tracks').innerHTML = 
            '<div class="loading">Carregando músicas...</div>';
        
        // In FiveM implementation, this will send a message to the server
        $.post('https://tokyo_box/getPlaylistTracks', JSON.stringify({
            playlistId: playlistId
        }));
    }
    
    // Show playlist view
    showPlaylistView() {
        // Hide all views
        document.querySelectorAll('.view').forEach(view => {
            view.classList.remove('active');
        });
        
        // Show playlist view
        document.getElementById('playlist-view').classList.add('active');
        
        // Deactivate nav items
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('active');
        });
    }
    
    // Go back from playlist view
    goBackFromPlaylist() {
        // In FiveM implementation, this will send a message to the server
        $.post('https://tokyo_box/goBack', JSON.stringify({}));
        
        // Change to library view
        document.querySelectorAll('.view').forEach(view => {
            view.classList.remove('active');
        });
        document.getElementById('library-view').classList.add('active');
        
        // Activate library nav item
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('active');
        });
        document.querySelector('.nav-item[data-view="library-view"]').classList.add('active');
    }
    
    // Set favorites data
    setFavorites(favorites) {
        this.favorites = favorites;
        this.renderFavorites();
    }
    
    // Render favorites in UI
    renderFavorites() {
        const container = document.getElementById('favorite-tracks');
        if (!container) return;
        
        let html = '';
        
        if (this.favorites.length === 0) {
            html = '<p class="empty-message">Você não tem músicas favoritas ainda.</p>';
        } else {
            this.favorites.forEach(track => {
                html += this.createTrackItemHtml(track, true);
            });
        }
        
        container.innerHTML = html;
        
        // Refresh Feather icons
        if (window.feather) {
            feather.replace();
        }
        
        // Attach event listeners to tracks
        this.attachTrackEventListeners('favorite-tracks');
    }
    
    // Create HTML for a track item
    createTrackItemHtml(track, isFavorite = false) {
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
    attachTrackEventListeners(containerId) {
        const trackItems = document.querySelectorAll(`#${containerId} .track-item`);
        
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
        
        // In FiveM implementation, this will send a message to the server
        $.post('https://tokyo_box/playTrack', JSON.stringify({
            trackId: trackId,
            playlistId: this.currentPlaylist ? this.currentPlaylist.id : null
        }));
    }
    
    // Show track options
    showTrackOptions(trackId) {
        // In a real implementation, this would be more complex
        // For now, just show a simple options modal
        if (typeof window.showTrackOptionsModal === 'function') {
            // Find the track in appropriate container based on context
            let track;
            
            if (this.currentPlaylist) {
                // Find in current playlist tracks
                const trackEl = document.querySelector(`#playlist-tracks .track-item[data-id="${trackId}"]`);
                if (trackEl) {
                    const title = trackEl.querySelector('.track-title').textContent;
                    const artist = trackEl.querySelector('.track-artist').textContent;
                    const thumbnail = trackEl.querySelector('.track-thumbnail').style.backgroundImage;
                    
                    track = {
                        id: trackId,
                        title: title,
                        artist: artist,
                        thumbnail: thumbnail.replace(/^url\(['"](.+)['"]\)$/, '$1')
                    };
                }
            } else if (this.favorites.length > 0) {
                // Find in favorites
                track = this.favorites.find(t => t.id == trackId);
            }
            
            if (track) {
                window.showTrackOptionsModal(track);
            }
        }
    }
}

// Create global playlists instance
const tokyoBoxPlaylists = new TokyoBoxPlaylists();

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    tokyoBoxPlaylists.init();
});