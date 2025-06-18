section     .vbe
vbe_info_struct:
    .signature: db      "VBE2"
    .vbe_data:  times   512-4   db  0