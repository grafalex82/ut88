import pygame

def _ctrl_pressed():
    return (pygame.key.get_mods() & pygame.KMOD_CTRL) != 0


class Keyboard:
    """
    UT-88 Alpha-Numeric keyboard

    This class emulates 59-keys alpha-numeric keyboard, that is a part of the UT-88 Video Configuration.

    Keyboard features are:
    - 50 keys containing digits, letters, symbols, and space
    - 4 arrow keys + home key
    - Clear screen key
    - 3 Mod keys:
        - RUS toggle key, that changes some keys to represent Russian letters (Ё and Ъ letters did not fit
          the keyboard layout)
        - Symbol shift - works like 'Shift' key on modern computers, but only for symbols. The computer does
          not offer lower case (all letters are upper case), so shift key does nothing for letter keys.
        - Control symbol - works like a 'Ctrl' key on modern computer terminals, but only for letter and 
          a few other keys. Aim of this button is to allow entering symbols with codes in 0x00-0x1f range.

    With mod keys the keyboard allows entering pretty much every symbol in a range 0x00-0x7f. Among them:
    - 0x00-0x1f some pseudo-graphics symbols. Also in some modes symbols in this range represent control 
      symbols (e.g. cursor movement, clear screen) 
    - 0x20-0x5f - symbols, numbers, and Latin letters. These codes fully match standard ASCII table in this
      range.
    - 0x60-0x7f - this part is reserved for Russian letters (Ё and Ъ letters still do not fit the range).

    The keyboard layout is odd, compared to what is being used nowadays, but was quite popular on soviet
    computers back in 80x. The layout is based on the standard Russian layout, while Latin letters match
    the Russian ones, where possible.

    Here is the proposed layout. Letters and symbols at the bottom are entered without modificator keys, 
    symbols on the top require Shift or RUS modificators to be entered. Leyout for arrow, home, and clear
    screen keys is not described in the magazine.

    |  +  |  !  |  "  |  #  |  $  |  %  |  &  |  '  |  (  |  )  |     |  =  |     |
    |  ;  |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |  9  |  0  |  -  | RUS |
      |  Й  |  Ц  |  У  |  К  |  Е  |  Н  |  Г  |  Ш  |  Щ  |  З  |  Х  |  *  |     |
      |  J  |  C  |  U  |  K  |  E  |  N  |  G  |  [  |  ]  |  Z  |  H  |  :  |     |
    |     |  Ф  |  Ы  |  В  |  А  |  П  |  Р  |  О  |  Л  |  Д  |  Ж  |  Э  |     |
    | Ctrl|  F  |  Y  |  W  |  A  |  P  |  R  |  O  |  L  |  D  |  V  |  \\ |Enter|
      |     |  Я  |  Ч  |  С  |  М  |  И  |  Т  |  Ь  |  Б  |  Ю  |  <  |  ?  |     |
      |Shift|  Q  |  ^  |  S  |  M  |  I  |  T  |  X  |  B  |  @  |  .  |  /  |     |

      
    
    Electrical connection notes:

    All the buttons (except for modification keys) are organized in a 8x7 matrix, connected to the
    computer via i8255 controller. Monitor F selects one column at a time, by setting low level
    on a corresponding bit in Port A. Row state is captured via Port B (highest bit is ties to gnd, 
    other bits are pulled up with resistors, and will be read as 1 if no button is pressed in the
    selected column).

    3 modification keys set low level in one of 3 lowest bits on the Port C.

    The 8255 controller connected as an I/O device at address range 0x04-0x07, but address lines are
    inverted (so that configuration register is on port 0x04, Port C on port 0x05, Port B on port 0x06,
    and Port A on port 0x07)

    
    Emulation notes

    Taking into account the odd layout, it would be quite impossible to emulate the keyboard as is.
    Instead, this class will detect keyboard press events, and translate it to Port A/B/C values (which
    in turn represent pressed button and a modification key). This approach allows emulating keyboard
    presses using currently active keyboard layout on the host system (including English and Russian).

    In order to detect letters on both languages, as well as distinguish symbols that are collocated on 
    the same button (e.g. colon and semicolon), the event.unicode field is used. For arrow keys, as
    well as Ctrl-key combinations, the pygame.KEYDOWN event is used.

    When a button is pressed, the emulator class sets the _pressed_key member to a tripple, representing
    ports A, B, and C values. When the Monitor F firmware will scan keyboard matrix via port A, the
    emulator will return port B value according to selected column and button pressed.
    """
    def __init__(self):
        self._selected_columns = 0xff
        self._mod_keys = 0xff
        self._pressed_key = (0xff, 0xff, 0xff)

        self._key_map = {}
        self._key_map['0'] = (0xfe, 0xfe, 0xff)     # Char code 0x30
        self._key_map['1'] = (0xfe, 0xfd, 0xff)     # Char code 0x31
        self._key_map['2'] = (0xfe, 0xfb, 0xff)     # Char code 0x32
        self._key_map['3'] = (0xfe, 0xf7, 0xff)     # Char code 0x33
        self._key_map['4'] = (0xfe, 0xef, 0xff)     # Char code 0x34
        self._key_map['5'] = (0xfe, 0xdf, 0xff)     # Char code 0x35
        self._key_map['6'] = (0xfe, 0xbf, 0xff)     # Char code 0x36

        self._key_map['7'] = (0xfd, 0xfe, 0xff)     # Char code 0x37
        self._key_map['8'] = (0xfd, 0xfd, 0xff)     # Char code 0x38
        self._key_map['9'] = (0xfd, 0xfb, 0xff)     # Char code 0x39
        self._key_map[':'] = (0xfd, 0xf7, 0xff)     # Char code 0x3a
        self._key_map[';'] = (0xfd, 0xef, 0xff)     # Char code 0x3b
        self._key_map[','] = (0xfd, 0xdf, 0xff)     # Char code 0x2c
        self._key_map['-'] = (0xfd, 0xbf, 0xff)     # Char code 0x2d

        self._key_map['.'] = (0xfb, 0xfe, 0xff)     # Char code 0x2e
        self._key_map['/'] = (0xfb, 0xfd, 0xff)     # Char code 0x2f
        self._key_map['@'] = (0xfb, 0xfb, 0xff)     # Char code 0x40
        self._key_map['A'] = (0xfb, 0xf7, 0xff)     # Char code 0x41
        self._key_map['B'] = (0xfb, 0xef, 0xff)     # Char code 0x42
        self._key_map['C'] = (0xfb, 0xdf, 0xff)     # Char code 0x43
        self._key_map['D'] = (0xfb, 0xbf, 0xff)     # Char code 0x44

        self._key_map['E'] = (0xf7, 0xfe, 0xff)     # Char code 0x45
        self._key_map['F'] = (0xf7, 0xfd, 0xff)     # Char code 0x46
        self._key_map['G'] = (0xf7, 0xfb, 0xff)     # Char code 0x47
        self._key_map['H'] = (0xf7, 0xf7, 0xff)     # Char code 0x48
        self._key_map['I'] = (0xf7, 0xef, 0xff)     # Char code 0x49
        self._key_map['J'] = (0xf7, 0xdf, 0xff)     # Char code 0x4a
        self._key_map['K'] = (0xf7, 0xbf, 0xff)     # Char code 0x4b

        self._key_map['L'] = (0xef, 0xfe, 0xff)     # Char code 0x4c
        self._key_map['M'] = (0xef, 0xfd, 0xff)     # Char code 0x4d
        self._key_map['N'] = (0xef, 0xfb, 0xff)     # Char code 0x4e
        self._key_map['O'] = (0xef, 0xf7, 0xff)     # Char code 0x4f
        self._key_map['P'] = (0xef, 0xef, 0xff)     # Char code 0x50
        self._key_map['Q'] = (0xef, 0xdf, 0xff)     # Char code 0x51
        self._key_map['R'] = (0xef, 0xbf, 0xff)     # Char code 0x52

        self._key_map['S'] = (0xdf, 0xfe, 0xff)     # Char code 0x53
        self._key_map['T'] = (0xdf, 0xfd, 0xff)     # Char code 0x54
        self._key_map['U'] = (0xdf, 0xfb, 0xff)     # Char code 0x55
        self._key_map['V'] = (0xdf, 0xf7, 0xff)     # Char code 0x56
        self._key_map['W'] = (0xdf, 0xef, 0xff)     # Char code 0x57
        self._key_map['X'] = (0xdf, 0xdf, 0xff)     # Char code 0x58
        self._key_map['Y'] = (0xdf, 0xbf, 0xff)     # Char code 0x59

        self._key_map['Z'] = (0xbf, 0xfe, 0xff)     # Char code 0x5a
        self._key_map['['] = (0xbf, 0xfd, 0xff)     # Char code 0x5b
        self._key_map['\\'] = (0xbf, 0xfb, 0xff)    # Char code 0x5c
        self._key_map[']'] = (0xbf, 0xf7, 0xff)     # Char code 0x5d
        self._key_map['^'] = (0xbf, 0xef, 0xff)     # Char code 0x5e
        self._key_map['_'] = (0xbf, 0xdf, 0xff)     # Char code 0x5f
        self._key_map[' '] = (0xbf, 0xbf, 0xff)     # Char code 0x20

        # Some symbols are entered with a 'Shift' key (Special Symbol key, port C = 0xfb)
        #self._key_map[' '] = (0xfe, 0xfe, 0xfd)     # Char code 0x20   # Shift-0 generates a space
        self._key_map['!'] = (0xfe, 0xfd, 0xfb)     # Char code 0x21
        self._key_map['"'] = (0xfe, 0xfb, 0xfb)     # Char code 0x22
        self._key_map['#'] = (0xfe, 0xf7, 0xfb)     # Char code 0x23
        self._key_map['$'] = (0xfe, 0xef, 0xfb)     # Char code 0x24    # There is no $ in the font. Strange symbol is printed instead
        self._key_map['%'] = (0xfe, 0xdf, 0xfb)     # Char code 0x25
        self._key_map['&'] = (0xfe, 0xbf, 0xfb)     # Char code 0x26

        self._key_map['\''] = (0xfd, 0xfe, 0xfb)    # Char code 0x27
        self._key_map['('] = (0xfd, 0xfd, 0xfb)     # Char code 0x28
        self._key_map[')'] = (0xfd, 0xfb, 0xfb)     # Char code 0x29
        self._key_map['*'] = (0xfd, 0xf7, 0xfb)     # Char code 0x2a
        self._key_map['+'] = (0xfd, 0xef, 0xfb)     # Char code 0x2b
        self._key_map['<'] = (0xfd, 0xdf, 0xfb)     # Char code 0x3c
        self._key_map['='] = (0xfd, 0xbf, 0xfb)     # Char code 0x3d

        self._key_map['>'] = (0xfb, 0xfe, 0xfb)     # Char code 0x3e
        self._key_map['?'] = (0xfb, 0xfd, 0xfb)     # Char code 0x3f

        # Alpha keys (with scan codes >= 0x40) with RUS button pressed (portC = 0xfe)
        self._key_map['Ю'] = (0xfb, 0xfb, 0xfe)     # Char code 0x60
        self._key_map['А'] = (0xfb, 0xf7, 0xfe)     # Char code 0x61
        self._key_map['Б'] = (0xfb, 0xef, 0xfe)     # Char code 0x62
        self._key_map['Ц'] = (0xfb, 0xdf, 0xfe)     # Char code 0x63
        self._key_map['Д'] = (0xfb, 0xbf, 0xfe)     # Char code 0x64

        self._key_map['Е'] = (0xf7, 0xfe, 0xfe)     # Char code 0x65
        self._key_map['Ф'] = (0xf7, 0xfd, 0xfe)     # Char code 0x66
        self._key_map['Г'] = (0xf7, 0xfb, 0xfe)     # Char code 0x67
        self._key_map['Х'] = (0xf7, 0xf7, 0xfe)     # Char code 0x68
        self._key_map['И'] = (0xf7, 0xef, 0xfe)     # Char code 0x69
        self._key_map['Й'] = (0xf7, 0xdf, 0xfe)     # Char code 0x6a
        self._key_map['К'] = (0xf7, 0xbf, 0xfe)     # Char code 0x6b

        self._key_map['Л'] = (0xef, 0xfe, 0xfe)     # Char code 0x6c
        self._key_map['М'] = (0xef, 0xfd, 0xfe)     # Char code 0x6d
        self._key_map['Н'] = (0xef, 0xfb, 0xfe)     # Char code 0x6e
        self._key_map['О'] = (0xef, 0xf7, 0xfe)     # Char code 0x6f
        self._key_map['П'] = (0xef, 0xef, 0xfe)     # Char code 0x70
        self._key_map['Я'] = (0xef, 0xdf, 0xfe)     # Char code 0x71
        self._key_map['Р'] = (0xef, 0xbf, 0xfe)     # Char code 0x72

        self._key_map['С'] = (0xdf, 0xfe, 0xfe)     # Char code 0x73
        self._key_map['Т'] = (0xdf, 0xfd, 0xfe)     # Char code 0x74
        self._key_map['У'] = (0xdf, 0xfb, 0xfe)     # Char code 0x75
        self._key_map['Ж'] = (0xdf, 0xf7, 0xfe)     # Char code 0x76
        self._key_map['В'] = (0xdf, 0xef, 0xfe)     # Char code 0x77
        self._key_map['Ь'] = (0xdf, 0xdf, 0xfe)     # Char code 0x78
        self._key_map['Ы'] = (0xdf, 0xbf, 0xfe)     # Char code 0x79

        self._key_map['З'] = (0xbf, 0xfe, 0xfe)     # Char code 0x7a
        self._key_map['Ш'] = (0xbf, 0xfd, 0xfe)     # Char code 0x7b
        self._key_map['Э'] = (0xbf, 0xfb, 0xfe)     # Char code 0x7c
        self._key_map['Щ'] = (0xbf, 0xf7, 0xfe)     # Char code 0x7d
        self._key_map['Ч'] = (0xbf, 0xef, 0xfe)     # Char code 0x7e

        self._key_codes_map = {}
        self._key_codes_map[pygame.K_RIGHT]     = (0x7f, 0xfe, 0xff)    # Char code 0x18
        self._key_codes_map[pygame.K_LEFT]      = (0x7f, 0xfd, 0xff)    # Char code 0x08
        self._key_codes_map[pygame.K_UP]        = (0x7f, 0xfb, 0xff)    # Char code 0x19
        self._key_codes_map[pygame.K_DOWN]      = (0x7f, 0xf7, 0xff)    # Char code 0x1a
        self._key_codes_map[pygame.K_RETURN]    = (0x7f, 0xef, 0xff)    # Char code 0x0d
        self._key_codes_map[pygame.K_DELETE]    = (0x7f, 0xdf, 0xff)    # Char code 0x1f (Clear screen)
        self._key_codes_map[pygame.K_HOME]      = (0x7f, 0xbf, 0xff)    # Char code 0x0c

        self._ctrl_codes_map = {}   # Ctrl mod key is pressed
        self._ctrl_codes_map[pygame.K_a]        = (0xfb, 0xf7, 0xfd)    # Char code 0x01
        self._ctrl_codes_map[pygame.K_b]        = (0xfb, 0xef, 0xfd)    # Char code 0x02
        self._ctrl_codes_map[pygame.K_c]        = (0xfb, 0xdf, 0xfd)    # Char code 0x03
        self._ctrl_codes_map[pygame.K_d]        = (0xfb, 0xbf, 0xfd)    # Char code 0x04

        self._ctrl_codes_map[pygame.K_e]        = (0xf7, 0xfe, 0xfd)    # Char code 0x05
        self._ctrl_codes_map[pygame.K_f]        = (0xf7, 0xfd, 0xfd)    # Char code 0x06
        self._ctrl_codes_map[pygame.K_g]        = (0xf7, 0xfb, 0xfd)    # Char code 0x07
        self._ctrl_codes_map[pygame.K_h]        = (0xf7, 0xf7, 0xfd)    # Char code 0x08
        self._ctrl_codes_map[pygame.K_i]        = (0xf7, 0xef, 0xfd)    # Char code 0x09
        self._ctrl_codes_map[pygame.K_j]        = (0xf7, 0xdf, 0xfd)    # Char code 0x0a
        self._ctrl_codes_map[pygame.K_k]        = (0xf7, 0xbf, 0xfd)    # Char code 0x0b

        self._ctrl_codes_map[pygame.K_l]        = (0xef, 0xfe, 0xfd)    # Char code 0x0c
        self._ctrl_codes_map[pygame.K_m]        = (0xef, 0xfd, 0xfd)    # Char code 0x0d
        self._ctrl_codes_map[pygame.K_n]        = (0xef, 0xfb, 0xfd)    # Char code 0x0e
        self._ctrl_codes_map[pygame.K_o]        = (0xef, 0xf7, 0xfd)    # Char code 0x0f
        self._ctrl_codes_map[pygame.K_p]        = (0xef, 0xef, 0xfd)    # Char code 0x10
        self._ctrl_codes_map[pygame.K_q]        = (0xef, 0xdf, 0xfd)    # Char code 0x11
        self._ctrl_codes_map[pygame.K_r]        = (0xef, 0xbf, 0xfd)    # Char code 0x12

        self._ctrl_codes_map[pygame.K_s]        = (0xdf, 0xfe, 0xfd)    # Char code 0x13
        self._ctrl_codes_map[pygame.K_t]        = (0xdf, 0xfd, 0xfd)    # Char code 0x14
        self._ctrl_codes_map[pygame.K_u]        = (0xdf, 0xfb, 0xfd)    # Char code 0x15
        self._ctrl_codes_map[pygame.K_v]        = (0xdf, 0xf7, 0xfd)    # Char code 0x16
        self._ctrl_codes_map[pygame.K_w]        = (0xdf, 0xef, 0xfd)    # Char code 0x17
        self._ctrl_codes_map[pygame.K_x]        = (0xdf, 0xdf, 0xfd)    # Char code 0x18
        self._ctrl_codes_map[pygame.K_y]        = (0xdf, 0xbf, 0xfd)    # Char code 0x19

        self._ctrl_codes_map[pygame.K_z]        = (0xbf, 0xfe, 0xfd)    # Char code 0x1a
        self._ctrl_codes_map[pygame.K_COMMA]    = (0xbf, 0xfd, 0xfd)    # Char code 0x1b
        self._ctrl_codes_map[pygame.K_PERIOD]   = (0xbf, 0xfb, 0xfd)    # Char code 0x1c
        self._ctrl_codes_map[pygame.K_SEMICOLON]= (0xbf, 0xf7, 0xfd)    # Char code 0x1d
        self._ctrl_codes_map[pygame.K_QUOTE]    = (0xbf, 0xef, 0xfd)    # Char code 0x1e
        self._ctrl_codes_map[pygame.K_SLASH]    = (0xbf, 0xdf, 0xfd)    # Char code 0x1f

        # Additional char codes with Ctrl key
        self._ctrl_codes_map[pygame.K_SPACE]    = (0xbf, 0xbf, 0xfd)    # Char code 0x20, but with Ctrl
        self._ctrl_codes_map[pygame.K_RIGHT]    = (0x7f, 0xfe, 0xfd)    # Char code 0x18, but with Ctrl
        self._ctrl_codes_map[pygame.K_LEFT]     = (0x7f, 0xfd, 0xfd)    # Char code 0x08, but with Ctrl
        self._ctrl_codes_map[pygame.K_UP]       = (0x7f, 0xfb, 0xfd)    # Char code 0x19, but with Ctrl
        self._ctrl_codes_map[pygame.K_DOWN]     = (0x7f, 0xf7, 0xfd)    # Char code 0x1a, but with Ctrl
        self._ctrl_codes_map[pygame.K_RETURN]   = (0x7f, 0xef, 0xfd)    # Char code 0x0d, but with Ctrl
        self._ctrl_codes_map[pygame.K_DELETE]   = (0x7f, 0xdf, 0xfd)    # Char code 0x1f, but with Ctrl
        self._ctrl_codes_map[pygame.K_HOME]     = (0x7f, 0xbf, 0xfd)    # Char code 0x0c, but with Ctrl


    def write_columns(self, value):
        self._selected_columns = value         


    def read_rows(self):
        # Return key scan line if scan column matches previously set on Port A
        if self._pressed_key[0] == self._selected_columns: 
            self._mod_keys = self._pressed_key[2]
            return self._pressed_key[1] & 0x7f  # MSB is unused, but for some reason checked in the code
        
        # Special case when Monitor F scans for any keyboard press
        if self._selected_columns == 0x00:
            return self._pressed_key[1] & 0x7f  # MSB is unused, but for some reason checked in the code

        return 0x7f


    def read_mod_keys(self):
        return self._mod_keys


    def handle_key_event(self, event):
        if event.type == pygame.KEYDOWN:
            if event.key in self._ctrl_codes_map and _ctrl_pressed():
                self._pressed_key = self._ctrl_codes_map[event.key]
                return
            
            if event.key in self._key_codes_map:
                self._pressed_key = self._key_codes_map[event.key]
                return
            
            ch = event.unicode.upper()
            if ch in self._key_map:
                self._pressed_key = self._key_map[ch]
                return

            
        if event.type == pygame.KEYUP:
            self._pressed_key = (0xff, 0xff, 0xff)


    def emulate_key_press(self, ch):
        if ch == None:
            self._pressed_key = (0xff, 0xff, 0xff)

        if ch in self._key_map:
            self._pressed_key = self._key_map[ch]


    def emulate_special_key_press(self, key, ctrl=False):
        if key == None:
            self._pressed_key = (0xff, 0xff, 0xff)

        if ctrl and key in self._ctrl_codes_map:
            self._pressed_key = self._ctrl_codes_map[key]
        elif key in self._key_codes_map:
            self._pressed_key = self._key_codes_map[key]


    def emulate_ctrl_key_press(self, ch):
        # expect either a letter ('C' meaning Ctrl-C) or digit code
        if isinstance(ch, str):
            ch = ch.upper()
            ch = ord(ch.upper())

        if ch >= 0x41 and ch <= 0x5f:
            self._pressed_key = self._ctrl_codes_map[pygame.K_a + ch - 0x41]
        elif ch in self._ctrl_codes_map:
            self._pressed_key = self._ctrl_codes_map[ch]
        else:
            self._pressed_key = (0xff, 0xff, 0xff)
