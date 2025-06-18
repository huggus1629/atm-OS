OUTPUT_FORMAT(binary)

MEMORY
{
    STAGE1  (rwx)   :   ORIGIN = 0x7c00, LENGTH = 0x200
    VBE     (rw)    :   ORIGIN = 0x7a00, LENGTH = 0x200
    STAGE2  (rwx)   :   ORIGIN = 0x7e00, LENGTH = 0x200 
}

SECTIONS
{
    .stage1 : AT(0x0) {
        *(.stage1)
    } > STAGE1

    .vbe : AT(0x200) {
        *(.vbe)
    } > VBE

    .stage2 : AT(0x400) {
        *(.stage2)
    } > STAGE2
}