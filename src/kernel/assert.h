#ifndef ASSERT_H
#define ASSERT_H

static inline void __assert_failure(void)
{
    asm
    (
        "cli;"
        "hlt;"
    );
}

#define assert(expr) ((expr) ? (void) 0 : __assert_failure())

#endif