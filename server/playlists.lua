-- Tokyo Box Server Playlist Functions

-- Get player's playlists
function GetPlayerPlaylists(identifier, callback)
    MySQL.Async.fetchAll('SELECT * FROM tokyo_box_playlists WHERE owner_id = ? ORDER BY created_at DESC', 
        {identifier},
        function(results)
            callback(results)
        end
    )
end

-- Create a new playlist
function CreatePlaylist(identifier, name, description, callback)
    MySQL.Async.insert('INSERT INTO tokyo_box_playlists (name, description, owner_id) VALUES (?, ?, ?)', 
        {name, description, identifier},
        function(playlistId)
            callback(playlistId)
        end
    )
end

-- Delete a playlist
function DeletePlaylist(identifier, playlistId, callback)
    -- First check if the playlist belongs to the player
    MySQL.Async.fetchScalar('SELECT owner_id FROM tokyo_box_playlists WHERE id = ?', 
        {playlistId},
        function(ownerId)
            if ownerId == identifier then
                -- Delete playlist_songs entries first
                MySQL.Async.execute('DELETE FROM tokyo_box_playlist_songs WHERE playlist_id = ?', 
                    {playlistId},
                    function()
                        -- Then delete the playlist itself
                        MySQL.Async.execute('DELETE FROM tokyo_box_playlists WHERE id = ?', 
                            {playlistId},
                            function(rowsChanged)
                                callback(rowsChanged > 0)
                            end
                        )
                    end
                )
            else
                callback(false)
            end
        end
    )
end

-- Get playlist info
function GetPlaylistInfo(playlistId, callback)
    MySQL.Async.fetchAll('SELECT * FROM tokyo_box_playlists WHERE id = ?', 
        {playlistId},
        function(results)
            if results and results[1] then
                -- Get song count
                MySQL.Async.fetchScalar('SELECT COUNT(*) FROM tokyo_box_playlist_songs WHERE playlist_id = ?', 
                    {playlistId},
                    function(count)
                        local playlist = results[1]
                        playlist.songCount = count
                        callback(playlist)
                    end
                )
            else
                callback(nil)
            end
        end
    )
end

-- Add track to playlist
function AddTrackToPlaylist(identifier, trackId, playlistId, callback)
    -- First check if the playlist belongs to the player
    MySQL.Async.fetchScalar('SELECT owner_id FROM tokyo_box_playlists WHERE id = ?', 
        {playlistId},
        function(ownerId)
            if ownerId == identifier then
                -- Check if the song exists
                EnsureSongExists(trackId, function(songId)
                    if songId then
                        -- Get max position to append at the end
                        MySQL.Async.fetchScalar('SELECT MAX(position) FROM tokyo_box_playlist_songs WHERE playlist_id = ?', 
                            {playlistId},
                            function(maxPosition)
                                local position = maxPosition and maxPosition + 1 or 0
                                
                                -- Check if song already exists in playlist
                                MySQL.Async.fetchScalar('SELECT COUNT(*) FROM tokyo_box_playlist_songs WHERE playlist_id = ? AND song_id = ?', 
                                    {playlistId, songId},
                                    function(count)
                                        if count > 0 then
                                            -- Song already in playlist
                                            callback(true)
                                        else
                                            -- Add song to playlist
                                            MySQL.Async.execute('INSERT INTO tokyo_box_playlist_songs (playlist_id, song_id, position) VALUES (?, ?, ?)', 
                                                {playlistId, songId, position},
                                                function(rowsChanged)
                                                    callback(rowsChanged > 0)
                                                end
                                            )
                                        end
                                    end
                                )
                            end
                        )
                    else
                        callback(false)
                    end
                end)
            else
                callback(false)
            end
        end
    )
end

-- Remove track from playlist
function RemoveTrackFromPlaylist(identifier, trackId, playlistId, callback)
    -- First check if the playlist belongs to the player
    MySQL.Async.fetchScalar('SELECT owner_id FROM tokyo_box_playlists WHERE id = ?', 
        {playlistId},
        function(ownerId)
            if ownerId == identifier then
                -- Remove song from playlist
                MySQL.Async.execute('DELETE FROM tokyo_box_playlist_songs WHERE playlist_id = ? AND song_id = ?', 
                    {playlistId, trackId},
                    function(rowsChanged)
                        callback(rowsChanged > 0)
                    end
                )
            else
                callback(false)
            end
        end
    )
end

-- Get playlist tracks
function GetPlaylistTracks(playlistId, callback)
    MySQL.Async.fetchAll([[
        SELECT s.*, ps.position, ps.id as playlist_song_id
        FROM tokyo_box_playlist_songs ps
        JOIN tokyo_box_songs s ON ps.song_id = s.id
        WHERE ps.playlist_id = ?
        ORDER BY ps.position
    ]], 
    {playlistId},
    function(results)
        callback(results)
    end)
end

-- Get next track in playlist
function GetNextTrack(playlistId, currentTrackId, callback)
    MySQL.Async.fetchScalar('SELECT position FROM tokyo_box_playlist_songs WHERE playlist_id = ? AND song_id = ?', 
        {playlistId, currentTrackId},
        function(currentPosition)
            if currentPosition == nil then
                -- If current track not found, get first track
                MySQL.Async.fetchAll([[
                    SELECT s.*
                    FROM tokyo_box_playlist_songs ps
                    JOIN tokyo_box_songs s ON ps.song_id = s.id
                    WHERE ps.playlist_id = ?
                    ORDER BY ps.position
                    LIMIT 1
                ]], 
                {playlistId},
                function(results)
                    callback(results and results[1] or nil)
                end)
            else
                -- Get next track
                MySQL.Async.fetchAll([[
                    SELECT s.*
                    FROM tokyo_box_playlist_songs ps
                    JOIN tokyo_box_songs s ON ps.song_id = s.id
                    WHERE ps.playlist_id = ? AND ps.position > ?
                    ORDER BY ps.position
                    LIMIT 1
                ]], 
                {playlistId, currentPosition},
                function(results)
                    callback(results and results[1] or nil)
                end)
            end
        end
    )
end

-- Get previous track in playlist
function GetPreviousTrack(playlistId, currentTrackId, callback)
    MySQL.Async.fetchScalar('SELECT position FROM tokyo_box_playlist_songs WHERE playlist_id = ? AND song_id = ?', 
        {playlistId, currentTrackId},
        function(currentPosition)
            if currentPosition == nil then
                -- If current track not found, get first track
                MySQL.Async.fetchAll([[
                    SELECT s.*
                    FROM tokyo_box_playlist_songs ps
                    JOIN tokyo_box_songs s ON ps.song_id = s.id
                    WHERE ps.playlist_id = ?
                    ORDER BY ps.position
                    LIMIT 1
                ]], 
                {playlistId},
                function(results)
                    callback(results and results[1] or nil)
                end)
            else
                -- Get previous track
                MySQL.Async.fetchAll([[
                    SELECT s.*
                    FROM tokyo_box_playlist_songs ps
                    JOIN tokyo_box_songs s ON ps.song_id = s.id
                    WHERE ps.playlist_id = ? AND ps.position < ?
                    ORDER BY ps.position DESC
                    LIMIT 1
                ]], 
                {playlistId, currentPosition},
                function(results)
                    callback(results and results[1] or nil)
                end)
            end
        end
    )
end