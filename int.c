#include "bootpack.h"

#define PORT_KEYDAT 0x0060

struct KEYBUF keybuf;

void init_pic(void) {
    io_out8(PIC0_IMR, 0xff);
    io_out8(PIC1_IMR, 0xff);

    io_out8(PIC0_ICW1, 0x11);
    io_out8(PIC0_ICW2, 0x20);
    io_out8(PIC0_ICW3, 1 << 2);
    io_out8(PIC0_ICW4, 0x01);

    io_out8(PIC1_ICW1, 0x11);
    io_out8(PIC1_ICW2, 0x28);
    io_out8(PIC1_ICW3, 2);
    io_out8(PIC1_ICW4, 0x01);

    io_out8(PIC0_IMR, 0xfb);
    io_out8(PIC1_IMR, 0xff);

    return;
}

void inthandler21(int *esp) {
    unsigned char data;
    io_out8(PIC0_OCW2, 0x61);
    data = io_in8(PORT_KEYDAT);
    if (keybuf.len < 32) {
        keybuf.data[keybuf.next_w] = data;
        keybuf.len++;
        keybuf.next_w++;
        if (keybuf.next_w == 32) {
            keybuf.next_w = 0;
        }
    }
    return;
}
