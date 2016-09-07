
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	//movl	%eax, %cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100025:	b8 2c 00 10 f0       	mov    $0xf010002c,%eax
	jmp	*%eax
f010002a:	ff e0                	jmp    *%eax

f010002c <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002c:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100031:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100036:	e8 56 00 00 00       	call   f0100091 <i386_init>

f010003b <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003b:	eb fe                	jmp    f010003b <spin>

f010003d <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f010003d:	55                   	push   %ebp
f010003e:	89 e5                	mov    %esp,%ebp
f0100040:	53                   	push   %ebx
f0100041:	83 ec 0c             	sub    $0xc,%esp
f0100044:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f0100047:	53                   	push   %ebx
f0100048:	68 80 18 10 f0       	push   $0xf0101880
f010004d:	e8 95 08 00 00       	call   f01008e7 <cprintf>
	if (x > 0)
f0100052:	83 c4 10             	add    $0x10,%esp
f0100055:	85 db                	test   %ebx,%ebx
f0100057:	7e 11                	jle    f010006a <test_backtrace+0x2d>
		test_backtrace(x-1);
f0100059:	83 ec 0c             	sub    $0xc,%esp
f010005c:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010005f:	50                   	push   %eax
f0100060:	e8 d8 ff ff ff       	call   f010003d <test_backtrace>
f0100065:	83 c4 10             	add    $0x10,%esp
f0100068:	eb 11                	jmp    f010007b <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006a:	83 ec 04             	sub    $0x4,%esp
f010006d:	6a 00                	push   $0x0
f010006f:	6a 00                	push   $0x0
f0100071:	6a 00                	push   $0x0
f0100073:	e8 e5 06 00 00       	call   f010075d <mon_backtrace>
f0100078:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007b:	83 ec 08             	sub    $0x8,%esp
f010007e:	53                   	push   %ebx
f010007f:	68 9c 18 10 f0       	push   $0xf010189c
f0100084:	e8 5e 08 00 00       	call   f01008e7 <cprintf>
}
f0100089:	83 c4 10             	add    $0x10,%esp
f010008c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010008f:	c9                   	leave  
f0100090:	c3                   	ret    

f0100091 <i386_init>:

void
i386_init(void)
{
f0100091:	55                   	push   %ebp
f0100092:	89 e5                	mov    %esp,%ebp
f0100094:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100097:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f010009c:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a1:	50                   	push   %eax
f01000a2:	6a 00                	push   $0x0
f01000a4:	68 00 23 11 f0       	push   $0xf0112300
f01000a9:	e8 22 13 00 00       	call   f01013d0 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000ae:	e8 8f 04 00 00       	call   f0100542 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b3:	83 c4 08             	add    $0x8,%esp
f01000b6:	68 ac 1a 00 00       	push   $0x1aac
f01000bb:	68 b7 18 10 f0       	push   $0xf01018b7
f01000c0:	e8 22 08 00 00       	call   f01008e7 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c5:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cc:	e8 6c ff ff ff       	call   f010003d <test_backtrace>
f01000d1:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d4:	83 ec 0c             	sub    $0xc,%esp
f01000d7:	6a 00                	push   $0x0
f01000d9:	e8 89 06 00 00       	call   f0100767 <monitor>
f01000de:	83 c4 10             	add    $0x10,%esp
f01000e1:	eb f1                	jmp    f01000d4 <i386_init+0x43>

f01000e3 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e3:	55                   	push   %ebp
f01000e4:	89 e5                	mov    %esp,%ebp
f01000e6:	56                   	push   %esi
f01000e7:	53                   	push   %ebx
f01000e8:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000eb:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f01000f2:	75 37                	jne    f010012b <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f4:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000fa:	fa                   	cli    
f01000fb:	fc                   	cld    

	va_start(ap, fmt);
f01000fc:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000ff:	83 ec 04             	sub    $0x4,%esp
f0100102:	ff 75 0c             	pushl  0xc(%ebp)
f0100105:	ff 75 08             	pushl  0x8(%ebp)
f0100108:	68 d2 18 10 f0       	push   $0xf01018d2
f010010d:	e8 d5 07 00 00       	call   f01008e7 <cprintf>
	vcprintf(fmt, ap);
f0100112:	83 c4 08             	add    $0x8,%esp
f0100115:	53                   	push   %ebx
f0100116:	56                   	push   %esi
f0100117:	e8 a5 07 00 00       	call   f01008c1 <vcprintf>
	cprintf("\n");
f010011c:	c7 04 24 0e 19 10 f0 	movl   $0xf010190e,(%esp)
f0100123:	e8 bf 07 00 00       	call   f01008e7 <cprintf>
	va_end(ap);
f0100128:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012b:	83 ec 0c             	sub    $0xc,%esp
f010012e:	6a 00                	push   $0x0
f0100130:	e8 32 06 00 00       	call   f0100767 <monitor>
f0100135:	83 c4 10             	add    $0x10,%esp
f0100138:	eb f1                	jmp    f010012b <_panic+0x48>

f010013a <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013a:	55                   	push   %ebp
f010013b:	89 e5                	mov    %esp,%ebp
f010013d:	53                   	push   %ebx
f010013e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100141:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100144:	ff 75 0c             	pushl  0xc(%ebp)
f0100147:	ff 75 08             	pushl  0x8(%ebp)
f010014a:	68 ea 18 10 f0       	push   $0xf01018ea
f010014f:	e8 93 07 00 00       	call   f01008e7 <cprintf>
	vcprintf(fmt, ap);
f0100154:	83 c4 08             	add    $0x8,%esp
f0100157:	53                   	push   %ebx
f0100158:	ff 75 10             	pushl  0x10(%ebp)
f010015b:	e8 61 07 00 00       	call   f01008c1 <vcprintf>
	cprintf("\n");
f0100160:	c7 04 24 0e 19 10 f0 	movl   $0xf010190e,(%esp)
f0100167:	e8 7b 07 00 00       	call   f01008e7 <cprintf>
	va_end(ap);
}
f010016c:	83 c4 10             	add    $0x10,%esp
f010016f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100172:	c9                   	leave  
f0100173:	c3                   	ret    

f0100174 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100174:	55                   	push   %ebp
f0100175:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100177:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017c:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010017d:	a8 01                	test   $0x1,%al
f010017f:	74 0b                	je     f010018c <serial_proc_data+0x18>
f0100181:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100186:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100187:	0f b6 c0             	movzbl %al,%eax
f010018a:	eb 05                	jmp    f0100191 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100193:	55                   	push   %ebp
f0100194:	89 e5                	mov    %esp,%ebp
f0100196:	53                   	push   %ebx
f0100197:	83 ec 04             	sub    $0x4,%esp
f010019a:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019c:	eb 2b                	jmp    f01001c9 <cons_intr+0x36>
		if (c == 0)
f010019e:	85 c0                	test   %eax,%eax
f01001a0:	74 27                	je     f01001c9 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a2:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001a8:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ab:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001b1:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001b7:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001bd:	75 0a                	jne    f01001c9 <cons_intr+0x36>
			cons.wpos = 0;
f01001bf:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001c6:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001c9:	ff d3                	call   *%ebx
f01001cb:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001ce:	75 ce                	jne    f010019e <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d0:	83 c4 04             	add    $0x4,%esp
f01001d3:	5b                   	pop    %ebx
f01001d4:	5d                   	pop    %ebp
f01001d5:	c3                   	ret    

f01001d6 <kbd_proc_data>:
f01001d6:	ba 64 00 00 00       	mov    $0x64,%edx
f01001db:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001dc:	a8 01                	test   $0x1,%al
f01001de:	0f 84 f0 00 00 00    	je     f01002d4 <kbd_proc_data+0xfe>
f01001e4:	ba 60 00 00 00       	mov    $0x60,%edx
f01001e9:	ec                   	in     (%dx),%al
f01001ea:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001ec:	3c e0                	cmp    $0xe0,%al
f01001ee:	75 0d                	jne    f01001fd <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01001f0:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f01001f7:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001fc:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001fd:	55                   	push   %ebp
f01001fe:	89 e5                	mov    %esp,%ebp
f0100200:	53                   	push   %ebx
f0100201:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100204:	84 c0                	test   %al,%al
f0100206:	79 36                	jns    f010023e <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100208:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010020e:	89 cb                	mov    %ecx,%ebx
f0100210:	83 e3 40             	and    $0x40,%ebx
f0100213:	83 e0 7f             	and    $0x7f,%eax
f0100216:	85 db                	test   %ebx,%ebx
f0100218:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010021b:	0f b6 d2             	movzbl %dl,%edx
f010021e:	0f b6 82 60 1a 10 f0 	movzbl -0xfefe5a0(%edx),%eax
f0100225:	83 c8 40             	or     $0x40,%eax
f0100228:	0f b6 c0             	movzbl %al,%eax
f010022b:	f7 d0                	not    %eax
f010022d:	21 c8                	and    %ecx,%eax
f010022f:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f0100234:	b8 00 00 00 00       	mov    $0x0,%eax
f0100239:	e9 9e 00 00 00       	jmp    f01002dc <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f010023e:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100244:	f6 c1 40             	test   $0x40,%cl
f0100247:	74 0e                	je     f0100257 <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100249:	83 c8 80             	or     $0xffffff80,%eax
f010024c:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010024e:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100251:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f0100257:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010025a:	0f b6 82 60 1a 10 f0 	movzbl -0xfefe5a0(%edx),%eax
f0100261:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f0100267:	0f b6 8a 60 19 10 f0 	movzbl -0xfefe6a0(%edx),%ecx
f010026e:	31 c8                	xor    %ecx,%eax
f0100270:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100275:	89 c1                	mov    %eax,%ecx
f0100277:	83 e1 03             	and    $0x3,%ecx
f010027a:	8b 0c 8d 40 19 10 f0 	mov    -0xfefe6c0(,%ecx,4),%ecx
f0100281:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100285:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100288:	a8 08                	test   $0x8,%al
f010028a:	74 1b                	je     f01002a7 <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f010028c:	89 da                	mov    %ebx,%edx
f010028e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100291:	83 f9 19             	cmp    $0x19,%ecx
f0100294:	77 05                	ja     f010029b <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100296:	83 eb 20             	sub    $0x20,%ebx
f0100299:	eb 0c                	jmp    f01002a7 <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f010029b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010029e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002a1:	83 fa 19             	cmp    $0x19,%edx
f01002a4:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002a7:	f7 d0                	not    %eax
f01002a9:	a8 06                	test   $0x6,%al
f01002ab:	75 2d                	jne    f01002da <kbd_proc_data+0x104>
f01002ad:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002b3:	75 25                	jne    f01002da <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01002b5:	83 ec 0c             	sub    $0xc,%esp
f01002b8:	68 04 19 10 f0       	push   $0xf0101904
f01002bd:	e8 25 06 00 00       	call   f01008e7 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c2:	ba 92 00 00 00       	mov    $0x92,%edx
f01002c7:	b8 03 00 00 00       	mov    $0x3,%eax
f01002cc:	ee                   	out    %al,(%dx)
f01002cd:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d0:	89 d8                	mov    %ebx,%eax
f01002d2:	eb 08                	jmp    f01002dc <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002d9:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002da:	89 d8                	mov    %ebx,%eax
}
f01002dc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002df:	c9                   	leave  
f01002e0:	c3                   	ret    

f01002e1 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002e1:	55                   	push   %ebp
f01002e2:	89 e5                	mov    %esp,%ebp
f01002e4:	57                   	push   %edi
f01002e5:	56                   	push   %esi
f01002e6:	53                   	push   %ebx
f01002e7:	83 ec 1c             	sub    $0x1c,%esp
f01002ea:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ec:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f1:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002f6:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fb:	eb 09                	jmp    f0100306 <cons_putc+0x25>
f01002fd:	89 ca                	mov    %ecx,%edx
f01002ff:	ec                   	in     (%dx),%al
f0100300:	ec                   	in     (%dx),%al
f0100301:	ec                   	in     (%dx),%al
f0100302:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100303:	83 c3 01             	add    $0x1,%ebx
f0100306:	89 f2                	mov    %esi,%edx
f0100308:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100309:	a8 20                	test   $0x20,%al
f010030b:	75 08                	jne    f0100315 <cons_putc+0x34>
f010030d:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100313:	7e e8                	jle    f01002fd <cons_putc+0x1c>
f0100315:	89 f8                	mov    %edi,%eax
f0100317:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010031a:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010031f:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100320:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100325:	be 79 03 00 00       	mov    $0x379,%esi
f010032a:	b9 84 00 00 00       	mov    $0x84,%ecx
f010032f:	eb 09                	jmp    f010033a <cons_putc+0x59>
f0100331:	89 ca                	mov    %ecx,%edx
f0100333:	ec                   	in     (%dx),%al
f0100334:	ec                   	in     (%dx),%al
f0100335:	ec                   	in     (%dx),%al
f0100336:	ec                   	in     (%dx),%al
f0100337:	83 c3 01             	add    $0x1,%ebx
f010033a:	89 f2                	mov    %esi,%edx
f010033c:	ec                   	in     (%dx),%al
f010033d:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100343:	7f 04                	jg     f0100349 <cons_putc+0x68>
f0100345:	84 c0                	test   %al,%al
f0100347:	79 e8                	jns    f0100331 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100349:	ba 78 03 00 00       	mov    $0x378,%edx
f010034e:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100352:	ee                   	out    %al,(%dx)
f0100353:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100358:	b8 0d 00 00 00       	mov    $0xd,%eax
f010035d:	ee                   	out    %al,(%dx)
f010035e:	b8 08 00 00 00       	mov    $0x8,%eax
f0100363:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100364:	89 fa                	mov    %edi,%edx
f0100366:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010036c:	89 f8                	mov    %edi,%eax
f010036e:	80 cc 07             	or     $0x7,%ah
f0100371:	85 d2                	test   %edx,%edx
f0100373:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100376:	89 f8                	mov    %edi,%eax
f0100378:	0f b6 c0             	movzbl %al,%eax
f010037b:	83 f8 09             	cmp    $0x9,%eax
f010037e:	74 74                	je     f01003f4 <cons_putc+0x113>
f0100380:	83 f8 09             	cmp    $0x9,%eax
f0100383:	7f 0a                	jg     f010038f <cons_putc+0xae>
f0100385:	83 f8 08             	cmp    $0x8,%eax
f0100388:	74 14                	je     f010039e <cons_putc+0xbd>
f010038a:	e9 99 00 00 00       	jmp    f0100428 <cons_putc+0x147>
f010038f:	83 f8 0a             	cmp    $0xa,%eax
f0100392:	74 3a                	je     f01003ce <cons_putc+0xed>
f0100394:	83 f8 0d             	cmp    $0xd,%eax
f0100397:	74 3d                	je     f01003d6 <cons_putc+0xf5>
f0100399:	e9 8a 00 00 00       	jmp    f0100428 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f010039e:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003a5:	66 85 c0             	test   %ax,%ax
f01003a8:	0f 84 e6 00 00 00    	je     f0100494 <cons_putc+0x1b3>
			crt_pos--;
f01003ae:	83 e8 01             	sub    $0x1,%eax
f01003b1:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003b7:	0f b7 c0             	movzwl %ax,%eax
f01003ba:	66 81 e7 00 ff       	and    $0xff00,%di
f01003bf:	83 cf 20             	or     $0x20,%edi
f01003c2:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003c8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003cc:	eb 78                	jmp    f0100446 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003ce:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003d5:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003d6:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003dd:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e3:	c1 e8 16             	shr    $0x16,%eax
f01003e6:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003e9:	c1 e0 04             	shl    $0x4,%eax
f01003ec:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f01003f2:	eb 52                	jmp    f0100446 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003f4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f9:	e8 e3 fe ff ff       	call   f01002e1 <cons_putc>
		cons_putc(' ');
f01003fe:	b8 20 00 00 00       	mov    $0x20,%eax
f0100403:	e8 d9 fe ff ff       	call   f01002e1 <cons_putc>
		cons_putc(' ');
f0100408:	b8 20 00 00 00       	mov    $0x20,%eax
f010040d:	e8 cf fe ff ff       	call   f01002e1 <cons_putc>
		cons_putc(' ');
f0100412:	b8 20 00 00 00       	mov    $0x20,%eax
f0100417:	e8 c5 fe ff ff       	call   f01002e1 <cons_putc>
		cons_putc(' ');
f010041c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100421:	e8 bb fe ff ff       	call   f01002e1 <cons_putc>
f0100426:	eb 1e                	jmp    f0100446 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100428:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010042f:	8d 50 01             	lea    0x1(%eax),%edx
f0100432:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f0100439:	0f b7 c0             	movzwl %ax,%eax
f010043c:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100442:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100446:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010044d:	cf 07 
f010044f:	76 43                	jbe    f0100494 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100451:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100456:	83 ec 04             	sub    $0x4,%esp
f0100459:	68 00 0f 00 00       	push   $0xf00
f010045e:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100464:	52                   	push   %edx
f0100465:	50                   	push   %eax
f0100466:	e8 b2 0f 00 00       	call   f010141d <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010046b:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100471:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100477:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010047d:	83 c4 10             	add    $0x10,%esp
f0100480:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100485:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100488:	39 d0                	cmp    %edx,%eax
f010048a:	75 f4                	jne    f0100480 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010048c:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f0100493:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100494:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f010049a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010049f:	89 ca                	mov    %ecx,%edx
f01004a1:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004a2:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004a9:	8d 71 01             	lea    0x1(%ecx),%esi
f01004ac:	89 d8                	mov    %ebx,%eax
f01004ae:	66 c1 e8 08          	shr    $0x8,%ax
f01004b2:	89 f2                	mov    %esi,%edx
f01004b4:	ee                   	out    %al,(%dx)
f01004b5:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004ba:	89 ca                	mov    %ecx,%edx
f01004bc:	ee                   	out    %al,(%dx)
f01004bd:	89 d8                	mov    %ebx,%eax
f01004bf:	89 f2                	mov    %esi,%edx
f01004c1:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004c2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004c5:	5b                   	pop    %ebx
f01004c6:	5e                   	pop    %esi
f01004c7:	5f                   	pop    %edi
f01004c8:	5d                   	pop    %ebp
f01004c9:	c3                   	ret    

f01004ca <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004ca:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004d1:	74 11                	je     f01004e4 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004d3:	55                   	push   %ebp
f01004d4:	89 e5                	mov    %esp,%ebp
f01004d6:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004d9:	b8 74 01 10 f0       	mov    $0xf0100174,%eax
f01004de:	e8 b0 fc ff ff       	call   f0100193 <cons_intr>
}
f01004e3:	c9                   	leave  
f01004e4:	f3 c3                	repz ret 

f01004e6 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004e6:	55                   	push   %ebp
f01004e7:	89 e5                	mov    %esp,%ebp
f01004e9:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ec:	b8 d6 01 10 f0       	mov    $0xf01001d6,%eax
f01004f1:	e8 9d fc ff ff       	call   f0100193 <cons_intr>
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004fe:	e8 c7 ff ff ff       	call   f01004ca <serial_intr>
	kbd_intr();
f0100503:	e8 de ff ff ff       	call   f01004e6 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100508:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010050d:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100513:	74 26                	je     f010053b <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100515:	8d 50 01             	lea    0x1(%eax),%edx
f0100518:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010051e:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100525:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100527:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010052d:	75 11                	jne    f0100540 <cons_getc+0x48>
			cons.rpos = 0;
f010052f:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100536:	00 00 00 
f0100539:	eb 05                	jmp    f0100540 <cons_getc+0x48>
		return c;
	}
	return 0;
f010053b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100540:	c9                   	leave  
f0100541:	c3                   	ret    

f0100542 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100542:	55                   	push   %ebp
f0100543:	89 e5                	mov    %esp,%ebp
f0100545:	57                   	push   %edi
f0100546:	56                   	push   %esi
f0100547:	53                   	push   %ebx
f0100548:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010054b:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100552:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100559:	5a a5 
	if (*cp != 0xA55A) {
f010055b:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100562:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100566:	74 11                	je     f0100579 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100568:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f010056f:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100572:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100577:	eb 16                	jmp    f010058f <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100579:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100580:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f0100587:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010058a:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010058f:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f0100595:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059a:	89 fa                	mov    %edi,%edx
f010059c:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010059d:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a0:	89 da                	mov    %ebx,%edx
f01005a2:	ec                   	in     (%dx),%al
f01005a3:	0f b6 c8             	movzbl %al,%ecx
f01005a6:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005a9:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005ae:	89 fa                	mov    %edi,%edx
f01005b0:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b1:	89 da                	mov    %ebx,%edx
f01005b3:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005b4:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005ba:	0f b6 c0             	movzbl %al,%eax
f01005bd:	09 c8                	or     %ecx,%eax
f01005bf:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c5:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01005cf:	89 f2                	mov    %esi,%edx
f01005d1:	ee                   	out    %al,(%dx)
f01005d2:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005d7:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005dc:	ee                   	out    %al,(%dx)
f01005dd:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005e2:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005e7:	89 da                	mov    %ebx,%edx
f01005e9:	ee                   	out    %al,(%dx)
f01005ea:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f4:	ee                   	out    %al,(%dx)
f01005f5:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005fa:	b8 03 00 00 00       	mov    $0x3,%eax
f01005ff:	ee                   	out    %al,(%dx)
f0100600:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100605:	b8 00 00 00 00       	mov    $0x0,%eax
f010060a:	ee                   	out    %al,(%dx)
f010060b:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100610:	b8 01 00 00 00       	mov    $0x1,%eax
f0100615:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100616:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010061b:	ec                   	in     (%dx),%al
f010061c:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010061e:	3c ff                	cmp    $0xff,%al
f0100620:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f0100627:	89 f2                	mov    %esi,%edx
f0100629:	ec                   	in     (%dx),%al
f010062a:	89 da                	mov    %ebx,%edx
f010062c:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010062d:	80 f9 ff             	cmp    $0xff,%cl
f0100630:	75 10                	jne    f0100642 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100632:	83 ec 0c             	sub    $0xc,%esp
f0100635:	68 10 19 10 f0       	push   $0xf0101910
f010063a:	e8 a8 02 00 00       	call   f01008e7 <cprintf>
f010063f:	83 c4 10             	add    $0x10,%esp
}
f0100642:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100645:	5b                   	pop    %ebx
f0100646:	5e                   	pop    %esi
f0100647:	5f                   	pop    %edi
f0100648:	5d                   	pop    %ebp
f0100649:	c3                   	ret    

f010064a <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010064a:	55                   	push   %ebp
f010064b:	89 e5                	mov    %esp,%ebp
f010064d:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100650:	8b 45 08             	mov    0x8(%ebp),%eax
f0100653:	e8 89 fc ff ff       	call   f01002e1 <cons_putc>
}
f0100658:	c9                   	leave  
f0100659:	c3                   	ret    

f010065a <getchar>:

int
getchar(void)
{
f010065a:	55                   	push   %ebp
f010065b:	89 e5                	mov    %esp,%ebp
f010065d:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100660:	e8 93 fe ff ff       	call   f01004f8 <cons_getc>
f0100665:	85 c0                	test   %eax,%eax
f0100667:	74 f7                	je     f0100660 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100669:	c9                   	leave  
f010066a:	c3                   	ret    

f010066b <iscons>:

int
iscons(int fdnum)
{
f010066b:	55                   	push   %ebp
f010066c:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010066e:	b8 01 00 00 00       	mov    $0x1,%eax
f0100673:	5d                   	pop    %ebp
f0100674:	c3                   	ret    

f0100675 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100675:	55                   	push   %ebp
f0100676:	89 e5                	mov    %esp,%ebp
f0100678:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010067b:	68 60 1b 10 f0       	push   $0xf0101b60
f0100680:	68 7e 1b 10 f0       	push   $0xf0101b7e
f0100685:	68 83 1b 10 f0       	push   $0xf0101b83
f010068a:	e8 58 02 00 00       	call   f01008e7 <cprintf>
f010068f:	83 c4 0c             	add    $0xc,%esp
f0100692:	68 ec 1b 10 f0       	push   $0xf0101bec
f0100697:	68 8c 1b 10 f0       	push   $0xf0101b8c
f010069c:	68 83 1b 10 f0       	push   $0xf0101b83
f01006a1:	e8 41 02 00 00       	call   f01008e7 <cprintf>
	return 0;
}
f01006a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ab:	c9                   	leave  
f01006ac:	c3                   	ret    

f01006ad <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006ad:	55                   	push   %ebp
f01006ae:	89 e5                	mov    %esp,%ebp
f01006b0:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006b3:	68 95 1b 10 f0       	push   $0xf0101b95
f01006b8:	e8 2a 02 00 00       	call   f01008e7 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006bd:	83 c4 08             	add    $0x8,%esp
f01006c0:	68 0c 00 10 00       	push   $0x10000c
f01006c5:	68 14 1c 10 f0       	push   $0xf0101c14
f01006ca:	e8 18 02 00 00       	call   f01008e7 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006cf:	83 c4 0c             	add    $0xc,%esp
f01006d2:	68 0c 00 10 00       	push   $0x10000c
f01006d7:	68 0c 00 10 f0       	push   $0xf010000c
f01006dc:	68 3c 1c 10 f0       	push   $0xf0101c3c
f01006e1:	e8 01 02 00 00       	call   f01008e7 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006e6:	83 c4 0c             	add    $0xc,%esp
f01006e9:	68 61 18 10 00       	push   $0x101861
f01006ee:	68 61 18 10 f0       	push   $0xf0101861
f01006f3:	68 60 1c 10 f0       	push   $0xf0101c60
f01006f8:	e8 ea 01 00 00       	call   f01008e7 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006fd:	83 c4 0c             	add    $0xc,%esp
f0100700:	68 00 23 11 00       	push   $0x112300
f0100705:	68 00 23 11 f0       	push   $0xf0112300
f010070a:	68 84 1c 10 f0       	push   $0xf0101c84
f010070f:	e8 d3 01 00 00       	call   f01008e7 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100714:	83 c4 0c             	add    $0xc,%esp
f0100717:	68 44 29 11 00       	push   $0x112944
f010071c:	68 44 29 11 f0       	push   $0xf0112944
f0100721:	68 a8 1c 10 f0       	push   $0xf0101ca8
f0100726:	e8 bc 01 00 00       	call   f01008e7 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010072b:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f0100730:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100735:	83 c4 08             	add    $0x8,%esp
f0100738:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010073d:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100743:	85 c0                	test   %eax,%eax
f0100745:	0f 48 c2             	cmovs  %edx,%eax
f0100748:	c1 f8 0a             	sar    $0xa,%eax
f010074b:	50                   	push   %eax
f010074c:	68 cc 1c 10 f0       	push   $0xf0101ccc
f0100751:	e8 91 01 00 00       	call   f01008e7 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100756:	b8 00 00 00 00       	mov    $0x0,%eax
f010075b:	c9                   	leave  
f010075c:	c3                   	ret    

f010075d <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010075d:	55                   	push   %ebp
f010075e:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100760:	b8 00 00 00 00       	mov    $0x0,%eax
f0100765:	5d                   	pop    %ebp
f0100766:	c3                   	ret    

f0100767 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100767:	55                   	push   %ebp
f0100768:	89 e5                	mov    %esp,%ebp
f010076a:	57                   	push   %edi
f010076b:	56                   	push   %esi
f010076c:	53                   	push   %ebx
f010076d:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100770:	68 f8 1c 10 f0       	push   $0xf0101cf8
f0100775:	e8 6d 01 00 00       	call   f01008e7 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010077a:	c7 04 24 1c 1d 10 f0 	movl   $0xf0101d1c,(%esp)
f0100781:	e8 61 01 00 00       	call   f01008e7 <cprintf>
f0100786:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100789:	83 ec 0c             	sub    $0xc,%esp
f010078c:	68 ae 1b 10 f0       	push   $0xf0101bae
f0100791:	e8 e3 09 00 00       	call   f0101179 <readline>
f0100796:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100798:	83 c4 10             	add    $0x10,%esp
f010079b:	85 c0                	test   %eax,%eax
f010079d:	74 ea                	je     f0100789 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010079f:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007a6:	be 00 00 00 00       	mov    $0x0,%esi
f01007ab:	eb 0a                	jmp    f01007b7 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007ad:	c6 03 00             	movb   $0x0,(%ebx)
f01007b0:	89 f7                	mov    %esi,%edi
f01007b2:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007b5:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007b7:	0f b6 03             	movzbl (%ebx),%eax
f01007ba:	84 c0                	test   %al,%al
f01007bc:	74 63                	je     f0100821 <monitor+0xba>
f01007be:	83 ec 08             	sub    $0x8,%esp
f01007c1:	0f be c0             	movsbl %al,%eax
f01007c4:	50                   	push   %eax
f01007c5:	68 b2 1b 10 f0       	push   $0xf0101bb2
f01007ca:	e8 c4 0b 00 00       	call   f0101393 <strchr>
f01007cf:	83 c4 10             	add    $0x10,%esp
f01007d2:	85 c0                	test   %eax,%eax
f01007d4:	75 d7                	jne    f01007ad <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f01007d6:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007d9:	74 46                	je     f0100821 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007db:	83 fe 0f             	cmp    $0xf,%esi
f01007de:	75 14                	jne    f01007f4 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007e0:	83 ec 08             	sub    $0x8,%esp
f01007e3:	6a 10                	push   $0x10
f01007e5:	68 b7 1b 10 f0       	push   $0xf0101bb7
f01007ea:	e8 f8 00 00 00       	call   f01008e7 <cprintf>
f01007ef:	83 c4 10             	add    $0x10,%esp
f01007f2:	eb 95                	jmp    f0100789 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f01007f4:	8d 7e 01             	lea    0x1(%esi),%edi
f01007f7:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01007fb:	eb 03                	jmp    f0100800 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01007fd:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100800:	0f b6 03             	movzbl (%ebx),%eax
f0100803:	84 c0                	test   %al,%al
f0100805:	74 ae                	je     f01007b5 <monitor+0x4e>
f0100807:	83 ec 08             	sub    $0x8,%esp
f010080a:	0f be c0             	movsbl %al,%eax
f010080d:	50                   	push   %eax
f010080e:	68 b2 1b 10 f0       	push   $0xf0101bb2
f0100813:	e8 7b 0b 00 00       	call   f0101393 <strchr>
f0100818:	83 c4 10             	add    $0x10,%esp
f010081b:	85 c0                	test   %eax,%eax
f010081d:	74 de                	je     f01007fd <monitor+0x96>
f010081f:	eb 94                	jmp    f01007b5 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100821:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100828:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100829:	85 f6                	test   %esi,%esi
f010082b:	0f 84 58 ff ff ff    	je     f0100789 <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100831:	83 ec 08             	sub    $0x8,%esp
f0100834:	68 7e 1b 10 f0       	push   $0xf0101b7e
f0100839:	ff 75 a8             	pushl  -0x58(%ebp)
f010083c:	e8 f4 0a 00 00       	call   f0101335 <strcmp>
f0100841:	83 c4 10             	add    $0x10,%esp
f0100844:	85 c0                	test   %eax,%eax
f0100846:	74 1e                	je     f0100866 <monitor+0xff>
f0100848:	83 ec 08             	sub    $0x8,%esp
f010084b:	68 8c 1b 10 f0       	push   $0xf0101b8c
f0100850:	ff 75 a8             	pushl  -0x58(%ebp)
f0100853:	e8 dd 0a 00 00       	call   f0101335 <strcmp>
f0100858:	83 c4 10             	add    $0x10,%esp
f010085b:	85 c0                	test   %eax,%eax
f010085d:	75 2f                	jne    f010088e <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010085f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100864:	eb 05                	jmp    f010086b <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100866:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f010086b:	83 ec 04             	sub    $0x4,%esp
f010086e:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100871:	01 d0                	add    %edx,%eax
f0100873:	ff 75 08             	pushl  0x8(%ebp)
f0100876:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100879:	51                   	push   %ecx
f010087a:	56                   	push   %esi
f010087b:	ff 14 85 4c 1d 10 f0 	call   *-0xfefe2b4(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100882:	83 c4 10             	add    $0x10,%esp
f0100885:	85 c0                	test   %eax,%eax
f0100887:	78 1d                	js     f01008a6 <monitor+0x13f>
f0100889:	e9 fb fe ff ff       	jmp    f0100789 <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010088e:	83 ec 08             	sub    $0x8,%esp
f0100891:	ff 75 a8             	pushl  -0x58(%ebp)
f0100894:	68 d4 1b 10 f0       	push   $0xf0101bd4
f0100899:	e8 49 00 00 00       	call   f01008e7 <cprintf>
f010089e:	83 c4 10             	add    $0x10,%esp
f01008a1:	e9 e3 fe ff ff       	jmp    f0100789 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008a6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008a9:	5b                   	pop    %ebx
f01008aa:	5e                   	pop    %esi
f01008ab:	5f                   	pop    %edi
f01008ac:	5d                   	pop    %ebp
f01008ad:	c3                   	ret    

f01008ae <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01008ae:	55                   	push   %ebp
f01008af:	89 e5                	mov    %esp,%ebp
f01008b1:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01008b4:	ff 75 08             	pushl  0x8(%ebp)
f01008b7:	e8 8e fd ff ff       	call   f010064a <cputchar>
	*cnt++;
}
f01008bc:	83 c4 10             	add    $0x10,%esp
f01008bf:	c9                   	leave  
f01008c0:	c3                   	ret    

f01008c1 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01008c1:	55                   	push   %ebp
f01008c2:	89 e5                	mov    %esp,%ebp
f01008c4:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01008c7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01008ce:	ff 75 0c             	pushl  0xc(%ebp)
f01008d1:	ff 75 08             	pushl  0x8(%ebp)
f01008d4:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01008d7:	50                   	push   %eax
f01008d8:	68 ae 08 10 f0       	push   $0xf01008ae
f01008dd:	e8 c9 03 00 00       	call   f0100cab <vprintfmt>
	return cnt;
}
f01008e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01008e5:	c9                   	leave  
f01008e6:	c3                   	ret    

f01008e7 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01008e7:	55                   	push   %ebp
f01008e8:	89 e5                	mov    %esp,%ebp
f01008ea:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01008ed:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01008f0:	50                   	push   %eax
f01008f1:	ff 75 08             	pushl  0x8(%ebp)
f01008f4:	e8 c8 ff ff ff       	call   f01008c1 <vcprintf>
	va_end(ap);

	return cnt;
}
f01008f9:	c9                   	leave  
f01008fa:	c3                   	ret    

f01008fb <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01008fb:	55                   	push   %ebp
f01008fc:	89 e5                	mov    %esp,%ebp
f01008fe:	57                   	push   %edi
f01008ff:	56                   	push   %esi
f0100900:	53                   	push   %ebx
f0100901:	83 ec 14             	sub    $0x14,%esp
f0100904:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100907:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010090a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010090d:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100910:	8b 1a                	mov    (%edx),%ebx
f0100912:	8b 01                	mov    (%ecx),%eax
f0100914:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100917:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010091e:	eb 7f                	jmp    f010099f <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0100920:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100923:	01 d8                	add    %ebx,%eax
f0100925:	89 c6                	mov    %eax,%esi
f0100927:	c1 ee 1f             	shr    $0x1f,%esi
f010092a:	01 c6                	add    %eax,%esi
f010092c:	d1 fe                	sar    %esi
f010092e:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100931:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100934:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0100937:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100939:	eb 03                	jmp    f010093e <stab_binsearch+0x43>
			m--;
f010093b:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010093e:	39 c3                	cmp    %eax,%ebx
f0100940:	7f 0d                	jg     f010094f <stab_binsearch+0x54>
f0100942:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100946:	83 ea 0c             	sub    $0xc,%edx
f0100949:	39 f9                	cmp    %edi,%ecx
f010094b:	75 ee                	jne    f010093b <stab_binsearch+0x40>
f010094d:	eb 05                	jmp    f0100954 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010094f:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100952:	eb 4b                	jmp    f010099f <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100954:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100957:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010095a:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010095e:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100961:	76 11                	jbe    f0100974 <stab_binsearch+0x79>
			*region_left = m;
f0100963:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100966:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100968:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010096b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100972:	eb 2b                	jmp    f010099f <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100974:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100977:	73 14                	jae    f010098d <stab_binsearch+0x92>
			*region_right = m - 1;
f0100979:	83 e8 01             	sub    $0x1,%eax
f010097c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010097f:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100982:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100984:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010098b:	eb 12                	jmp    f010099f <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010098d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100990:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100992:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100996:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100998:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010099f:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01009a2:	0f 8e 78 ff ff ff    	jle    f0100920 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01009a8:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01009ac:	75 0f                	jne    f01009bd <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01009ae:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009b1:	8b 00                	mov    (%eax),%eax
f01009b3:	83 e8 01             	sub    $0x1,%eax
f01009b6:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01009b9:	89 06                	mov    %eax,(%esi)
f01009bb:	eb 2c                	jmp    f01009e9 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009bd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01009c0:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01009c2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01009c5:	8b 0e                	mov    (%esi),%ecx
f01009c7:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01009ca:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01009cd:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009d0:	eb 03                	jmp    f01009d5 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01009d2:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009d5:	39 c8                	cmp    %ecx,%eax
f01009d7:	7e 0b                	jle    f01009e4 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01009d9:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01009dd:	83 ea 0c             	sub    $0xc,%edx
f01009e0:	39 df                	cmp    %ebx,%edi
f01009e2:	75 ee                	jne    f01009d2 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01009e4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01009e7:	89 06                	mov    %eax,(%esi)
	}
}
f01009e9:	83 c4 14             	add    $0x14,%esp
f01009ec:	5b                   	pop    %ebx
f01009ed:	5e                   	pop    %esi
f01009ee:	5f                   	pop    %edi
f01009ef:	5d                   	pop    %ebp
f01009f0:	c3                   	ret    

f01009f1 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01009f1:	55                   	push   %ebp
f01009f2:	89 e5                	mov    %esp,%ebp
f01009f4:	57                   	push   %edi
f01009f5:	56                   	push   %esi
f01009f6:	53                   	push   %ebx
f01009f7:	83 ec 1c             	sub    $0x1c,%esp
f01009fa:	8b 7d 08             	mov    0x8(%ebp),%edi
f01009fd:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a00:	c7 06 5c 1d 10 f0    	movl   $0xf0101d5c,(%esi)
	info->eip_line = 0;
f0100a06:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100a0d:	c7 46 08 5c 1d 10 f0 	movl   $0xf0101d5c,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100a14:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100a1b:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100a1e:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a25:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100a2b:	76 11                	jbe    f0100a3e <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a2d:	b8 22 71 10 f0       	mov    $0xf0107122,%eax
f0100a32:	3d 5d 58 10 f0       	cmp    $0xf010585d,%eax
f0100a37:	77 19                	ja     f0100a52 <debuginfo_eip+0x61>
f0100a39:	e9 62 01 00 00       	jmp    f0100ba0 <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a3e:	83 ec 04             	sub    $0x4,%esp
f0100a41:	68 66 1d 10 f0       	push   $0xf0101d66
f0100a46:	6a 7f                	push   $0x7f
f0100a48:	68 73 1d 10 f0       	push   $0xf0101d73
f0100a4d:	e8 91 f6 ff ff       	call   f01000e3 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a52:	80 3d 21 71 10 f0 00 	cmpb   $0x0,0xf0107121
f0100a59:	0f 85 48 01 00 00    	jne    f0100ba7 <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100a5f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100a66:	b8 5c 58 10 f0       	mov    $0xf010585c,%eax
f0100a6b:	2d b0 1f 10 f0       	sub    $0xf0101fb0,%eax
f0100a70:	c1 f8 02             	sar    $0x2,%eax
f0100a73:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100a79:	83 e8 01             	sub    $0x1,%eax
f0100a7c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100a7f:	83 ec 08             	sub    $0x8,%esp
f0100a82:	57                   	push   %edi
f0100a83:	6a 64                	push   $0x64
f0100a85:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100a88:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100a8b:	b8 b0 1f 10 f0       	mov    $0xf0101fb0,%eax
f0100a90:	e8 66 fe ff ff       	call   f01008fb <stab_binsearch>
	if (lfile == 0)
f0100a95:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a98:	83 c4 10             	add    $0x10,%esp
f0100a9b:	85 c0                	test   %eax,%eax
f0100a9d:	0f 84 0b 01 00 00    	je     f0100bae <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100aa3:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100aa6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100aa9:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100aac:	83 ec 08             	sub    $0x8,%esp
f0100aaf:	57                   	push   %edi
f0100ab0:	6a 24                	push   $0x24
f0100ab2:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100ab5:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ab8:	b8 b0 1f 10 f0       	mov    $0xf0101fb0,%eax
f0100abd:	e8 39 fe ff ff       	call   f01008fb <stab_binsearch>

	if (lfun <= rfun) {
f0100ac2:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100ac5:	83 c4 10             	add    $0x10,%esp
f0100ac8:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100acb:	7f 31                	jg     f0100afe <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100acd:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100ad0:	c1 e0 02             	shl    $0x2,%eax
f0100ad3:	8d 90 b0 1f 10 f0    	lea    -0xfefe050(%eax),%edx
f0100ad9:	8b 88 b0 1f 10 f0    	mov    -0xfefe050(%eax),%ecx
f0100adf:	b8 22 71 10 f0       	mov    $0xf0107122,%eax
f0100ae4:	2d 5d 58 10 f0       	sub    $0xf010585d,%eax
f0100ae9:	39 c1                	cmp    %eax,%ecx
f0100aeb:	73 09                	jae    f0100af6 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100aed:	81 c1 5d 58 10 f0    	add    $0xf010585d,%ecx
f0100af3:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100af6:	8b 42 08             	mov    0x8(%edx),%eax
f0100af9:	89 46 10             	mov    %eax,0x10(%esi)
f0100afc:	eb 06                	jmp    f0100b04 <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100afe:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100b01:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b04:	83 ec 08             	sub    $0x8,%esp
f0100b07:	6a 3a                	push   $0x3a
f0100b09:	ff 76 08             	pushl  0x8(%esi)
f0100b0c:	e8 a3 08 00 00       	call   f01013b4 <strfind>
f0100b11:	2b 46 08             	sub    0x8(%esi),%eax
f0100b14:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b17:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b1a:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b1d:	8d 04 85 b0 1f 10 f0 	lea    -0xfefe050(,%eax,4),%eax
f0100b24:	83 c4 10             	add    $0x10,%esp
f0100b27:	eb 06                	jmp    f0100b2f <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b29:	83 eb 01             	sub    $0x1,%ebx
f0100b2c:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b2f:	39 fb                	cmp    %edi,%ebx
f0100b31:	7c 34                	jl     f0100b67 <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f0100b33:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100b37:	80 fa 84             	cmp    $0x84,%dl
f0100b3a:	74 0b                	je     f0100b47 <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b3c:	80 fa 64             	cmp    $0x64,%dl
f0100b3f:	75 e8                	jne    f0100b29 <debuginfo_eip+0x138>
f0100b41:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100b45:	74 e2                	je     f0100b29 <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b47:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b4a:	8b 14 85 b0 1f 10 f0 	mov    -0xfefe050(,%eax,4),%edx
f0100b51:	b8 22 71 10 f0       	mov    $0xf0107122,%eax
f0100b56:	2d 5d 58 10 f0       	sub    $0xf010585d,%eax
f0100b5b:	39 c2                	cmp    %eax,%edx
f0100b5d:	73 08                	jae    f0100b67 <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100b5f:	81 c2 5d 58 10 f0    	add    $0xf010585d,%edx
f0100b65:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100b67:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100b6a:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b6d:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100b72:	39 cb                	cmp    %ecx,%ebx
f0100b74:	7d 44                	jge    f0100bba <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f0100b76:	8d 53 01             	lea    0x1(%ebx),%edx
f0100b79:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b7c:	8d 04 85 b0 1f 10 f0 	lea    -0xfefe050(,%eax,4),%eax
f0100b83:	eb 07                	jmp    f0100b8c <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100b85:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100b89:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100b8c:	39 ca                	cmp    %ecx,%edx
f0100b8e:	74 25                	je     f0100bb5 <debuginfo_eip+0x1c4>
f0100b90:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100b93:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100b97:	74 ec                	je     f0100b85 <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b99:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b9e:	eb 1a                	jmp    f0100bba <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100ba0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ba5:	eb 13                	jmp    f0100bba <debuginfo_eip+0x1c9>
f0100ba7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bac:	eb 0c                	jmp    f0100bba <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100bae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bb3:	eb 05                	jmp    f0100bba <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bb5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100bba:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100bbd:	5b                   	pop    %ebx
f0100bbe:	5e                   	pop    %esi
f0100bbf:	5f                   	pop    %edi
f0100bc0:	5d                   	pop    %ebp
f0100bc1:	c3                   	ret    

f0100bc2 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100bc2:	55                   	push   %ebp
f0100bc3:	89 e5                	mov    %esp,%ebp
f0100bc5:	57                   	push   %edi
f0100bc6:	56                   	push   %esi
f0100bc7:	53                   	push   %ebx
f0100bc8:	83 ec 1c             	sub    $0x1c,%esp
f0100bcb:	89 c7                	mov    %eax,%edi
f0100bcd:	89 d6                	mov    %edx,%esi
f0100bcf:	8b 45 08             	mov    0x8(%ebp),%eax
f0100bd2:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100bd5:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100bd8:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100bdb:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100bde:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100be3:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100be6:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100be9:	39 d3                	cmp    %edx,%ebx
f0100beb:	72 05                	jb     f0100bf2 <printnum+0x30>
f0100bed:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100bf0:	77 45                	ja     f0100c37 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100bf2:	83 ec 0c             	sub    $0xc,%esp
f0100bf5:	ff 75 18             	pushl  0x18(%ebp)
f0100bf8:	8b 45 14             	mov    0x14(%ebp),%eax
f0100bfb:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100bfe:	53                   	push   %ebx
f0100bff:	ff 75 10             	pushl  0x10(%ebp)
f0100c02:	83 ec 08             	sub    $0x8,%esp
f0100c05:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c08:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c0b:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c0e:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c11:	e8 ca 09 00 00       	call   f01015e0 <__udivdi3>
f0100c16:	83 c4 18             	add    $0x18,%esp
f0100c19:	52                   	push   %edx
f0100c1a:	50                   	push   %eax
f0100c1b:	89 f2                	mov    %esi,%edx
f0100c1d:	89 f8                	mov    %edi,%eax
f0100c1f:	e8 9e ff ff ff       	call   f0100bc2 <printnum>
f0100c24:	83 c4 20             	add    $0x20,%esp
f0100c27:	eb 18                	jmp    f0100c41 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100c29:	83 ec 08             	sub    $0x8,%esp
f0100c2c:	56                   	push   %esi
f0100c2d:	ff 75 18             	pushl  0x18(%ebp)
f0100c30:	ff d7                	call   *%edi
f0100c32:	83 c4 10             	add    $0x10,%esp
f0100c35:	eb 03                	jmp    f0100c3a <printnum+0x78>
f0100c37:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100c3a:	83 eb 01             	sub    $0x1,%ebx
f0100c3d:	85 db                	test   %ebx,%ebx
f0100c3f:	7f e8                	jg     f0100c29 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100c41:	83 ec 08             	sub    $0x8,%esp
f0100c44:	56                   	push   %esi
f0100c45:	83 ec 04             	sub    $0x4,%esp
f0100c48:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c4b:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c4e:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c51:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c54:	e8 b7 0a 00 00       	call   f0101710 <__umoddi3>
f0100c59:	83 c4 14             	add    $0x14,%esp
f0100c5c:	0f be 80 81 1d 10 f0 	movsbl -0xfefe27f(%eax),%eax
f0100c63:	50                   	push   %eax
f0100c64:	ff d7                	call   *%edi
}
f0100c66:	83 c4 10             	add    $0x10,%esp
f0100c69:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c6c:	5b                   	pop    %ebx
f0100c6d:	5e                   	pop    %esi
f0100c6e:	5f                   	pop    %edi
f0100c6f:	5d                   	pop    %ebp
f0100c70:	c3                   	ret    

f0100c71 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100c71:	55                   	push   %ebp
f0100c72:	89 e5                	mov    %esp,%ebp
f0100c74:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100c77:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100c7b:	8b 10                	mov    (%eax),%edx
f0100c7d:	3b 50 04             	cmp    0x4(%eax),%edx
f0100c80:	73 0a                	jae    f0100c8c <sprintputch+0x1b>
		*b->buf++ = ch;
f0100c82:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100c85:	89 08                	mov    %ecx,(%eax)
f0100c87:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c8a:	88 02                	mov    %al,(%edx)
}
f0100c8c:	5d                   	pop    %ebp
f0100c8d:	c3                   	ret    

f0100c8e <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100c8e:	55                   	push   %ebp
f0100c8f:	89 e5                	mov    %esp,%ebp
f0100c91:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100c94:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100c97:	50                   	push   %eax
f0100c98:	ff 75 10             	pushl  0x10(%ebp)
f0100c9b:	ff 75 0c             	pushl  0xc(%ebp)
f0100c9e:	ff 75 08             	pushl  0x8(%ebp)
f0100ca1:	e8 05 00 00 00       	call   f0100cab <vprintfmt>
	va_end(ap);
}
f0100ca6:	83 c4 10             	add    $0x10,%esp
f0100ca9:	c9                   	leave  
f0100caa:	c3                   	ret    

f0100cab <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100cab:	55                   	push   %ebp
f0100cac:	89 e5                	mov    %esp,%ebp
f0100cae:	57                   	push   %edi
f0100caf:	56                   	push   %esi
f0100cb0:	53                   	push   %ebx
f0100cb1:	83 ec 2c             	sub    $0x2c,%esp
f0100cb4:	8b 75 08             	mov    0x8(%ebp),%esi
f0100cb7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100cba:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100cbd:	eb 12                	jmp    f0100cd1 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100cbf:	85 c0                	test   %eax,%eax
f0100cc1:	0f 84 42 04 00 00    	je     f0101109 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0100cc7:	83 ec 08             	sub    $0x8,%esp
f0100cca:	53                   	push   %ebx
f0100ccb:	50                   	push   %eax
f0100ccc:	ff d6                	call   *%esi
f0100cce:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100cd1:	83 c7 01             	add    $0x1,%edi
f0100cd4:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100cd8:	83 f8 25             	cmp    $0x25,%eax
f0100cdb:	75 e2                	jne    f0100cbf <vprintfmt+0x14>
f0100cdd:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100ce1:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100ce8:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100cef:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100cf6:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100cfb:	eb 07                	jmp    f0100d04 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100cfd:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100d00:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d04:	8d 47 01             	lea    0x1(%edi),%eax
f0100d07:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d0a:	0f b6 07             	movzbl (%edi),%eax
f0100d0d:	0f b6 d0             	movzbl %al,%edx
f0100d10:	83 e8 23             	sub    $0x23,%eax
f0100d13:	3c 55                	cmp    $0x55,%al
f0100d15:	0f 87 d3 03 00 00    	ja     f01010ee <vprintfmt+0x443>
f0100d1b:	0f b6 c0             	movzbl %al,%eax
f0100d1e:	ff 24 85 20 1e 10 f0 	jmp    *-0xfefe1e0(,%eax,4)
f0100d25:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100d28:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100d2c:	eb d6                	jmp    f0100d04 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d2e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d31:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d36:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100d39:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100d3c:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100d40:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100d43:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100d46:	83 f9 09             	cmp    $0x9,%ecx
f0100d49:	77 3f                	ja     f0100d8a <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100d4b:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100d4e:	eb e9                	jmp    f0100d39 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100d50:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d53:	8b 00                	mov    (%eax),%eax
f0100d55:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100d58:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d5b:	8d 40 04             	lea    0x4(%eax),%eax
f0100d5e:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d61:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100d64:	eb 2a                	jmp    f0100d90 <vprintfmt+0xe5>
f0100d66:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d69:	85 c0                	test   %eax,%eax
f0100d6b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d70:	0f 49 d0             	cmovns %eax,%edx
f0100d73:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d76:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d79:	eb 89                	jmp    f0100d04 <vprintfmt+0x59>
f0100d7b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100d7e:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100d85:	e9 7a ff ff ff       	jmp    f0100d04 <vprintfmt+0x59>
f0100d8a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d8d:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100d90:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100d94:	0f 89 6a ff ff ff    	jns    f0100d04 <vprintfmt+0x59>
				width = precision, precision = -1;
f0100d9a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100d9d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100da0:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100da7:	e9 58 ff ff ff       	jmp    f0100d04 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100dac:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100daf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100db2:	e9 4d ff ff ff       	jmp    f0100d04 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100db7:	8b 45 14             	mov    0x14(%ebp),%eax
f0100dba:	8d 78 04             	lea    0x4(%eax),%edi
f0100dbd:	83 ec 08             	sub    $0x8,%esp
f0100dc0:	53                   	push   %ebx
f0100dc1:	ff 30                	pushl  (%eax)
f0100dc3:	ff d6                	call   *%esi
			break;
f0100dc5:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100dc8:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dcb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100dce:	e9 fe fe ff ff       	jmp    f0100cd1 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100dd3:	8b 45 14             	mov    0x14(%ebp),%eax
f0100dd6:	8d 78 04             	lea    0x4(%eax),%edi
f0100dd9:	8b 00                	mov    (%eax),%eax
f0100ddb:	99                   	cltd   
f0100ddc:	31 d0                	xor    %edx,%eax
f0100dde:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100de0:	83 f8 07             	cmp    $0x7,%eax
f0100de3:	7f 0b                	jg     f0100df0 <vprintfmt+0x145>
f0100de5:	8b 14 85 80 1f 10 f0 	mov    -0xfefe080(,%eax,4),%edx
f0100dec:	85 d2                	test   %edx,%edx
f0100dee:	75 1b                	jne    f0100e0b <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0100df0:	50                   	push   %eax
f0100df1:	68 99 1d 10 f0       	push   $0xf0101d99
f0100df6:	53                   	push   %ebx
f0100df7:	56                   	push   %esi
f0100df8:	e8 91 fe ff ff       	call   f0100c8e <printfmt>
f0100dfd:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100e00:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e03:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100e06:	e9 c6 fe ff ff       	jmp    f0100cd1 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100e0b:	52                   	push   %edx
f0100e0c:	68 a2 1d 10 f0       	push   $0xf0101da2
f0100e11:	53                   	push   %ebx
f0100e12:	56                   	push   %esi
f0100e13:	e8 76 fe ff ff       	call   f0100c8e <printfmt>
f0100e18:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100e1b:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e1e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e21:	e9 ab fe ff ff       	jmp    f0100cd1 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100e26:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e29:	83 c0 04             	add    $0x4,%eax
f0100e2c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100e2f:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e32:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100e34:	85 ff                	test   %edi,%edi
f0100e36:	b8 92 1d 10 f0       	mov    $0xf0101d92,%eax
f0100e3b:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100e3e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e42:	0f 8e 94 00 00 00    	jle    f0100edc <vprintfmt+0x231>
f0100e48:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100e4c:	0f 84 98 00 00 00    	je     f0100eea <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e52:	83 ec 08             	sub    $0x8,%esp
f0100e55:	ff 75 d0             	pushl  -0x30(%ebp)
f0100e58:	57                   	push   %edi
f0100e59:	e8 0c 04 00 00       	call   f010126a <strnlen>
f0100e5e:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100e61:	29 c1                	sub    %eax,%ecx
f0100e63:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0100e66:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100e69:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100e6d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e70:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100e73:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e75:	eb 0f                	jmp    f0100e86 <vprintfmt+0x1db>
					putch(padc, putdat);
f0100e77:	83 ec 08             	sub    $0x8,%esp
f0100e7a:	53                   	push   %ebx
f0100e7b:	ff 75 e0             	pushl  -0x20(%ebp)
f0100e7e:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e80:	83 ef 01             	sub    $0x1,%edi
f0100e83:	83 c4 10             	add    $0x10,%esp
f0100e86:	85 ff                	test   %edi,%edi
f0100e88:	7f ed                	jg     f0100e77 <vprintfmt+0x1cc>
f0100e8a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100e8d:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0100e90:	85 c9                	test   %ecx,%ecx
f0100e92:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e97:	0f 49 c1             	cmovns %ecx,%eax
f0100e9a:	29 c1                	sub    %eax,%ecx
f0100e9c:	89 75 08             	mov    %esi,0x8(%ebp)
f0100e9f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100ea2:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100ea5:	89 cb                	mov    %ecx,%ebx
f0100ea7:	eb 4d                	jmp    f0100ef6 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100ea9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100ead:	74 1b                	je     f0100eca <vprintfmt+0x21f>
f0100eaf:	0f be c0             	movsbl %al,%eax
f0100eb2:	83 e8 20             	sub    $0x20,%eax
f0100eb5:	83 f8 5e             	cmp    $0x5e,%eax
f0100eb8:	76 10                	jbe    f0100eca <vprintfmt+0x21f>
					putch('?', putdat);
f0100eba:	83 ec 08             	sub    $0x8,%esp
f0100ebd:	ff 75 0c             	pushl  0xc(%ebp)
f0100ec0:	6a 3f                	push   $0x3f
f0100ec2:	ff 55 08             	call   *0x8(%ebp)
f0100ec5:	83 c4 10             	add    $0x10,%esp
f0100ec8:	eb 0d                	jmp    f0100ed7 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0100eca:	83 ec 08             	sub    $0x8,%esp
f0100ecd:	ff 75 0c             	pushl  0xc(%ebp)
f0100ed0:	52                   	push   %edx
f0100ed1:	ff 55 08             	call   *0x8(%ebp)
f0100ed4:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100ed7:	83 eb 01             	sub    $0x1,%ebx
f0100eda:	eb 1a                	jmp    f0100ef6 <vprintfmt+0x24b>
f0100edc:	89 75 08             	mov    %esi,0x8(%ebp)
f0100edf:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100ee2:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100ee5:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100ee8:	eb 0c                	jmp    f0100ef6 <vprintfmt+0x24b>
f0100eea:	89 75 08             	mov    %esi,0x8(%ebp)
f0100eed:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100ef0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100ef3:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100ef6:	83 c7 01             	add    $0x1,%edi
f0100ef9:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100efd:	0f be d0             	movsbl %al,%edx
f0100f00:	85 d2                	test   %edx,%edx
f0100f02:	74 23                	je     f0100f27 <vprintfmt+0x27c>
f0100f04:	85 f6                	test   %esi,%esi
f0100f06:	78 a1                	js     f0100ea9 <vprintfmt+0x1fe>
f0100f08:	83 ee 01             	sub    $0x1,%esi
f0100f0b:	79 9c                	jns    f0100ea9 <vprintfmt+0x1fe>
f0100f0d:	89 df                	mov    %ebx,%edi
f0100f0f:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f12:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f15:	eb 18                	jmp    f0100f2f <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100f17:	83 ec 08             	sub    $0x8,%esp
f0100f1a:	53                   	push   %ebx
f0100f1b:	6a 20                	push   $0x20
f0100f1d:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100f1f:	83 ef 01             	sub    $0x1,%edi
f0100f22:	83 c4 10             	add    $0x10,%esp
f0100f25:	eb 08                	jmp    f0100f2f <vprintfmt+0x284>
f0100f27:	89 df                	mov    %ebx,%edi
f0100f29:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f2c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f2f:	85 ff                	test   %edi,%edi
f0100f31:	7f e4                	jg     f0100f17 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f33:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0100f36:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f39:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f3c:	e9 90 fd ff ff       	jmp    f0100cd1 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100f41:	83 f9 01             	cmp    $0x1,%ecx
f0100f44:	7e 19                	jle    f0100f5f <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0100f46:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f49:	8b 50 04             	mov    0x4(%eax),%edx
f0100f4c:	8b 00                	mov    (%eax),%eax
f0100f4e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f51:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100f54:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f57:	8d 40 08             	lea    0x8(%eax),%eax
f0100f5a:	89 45 14             	mov    %eax,0x14(%ebp)
f0100f5d:	eb 38                	jmp    f0100f97 <vprintfmt+0x2ec>
	else if (lflag)
f0100f5f:	85 c9                	test   %ecx,%ecx
f0100f61:	74 1b                	je     f0100f7e <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0100f63:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f66:	8b 00                	mov    (%eax),%eax
f0100f68:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f6b:	89 c1                	mov    %eax,%ecx
f0100f6d:	c1 f9 1f             	sar    $0x1f,%ecx
f0100f70:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100f73:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f76:	8d 40 04             	lea    0x4(%eax),%eax
f0100f79:	89 45 14             	mov    %eax,0x14(%ebp)
f0100f7c:	eb 19                	jmp    f0100f97 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0100f7e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f81:	8b 00                	mov    (%eax),%eax
f0100f83:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f86:	89 c1                	mov    %eax,%ecx
f0100f88:	c1 f9 1f             	sar    $0x1f,%ecx
f0100f8b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100f8e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f91:	8d 40 04             	lea    0x4(%eax),%eax
f0100f94:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0100f97:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100f9a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0100f9d:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0100fa2:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100fa6:	0f 89 0e 01 00 00    	jns    f01010ba <vprintfmt+0x40f>
				putch('-', putdat);
f0100fac:	83 ec 08             	sub    $0x8,%esp
f0100faf:	53                   	push   %ebx
f0100fb0:	6a 2d                	push   $0x2d
f0100fb2:	ff d6                	call   *%esi
				num = -(long long) num;
f0100fb4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100fb7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100fba:	f7 da                	neg    %edx
f0100fbc:	83 d1 00             	adc    $0x0,%ecx
f0100fbf:	f7 d9                	neg    %ecx
f0100fc1:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0100fc4:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100fc9:	e9 ec 00 00 00       	jmp    f01010ba <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100fce:	83 f9 01             	cmp    $0x1,%ecx
f0100fd1:	7e 18                	jle    f0100feb <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0100fd3:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fd6:	8b 10                	mov    (%eax),%edx
f0100fd8:	8b 48 04             	mov    0x4(%eax),%ecx
f0100fdb:	8d 40 08             	lea    0x8(%eax),%eax
f0100fde:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0100fe1:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100fe6:	e9 cf 00 00 00       	jmp    f01010ba <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0100feb:	85 c9                	test   %ecx,%ecx
f0100fed:	74 1a                	je     f0101009 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0100fef:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ff2:	8b 10                	mov    (%eax),%edx
f0100ff4:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100ff9:	8d 40 04             	lea    0x4(%eax),%eax
f0100ffc:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0100fff:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101004:	e9 b1 00 00 00       	jmp    f01010ba <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0101009:	8b 45 14             	mov    0x14(%ebp),%eax
f010100c:	8b 10                	mov    (%eax),%edx
f010100e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101013:	8d 40 04             	lea    0x4(%eax),%eax
f0101016:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101019:	b8 0a 00 00 00       	mov    $0xa,%eax
f010101e:	e9 97 00 00 00       	jmp    f01010ba <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0101023:	83 ec 08             	sub    $0x8,%esp
f0101026:	53                   	push   %ebx
f0101027:	6a 58                	push   $0x58
f0101029:	ff d6                	call   *%esi
			putch('X', putdat);
f010102b:	83 c4 08             	add    $0x8,%esp
f010102e:	53                   	push   %ebx
f010102f:	6a 58                	push   $0x58
f0101031:	ff d6                	call   *%esi
			putch('X', putdat);
f0101033:	83 c4 08             	add    $0x8,%esp
f0101036:	53                   	push   %ebx
f0101037:	6a 58                	push   $0x58
f0101039:	ff d6                	call   *%esi
			break;
f010103b:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010103e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0101041:	e9 8b fc ff ff       	jmp    f0100cd1 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0101046:	83 ec 08             	sub    $0x8,%esp
f0101049:	53                   	push   %ebx
f010104a:	6a 30                	push   $0x30
f010104c:	ff d6                	call   *%esi
			putch('x', putdat);
f010104e:	83 c4 08             	add    $0x8,%esp
f0101051:	53                   	push   %ebx
f0101052:	6a 78                	push   $0x78
f0101054:	ff d6                	call   *%esi
			num = (unsigned long long)
f0101056:	8b 45 14             	mov    0x14(%ebp),%eax
f0101059:	8b 10                	mov    (%eax),%edx
f010105b:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101060:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101063:	8d 40 04             	lea    0x4(%eax),%eax
f0101066:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101069:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f010106e:	eb 4a                	jmp    f01010ba <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101070:	83 f9 01             	cmp    $0x1,%ecx
f0101073:	7e 15                	jle    f010108a <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0101075:	8b 45 14             	mov    0x14(%ebp),%eax
f0101078:	8b 10                	mov    (%eax),%edx
f010107a:	8b 48 04             	mov    0x4(%eax),%ecx
f010107d:	8d 40 08             	lea    0x8(%eax),%eax
f0101080:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101083:	b8 10 00 00 00       	mov    $0x10,%eax
f0101088:	eb 30                	jmp    f01010ba <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f010108a:	85 c9                	test   %ecx,%ecx
f010108c:	74 17                	je     f01010a5 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f010108e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101091:	8b 10                	mov    (%eax),%edx
f0101093:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101098:	8d 40 04             	lea    0x4(%eax),%eax
f010109b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010109e:	b8 10 00 00 00       	mov    $0x10,%eax
f01010a3:	eb 15                	jmp    f01010ba <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f01010a5:	8b 45 14             	mov    0x14(%ebp),%eax
f01010a8:	8b 10                	mov    (%eax),%edx
f01010aa:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010af:	8d 40 04             	lea    0x4(%eax),%eax
f01010b2:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01010b5:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01010ba:	83 ec 0c             	sub    $0xc,%esp
f01010bd:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01010c1:	57                   	push   %edi
f01010c2:	ff 75 e0             	pushl  -0x20(%ebp)
f01010c5:	50                   	push   %eax
f01010c6:	51                   	push   %ecx
f01010c7:	52                   	push   %edx
f01010c8:	89 da                	mov    %ebx,%edx
f01010ca:	89 f0                	mov    %esi,%eax
f01010cc:	e8 f1 fa ff ff       	call   f0100bc2 <printnum>
			break;
f01010d1:	83 c4 20             	add    $0x20,%esp
f01010d4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01010d7:	e9 f5 fb ff ff       	jmp    f0100cd1 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01010dc:	83 ec 08             	sub    $0x8,%esp
f01010df:	53                   	push   %ebx
f01010e0:	52                   	push   %edx
f01010e1:	ff d6                	call   *%esi
			break;
f01010e3:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010e6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01010e9:	e9 e3 fb ff ff       	jmp    f0100cd1 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01010ee:	83 ec 08             	sub    $0x8,%esp
f01010f1:	53                   	push   %ebx
f01010f2:	6a 25                	push   $0x25
f01010f4:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01010f6:	83 c4 10             	add    $0x10,%esp
f01010f9:	eb 03                	jmp    f01010fe <vprintfmt+0x453>
f01010fb:	83 ef 01             	sub    $0x1,%edi
f01010fe:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101102:	75 f7                	jne    f01010fb <vprintfmt+0x450>
f0101104:	e9 c8 fb ff ff       	jmp    f0100cd1 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101109:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010110c:	5b                   	pop    %ebx
f010110d:	5e                   	pop    %esi
f010110e:	5f                   	pop    %edi
f010110f:	5d                   	pop    %ebp
f0101110:	c3                   	ret    

f0101111 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101111:	55                   	push   %ebp
f0101112:	89 e5                	mov    %esp,%ebp
f0101114:	83 ec 18             	sub    $0x18,%esp
f0101117:	8b 45 08             	mov    0x8(%ebp),%eax
f010111a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010111d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101120:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101124:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101127:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010112e:	85 c0                	test   %eax,%eax
f0101130:	74 26                	je     f0101158 <vsnprintf+0x47>
f0101132:	85 d2                	test   %edx,%edx
f0101134:	7e 22                	jle    f0101158 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101136:	ff 75 14             	pushl  0x14(%ebp)
f0101139:	ff 75 10             	pushl  0x10(%ebp)
f010113c:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010113f:	50                   	push   %eax
f0101140:	68 71 0c 10 f0       	push   $0xf0100c71
f0101145:	e8 61 fb ff ff       	call   f0100cab <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010114a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010114d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101150:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101153:	83 c4 10             	add    $0x10,%esp
f0101156:	eb 05                	jmp    f010115d <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101158:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010115d:	c9                   	leave  
f010115e:	c3                   	ret    

f010115f <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010115f:	55                   	push   %ebp
f0101160:	89 e5                	mov    %esp,%ebp
f0101162:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101165:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101168:	50                   	push   %eax
f0101169:	ff 75 10             	pushl  0x10(%ebp)
f010116c:	ff 75 0c             	pushl  0xc(%ebp)
f010116f:	ff 75 08             	pushl  0x8(%ebp)
f0101172:	e8 9a ff ff ff       	call   f0101111 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101177:	c9                   	leave  
f0101178:	c3                   	ret    

f0101179 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101179:	55                   	push   %ebp
f010117a:	89 e5                	mov    %esp,%ebp
f010117c:	57                   	push   %edi
f010117d:	56                   	push   %esi
f010117e:	53                   	push   %ebx
f010117f:	83 ec 0c             	sub    $0xc,%esp
f0101182:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101185:	85 c0                	test   %eax,%eax
f0101187:	74 11                	je     f010119a <readline+0x21>
		cprintf("%s", prompt);
f0101189:	83 ec 08             	sub    $0x8,%esp
f010118c:	50                   	push   %eax
f010118d:	68 a2 1d 10 f0       	push   $0xf0101da2
f0101192:	e8 50 f7 ff ff       	call   f01008e7 <cprintf>
f0101197:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010119a:	83 ec 0c             	sub    $0xc,%esp
f010119d:	6a 00                	push   $0x0
f010119f:	e8 c7 f4 ff ff       	call   f010066b <iscons>
f01011a4:	89 c7                	mov    %eax,%edi
f01011a6:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01011a9:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01011ae:	e8 a7 f4 ff ff       	call   f010065a <getchar>
f01011b3:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01011b5:	85 c0                	test   %eax,%eax
f01011b7:	79 18                	jns    f01011d1 <readline+0x58>
			cprintf("read error: %e\n", c);
f01011b9:	83 ec 08             	sub    $0x8,%esp
f01011bc:	50                   	push   %eax
f01011bd:	68 a0 1f 10 f0       	push   $0xf0101fa0
f01011c2:	e8 20 f7 ff ff       	call   f01008e7 <cprintf>
			return NULL;
f01011c7:	83 c4 10             	add    $0x10,%esp
f01011ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01011cf:	eb 79                	jmp    f010124a <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01011d1:	83 f8 08             	cmp    $0x8,%eax
f01011d4:	0f 94 c2             	sete   %dl
f01011d7:	83 f8 7f             	cmp    $0x7f,%eax
f01011da:	0f 94 c0             	sete   %al
f01011dd:	08 c2                	or     %al,%dl
f01011df:	74 1a                	je     f01011fb <readline+0x82>
f01011e1:	85 f6                	test   %esi,%esi
f01011e3:	7e 16                	jle    f01011fb <readline+0x82>
			if (echoing)
f01011e5:	85 ff                	test   %edi,%edi
f01011e7:	74 0d                	je     f01011f6 <readline+0x7d>
				cputchar('\b');
f01011e9:	83 ec 0c             	sub    $0xc,%esp
f01011ec:	6a 08                	push   $0x8
f01011ee:	e8 57 f4 ff ff       	call   f010064a <cputchar>
f01011f3:	83 c4 10             	add    $0x10,%esp
			i--;
f01011f6:	83 ee 01             	sub    $0x1,%esi
f01011f9:	eb b3                	jmp    f01011ae <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01011fb:	83 fb 1f             	cmp    $0x1f,%ebx
f01011fe:	7e 23                	jle    f0101223 <readline+0xaa>
f0101200:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101206:	7f 1b                	jg     f0101223 <readline+0xaa>
			if (echoing)
f0101208:	85 ff                	test   %edi,%edi
f010120a:	74 0c                	je     f0101218 <readline+0x9f>
				cputchar(c);
f010120c:	83 ec 0c             	sub    $0xc,%esp
f010120f:	53                   	push   %ebx
f0101210:	e8 35 f4 ff ff       	call   f010064a <cputchar>
f0101215:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101218:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f010121e:	8d 76 01             	lea    0x1(%esi),%esi
f0101221:	eb 8b                	jmp    f01011ae <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101223:	83 fb 0a             	cmp    $0xa,%ebx
f0101226:	74 05                	je     f010122d <readline+0xb4>
f0101228:	83 fb 0d             	cmp    $0xd,%ebx
f010122b:	75 81                	jne    f01011ae <readline+0x35>
			if (echoing)
f010122d:	85 ff                	test   %edi,%edi
f010122f:	74 0d                	je     f010123e <readline+0xc5>
				cputchar('\n');
f0101231:	83 ec 0c             	sub    $0xc,%esp
f0101234:	6a 0a                	push   $0xa
f0101236:	e8 0f f4 ff ff       	call   f010064a <cputchar>
f010123b:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010123e:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f0101245:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f010124a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010124d:	5b                   	pop    %ebx
f010124e:	5e                   	pop    %esi
f010124f:	5f                   	pop    %edi
f0101250:	5d                   	pop    %ebp
f0101251:	c3                   	ret    

f0101252 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101252:	55                   	push   %ebp
f0101253:	89 e5                	mov    %esp,%ebp
f0101255:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101258:	b8 00 00 00 00       	mov    $0x0,%eax
f010125d:	eb 03                	jmp    f0101262 <strlen+0x10>
		n++;
f010125f:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101262:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101266:	75 f7                	jne    f010125f <strlen+0xd>
		n++;
	return n;
}
f0101268:	5d                   	pop    %ebp
f0101269:	c3                   	ret    

f010126a <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010126a:	55                   	push   %ebp
f010126b:	89 e5                	mov    %esp,%ebp
f010126d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101270:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101273:	ba 00 00 00 00       	mov    $0x0,%edx
f0101278:	eb 03                	jmp    f010127d <strnlen+0x13>
		n++;
f010127a:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010127d:	39 c2                	cmp    %eax,%edx
f010127f:	74 08                	je     f0101289 <strnlen+0x1f>
f0101281:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101285:	75 f3                	jne    f010127a <strnlen+0x10>
f0101287:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101289:	5d                   	pop    %ebp
f010128a:	c3                   	ret    

f010128b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010128b:	55                   	push   %ebp
f010128c:	89 e5                	mov    %esp,%ebp
f010128e:	53                   	push   %ebx
f010128f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101292:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101295:	89 c2                	mov    %eax,%edx
f0101297:	83 c2 01             	add    $0x1,%edx
f010129a:	83 c1 01             	add    $0x1,%ecx
f010129d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01012a1:	88 5a ff             	mov    %bl,-0x1(%edx)
f01012a4:	84 db                	test   %bl,%bl
f01012a6:	75 ef                	jne    f0101297 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01012a8:	5b                   	pop    %ebx
f01012a9:	5d                   	pop    %ebp
f01012aa:	c3                   	ret    

f01012ab <strcat>:

char *
strcat(char *dst, const char *src)
{
f01012ab:	55                   	push   %ebp
f01012ac:	89 e5                	mov    %esp,%ebp
f01012ae:	53                   	push   %ebx
f01012af:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01012b2:	53                   	push   %ebx
f01012b3:	e8 9a ff ff ff       	call   f0101252 <strlen>
f01012b8:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01012bb:	ff 75 0c             	pushl  0xc(%ebp)
f01012be:	01 d8                	add    %ebx,%eax
f01012c0:	50                   	push   %eax
f01012c1:	e8 c5 ff ff ff       	call   f010128b <strcpy>
	return dst;
}
f01012c6:	89 d8                	mov    %ebx,%eax
f01012c8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01012cb:	c9                   	leave  
f01012cc:	c3                   	ret    

f01012cd <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01012cd:	55                   	push   %ebp
f01012ce:	89 e5                	mov    %esp,%ebp
f01012d0:	56                   	push   %esi
f01012d1:	53                   	push   %ebx
f01012d2:	8b 75 08             	mov    0x8(%ebp),%esi
f01012d5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01012d8:	89 f3                	mov    %esi,%ebx
f01012da:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01012dd:	89 f2                	mov    %esi,%edx
f01012df:	eb 0f                	jmp    f01012f0 <strncpy+0x23>
		*dst++ = *src;
f01012e1:	83 c2 01             	add    $0x1,%edx
f01012e4:	0f b6 01             	movzbl (%ecx),%eax
f01012e7:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01012ea:	80 39 01             	cmpb   $0x1,(%ecx)
f01012ed:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01012f0:	39 da                	cmp    %ebx,%edx
f01012f2:	75 ed                	jne    f01012e1 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01012f4:	89 f0                	mov    %esi,%eax
f01012f6:	5b                   	pop    %ebx
f01012f7:	5e                   	pop    %esi
f01012f8:	5d                   	pop    %ebp
f01012f9:	c3                   	ret    

f01012fa <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01012fa:	55                   	push   %ebp
f01012fb:	89 e5                	mov    %esp,%ebp
f01012fd:	56                   	push   %esi
f01012fe:	53                   	push   %ebx
f01012ff:	8b 75 08             	mov    0x8(%ebp),%esi
f0101302:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101305:	8b 55 10             	mov    0x10(%ebp),%edx
f0101308:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010130a:	85 d2                	test   %edx,%edx
f010130c:	74 21                	je     f010132f <strlcpy+0x35>
f010130e:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101312:	89 f2                	mov    %esi,%edx
f0101314:	eb 09                	jmp    f010131f <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101316:	83 c2 01             	add    $0x1,%edx
f0101319:	83 c1 01             	add    $0x1,%ecx
f010131c:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010131f:	39 c2                	cmp    %eax,%edx
f0101321:	74 09                	je     f010132c <strlcpy+0x32>
f0101323:	0f b6 19             	movzbl (%ecx),%ebx
f0101326:	84 db                	test   %bl,%bl
f0101328:	75 ec                	jne    f0101316 <strlcpy+0x1c>
f010132a:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010132c:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010132f:	29 f0                	sub    %esi,%eax
}
f0101331:	5b                   	pop    %ebx
f0101332:	5e                   	pop    %esi
f0101333:	5d                   	pop    %ebp
f0101334:	c3                   	ret    

f0101335 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101335:	55                   	push   %ebp
f0101336:	89 e5                	mov    %esp,%ebp
f0101338:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010133b:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010133e:	eb 06                	jmp    f0101346 <strcmp+0x11>
		p++, q++;
f0101340:	83 c1 01             	add    $0x1,%ecx
f0101343:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101346:	0f b6 01             	movzbl (%ecx),%eax
f0101349:	84 c0                	test   %al,%al
f010134b:	74 04                	je     f0101351 <strcmp+0x1c>
f010134d:	3a 02                	cmp    (%edx),%al
f010134f:	74 ef                	je     f0101340 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101351:	0f b6 c0             	movzbl %al,%eax
f0101354:	0f b6 12             	movzbl (%edx),%edx
f0101357:	29 d0                	sub    %edx,%eax
}
f0101359:	5d                   	pop    %ebp
f010135a:	c3                   	ret    

f010135b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010135b:	55                   	push   %ebp
f010135c:	89 e5                	mov    %esp,%ebp
f010135e:	53                   	push   %ebx
f010135f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101362:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101365:	89 c3                	mov    %eax,%ebx
f0101367:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010136a:	eb 06                	jmp    f0101372 <strncmp+0x17>
		n--, p++, q++;
f010136c:	83 c0 01             	add    $0x1,%eax
f010136f:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101372:	39 d8                	cmp    %ebx,%eax
f0101374:	74 15                	je     f010138b <strncmp+0x30>
f0101376:	0f b6 08             	movzbl (%eax),%ecx
f0101379:	84 c9                	test   %cl,%cl
f010137b:	74 04                	je     f0101381 <strncmp+0x26>
f010137d:	3a 0a                	cmp    (%edx),%cl
f010137f:	74 eb                	je     f010136c <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101381:	0f b6 00             	movzbl (%eax),%eax
f0101384:	0f b6 12             	movzbl (%edx),%edx
f0101387:	29 d0                	sub    %edx,%eax
f0101389:	eb 05                	jmp    f0101390 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010138b:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101390:	5b                   	pop    %ebx
f0101391:	5d                   	pop    %ebp
f0101392:	c3                   	ret    

f0101393 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101393:	55                   	push   %ebp
f0101394:	89 e5                	mov    %esp,%ebp
f0101396:	8b 45 08             	mov    0x8(%ebp),%eax
f0101399:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010139d:	eb 07                	jmp    f01013a6 <strchr+0x13>
		if (*s == c)
f010139f:	38 ca                	cmp    %cl,%dl
f01013a1:	74 0f                	je     f01013b2 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01013a3:	83 c0 01             	add    $0x1,%eax
f01013a6:	0f b6 10             	movzbl (%eax),%edx
f01013a9:	84 d2                	test   %dl,%dl
f01013ab:	75 f2                	jne    f010139f <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01013ad:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01013b2:	5d                   	pop    %ebp
f01013b3:	c3                   	ret    

f01013b4 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01013b4:	55                   	push   %ebp
f01013b5:	89 e5                	mov    %esp,%ebp
f01013b7:	8b 45 08             	mov    0x8(%ebp),%eax
f01013ba:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01013be:	eb 03                	jmp    f01013c3 <strfind+0xf>
f01013c0:	83 c0 01             	add    $0x1,%eax
f01013c3:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01013c6:	38 ca                	cmp    %cl,%dl
f01013c8:	74 04                	je     f01013ce <strfind+0x1a>
f01013ca:	84 d2                	test   %dl,%dl
f01013cc:	75 f2                	jne    f01013c0 <strfind+0xc>
			break;
	return (char *) s;
}
f01013ce:	5d                   	pop    %ebp
f01013cf:	c3                   	ret    

f01013d0 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01013d0:	55                   	push   %ebp
f01013d1:	89 e5                	mov    %esp,%ebp
f01013d3:	57                   	push   %edi
f01013d4:	56                   	push   %esi
f01013d5:	53                   	push   %ebx
f01013d6:	8b 7d 08             	mov    0x8(%ebp),%edi
f01013d9:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01013dc:	85 c9                	test   %ecx,%ecx
f01013de:	74 36                	je     f0101416 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01013e0:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01013e6:	75 28                	jne    f0101410 <memset+0x40>
f01013e8:	f6 c1 03             	test   $0x3,%cl
f01013eb:	75 23                	jne    f0101410 <memset+0x40>
		c &= 0xFF;
f01013ed:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01013f1:	89 d3                	mov    %edx,%ebx
f01013f3:	c1 e3 08             	shl    $0x8,%ebx
f01013f6:	89 d6                	mov    %edx,%esi
f01013f8:	c1 e6 18             	shl    $0x18,%esi
f01013fb:	89 d0                	mov    %edx,%eax
f01013fd:	c1 e0 10             	shl    $0x10,%eax
f0101400:	09 f0                	or     %esi,%eax
f0101402:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0101404:	89 d8                	mov    %ebx,%eax
f0101406:	09 d0                	or     %edx,%eax
f0101408:	c1 e9 02             	shr    $0x2,%ecx
f010140b:	fc                   	cld    
f010140c:	f3 ab                	rep stos %eax,%es:(%edi)
f010140e:	eb 06                	jmp    f0101416 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101410:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101413:	fc                   	cld    
f0101414:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101416:	89 f8                	mov    %edi,%eax
f0101418:	5b                   	pop    %ebx
f0101419:	5e                   	pop    %esi
f010141a:	5f                   	pop    %edi
f010141b:	5d                   	pop    %ebp
f010141c:	c3                   	ret    

f010141d <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010141d:	55                   	push   %ebp
f010141e:	89 e5                	mov    %esp,%ebp
f0101420:	57                   	push   %edi
f0101421:	56                   	push   %esi
f0101422:	8b 45 08             	mov    0x8(%ebp),%eax
f0101425:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101428:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010142b:	39 c6                	cmp    %eax,%esi
f010142d:	73 35                	jae    f0101464 <memmove+0x47>
f010142f:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101432:	39 d0                	cmp    %edx,%eax
f0101434:	73 2e                	jae    f0101464 <memmove+0x47>
		s += n;
		d += n;
f0101436:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101439:	89 d6                	mov    %edx,%esi
f010143b:	09 fe                	or     %edi,%esi
f010143d:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101443:	75 13                	jne    f0101458 <memmove+0x3b>
f0101445:	f6 c1 03             	test   $0x3,%cl
f0101448:	75 0e                	jne    f0101458 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010144a:	83 ef 04             	sub    $0x4,%edi
f010144d:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101450:	c1 e9 02             	shr    $0x2,%ecx
f0101453:	fd                   	std    
f0101454:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101456:	eb 09                	jmp    f0101461 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101458:	83 ef 01             	sub    $0x1,%edi
f010145b:	8d 72 ff             	lea    -0x1(%edx),%esi
f010145e:	fd                   	std    
f010145f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101461:	fc                   	cld    
f0101462:	eb 1d                	jmp    f0101481 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101464:	89 f2                	mov    %esi,%edx
f0101466:	09 c2                	or     %eax,%edx
f0101468:	f6 c2 03             	test   $0x3,%dl
f010146b:	75 0f                	jne    f010147c <memmove+0x5f>
f010146d:	f6 c1 03             	test   $0x3,%cl
f0101470:	75 0a                	jne    f010147c <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0101472:	c1 e9 02             	shr    $0x2,%ecx
f0101475:	89 c7                	mov    %eax,%edi
f0101477:	fc                   	cld    
f0101478:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010147a:	eb 05                	jmp    f0101481 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010147c:	89 c7                	mov    %eax,%edi
f010147e:	fc                   	cld    
f010147f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101481:	5e                   	pop    %esi
f0101482:	5f                   	pop    %edi
f0101483:	5d                   	pop    %ebp
f0101484:	c3                   	ret    

f0101485 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101485:	55                   	push   %ebp
f0101486:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101488:	ff 75 10             	pushl  0x10(%ebp)
f010148b:	ff 75 0c             	pushl  0xc(%ebp)
f010148e:	ff 75 08             	pushl  0x8(%ebp)
f0101491:	e8 87 ff ff ff       	call   f010141d <memmove>
}
f0101496:	c9                   	leave  
f0101497:	c3                   	ret    

f0101498 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101498:	55                   	push   %ebp
f0101499:	89 e5                	mov    %esp,%ebp
f010149b:	56                   	push   %esi
f010149c:	53                   	push   %ebx
f010149d:	8b 45 08             	mov    0x8(%ebp),%eax
f01014a0:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014a3:	89 c6                	mov    %eax,%esi
f01014a5:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01014a8:	eb 1a                	jmp    f01014c4 <memcmp+0x2c>
		if (*s1 != *s2)
f01014aa:	0f b6 08             	movzbl (%eax),%ecx
f01014ad:	0f b6 1a             	movzbl (%edx),%ebx
f01014b0:	38 d9                	cmp    %bl,%cl
f01014b2:	74 0a                	je     f01014be <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01014b4:	0f b6 c1             	movzbl %cl,%eax
f01014b7:	0f b6 db             	movzbl %bl,%ebx
f01014ba:	29 d8                	sub    %ebx,%eax
f01014bc:	eb 0f                	jmp    f01014cd <memcmp+0x35>
		s1++, s2++;
f01014be:	83 c0 01             	add    $0x1,%eax
f01014c1:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01014c4:	39 f0                	cmp    %esi,%eax
f01014c6:	75 e2                	jne    f01014aa <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01014c8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014cd:	5b                   	pop    %ebx
f01014ce:	5e                   	pop    %esi
f01014cf:	5d                   	pop    %ebp
f01014d0:	c3                   	ret    

f01014d1 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01014d1:	55                   	push   %ebp
f01014d2:	89 e5                	mov    %esp,%ebp
f01014d4:	53                   	push   %ebx
f01014d5:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01014d8:	89 c1                	mov    %eax,%ecx
f01014da:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01014dd:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01014e1:	eb 0a                	jmp    f01014ed <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01014e3:	0f b6 10             	movzbl (%eax),%edx
f01014e6:	39 da                	cmp    %ebx,%edx
f01014e8:	74 07                	je     f01014f1 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01014ea:	83 c0 01             	add    $0x1,%eax
f01014ed:	39 c8                	cmp    %ecx,%eax
f01014ef:	72 f2                	jb     f01014e3 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01014f1:	5b                   	pop    %ebx
f01014f2:	5d                   	pop    %ebp
f01014f3:	c3                   	ret    

f01014f4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01014f4:	55                   	push   %ebp
f01014f5:	89 e5                	mov    %esp,%ebp
f01014f7:	57                   	push   %edi
f01014f8:	56                   	push   %esi
f01014f9:	53                   	push   %ebx
f01014fa:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014fd:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101500:	eb 03                	jmp    f0101505 <strtol+0x11>
		s++;
f0101502:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101505:	0f b6 01             	movzbl (%ecx),%eax
f0101508:	3c 20                	cmp    $0x20,%al
f010150a:	74 f6                	je     f0101502 <strtol+0xe>
f010150c:	3c 09                	cmp    $0x9,%al
f010150e:	74 f2                	je     f0101502 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101510:	3c 2b                	cmp    $0x2b,%al
f0101512:	75 0a                	jne    f010151e <strtol+0x2a>
		s++;
f0101514:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101517:	bf 00 00 00 00       	mov    $0x0,%edi
f010151c:	eb 11                	jmp    f010152f <strtol+0x3b>
f010151e:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101523:	3c 2d                	cmp    $0x2d,%al
f0101525:	75 08                	jne    f010152f <strtol+0x3b>
		s++, neg = 1;
f0101527:	83 c1 01             	add    $0x1,%ecx
f010152a:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010152f:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101535:	75 15                	jne    f010154c <strtol+0x58>
f0101537:	80 39 30             	cmpb   $0x30,(%ecx)
f010153a:	75 10                	jne    f010154c <strtol+0x58>
f010153c:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101540:	75 7c                	jne    f01015be <strtol+0xca>
		s += 2, base = 16;
f0101542:	83 c1 02             	add    $0x2,%ecx
f0101545:	bb 10 00 00 00       	mov    $0x10,%ebx
f010154a:	eb 16                	jmp    f0101562 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010154c:	85 db                	test   %ebx,%ebx
f010154e:	75 12                	jne    f0101562 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101550:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101555:	80 39 30             	cmpb   $0x30,(%ecx)
f0101558:	75 08                	jne    f0101562 <strtol+0x6e>
		s++, base = 8;
f010155a:	83 c1 01             	add    $0x1,%ecx
f010155d:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0101562:	b8 00 00 00 00       	mov    $0x0,%eax
f0101567:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010156a:	0f b6 11             	movzbl (%ecx),%edx
f010156d:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101570:	89 f3                	mov    %esi,%ebx
f0101572:	80 fb 09             	cmp    $0x9,%bl
f0101575:	77 08                	ja     f010157f <strtol+0x8b>
			dig = *s - '0';
f0101577:	0f be d2             	movsbl %dl,%edx
f010157a:	83 ea 30             	sub    $0x30,%edx
f010157d:	eb 22                	jmp    f01015a1 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010157f:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101582:	89 f3                	mov    %esi,%ebx
f0101584:	80 fb 19             	cmp    $0x19,%bl
f0101587:	77 08                	ja     f0101591 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0101589:	0f be d2             	movsbl %dl,%edx
f010158c:	83 ea 57             	sub    $0x57,%edx
f010158f:	eb 10                	jmp    f01015a1 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0101591:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101594:	89 f3                	mov    %esi,%ebx
f0101596:	80 fb 19             	cmp    $0x19,%bl
f0101599:	77 16                	ja     f01015b1 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010159b:	0f be d2             	movsbl %dl,%edx
f010159e:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01015a1:	3b 55 10             	cmp    0x10(%ebp),%edx
f01015a4:	7d 0b                	jge    f01015b1 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01015a6:	83 c1 01             	add    $0x1,%ecx
f01015a9:	0f af 45 10          	imul   0x10(%ebp),%eax
f01015ad:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01015af:	eb b9                	jmp    f010156a <strtol+0x76>

	if (endptr)
f01015b1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01015b5:	74 0d                	je     f01015c4 <strtol+0xd0>
		*endptr = (char *) s;
f01015b7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015ba:	89 0e                	mov    %ecx,(%esi)
f01015bc:	eb 06                	jmp    f01015c4 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01015be:	85 db                	test   %ebx,%ebx
f01015c0:	74 98                	je     f010155a <strtol+0x66>
f01015c2:	eb 9e                	jmp    f0101562 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01015c4:	89 c2                	mov    %eax,%edx
f01015c6:	f7 da                	neg    %edx
f01015c8:	85 ff                	test   %edi,%edi
f01015ca:	0f 45 c2             	cmovne %edx,%eax
}
f01015cd:	5b                   	pop    %ebx
f01015ce:	5e                   	pop    %esi
f01015cf:	5f                   	pop    %edi
f01015d0:	5d                   	pop    %ebp
f01015d1:	c3                   	ret    
f01015d2:	66 90                	xchg   %ax,%ax
f01015d4:	66 90                	xchg   %ax,%ax
f01015d6:	66 90                	xchg   %ax,%ax
f01015d8:	66 90                	xchg   %ax,%ax
f01015da:	66 90                	xchg   %ax,%ax
f01015dc:	66 90                	xchg   %ax,%ax
f01015de:	66 90                	xchg   %ax,%ax

f01015e0 <__udivdi3>:
f01015e0:	55                   	push   %ebp
f01015e1:	57                   	push   %edi
f01015e2:	56                   	push   %esi
f01015e3:	53                   	push   %ebx
f01015e4:	83 ec 1c             	sub    $0x1c,%esp
f01015e7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01015eb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01015ef:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01015f3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01015f7:	85 f6                	test   %esi,%esi
f01015f9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01015fd:	89 ca                	mov    %ecx,%edx
f01015ff:	89 f8                	mov    %edi,%eax
f0101601:	75 3d                	jne    f0101640 <__udivdi3+0x60>
f0101603:	39 cf                	cmp    %ecx,%edi
f0101605:	0f 87 c5 00 00 00    	ja     f01016d0 <__udivdi3+0xf0>
f010160b:	85 ff                	test   %edi,%edi
f010160d:	89 fd                	mov    %edi,%ebp
f010160f:	75 0b                	jne    f010161c <__udivdi3+0x3c>
f0101611:	b8 01 00 00 00       	mov    $0x1,%eax
f0101616:	31 d2                	xor    %edx,%edx
f0101618:	f7 f7                	div    %edi
f010161a:	89 c5                	mov    %eax,%ebp
f010161c:	89 c8                	mov    %ecx,%eax
f010161e:	31 d2                	xor    %edx,%edx
f0101620:	f7 f5                	div    %ebp
f0101622:	89 c1                	mov    %eax,%ecx
f0101624:	89 d8                	mov    %ebx,%eax
f0101626:	89 cf                	mov    %ecx,%edi
f0101628:	f7 f5                	div    %ebp
f010162a:	89 c3                	mov    %eax,%ebx
f010162c:	89 d8                	mov    %ebx,%eax
f010162e:	89 fa                	mov    %edi,%edx
f0101630:	83 c4 1c             	add    $0x1c,%esp
f0101633:	5b                   	pop    %ebx
f0101634:	5e                   	pop    %esi
f0101635:	5f                   	pop    %edi
f0101636:	5d                   	pop    %ebp
f0101637:	c3                   	ret    
f0101638:	90                   	nop
f0101639:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101640:	39 ce                	cmp    %ecx,%esi
f0101642:	77 74                	ja     f01016b8 <__udivdi3+0xd8>
f0101644:	0f bd fe             	bsr    %esi,%edi
f0101647:	83 f7 1f             	xor    $0x1f,%edi
f010164a:	0f 84 98 00 00 00    	je     f01016e8 <__udivdi3+0x108>
f0101650:	bb 20 00 00 00       	mov    $0x20,%ebx
f0101655:	89 f9                	mov    %edi,%ecx
f0101657:	89 c5                	mov    %eax,%ebp
f0101659:	29 fb                	sub    %edi,%ebx
f010165b:	d3 e6                	shl    %cl,%esi
f010165d:	89 d9                	mov    %ebx,%ecx
f010165f:	d3 ed                	shr    %cl,%ebp
f0101661:	89 f9                	mov    %edi,%ecx
f0101663:	d3 e0                	shl    %cl,%eax
f0101665:	09 ee                	or     %ebp,%esi
f0101667:	89 d9                	mov    %ebx,%ecx
f0101669:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010166d:	89 d5                	mov    %edx,%ebp
f010166f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101673:	d3 ed                	shr    %cl,%ebp
f0101675:	89 f9                	mov    %edi,%ecx
f0101677:	d3 e2                	shl    %cl,%edx
f0101679:	89 d9                	mov    %ebx,%ecx
f010167b:	d3 e8                	shr    %cl,%eax
f010167d:	09 c2                	or     %eax,%edx
f010167f:	89 d0                	mov    %edx,%eax
f0101681:	89 ea                	mov    %ebp,%edx
f0101683:	f7 f6                	div    %esi
f0101685:	89 d5                	mov    %edx,%ebp
f0101687:	89 c3                	mov    %eax,%ebx
f0101689:	f7 64 24 0c          	mull   0xc(%esp)
f010168d:	39 d5                	cmp    %edx,%ebp
f010168f:	72 10                	jb     f01016a1 <__udivdi3+0xc1>
f0101691:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101695:	89 f9                	mov    %edi,%ecx
f0101697:	d3 e6                	shl    %cl,%esi
f0101699:	39 c6                	cmp    %eax,%esi
f010169b:	73 07                	jae    f01016a4 <__udivdi3+0xc4>
f010169d:	39 d5                	cmp    %edx,%ebp
f010169f:	75 03                	jne    f01016a4 <__udivdi3+0xc4>
f01016a1:	83 eb 01             	sub    $0x1,%ebx
f01016a4:	31 ff                	xor    %edi,%edi
f01016a6:	89 d8                	mov    %ebx,%eax
f01016a8:	89 fa                	mov    %edi,%edx
f01016aa:	83 c4 1c             	add    $0x1c,%esp
f01016ad:	5b                   	pop    %ebx
f01016ae:	5e                   	pop    %esi
f01016af:	5f                   	pop    %edi
f01016b0:	5d                   	pop    %ebp
f01016b1:	c3                   	ret    
f01016b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01016b8:	31 ff                	xor    %edi,%edi
f01016ba:	31 db                	xor    %ebx,%ebx
f01016bc:	89 d8                	mov    %ebx,%eax
f01016be:	89 fa                	mov    %edi,%edx
f01016c0:	83 c4 1c             	add    $0x1c,%esp
f01016c3:	5b                   	pop    %ebx
f01016c4:	5e                   	pop    %esi
f01016c5:	5f                   	pop    %edi
f01016c6:	5d                   	pop    %ebp
f01016c7:	c3                   	ret    
f01016c8:	90                   	nop
f01016c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01016d0:	89 d8                	mov    %ebx,%eax
f01016d2:	f7 f7                	div    %edi
f01016d4:	31 ff                	xor    %edi,%edi
f01016d6:	89 c3                	mov    %eax,%ebx
f01016d8:	89 d8                	mov    %ebx,%eax
f01016da:	89 fa                	mov    %edi,%edx
f01016dc:	83 c4 1c             	add    $0x1c,%esp
f01016df:	5b                   	pop    %ebx
f01016e0:	5e                   	pop    %esi
f01016e1:	5f                   	pop    %edi
f01016e2:	5d                   	pop    %ebp
f01016e3:	c3                   	ret    
f01016e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01016e8:	39 ce                	cmp    %ecx,%esi
f01016ea:	72 0c                	jb     f01016f8 <__udivdi3+0x118>
f01016ec:	31 db                	xor    %ebx,%ebx
f01016ee:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01016f2:	0f 87 34 ff ff ff    	ja     f010162c <__udivdi3+0x4c>
f01016f8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01016fd:	e9 2a ff ff ff       	jmp    f010162c <__udivdi3+0x4c>
f0101702:	66 90                	xchg   %ax,%ax
f0101704:	66 90                	xchg   %ax,%ax
f0101706:	66 90                	xchg   %ax,%ax
f0101708:	66 90                	xchg   %ax,%ax
f010170a:	66 90                	xchg   %ax,%ax
f010170c:	66 90                	xchg   %ax,%ax
f010170e:	66 90                	xchg   %ax,%ax

f0101710 <__umoddi3>:
f0101710:	55                   	push   %ebp
f0101711:	57                   	push   %edi
f0101712:	56                   	push   %esi
f0101713:	53                   	push   %ebx
f0101714:	83 ec 1c             	sub    $0x1c,%esp
f0101717:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010171b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010171f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101723:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101727:	85 d2                	test   %edx,%edx
f0101729:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010172d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101731:	89 f3                	mov    %esi,%ebx
f0101733:	89 3c 24             	mov    %edi,(%esp)
f0101736:	89 74 24 04          	mov    %esi,0x4(%esp)
f010173a:	75 1c                	jne    f0101758 <__umoddi3+0x48>
f010173c:	39 f7                	cmp    %esi,%edi
f010173e:	76 50                	jbe    f0101790 <__umoddi3+0x80>
f0101740:	89 c8                	mov    %ecx,%eax
f0101742:	89 f2                	mov    %esi,%edx
f0101744:	f7 f7                	div    %edi
f0101746:	89 d0                	mov    %edx,%eax
f0101748:	31 d2                	xor    %edx,%edx
f010174a:	83 c4 1c             	add    $0x1c,%esp
f010174d:	5b                   	pop    %ebx
f010174e:	5e                   	pop    %esi
f010174f:	5f                   	pop    %edi
f0101750:	5d                   	pop    %ebp
f0101751:	c3                   	ret    
f0101752:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101758:	39 f2                	cmp    %esi,%edx
f010175a:	89 d0                	mov    %edx,%eax
f010175c:	77 52                	ja     f01017b0 <__umoddi3+0xa0>
f010175e:	0f bd ea             	bsr    %edx,%ebp
f0101761:	83 f5 1f             	xor    $0x1f,%ebp
f0101764:	75 5a                	jne    f01017c0 <__umoddi3+0xb0>
f0101766:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010176a:	0f 82 e0 00 00 00    	jb     f0101850 <__umoddi3+0x140>
f0101770:	39 0c 24             	cmp    %ecx,(%esp)
f0101773:	0f 86 d7 00 00 00    	jbe    f0101850 <__umoddi3+0x140>
f0101779:	8b 44 24 08          	mov    0x8(%esp),%eax
f010177d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101781:	83 c4 1c             	add    $0x1c,%esp
f0101784:	5b                   	pop    %ebx
f0101785:	5e                   	pop    %esi
f0101786:	5f                   	pop    %edi
f0101787:	5d                   	pop    %ebp
f0101788:	c3                   	ret    
f0101789:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101790:	85 ff                	test   %edi,%edi
f0101792:	89 fd                	mov    %edi,%ebp
f0101794:	75 0b                	jne    f01017a1 <__umoddi3+0x91>
f0101796:	b8 01 00 00 00       	mov    $0x1,%eax
f010179b:	31 d2                	xor    %edx,%edx
f010179d:	f7 f7                	div    %edi
f010179f:	89 c5                	mov    %eax,%ebp
f01017a1:	89 f0                	mov    %esi,%eax
f01017a3:	31 d2                	xor    %edx,%edx
f01017a5:	f7 f5                	div    %ebp
f01017a7:	89 c8                	mov    %ecx,%eax
f01017a9:	f7 f5                	div    %ebp
f01017ab:	89 d0                	mov    %edx,%eax
f01017ad:	eb 99                	jmp    f0101748 <__umoddi3+0x38>
f01017af:	90                   	nop
f01017b0:	89 c8                	mov    %ecx,%eax
f01017b2:	89 f2                	mov    %esi,%edx
f01017b4:	83 c4 1c             	add    $0x1c,%esp
f01017b7:	5b                   	pop    %ebx
f01017b8:	5e                   	pop    %esi
f01017b9:	5f                   	pop    %edi
f01017ba:	5d                   	pop    %ebp
f01017bb:	c3                   	ret    
f01017bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017c0:	8b 34 24             	mov    (%esp),%esi
f01017c3:	bf 20 00 00 00       	mov    $0x20,%edi
f01017c8:	89 e9                	mov    %ebp,%ecx
f01017ca:	29 ef                	sub    %ebp,%edi
f01017cc:	d3 e0                	shl    %cl,%eax
f01017ce:	89 f9                	mov    %edi,%ecx
f01017d0:	89 f2                	mov    %esi,%edx
f01017d2:	d3 ea                	shr    %cl,%edx
f01017d4:	89 e9                	mov    %ebp,%ecx
f01017d6:	09 c2                	or     %eax,%edx
f01017d8:	89 d8                	mov    %ebx,%eax
f01017da:	89 14 24             	mov    %edx,(%esp)
f01017dd:	89 f2                	mov    %esi,%edx
f01017df:	d3 e2                	shl    %cl,%edx
f01017e1:	89 f9                	mov    %edi,%ecx
f01017e3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01017e7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01017eb:	d3 e8                	shr    %cl,%eax
f01017ed:	89 e9                	mov    %ebp,%ecx
f01017ef:	89 c6                	mov    %eax,%esi
f01017f1:	d3 e3                	shl    %cl,%ebx
f01017f3:	89 f9                	mov    %edi,%ecx
f01017f5:	89 d0                	mov    %edx,%eax
f01017f7:	d3 e8                	shr    %cl,%eax
f01017f9:	89 e9                	mov    %ebp,%ecx
f01017fb:	09 d8                	or     %ebx,%eax
f01017fd:	89 d3                	mov    %edx,%ebx
f01017ff:	89 f2                	mov    %esi,%edx
f0101801:	f7 34 24             	divl   (%esp)
f0101804:	89 d6                	mov    %edx,%esi
f0101806:	d3 e3                	shl    %cl,%ebx
f0101808:	f7 64 24 04          	mull   0x4(%esp)
f010180c:	39 d6                	cmp    %edx,%esi
f010180e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101812:	89 d1                	mov    %edx,%ecx
f0101814:	89 c3                	mov    %eax,%ebx
f0101816:	72 08                	jb     f0101820 <__umoddi3+0x110>
f0101818:	75 11                	jne    f010182b <__umoddi3+0x11b>
f010181a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010181e:	73 0b                	jae    f010182b <__umoddi3+0x11b>
f0101820:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101824:	1b 14 24             	sbb    (%esp),%edx
f0101827:	89 d1                	mov    %edx,%ecx
f0101829:	89 c3                	mov    %eax,%ebx
f010182b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010182f:	29 da                	sub    %ebx,%edx
f0101831:	19 ce                	sbb    %ecx,%esi
f0101833:	89 f9                	mov    %edi,%ecx
f0101835:	89 f0                	mov    %esi,%eax
f0101837:	d3 e0                	shl    %cl,%eax
f0101839:	89 e9                	mov    %ebp,%ecx
f010183b:	d3 ea                	shr    %cl,%edx
f010183d:	89 e9                	mov    %ebp,%ecx
f010183f:	d3 ee                	shr    %cl,%esi
f0101841:	09 d0                	or     %edx,%eax
f0101843:	89 f2                	mov    %esi,%edx
f0101845:	83 c4 1c             	add    $0x1c,%esp
f0101848:	5b                   	pop    %ebx
f0101849:	5e                   	pop    %esi
f010184a:	5f                   	pop    %edi
f010184b:	5d                   	pop    %ebp
f010184c:	c3                   	ret    
f010184d:	8d 76 00             	lea    0x0(%esi),%esi
f0101850:	29 f9                	sub    %edi,%ecx
f0101852:	19 d6                	sbb    %edx,%esi
f0101854:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101858:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010185c:	e9 18 ff ff ff       	jmp    f0101779 <__umoddi3+0x69>
