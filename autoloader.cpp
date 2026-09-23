// written by Paul Baxter
/**
 * @file autoloader.cpp
 * @author Paul Baxter
 * @brief Implementation of the Commodore 64 autostart bootstrap loader generator.
 */

#include "autoloader.h"
#include <cctype>
#include <stdexcept>

/**
 * @brief Generates and patches the Commodore 64 autostart bootstrap loader binary.
 * 
 * This function constructs a raw byte array representing a 6502 machine code routine 
 * designed to run at address $0102. It suppresses interrupts, interacts with C64 KERNAL 
 * routines (`RESTOR`, `STROUT`, `SETNAM`, `SETLFS`, `LOAD`) to load the specified 
 * program from disk silently, restores system vectors, and jumps directly to the 
 * target program entry address.
 * 
 * @param filename The target PRG filename to load from disk.
 * @param addr     The target execution/load address of the main program.
 * @return std::vector<uint8_t> The complete, ready-to-write LOADER.PRG binary array.
 */
std::vector<uint8_t> CreateAutoLoader(const std::string& filename, uint16_t addr) {
    std::vector<uint8_t> loader_code = {
        // ----------------------------------------------------
        // Autostart Bootstrap Loader (* = $0102)
        // ----------------------------------------------------
        0x02, 0x01,            // [0, 1] preset load address
        0xA9, 0x7F,            // [2, 3] lda #$7F (suppress irq & nmi)
        0x8D, 0x0D, 0xDC,      // [4, 5, 6] sta CIAICR
        0x8D, 0x0E, 0xDC,      // [7, 8, 9] sta CIACRA
        0x20, 0x8A, 0xFF,      // [10, 11, 12] jsr RESTOR

        0xA9, 0x36,            // [13, 14] lda #36 (<MSG)
        0xA0, 0x01,            // [15, 16] ldy #01 (>MSG)
        0x20, 0x1E, 0xAB,      // [17, 18, 19] jsr STROUT

        0xA9, 0x00,            // [20, 21] lda #NAMELEN ([21] is the length byte to update)
        0xA2, 0x37,            // [22, 23] ldx #37 (<NAME)
        0xA0, 0x01,            // [24, 25] ldy #01 (>NAME)
        0x20, 0xBD, 0xFF,      // [26, 27, 28] jsr SETNAM

        0xA5, 0xBA,            // [29, 30] lda FA (device number)
        0xAA,                  // [31] tax
        0xA8,                  // [32] tay
        0x20, 0xBA, 0xFF,      // [33, 34, 35] jsr SETLFS

        0xA9, 0x00,            // [36, 37] lda #00 (load mode)
        0x85, 0x9D,            // [38, 39] sta MSGFLG (suppress 'searching for' msg)
        0x20, 0xD5, 0xFF,      // [40, 41, 42] jsr LOAD

        0xA9, 0x81,            // [43, 44] lda #$81 (restore irq & nmi)         
        0x8D, 0x0D, 0xDC,      // [45, 46, 47] sta $DC0D
        0x8D, 0x0E, 0xDC,      // [48, 49, 50] sta $DC0E

        0x4C, 0x00, 0x00,      // [51, 52, 53] jmp $C000 (start loaded program)

        // ----------------------------------------------------
        // Data & Strings (MSG and NAME)
        // ----------------------------------------------------
        0x20,                  // [54] MSG: .byte " "
        0x01, 0x01, 0x01,      // [55, 56, 57] NAME START HERE
        0x01,                  // [58]
        
        // ----------------------------------------------------
        // Fill Padding (196 bytes of $01)
        // ----------------------------------------------------
        0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
        0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
        0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
        0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
        0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
        0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
        0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
        0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
        0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
        0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
        0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
        0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
        0x01, 0x01, 0x01, 0x01, 0x01
    };

    // 1. Update the name length byte (at index 21)
    loader_code[21] = static_cast<uint8_t>(filename.length());

    // 2. Set the load address (jumps to target program entry at bytes 52-53)
    auto lo = static_cast<uint8_t>(addr & 0xFF); 
    auto hi = static_cast<uint8_t>((addr >> 8) & 0xFF); 
    loader_code[52] = lo;
    loader_code[53] = hi;

    // 3. Overwrite the name bytes starting at index 55
    constexpr size_t name_offset = 55;
    for (size_t i = 0; i < filename.length(); ++i) {
        loader_code[name_offset + i] = static_cast<uint8_t>(std::toupper(filename[i]));
    }

    // 3. Add the null terminator right after the filename
    loader_code[name_offset + filename.length()] = 0x00;
    
    return loader_code;
}
