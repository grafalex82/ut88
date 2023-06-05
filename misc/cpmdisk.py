import os

StandardDiskParams = {
    'sectors_per_track': 26,
    'tracks_count': 77,
    'sector_translation': [0, 6, 12, 18, 24, 4, 10, 16, 22, 2, 8, 14, 20, 
                           1, 7, 13, 19, 25, 5, 11, 17, 23, 3, 9, 15, 21], # Skew factor 6
    'reserved_tracks': 2,
    'num_blocks': 243,
    'num_dir_entries': 64
}

UT88DiskParams = {
    'sectors_per_track': 8,
    'tracks_count': 256,
    'sector_translation': [0, 1, 2, 3, 4, 5, 6, 7], # No sector translation
    'reserved_tracks': 6,
    'num_blocks': 58,
    'num_dir_entries': 32    
}

class CPMDisk():
    def __init__(self, filename, params=StandardDiskParams):
        self.filename = filename
        self.params = params

        self.sector_translation = params['sector_translation']
        self.reverse_translation = [0] * self.params['sectors_per_track']
        for i in range(len(self.sector_translation)):
            self.reverse_translation[self.sector_translation[i]] = i

        if os.path.isfile(self.filename):
            with open(self.filename, "rb") as f:
                self.data = self.do_sector_translation(f.read(), False)
                
        else:
            self.data = [0] * (self.params['tracks_count'] * self.params['sectors_per_track'] * 128)


    def do_sector_translation(self, data, reverse=False):
        sector_translation = self.reverse_translation if reverse else self.sector_translation
        
        assert len(data) == self.params['tracks_count'] * self.params['sectors_per_track'] * 128

        sectors_per_track = self.params['sectors_per_track']

        res = []
        for track in range(self.params['tracks_count']):
            for sector in range(sectors_per_track):
                track_offset = track * sectors_per_track * 128
                sector_offset = sector_translation[sector] * 128
                res.extend(data[track_offset + sector_offset:track_offset + sector_offset+128])

        return res

    def flush(self):
        with open(self.filename, "w+b") as f:
            f.write(bytearray(self.do_sector_translation(self.data, True)))


    def list_dir(self):
        dir_offset = self.params['reserved_tracks'] * self.params['sectors_per_track'] * 128

        #for i in range(self.params['num_dir_entries'])
