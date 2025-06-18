#ifndef STDDEF_H
#define STDDEF_H

typedef unsigned long size_t;
typedef signed long ptrdiff_t;

typedef unsigned char BYTE;
typedef unsigned short WORD;
typedef unsigned long DWORD;

#define NULL ((void*) 0)

#define offsetof(type, member) ((size_t) &(((type*) NULL)->member))

#endif // STDDEF_H