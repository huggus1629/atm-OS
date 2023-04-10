OUTPUT_FORMAT(binary)

SECTIONS
{
  .text.start (0x8000) : {
    build/obj/entry.o( .text )
  }

  .text : {
_TEXT_START_ = .;
    *(.text)
_TEXT_END_ = .;
  }

  .data : {
_DATA_START_ = .;
    *(.data)
_DATA_END_ = .;
  }
}
