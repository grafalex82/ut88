import os

StandardDiskParams = {
    'sectors_per_track': 26,
    'tracks_count': 77,
    'sector_translation': [0, 6, 12, 18, 24, 4, 10, 16, 22, 2, 8, 14, 20, 
                           1, 7, 13, 19, 25, 5, 11, 17, 23, 3, 9, 15, 21], # Skew factor 6
    'reserved_tracks': 2,
    'num_blocks': 243,
    'block_size': 1024,
    'num_dir_entries': 64,
    'extent_mask': 0 
}

UT88DiskParams = {
    'sectors_per_track': 8,
    'tracks_count': 256,
    'sector_translation': [0, 1, 2, 3, 4, 5, 6, 7], # No sector translation
    'reserved_tracks': 6,
    'num_blocks': 250,
    'block_size': 1024,
    'num_dir_entries': 32,
    'extent_mask': 0
}

SECTOR_SIZE = 128
DIR_ENTRY_SIZE = 32

def bytes2str(data):
    return ''.join(chr(code) for code in data)


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
            self.data = [0xe5] * (self.params['tracks_count'] * self.params['sectors_per_track'] * SECTOR_SIZE)


    def do_sector_translation(self, data, reverse=False):
        sector_translation = self.reverse_translation if reverse else self.sector_translation
        
        assert len(data) == self.params['tracks_count'] * self.params['sectors_per_track'] * SECTOR_SIZE

        sectors_per_track = self.params['sectors_per_track']

        res = []
        for track in range(self.params['tracks_count']):
            for sector in range(sectors_per_track):
                track_offset = track * sectors_per_track * SECTOR_SIZE
                sector_offset = sector_translation[sector] * SECTOR_SIZE
                res.extend(data[track_offset + sector_offset : track_offset + sector_offset + SECTOR_SIZE])

        return res


    def flush(self):
        with open(self.filename, "w+b") as f:
            f.write(bytearray(self.do_sector_translation(self.data, True)))


    def get_dir_entries(self):
        dir_offset = self.params['reserved_tracks'] * self.params['sectors_per_track'] * SECTOR_SIZE
        for i in range(self.params['num_dir_entries']):
            yield dir_offset + i * DIR_ENTRY_SIZE


    def list_dir_raw(self):
        res = []
        for entry_offset in self.get_dir_entries():
            entry = self.data[entry_offset : entry_offset + DIR_ENTRY_SIZE] 

            code = self.data[entry_offset + 0]
            if code == 0xe5:        # Entries that start with 0xe5 byte are deleted/empty
                continue

            record = {}
            record['user_code'] = code
            record['name'] = bytes2str(entry[1:9]).strip()
            record['ext'] = bytes2str(entry[9:12]).strip()
            record['EX'] = entry[12]
            record['S2'] = entry[14]
            record['entry'] = ((DIR_ENTRY_SIZE * entry[14]) + entry[12]) // (self.params['extent_mask'] + 1) # as per spec
            record['num_records'] = (entry[12] & self.params['extent_mask']) * SECTOR_SIZE + entry[15]
            record['allocation'] = [x for x in entry[16:32] if x != 0] # Only 1-byte allocation entries supported
            res.append(record)

        return res
    

    def list_dir(self):
        entries = sorted(self.list_dir_raw(), key=lambda x: x['entry'], reverse=False)

        res = {}
        for entry in entries:
            filename = entry['name'] + '.' + entry['ext']

            if filename in res:
                record = res[filename]
                record['allocation'].extend(entry['allocation'])
                record['num_records'] += entry['num_records']
            else:
                record = {
                    'filename': filename,
                    'num_records': entry['num_records'],
                    'allocation': entry['allocation'],
                    'user_code': entry['user_code']
                }
                res[filename] = record

        return res
    

    def read_block(self, block):
        data_start = self.params['sectors_per_track'] * self.params['reserved_tracks'] * SECTOR_SIZE
        block_size = self.params['block_size']
        block_offset = block_size * block
        return self.data[data_start + block_offset : data_start + block_offset + block_size]


    def write_block(self, block, data):
        data_start = self.params['sectors_per_track'] * self.params['reserved_tracks'] * SECTOR_SIZE
        block_size = self.params['block_size']
        data_size = min(len(data), block_size)
        block_offset = block_size * block
        self.data[data_start + block_offset : data_start + block_offset + data_size] = data[0 : data_size]


    def get_disk_allocation(self):
        # Create an allocation vector with all blocks free
        allocation = [False] * self.params['num_blocks']

        # Mark directory blocks as allocated
        num_dir_blocks = self.params['num_dir_entries'] * DIR_ENTRY_SIZE // self.params['block_size']
        for i in range(num_dir_blocks):
            allocation[i] = True

        # Iterate over all files, and mark their blocks as allocated
        for entry in self.list_dir_raw():
            for alloc_entry in entry['allocation']:
                allocation[alloc_entry] = True

        return allocation
        

    def get_free_blocks(self):
        allocation = self.get_disk_allocation()
        free_blocks = [b for b in range(len(allocation)) if allocation[b] == False]
        return free_blocks            


    def write_directory_entry(self, filename, extent, extent_allocation, extent_records, user_code = 0):
        # Search for an empty entry
        for entry_offset in self.get_dir_entries():
            if self.data[entry_offset] != 0xe5:
                continue

            # Write the entry
            name, ext = filename.split('.')
            name = f"{name.strip():8}"
            self.data[entry_offset + 0] = user_code
            self.data[entry_offset + 1 : entry_offset + 9] = bytearray(f"{name.strip():8}".encode('ascii'))
            self.data[entry_offset + 9 : entry_offset + 12] = bytearray(f"{ext.strip():3}".encode('ascii'))
            self.data[entry_offset + 12] = extent
            self.data[entry_offset + 13] = 0 # S1
            self.data[entry_offset + 14] = 0 # S2
            self.data[entry_offset + 15] = extent_records
            assert len(extent_allocation) <= 16
            for i in range(16):
                self.data[entry_offset + 16 + i] = 0 if i >= len(extent_allocation) else extent_allocation[i]

            return

        # No 'out of dir entries' error processing is implemented



    def read_file(self, filename):
        entry = self.list_dir()[filename]   # TODO filter by user code as well
        num_records = entry['num_records']

        data = bytearray()
        for block in entry['allocation']:
            data.extend(self.read_block(block))

        return data[0:num_records*SECTOR_SIZE]
    

    def write_file(self, filename, data, user_code = 0):
        # Delete the file, if another file with the same name exists
        self.delete_file(filename)

        # Pre-calculate variables
        free_blocks = self.get_free_blocks()
        block_size = self.params['block_size']
        data_offset = 0
        extent = 0
        extent_allocation = []
        extent_records = 0

        # Pad the data to sector boundary
        bytes_to_pad = (128 - len(data) % 128) % 128
        data = bytearray(data)
        data.extend(bytearray([0x1e] * bytes_to_pad))

        # Iterate over data sectors
        while(data_offset < len(data)):
            data_len = min(len(data) - data_offset, block_size)
            block = free_blocks.pop(0)
            self.write_block(block, data[data_offset : data_offset + data_len])

            extent_allocation.append(block) # Only 1-byte allocation entries supported
            extent_records += data_len // SECTOR_SIZE

            if len(extent_allocation) == 16:
                self.write_directory_entry(filename, extent, extent_allocation, extent_records, user_code)
                extent += 1
                extent_allocation = []
                extent_records = 0

            data_offset += data_len

        # Write the final extent entry (may cause an extra empty extent entry, but this is correct)
        self.write_directory_entry(filename, extent, extent_allocation, extent_records, user_code)


    def delete_file(self, filename):
        # Prepare file name and extension
        name, ext = filename.split('.')
        name = f"{name.strip().upper():8}"
        ext = f"{ext.strip().upper():3}"

        # Iterate through the directory entries
        for entry_offset in self.get_dir_entries():
            # Skip already deleted entries
            if self.data[entry_offset] == 0xe5:
                continue

            # Match the file name and extension
            if bytes2str(self.data[entry_offset + 1 : entry_offset + 9]) != name:
                continue
            if bytes2str(self.data[entry_offset + 9 : entry_offset + 12]) != ext:
                continue

            # Mark the found entry as deleted
            self.data[entry_offset] = 0xe5

