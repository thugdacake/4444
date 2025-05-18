// Tokyo Box Player Component
// This component handles audio player functionality

class TokyoBoxPlayer {
    constructor() {
        // State variables
        this.currentTrack = null;
        this.isPlaying = false;
        this.isPaused = false;
        this.volume = 70; // 0-100
        this.position = 0;
        this.duration = 0;
        this.currentPlaylist = null;
        this.bluetoothEnabled = false;
        this.audioRange = 10.0;
    }
    
    // Initialize the player
    init() {
        // Set up volume from saved settings
        if (localStorage.getItem('tokyo_box_volume')) {
            this.volume = parseInt(localStorage.getItem('tokyo_box_volume'));
        }
        
        // Set bluetooth status
        if (localStorage.getItem('tokyo_box_bluetooth')) {
            this.bluetoothEnabled = localStorage.getItem('tokyo_box_bluetooth') === 'true';
        }
        
        // Set audio range
        if (localStorage.getItem('tokyo_box_range')) {
            this.audioRange = parseFloat(localStorage.getItem('tokyo_box_range'));
        }
        
        // Update the UI
        this.updateVolumeUI();
        this.updateBluetoothUI();
        this.updateRangeUI();
    }
    
    // Play a new track
    playTrack(track, playlist = null) {
        if (!track) return;
        
        // Save the current track
        this.currentTrack = track;
        
        // Save the playlist if provided
        if (playlist) {
            this.currentPlaylist = playlist;
        }
        
        // Reset position
        this.position = 0;
        this.duration = track.duration || 0;
        
        // Update state
        this.isPlaying = true;
        this.isPaused = false;
        
        // Update UI
        this.updatePlayerUI();
    }
    
    // Pause the current track
    pauseTrack() {
        if (!this.currentTrack || !this.isPlaying) return;
        
        this.isPaused = true;
        this.updatePlayerUI();
    }
    
    // Resume the current track
    resumeTrack() {
        if (!this.currentTrack) return;
        
        this.isPaused = false;
        this.isPlaying = true;
        this.updatePlayerUI();
    }
    
    // Stop the current track
    stopTrack() {
        this.isPlaying = false;
        this.isPaused = false;
        this.position = 0;
        this.updatePlayerUI();
    }
    
    // Update player UI
    updatePlayerUI() {
        // This functions just as a placeholder - actual UI updates
        // are handled by the main script.js when it receives events
    }
    
    // Update volume UI
    updateVolumeUI() {
        const volumeFill = document.getElementById('volume-fill');
        const volumeHandle = document.getElementById('volume-handle');
        
        if (volumeFill && volumeHandle) {
            volumeFill.style.width = this.volume + '%';
            volumeHandle.style.left = this.volume + '%';
        }
        
        // Save to localStorage
        localStorage.setItem('tokyo_box_volume', this.volume);
    }
    
    // Update bluetooth UI
    updateBluetoothUI() {
        const bluetoothToggle = document.getElementById('bluetooth-toggle');
        
        if (bluetoothToggle) {
            bluetoothToggle.checked = this.bluetoothEnabled;
        }
        
        // Save to localStorage
        localStorage.setItem('tokyo_box_bluetooth', this.bluetoothEnabled);
    }
    
    // Update range UI
    updateRangeUI() {
        const rangeSlider = document.getElementById('range-slider');
        const rangeValue = document.getElementById('range-value');
        
        if (rangeSlider && rangeValue) {
            rangeSlider.value = this.audioRange;
            rangeValue.textContent = this.audioRange;
        }
        
        // Save to localStorage
        localStorage.setItem('tokyo_box_range', this.audioRange);
    }
    
    // Set volume
    setVolume(volume) {
        this.volume = Math.max(0, Math.min(100, volume));
        this.updateVolumeUI();
    }
    
    // Set bluetooth status
    setBluetoothStatus(enabled) {
        this.bluetoothEnabled = enabled;
        this.updateBluetoothUI();
    }
    
    // Set audio range
    setAudioRange(range) {
        this.audioRange = Math.max(1.0, Math.min(30.0, range));
        this.updateRangeUI();
    }
    
    // Seek to position
    seekToPosition(position) {
        if (!this.currentTrack) return;
        
        this.position = Math.max(0, Math.min(this.duration, position));
    }
    
    // Update position
    updatePosition(position) {
        if (!this.currentTrack) return;
        
        this.position = position;
        
        // Update progress UI
        this.updateProgressUI();
    }
    
    // Update progress UI
    updateProgressUI() {
        if (!this.currentTrack || this.duration <= 0) return;
        
        const percent = (this.position / this.duration) * 100;
        const progressFill = document.getElementById('progress-fill');
        const progressHandle = document.getElementById('progress-handle');
        const currentTime = document.getElementById('current-time');
        
        if (progressFill && progressHandle) {
            progressFill.style.width = percent + '%';
            progressHandle.style.left = percent + '%';
        }
        
        if (currentTime) {
            currentTime.textContent = this.formatTime(this.position);
        }
    }
    
    // Format time in seconds to MM:SS
    formatTime(timeInSeconds) {
        const minutes = Math.floor(timeInSeconds / 60);
        const seconds = Math.floor(timeInSeconds % 60);
        return `${minutes}:${seconds.toString().padStart(2, '0')}`;
    }
    
    // Get the player state
    getState() {
        return {
            currentTrack: this.currentTrack,
            isPlaying: this.isPlaying,
            isPaused: this.isPaused,
            volume: this.volume,
            position: this.position,
            duration: this.duration,
            currentPlaylist: this.currentPlaylist,
            bluetoothEnabled: this.bluetoothEnabled,
            audioRange: this.audioRange
        };
    }
    
    // Play next track
    playNextTrack() {
        if (!this.currentPlaylist || !this.currentTrack) return false;
        
        // In FiveM implementation, this will be handled by the server
        // which keeps track of playlist ordering
        return true;
    }
    
    // Play previous track
    playPreviousTrack() {
        if (!this.currentPlaylist || !this.currentTrack) return false;
        
        // In FiveM implementation, this will be handled by the server
        // which keeps track of playlist ordering
        return true;
    }
}

// Create global player instance
const tokyoBoxPlayer = new TokyoBoxPlayer();

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    tokyoBoxPlayer.init();
});