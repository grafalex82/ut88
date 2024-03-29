import pygame

def _ctrl_pressed():
    return (pygame.key.get_mods() & pygame.KMOD_CTRL) != 0


class RK86Keyboard():
    """
        Radio-86RK Keyboard emulator

        This class emulates Radio-86RK alpha-numeric keyboard. The keyboard contains 8x8 keyboard matrix,
        and a 3 additional mod keys (Rus, Shift, and Ctrl). 

        Keyboard features are:
        - keys containing digits, letters, symbols, and space
        - 4 arrow keys + home key
        - CR and LF keys
        - Clear screen key
        - 3 Mod keys:
            - RUS toggle key, that changes some keys to represent Russian letters (Ё and Ъ letters did not fit
            the keyboard layout). Although Rus key behaves like a toggle, in fact it is a usual push button, 
            while the toggle feature is implemented by the Monitor.
            - Symbol shift - works like 'Shift' key on modern computers, but only for symbols. The computer does
            not offer lower case (all letters are upper case), so shift key does nothing for letter keys.
            - Control symbol - works like a 'Ctrl' key on modern computer terminals, but only for letter and 
            a few other keys. Aim of this button is to allow entering symbols with codes in 0x00-0x1f range.
        - F1-F5 keys (not handled by the Monitor, but can be used by user programs)

        With mod keys the keyboard allows entering pretty much every symbol in a range 0x00-0x7f. Among them:
        - 0x00-0x1f some pseudo-graphics symbols. Also in some modes symbols in this range represent control 
        symbols (e.g. cursor movement, clear screen) 
        - 0x20-0x5f - symbols, numbers, and Latin letters. These codes fully match standard ASCII table in this
        range.
        - 0x60-0x7f - this part is reserved for Russian letters (Ё and Ъ letters still do not fit the range).

        The keyboard layout is odd, compared to what is being used nowadays, but was quite popular on soviet
        computers back in 80x. The layout is based on the standard Russian layout, while Latin letters match
        the Russian ones, where possible. 
        

        Electrical connection notes:

        All the buttons (except for modification keys) are organized in a 8x8 matrix, connected to the
        computer via i8255 controller. Monitor selects one column at a time, by setting low level
        on a corresponding bit in Port A. Row state is captured via Port B (highest bit is ties to gnd, 
        other bits are pulled up with resistors, and will be read as 1 if no button is pressed in the
        selected column).

        3 modification keys set low level on corresponding bits on the Port C.        


        Emulation notes:

        Taking into account the odd layout, it would be quite impossible to emulate the keyboard as is.
        Instead, this class will detect keyboard press events, and translate it to Port A/B/C values (which
        in turn represent pressed button and a modification key). This approach allows emulating keyboard
        presses using currently active keyboard layout on the host system (including English and Russian).

        In order to detect letters on both languages, as well as distinguish symbols that are collocated on 
        the same button (e.g. colon and semicolon), the event.unicode field is used. For arrow keys, as
        well as Ctrl-key combinations, the pygame.KEYDOWN event is used.

        When a button is pressed, the emulator class sets the _pressed_key member to a tuple, representing
        ports A, B, and mod key values. When the Monitor F firmware will scan keyboard matrix via port A, the
        emulator will return port B value according to selected column and button pressed.

        Having that RUS mode toggle is a Monitor feature, the Cyrillic letters are not implemented in this
        keyboard emulator.
    """


    def __init__(self):
        self._port_a = 0xff
        self._port_c = 0xff
        self._pressed_key = (0xff, 0xff, False, False)

        self._key_map = {}
        self._key_map['0'] = (0xfb, 0xfe, False, False)     # Char code 0x30
        self._key_map['1'] = (0xfb, 0xfd, False, False)     # Char code 0x31
        self._key_map['2'] = (0xfb, 0xfb, False, False)     # Char code 0x32
        self._key_map['3'] = (0xfb, 0xf7, False, False)     # Char code 0x33
        self._key_map['4'] = (0xfb, 0xef, False, False)     # Char code 0x34
        self._key_map['5'] = (0xfb, 0xdf, False, False)     # Char code 0x35
        self._key_map['6'] = (0xfb, 0xbf, False, False)     # Char code 0x36
        self._key_map['7'] = (0xfb, 0x7f, False, False)     # Char code 0x37

        self._key_map['8'] = (0xf7, 0xfe, False, False)     # Char code 0x38
        self._key_map['9'] = (0xf7, 0xfd, False, False)     # Char code 0x39
        self._key_map[':'] = (0xf7, 0xfb, False, False)     # Char code 0x3a
        self._key_map[';'] = (0xf7, 0xf7, False, False)     # Char code 0x3b
        self._key_map[','] = (0xf7, 0xef, False, False)     # Char code 0x2c
        self._key_map['-'] = (0xf7, 0xdf, False, False)     # Char code 0x2d
        self._key_map['.'] = (0xf7, 0xbf, False, False)     # Char code 0x2e
        self._key_map['/'] = (0xf7, 0x7f, False, False)     # Char code 0x2f

        self._key_map['@'] = (0xef, 0xfe, False, False)     # Char code 0x40
        self._key_map['A'] = (0xef, 0xfd, False, False)     # Char code 0x41
        self._key_map['B'] = (0xef, 0xfb, False, False)     # Char code 0x42
        self._key_map['C'] = (0xef, 0xf7, False, False)     # Char code 0x43
        self._key_map['D'] = (0xef, 0xef, False, False)     # Char code 0x44
        self._key_map['E'] = (0xef, 0xdf, False, False)     # Char code 0x45
        self._key_map['F'] = (0xef, 0xbf, False, False)     # Char code 0x46
        self._key_map['G'] = (0xef, 0x7f, False, False)     # Char code 0x47

        self._key_map['H'] = (0xdf, 0xfe, False, False)     # Char code 0x48
        self._key_map['I'] = (0xdf, 0xfd, False, False)     # Char code 0x49
        self._key_map['J'] = (0xdf, 0xfb, False, False)     # Char code 0x4a
        self._key_map['K'] = (0xdf, 0xf7, False, False)     # Char code 0x4b
        self._key_map['L'] = (0xdf, 0xef, False, False)     # Char code 0x4c
        self._key_map['M'] = (0xdf, 0xdf, False, False)     # Char code 0x4d
        self._key_map['N'] = (0xdf, 0xbf, False, False)     # Char code 0x4e
        self._key_map['O'] = (0xdf, 0x7f, False, False)     # Char code 0x4f

        self._key_map['P'] = (0xbf, 0xfe, False, False)     # Char code 0x50
        self._key_map['Q'] = (0xbf, 0xfd, False, False)     # Char code 0x51
        self._key_map['R'] = (0xbf, 0xfb, False, False)     # Char code 0x52
        self._key_map['S'] = (0xbf, 0xf7, False, False)     # Char code 0x53
        self._key_map['T'] = (0xbf, 0xef, False, False)     # Char code 0x54
        self._key_map['U'] = (0xbf, 0xdf, False, False)     # Char code 0x55
        self._key_map['V'] = (0xbf, 0xbf, False, False)     # Char code 0x56
        self._key_map['W'] = (0xbf, 0x7f, False, False)     # Char code 0x57

        self._key_map['X'] = (0x7f, 0xfe, False, False)     # Char code 0x58
        self._key_map['Y'] = (0x7f, 0xfd, False, False)     # Char code 0x59
        self._key_map['Z'] = (0x7f, 0xfb, False, False)     # Char code 0x5a
        self._key_map['['] = (0x7f, 0xf7, False, False)     # Char code 0x5b
        self._key_map['\\'] = (0x7f, 0xef, False, False)    # Char code 0x5c
        self._key_map[']'] = (0x7f, 0xdf, False, False)     # Char code 0x5d
        self._key_map['^'] = (0x7f, 0xbf, False, False)     # Char code 0x5e
        self._key_map[' '] = (0x7f, 0x7f, False, False)     # Char code 0x20

        # Some symbols are entered with a 'Shift' key (Special Symbol key)
        #self._key_map[' '] = (0xfb, 0xfe, False, True)     # Char code 0x20   # Shift-0 generates a space
        self._key_map['!'] = (0xfb, 0xfd, False, True)      # Char code 0x21
        self._key_map['"'] = (0xfb, 0xfb, False, True)      # Char code 0x22
        self._key_map['#'] = (0xfb, 0xf7, False, True)      # Char code 0x23
        self._key_map['$'] = (0xfb, 0xef, False, True)      # Char code 0x24
        self._key_map['%'] = (0xfb, 0xdf, False, True)      # Char code 0x25
        self._key_map['&'] = (0xfb, 0xbf, False, True)      # Char code 0x26
        self._key_map["'"] = (0xfb, 0x7f, False, True)      # Char code 0x27

        self._key_map['('] = (0xf7, 0xfe, False, True)      # Char code 0x28
        self._key_map[')'] = (0xf7, 0xfd, False, True)      # Char code 0x29
        self._key_map['*'] = (0xf7, 0xfb, False, True)      # Char code 0x2a
        self._key_map['+'] = (0xf7, 0xf7, False, True)      # Char code 0x2b
        self._key_map['<'] = (0xf7, 0xef, False, True)      # Char code 0x3c
        self._key_map['='] = (0xf7, 0xdf, False, True)      # Char code 0x3d
        self._key_map['>'] = (0xf7, 0xbf, False, True)      # Char code 0x3e
        self._key_map['?'] = (0xf7, 0x7f, False, True)      # Char code 0x3f

        # Key codes for special keys
        self._key_codes_map = {}
        self._key_codes_map[pygame.K_TAB]       = (0xfd, 0xfe, False, False)  # Char code 0x09 (tab)
        self._key_codes_map[pygame.K_END]       = (0xfd, 0xfd, False, False)  # Char code 0x0a (line feed)
        self._key_codes_map[pygame.K_RETURN]    = (0xfd, 0xfb, False, False)  # Char code 0x0d (carriage return)
        self._key_codes_map[pygame.K_BACKSPACE] = (0xfd, 0xf7, False, False)  # Char code 0x7f (back space)
        self._key_codes_map[pygame.K_LEFT]      = (0xfd, 0xef, False, False)  # Char code 0x08 (left arrow)
        self._key_codes_map[pygame.K_UP]        = (0xfd, 0xdf, False, False)  # Char code 0x19 (up arrow)
        self._key_codes_map[pygame.K_RIGHT]     = (0xfd, 0xbf, False, False)  # Char code 0x18 (right arrow)
        self._key_codes_map[pygame.K_DOWN]      = (0xfd, 0x7f, False, False)  # Char code 0x1a (down arrow)

        self._key_codes_map[pygame.K_HOME]      = (0xfe, 0xfe, False, False)  # Char code 0x0c (home)
        self._key_codes_map[pygame.K_DELETE]    = (0xfe, 0xfd, False, False)  # Char code 0x1f (clear screen)
        self._key_codes_map[pygame.K_BACKQUOTE] = (0xfe, 0xfb, False, False)  # Char code 0x1b (escape / AR2)
        self._key_codes_map[pygame.K_F1]        = (0xfe, 0xf7, False, False)  # Char code 0x00 (F1)
        self._key_codes_map[pygame.K_F2]        = (0xfe, 0xef, False, False)  # Char code 0x01 (F2)
        self._key_codes_map[pygame.K_F3]        = (0xfe, 0xdf, False, False)  # Char code 0x02 (F3)
        self._key_codes_map[pygame.K_F4]        = (0xfe, 0xbf, False, False)  # Char code 0x03 (F4)
        self._key_codes_map[pygame.K_F5]        = (0xfe, 0x7f, False, False)  # Char code 0x04 (F5)


    def set_columns(self, value):
        self._port_a = value


    def read_rows(self):
        # Return key scan line if scan column matches previously set on Port A
        if self._pressed_key[0] == self._port_a: 
            self._pressed_ctrl = self._pressed_key[2]
            self._pressed_shift = self._pressed_key[3]
            return self._pressed_key[1]
        
        # Special case when Monitor scans for any keyboard press
        if self._port_a == 0x00:
            return self._pressed_key[1]

        # Return 'nothing is pressed' otherwise
        return 0xff


    def read_ctrl_key(self):
        return not self._pressed_key[2]     # Monitor expects an inverted value of the Ctrl key press


    def read_shift_key(self):
        return not self._pressed_key[3]     # Monitor expects an inverted value of the Shift key press


    def read_rus_key(self):
        return True


    def handle_key_event(self, event):
        if event.type == pygame.KEYDOWN:
            # if event.key in self._ctrl_codes_map and _ctrl_pressed():
            #     self._pressed_key = self._ctrl_codes_map[event.key]
            #     return
            
            if event.key in self._key_codes_map:
                self._pressed_key = self._key_codes_map[event.key]
                return
            
            ch = event.unicode.upper()
            if ch in self._key_map:
                self._pressed_key = self._key_map[ch]
                return
            
        if event.type == pygame.KEYUP:
            self._pressed_key = (0xff, 0xff, False, False)
