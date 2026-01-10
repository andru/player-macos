protocol AlbumsQueries {
    func fetchAlbumRows () async throws -> [AlbumRow]
    
//    func fetchAlbumDetails (releaseGroupId: Int64) async throws -> [AlbumDetails]
}
