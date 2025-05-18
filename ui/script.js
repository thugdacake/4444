// Tokyo Box Main UI Script

// Global Variables
let isPlaying = false;
let isPaused = false;
let currentTrack = null;
let currentPlaylist = null;
let currentVolume = 70; // Default volume (0-100)
let currentPosition = 0;
let trackDuration = 0;
let playlists = [];
let favorites = [];
let dragStartY = 0;
let isDraggingProgress = false;
let isDraggingVolume = false;
let isExpandedPlayerVisible = false;
let currentView = 'home-view';
let currentLibraryTab = 'playlists';
let selectedTrackForOptions = null;
let bluetoothEnabled = false;
let audioRange = 10.0; // Default range in meters

// Initialize on document load
document.addEventListener('DOMContentLoaded', function() {
    // Initialize Feather icons
    feather.replace();
    
    // Setup event listeners
    setupEventListeners();
    
    // Set current time in status bar
    updateStatusBarTime();
    
    // Setup bluetooth and range sliders
    setupBluetoothControls();
});

// Update time in status bar
function updateStatusBarTime() {
    const now = new Date();
    const hours = now.getHours().toString().padStart(2, '0');
    const minutes = now.getMinutes().toString().padStart(2, '0');
    document.querySelector('.status-time').textContent = `${hours}:${minutes}`;
    setTimeout(updateStatusBarTime, 60000); // Update every minute
}

// Setup Bluetooth and Range controls
function setupBluetoothControls() {
    // Bluetooth toggle
    const bluetoothToggle = document.getElementById('bluetooth-toggle');
    bluetoothToggle.addEventListener('change', function() {
        bluetoothEnabled = this.checked;
        $.post('https://tokyo_box/toggleBluetooth', JSON.stringify({
            enabled: bluetoothEnabled
        }));
    });
    
    // Range slider
    const rangeSlider = document.getElementById('range-slider');
    const rangeValueDisplay = document.getElementById('range-value');
    
    rangeSlider.addEventListener('input', function() {
        audioRange = parseFloat(this.value);
        rangeValueDisplay.textContent = audioRange;
    });
    
    rangeSlider.addEventListener('change', function() {
        $.post('https://tokyo_box/setAudioRange', JSON.stringify({
            range: audioRange
        }));
    });
}

// Setup all event listeners
function setupEventListeners() {
    // Bottom navigation
    const navItems = document.querySelectorAll('.nav-item');
    navItems.forEach(item => {
        item.addEventListener('click', () => {
            const view = item.getAttribute('data-view');
            changeView(view);
        });
    });
    
    // Library tabs
    const tabs = document.querySelectorAll('.tab');
    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            const tabName = tab.getAttribute('data-tab');
            changeLibraryTab(tabName);
        });
    });
    
    // Player controls
    document.getElementById('play-pause-btn').addEventListener('click', togglePlayPause);
    document.getElementById('play-pause-btn-expanded').addEventListener('click', togglePlayPause);
    document.getElementById('previous-btn').addEventListener('click', playPrevious);
    document.getElementById('next-btn').addEventListener('click', playNext);
    
    // Mini player click to expand
    document.getElementById('player-bar-collapsed').addEventListener('click', function(e) {
        if (!e.target.closest('button')) {
            toggleExpandedPlayer(true);
        }
    });
    
    // Collapse expanded player
    document.getElementById('collapse-player-btn').addEventListener('click', () => toggleExpandedPlayer(false));
    
    // Progress bar
    const progressBar = document.querySelector('.progress-bar');
    progressBar.addEventListener('mousedown', startProgressDrag);
    
    // Volume bar
    const volumeBar = document.querySelector('.volume-bar');
    volumeBar.addEventListener('mousedown', startVolumeDrag);
    
    // Global mouse events for dragging
    document.addEventListener('mousemove', onMouseMove);
    document.addEventListener('mouseup', onMouseUp);
    document.addEventListener('mouseleave', onMouseUp);
    
    // Touch events for mobile
    progressBar.addEventListener('touchstart', (e) => startProgressDrag(e.touches[0]), { passive: false });
    volumeBar.addEventListener('touchstart', (e) => startVolumeDrag(e.touches[0]), { passive: false });
    document.addEventListener('touchmove', (e) => onMouseMove(e.touches[0]), { passive: false });
    document.addEventListener('touchend', onMouseUp);
    
    // Create playlist button
    document.querySelector('.create-playlist').addEventListener('click', showCreatePlaylistModal);
    
    // Playlist creation modal
    document.getElementById('cancel-create-playlist').addEventListener('click', hideCreatePlaylistModal);
    document.getElementById('confirm-create-playlist').addEventListener('click', createPlaylist);
    
    // Playlist back button
    document.getElementById('playlist-back').addEventListener('click', goBackFromPlaylist);
    
    // Search input
    const searchInput = document.getElementById('search-input');
    searchInput.addEventListener('input', handleSearchInput);
    document.getElementById('clear-search').addEventListener('click', clearSearch);
    
    // Track options modal
    document.getElementById('cancel-track-options').addEventListener('click', hideTrackOptionsModal);
    document.getElementById('option-play').addEventListener('click', playSelectedTrack);
    document.getElementById('option-add-to-playlist').addEventListener('click', showAddToPlaylistModal);
    document.getElementById('option-toggle-favorite').addEventListener('click', toggleFavoriteSelectedTrack);
    
    // Add to playlist modal
    document.getElementById('cancel-add-to-playlist').addEventListener('click', hideAddToPlaylistModal);
}

// Change the active view
function changeView(viewId) {
    // Update view
    document.querySelectorAll('.view').forEach(view => {
        view.classList.remove('active');
    });
    document.getElementById(viewId).classList.add('active');
    
    // Update nav
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.remove('active');
    });
    document.querySelector(`.nav-item[data-view="${viewId}"]`).classList.add('active');
    
    currentView = viewId;
    
    // Load content for specific views
    if (viewId === 'library-view') {
        // If in library view, get playlists and favorites
        if (currentLibraryTab === 'favorites') {
            $.post('https://tokyo_box/getFavorites', JSON.stringify({}));
        } else {
            $.post('https://tokyo_box/getPlayerPlaylists', JSON.stringify({}));
        }
    }
}

// Change library tab
function changeLibraryTab(tabName) {
    // Update tabs
    document.querySelectorAll('.tab').forEach(tab => {
        tab.classList.remove('active');
    });
    document.querySelector(`.tab[data-tab="${tabName}"]`).classList.add('active');
    
    // Update content
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    document.getElementById(`${tabName}-tab`).classList.add('active');
    
    currentLibraryTab = tabName;
    
    // Load content for specific tabs
    if (tabName === 'favorites') {
        $.post('https://tokyo_box/getFavorites', JSON.stringify({}));
    } else {
        $.post('https://tokyo_box/getPlayerPlaylists', JSON.stringify({}));
    }
}

// Toggle play/pause
function togglePlayPause() {
    if (!currentTrack) return;
    
    if (isPaused || !isPlaying) {
        if (isPaused) {
            // Resume
            $.post('https://tokyo_box/resumeTrack', JSON.stringify({}));
        } else {
            // Play
            const data = {
                trackId: currentTrack.id,
                playlistId: currentPlaylist ? currentPlaylist.id : null
            };
            $.post('https://tokyo_box/playTrack', JSON.stringify(data));
        }
        isPlaying = true;
        updatePlayPauseIcons(true);
    } else {
        // Pause
        $.post('https://tokyo_box/pauseTrack', JSON.stringify({}));
        isPaused = true;
        updatePlayPauseIcons(false);
    }
}

// Play previous track
function playPrevious() {
    if (!currentTrack || !currentPlaylist) return;
    $.post('https://tokyo_box/previousTrack', JSON.stringify({}));
}

// Play next track
function playNext() {
    if (!currentTrack || !currentPlaylist) return;
    $.post('https://tokyo_box/nextTrack', JSON.stringify({}));
}

// Update play/pause icons
function updatePlayPauseIcons(isPlaying) {
    const playBtns = document.querySelectorAll('#play-pause-btn, #play-pause-btn-expanded');
    
    playBtns.forEach(btn => {
        btn.innerHTML = '';
        const icon = document.createElement('i');
        icon.setAttribute('data-feather', isPlaying ? 'pause' : 'play');
        btn.appendChild(icon);
    });
    
    feather.replace();
}

// Toggle expanded player
function toggleExpandedPlayer(show) {
    const expandedPlayer = document.getElementById('player-bar-expanded');
    const collapsedPlayer = document.getElementById('player-bar-collapsed');
    
    if (show) {
        expandedPlayer.classList.remove('hidden');
        expandedPlayer.classList.add('visible');
        collapsedPlayer.style.opacity = 0;
        isExpandedPlayerVisible = true;
    } else {
        expandedPlayer.classList.remove('visible');
        expandedPlayer.classList.add('hidden');
        collapsedPlayer.style.opacity = 1;
        isExpandedPlayerVisible = false;
    }
}

// Start dragging progress bar
function startProgressDrag(e) {
    e.preventDefault();
    isDraggingProgress = true;
    updateProgressPosition(e);
}

// Start dragging volume bar
function startVolumeDrag(e) {
    e.preventDefault();
    isDraggingVolume = true;
    updateVolumePosition(e);
}

// Handle mouse movement for dragging
function onMouseMove(e) {
    if (isDraggingProgress) {
        updateProgressPosition(e);
    } else if (isDraggingVolume) {
        updateVolumePosition(e);
    }
}

// Handle mouse up to stop dragging
function onMouseUp() {
    if (isDraggingProgress) {
        isDraggingProgress = false;
        
        // Send position to backend
        if (currentTrack) {
            const newPosition = (trackDuration * currentPosition) / 100;
            $.post('https://tokyo_box/seekTrack', JSON.stringify({
                position: newPosition
            }));
        }
    }
    
    if (isDraggingVolume) {
        isDraggingVolume = false;
        
        // Send volume to backend
        $.post('https://tokyo_box/setVolume', JSON.stringify({
            volume: currentVolume
        }));
    }
}

// Update progress bar position
function updateProgressPosition(e) {
    const progressBar = document.querySelector('.progress-bar');
    const rect = progressBar.getBoundingClientRect();
    let percentage = ((e.clientX - rect.left) / rect.width) * 100;
    
    // Clamp to 0-100
    percentage = Math.max(0, Math.min(100, percentage));
    
    // Update UI
    document.getElementById('progress-fill').style.width = percentage + '%';
    document.getElementById('progress-handle').style.left = percentage + '%';
    
    // Update time display
    if (trackDuration) {
        const newTime = (trackDuration * percentage) / 100;
        document.getElementById('current-time').textContent = formatTime(newTime);
    }
    
    currentPosition = percentage;
}

// Update volume bar position
function updateVolumePosition(e) {
    const volumeBar = document.querySelector('.volume-bar');
    const rect = volumeBar.getBoundingClientRect();
    let percentage = ((e.clientX - rect.left) / rect.width) * 100;
    
    // Clamp to 0-100
    percentage = Math.max(0, Math.min(100, percentage));
    
    // Update UI
    document.getElementById('volume-fill').style.width = percentage + '%';
    document.getElementById('volume-handle').style.left = percentage + '%';
    
    currentVolume = Math.round(percentage);
}

// Format time in seconds to MM:SS
function formatTime(timeInSeconds) {
    const minutes = Math.floor(timeInSeconds / 60);
    const seconds = Math.floor(timeInSeconds % 60);
    return `${minutes}:${seconds.toString().padStart(2, '0')}`;
}

// Show create playlist modal
function showCreatePlaylistModal() {
    document.getElementById('playlist-name').value = '';
    document.getElementById('playlist-description').value = '';
    document.getElementById('create-playlist-modal').classList.add('visible');
}

// Hide create playlist modal
function hideCreatePlaylistModal() {
    document.getElementById('create-playlist-modal').classList.remove('visible');
}

// Create a new playlist
function createPlaylist() {
    const name = document.getElementById('playlist-name').value.trim();
    const description = document.getElementById('playlist-description').value.trim();
    
    if (name.length < 3) {
        showNotification('O nome da playlist deve ter pelo menos 3 caracteres', 'error');
        return;
    }
    
    $.post('https://tokyo_box/createPlaylist', JSON.stringify({
        name: name,
        description: description
    }));
    
    hideCreatePlaylistModal();
}

// Go back from playlist view
function goBackFromPlaylist() {
    $.post('https://tokyo_box/goBack', JSON.stringify({}));
    changeView('library-view');
}

// Handle search input
function handleSearchInput() {
    const input = document.getElementById('search-input');
    const clearButton = document.getElementById('clear-search');
    
    if (input.value.trim() === '') {
        clearButton.classList.add('hidden');
    } else {
        clearButton.classList.remove('hidden');
        
        // Search if at least 2 characters
        if (input.value.trim().length >= 2) {
            $.post('https://tokyo_box/searchTracks', JSON.stringify({
                query: input.value.trim()
            }));
        }
    }
}

// Clear search
function clearSearch() {
    document.getElementById('search-input').value = '';
    document.getElementById('clear-search').classList.add('hidden');
    document.getElementById('search-results').innerHTML = '';
}

// Show track options modal
function showTrackOptionsModal(track) {
    selectedTrackForOptions = track;
    
    document.getElementById('track-options-title').textContent = track.title;
    
    // Update favorite text
    const favOption = document.getElementById('option-toggle-favorite');
    const isFavorite = favorites.some(fav => fav.id === track.id);
    
    favOption.querySelector('span').textContent = isFavorite 
        ? 'Remover dos favoritos' 
        : 'Adicionar aos favoritos';
        
    favOption.querySelector('i').setAttribute('data-feather', isFavorite ? 'heart-off' : 'heart');
    
    document.getElementById('track-options-modal').classList.add('visible');
    feather.replace();
}

// Hide track options modal
function hideTrackOptionsModal() {
    document.getElementById('track-options-modal').classList.remove('visible');
    selectedTrackForOptions = null;
}

// Play selected track from options modal
function playSelectedTrack() {
    if (!selectedTrackForOptions) return;
    
    $.post('https://tokyo_box/playTrack', JSON.stringify({
        trackId: selectedTrackForOptions.id,
        playlistId: currentPlaylist ? currentPlaylist.id : null
    }));
    
    hideTrackOptionsModal();
}

// Toggle favorite for selected track
function toggleFavoriteSelectedTrack() {
    if (!selectedTrackForOptions) return;
    
    $.post('https://tokyo_box/toggleFavorite', JSON.stringify({
        trackId: selectedTrackForOptions.id
    }));
    
    hideTrackOptionsModal();
}

// Show add to playlist modal
function showAddToPlaylistModal() {
    if (!selectedTrackForOptions) return;
    
    // Populate playlists
    const container = document.getElementById('playlist-options');
    container.innerHTML = '';
    
    if (playlists.length === 0) {
        container.innerHTML = '<p class="empty-message">Você não tem playlists. Crie uma primeiro!</p>';
    } else {
        playlists.forEach(playlist => {
            const option = document.createElement('div');
            option.className = 'option';
            option.innerHTML = `
                <i data-feather="plus-square"></i>
                <span>${playlist.name}</span>
            `;
            option.addEventListener('click', () => {
                addTrackToPlaylist(selectedTrackForOptions.id, playlist.id);
                hideAddToPlaylistModal();
                hideTrackOptionsModal();
            });
            
            container.appendChild(option);
        });
    }
    
    // Replace icons
    feather.replace();
    
    document.getElementById('add-to-playlist-modal').classList.add('visible');
}

// Hide add to playlist modal
function hideAddToPlaylistModal() {
    document.getElementById('add-to-playlist-modal').classList.remove('visible');
}

// Add track to playlist
function addTrackToPlaylist(trackId, playlistId) {
    $.post('https://tokyo_box/addToPlaylist', JSON.stringify({
        trackId: trackId,
        playlistId: playlistId
    }));
}

// Show notification
function showNotification(message, status = 'info') {
    const notification = document.getElementById('notification');
    notification.classList.remove('success', 'error', 'info', 'warning');
    notification.classList.add(status);
    
    document.querySelector('.notification-message').textContent = message;
    notification.classList.add('visible');
    
    // Hide after 3 seconds
    setTimeout(() => {
        notification.classList.remove('visible');
    }, 3000);
}

// NUI Message Handler
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch (data.type) {
        case "openUI":
            // Initialize UI with settings
            currentVolume = data.volume || 70;
            bluetoothEnabled = data.bluetooth || false;
            audioRange = data.audioRange || 10.0;
            
            // Update UI
            document.getElementById('volume-fill').style.width = currentVolume + '%';
            document.getElementById('volume-handle').style.left = currentVolume + '%';
            document.getElementById('bluetooth-toggle').checked = bluetoothEnabled;
            document.getElementById('range-slider').value = audioRange;
            document.getElementById('range-value').textContent = audioRange;
            break;
            
        case "closeUI":
            // Cleanup if needed
            break;
            
        case "setPlaylists":
            // Save playlists and render them
            playlists = data.playlists;
            renderPlaylists();
            break;
            
        case "searchResults":
            // Display search results
            renderSearchResults(data.results);
            break;
            
        case "playlistTracks":
            // Display playlist tracks
            if (data.playlistInfo) {
                document.getElementById('current-playlist-name').textContent = data.playlistInfo.name;
                document.getElementById('current-playlist-info').textContent = 
                    `${data.tracks.length} músicas`;
                
                // Set cover with gradient if none provided
                const coverEl = document.getElementById('current-playlist-cover');
                if (data.playlistInfo.cover_url) {
                    coverEl.style.backgroundImage = `url('${data.playlistInfo.cover_url}')`;
                } else {
                    const gradients = [
                        '45deg, #6225E6, #4DC5FF',
                        '45deg, #8A5DE8, #4DFFA3',
                        '45deg, #FF4D6A, #8A5DE8',
                        '45deg, #4DC5FF, #FFB74D',
                        '45deg, #4DFFA3, #6225E6'
                    ];
                    const gradient = gradients[Math.floor(Math.random() * gradients.length)];
                    coverEl.style.backgroundImage = `linear-gradient(${gradient})`;
                }
            }
            
            renderPlaylistTracks(data.tracks);
            break;
            
        case "favorites":
            // Display favorite tracks
            favorites = data.favorites;
            renderFavorites();
            break;
            
        case "updatePlayer":
            // Update player with track info
            currentTrack = data.track;
            if (data.playlist) {
                currentPlaylist = data.playlist;
            }
            
            // Update UI elements
            document.getElementById('current-track-title').textContent = data.track.title;
            document.getElementById('current-track-artist').textContent = data.track.artist || 'Artista Desconhecido';
            
            if (data.track.thumbnail) {
                document.getElementById('current-track-thumbnail').style.backgroundImage = `url('${data.track.thumbnail}')`;
            } else {
                document.getElementById('current-track-thumbnail').style.backgroundImage = 'none';
                document.getElementById('current-track-thumbnail').style.backgroundColor = 'var(--background-light)';
            }
            
            // Update expanded view
            document.getElementById('current-track-title-expanded').textContent = data.track.title;
            document.getElementById('current-track-artist-expanded').textContent = data.track.artist || 'Artista Desconhecido';
            
            if (data.track.thumbnail) {
                document.getElementById('current-track-thumbnail-expanded').style.backgroundImage = `url('${data.track.thumbnail}')`;
            } else {
                document.getElementById('current-track-thumbnail-expanded').style.backgroundImage = 'none';
                document.getElementById('current-track-thumbnail-expanded').style.backgroundColor = 'var(--background-light)';
            }
            
            // Update player state and icons
            isPlaying = true;
            isPaused = false;
            updatePlayPauseIcons(true);
            
            // Set duration if available
            if (data.track.duration) {
                trackDuration = data.track.duration;
                document.getElementById('total-time').textContent = formatTime(trackDuration);
            }
            break;
            
        case "playerState":
            // Update player state (playing/paused)
            isPaused = data.isPaused || false;
            isPlaying = data.isPlaying !== false;
            updatePlayPauseIcons(!isPaused && isPlaying);
            break;
            
        case "position":
            // Update position in player
            if (trackDuration > 0) {
                const percent = (data.position / data.duration) * 100;
                document.getElementById('progress-fill').style.width = percent + '%';
                document.getElementById('progress-handle').style.left = percent + '%';
                document.getElementById('current-time').textContent = formatTime(data.position);
            }
            break;
            
        case "bluetoothState":
            // Update bluetooth state
            bluetoothEnabled = data.enabled;
            document.getElementById('bluetooth-toggle').checked = bluetoothEnabled;
            break;
            
        case "audioRange":
            // Update audio range
            audioRange = data.range;
            document.getElementById('range-slider').value = audioRange;
            document.getElementById('range-value').textContent = audioRange;
            break;
            
        case "notification":
            // Show notification
            showNotification(data.message, data.status);
            break;
            
        case "goBack":
            // Handle back navigation
            if (currentView === 'playlist-view') {
                changeView('library-view');
            }
            break;
    }
});

// Render playlists in UI
function renderPlaylists() {
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
        const recentPlaylists = playlists.slice(0, 5);
        recentPlaylists.forEach(playlist => {
            const gradients = [
                '45deg, #6225E6, #4DC5FF',
                '45deg, #8A5DE8, #4DFFA3',
                '45deg, #FF4D6A, #8A5DE8',
                '45deg, #4DC5FF, #FFB74D',
                '45deg, #4DFFA3, #6225E6'
            ];
            const gradient = gradients[Math.floor(Math.random() * gradients.length)];
            
            const coverStyle = playlist.cover_url 
                ? `background-image: url('${playlist.cover_url}')`
                : `background-image: linear-gradient(${gradient})`;
                
            homeHtml += `
                <div class="playlist-item" data-id="${playlist.id}">
                    <div class="playlist-cover" style="${coverStyle}"></div>
                    <div class="playlist-name">${playlist.name}</div>
                </div>
            `;
        });
        
        homeContainer.innerHTML = homeHtml;
    }
    
    // For Library view (all playlists)
    const libraryContainer = document.getElementById('library-playlists');
    if (libraryContainer) {
        let libraryHtml = '';
        
        if (playlists.length === 0) {
            libraryHtml = '<p class="empty-message">Você não tem playlists. Crie uma!</p>';
        } else {
            playlists.forEach(playlist => {
                const gradients = [
                    '45deg, #6225E6, #4DC5FF',
                    '45deg, #8A5DE8, #4DFFA3',
                    '45deg, #FF4D6A, #8A5DE8',
                    '45deg, #4DC5FF, #FFB74D',
                    '45deg, #4DFFA3, #6225E6'
                ];
                const gradient = gradients[Math.floor(Math.random() * gradients.length)];
                
                const coverStyle = playlist.cover_url 
                    ? `background-image: url('${playlist.cover_url}')`
                    : `background-image: linear-gradient(${gradient})`;
                    
                libraryHtml += `
                    <div class="playlist-item" data-id="${playlist.id}">
                        <div class="playlist-cover" style="${coverStyle}"></div>
                        <div class="playlist-name">${playlist.name}</div>
                    </div>
                `;
            });
        }
        
        libraryContainer.innerHTML = libraryHtml;
    }
    
    // Refresh Feather icons
    feather.replace();
    
    // Add event listeners to playlists
    document.querySelectorAll('.playlist-item:not(.create-playlist)').forEach(item => {
        item.addEventListener('click', () => {
            const playlistId = item.getAttribute('data-id');
            if (playlistId) {
                // Get playlist tracks
                $.post('https://tokyo_box/getPlaylistTracks', JSON.stringify({
                    playlistId: playlistId
                }));
                
                // Show playlist view
                changeView('playlist-view');
            }
        });
    });
}

// Render search results
function renderSearchResults(results) {
    const container = document.getElementById('search-results');
    if (!container) return;
    
    if (!results || results.length === 0) {
        container.innerHTML = '<p class="empty-message">Nenhum resultado encontrado. Tente outra busca.</p>';
        return;
    }
    
    let html = '';
    results.forEach(track => {
        const thumbStyle = track.thumbnail 
            ? `background-image: url('${track.thumbnail}')`
            : `background-color: var(--background-light)`;
        
        html += `
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
    });
    
    container.innerHTML = html;
    
    // Refresh Feather icons
    feather.replace();
    
    // Add event listeners
    attachTrackEventListeners(container, results);
}

// Render playlist tracks
function renderPlaylistTracks(tracks) {
    const container = document.getElementById('playlist-tracks');
    if (!container) return;
    
    if (!tracks || tracks.length === 0) {
        container.innerHTML = '<p class="empty-message">Esta playlist está vazia. Adicione músicas!</p>';
        return;
    }
    
    let html = '';
    tracks.forEach(track => {
        const thumbStyle = track.thumbnail 
            ? `background-image: url('${track.thumbnail}')`
            : `background-color: var(--background-light)`;
        
        html += `
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
    });
    
    container.innerHTML = html;
    
    // Refresh Feather icons
    feather.replace();
    
    // Add event listeners
    attachTrackEventListeners(container, tracks);
}

// Render favorites
function renderFavorites() {
    const container = document.getElementById('favorite-tracks');
    if (!container) return;
    
    if (!favorites || favorites.length === 0) {
        container.innerHTML = '<p class="empty-message">Você não tem músicas favoritas ainda.</p>';
        return;
    }
    
    let html = '';
    favorites.forEach(track => {
        const thumbStyle = track.thumbnail 
            ? `background-image: url('${track.thumbnail}')`
            : `background-color: var(--background-light)`;
        
        html += `
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
    });
    
    container.innerHTML = html;
    
    // Refresh Feather icons
    feather.replace();
    
    // Add event listeners
    attachTrackEventListeners(container, favorites);
}

// Attach event listeners to track items
function attachTrackEventListeners(container, tracks) {
    const trackItems = container.querySelectorAll('.track-item');
    
    trackItems.forEach(item => {
        // Play on click
        item.addEventListener('click', (e) => {
            if (!e.target.closest('.track-options')) {
                const trackId = item.getAttribute('data-id');
                const track = tracks.find(t => t.id == trackId);
                
                $.post('https://tokyo_box/playTrack', JSON.stringify({
                    trackId: trackId,
                    playlistId: currentPlaylist ? currentPlaylist.id : null
                }));
            }
        });
        
        // Options menu
        const optionsBtn = item.querySelector('.track-options');
        if (optionsBtn) {
            optionsBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                const trackId = item.getAttribute('data-id');
                const track = tracks.find(t => t.id == trackId);
                
                if (track) {
                    showTrackOptionsModal(track);
                }
            });
        }
    });
}

// NUI Callback Function
function closeApp() {
    $.post('https://tokyo_box/closeUI', JSON.stringify({}));
}

// Keybind for closing UI with Escape key
document.addEventListener('keyup', function(event) {
    if (event.key === 'Escape') {
        closeApp();
    }
});