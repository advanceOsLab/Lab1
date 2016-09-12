
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
f010000b:	e4 66                	in     $0x66,%al

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
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 c0 19 10 f0 	movl   $0xf01019c0,(%esp)
f0100055:	e8 34 09 00 00       	call   f010098e <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(1, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100082:	e8 08 07 00 00       	call   f010078f <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 dc 19 10 f0 	movl   $0xf01019dc,(%esp)
f0100092:	e8 f7 08 00 00       	call   f010098e <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 62 14 00 00       	call   f0101527 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 95 04 00 00       	call   f010055f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 f7 19 10 f0 	movl   $0xf01019f7,(%esp)
f01000d9:	e8 b0 08 00 00       	call   f010098e <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 10 07 00 00       	call   f0100806 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 12 1a 10 f0 	movl   $0xf0101a12,(%esp)
f010012c:	e8 5d 08 00 00       	call   f010098e <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 1e 08 00 00       	call   f010095b <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 fe 1c 10 f0 	movl   $0xf0101cfe,(%esp)
f0100144:	e8 45 08 00 00       	call   f010098e <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 b1 06 00 00       	call   f0100806 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 2a 1a 10 f0 	movl   $0xf0101a2a,(%esp)
f0100176:	e8 13 08 00 00       	call   f010098e <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 d1 07 00 00       	call   f010095b <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 fe 1c 10 f0 	movl   $0xf0101cfe,(%esp)
f0100191:	e8 f8 07 00 00       	call   f010098e <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 24 25 11 f0    	mov    %ecx,0xf0112524
f01001d9:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 ef 00 00 00    	je     f01002fd <kbd_proc_data+0xfd>
f010020e:	b2 60                	mov    $0x60,%dl
f0100210:	ec                   	in     (%dx),%al
f0100211:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100213:	3c e0                	cmp    $0xe0,%al
f0100215:	75 0d                	jne    f0100224 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100217:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f010021e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100223:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100224:	55                   	push   %ebp
f0100225:	89 e5                	mov    %esp,%ebp
f0100227:	53                   	push   %ebx
f0100228:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010022b:	84 c0                	test   %al,%al
f010022d:	79 37                	jns    f0100266 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010022f:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100235:	89 cb                	mov    %ecx,%ebx
f0100237:	83 e3 40             	and    $0x40,%ebx
f010023a:	83 e0 7f             	and    $0x7f,%eax
f010023d:	85 db                	test   %ebx,%ebx
f010023f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100242:	0f b6 d2             	movzbl %dl,%edx
f0100245:	0f b6 82 a0 1b 10 f0 	movzbl -0xfefe460(%edx),%eax
f010024c:	83 c8 40             	or     $0x40,%eax
f010024f:	0f b6 c0             	movzbl %al,%eax
f0100252:	f7 d0                	not    %eax
f0100254:	21 c1                	and    %eax,%ecx
f0100256:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
		return 0;
f010025c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100261:	e9 9d 00 00 00       	jmp    f0100303 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100266:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010026c:	f6 c1 40             	test   $0x40,%cl
f010026f:	74 0e                	je     f010027f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100271:	83 c8 80             	or     $0xffffff80,%eax
f0100274:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100276:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100279:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010027f:	0f b6 d2             	movzbl %dl,%edx
f0100282:	0f b6 82 a0 1b 10 f0 	movzbl -0xfefe460(%edx),%eax
f0100289:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f010028f:	0f b6 8a a0 1a 10 f0 	movzbl -0xfefe560(%edx),%ecx
f0100296:	31 c8                	xor    %ecx,%eax
f0100298:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f010029d:	89 c1                	mov    %eax,%ecx
f010029f:	83 e1 03             	and    $0x3,%ecx
f01002a2:	8b 0c 8d 80 1a 10 f0 	mov    -0xfefe580(,%ecx,4),%ecx
f01002a9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002ad:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b0:	a8 08                	test   $0x8,%al
f01002b2:	74 1b                	je     f01002cf <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01002b4:	89 da                	mov    %ebx,%edx
f01002b6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002b9:	83 f9 19             	cmp    $0x19,%ecx
f01002bc:	77 05                	ja     f01002c3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01002be:	83 eb 20             	sub    $0x20,%ebx
f01002c1:	eb 0c                	jmp    f01002cf <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01002c3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002c6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002c9:	83 fa 19             	cmp    $0x19,%edx
f01002cc:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002cf:	f7 d0                	not    %eax
f01002d1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d5:	f6 c2 06             	test   $0x6,%dl
f01002d8:	75 29                	jne    f0100303 <kbd_proc_data+0x103>
f01002da:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e0:	75 21                	jne    f0100303 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002e2:	c7 04 24 44 1a 10 f0 	movl   $0xf0101a44,(%esp)
f01002e9:	e8 a0 06 00 00       	call   f010098e <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ee:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f9:	89 d8                	mov    %ebx,%eax
f01002fb:	eb 06                	jmp    f0100303 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100302:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100303:	83 c4 14             	add    $0x14,%esp
f0100306:	5b                   	pop    %ebx
f0100307:	5d                   	pop    %ebp
f0100308:	c3                   	ret    

f0100309 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100309:	55                   	push   %ebp
f010030a:	89 e5                	mov    %esp,%ebp
f010030c:	57                   	push   %edi
f010030d:	56                   	push   %esi
f010030e:	53                   	push   %ebx
f010030f:	83 ec 1c             	sub    $0x1c,%esp
f0100312:	89 c7                	mov    %eax,%edi
f0100314:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100319:	be fd 03 00 00       	mov    $0x3fd,%esi
f010031e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100323:	eb 06                	jmp    f010032b <cons_putc+0x22>
f0100325:	89 ca                	mov    %ecx,%edx
f0100327:	ec                   	in     (%dx),%al
f0100328:	ec                   	in     (%dx),%al
f0100329:	ec                   	in     (%dx),%al
f010032a:	ec                   	in     (%dx),%al
f010032b:	89 f2                	mov    %esi,%edx
f010032d:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010032e:	a8 20                	test   $0x20,%al
f0100330:	75 05                	jne    f0100337 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100332:	83 eb 01             	sub    $0x1,%ebx
f0100335:	75 ee                	jne    f0100325 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100337:	89 f8                	mov    %edi,%eax
f0100339:	0f b6 c0             	movzbl %al,%eax
f010033c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010033f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100344:	ee                   	out    %al,(%dx)
f0100345:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010034a:	be 79 03 00 00       	mov    $0x379,%esi
f010034f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100354:	eb 06                	jmp    f010035c <cons_putc+0x53>
f0100356:	89 ca                	mov    %ecx,%edx
f0100358:	ec                   	in     (%dx),%al
f0100359:	ec                   	in     (%dx),%al
f010035a:	ec                   	in     (%dx),%al
f010035b:	ec                   	in     (%dx),%al
f010035c:	89 f2                	mov    %esi,%edx
f010035e:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010035f:	84 c0                	test   %al,%al
f0100361:	78 05                	js     f0100368 <cons_putc+0x5f>
f0100363:	83 eb 01             	sub    $0x1,%ebx
f0100366:	75 ee                	jne    f0100356 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100368:	ba 78 03 00 00       	mov    $0x378,%edx
f010036d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100371:	ee                   	out    %al,(%dx)
f0100372:	b2 7a                	mov    $0x7a,%dl
f0100374:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100379:	ee                   	out    %al,(%dx)
f010037a:	b8 08 00 00 00       	mov    $0x8,%eax
f010037f:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100380:	89 fa                	mov    %edi,%edx
f0100382:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100388:	89 f8                	mov    %edi,%eax
f010038a:	80 cc 07             	or     $0x7,%ah
f010038d:	85 d2                	test   %edx,%edx
f010038f:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100392:	89 f8                	mov    %edi,%eax
f0100394:	0f b6 c0             	movzbl %al,%eax
f0100397:	83 f8 09             	cmp    $0x9,%eax
f010039a:	74 76                	je     f0100412 <cons_putc+0x109>
f010039c:	83 f8 09             	cmp    $0x9,%eax
f010039f:	7f 0a                	jg     f01003ab <cons_putc+0xa2>
f01003a1:	83 f8 08             	cmp    $0x8,%eax
f01003a4:	74 16                	je     f01003bc <cons_putc+0xb3>
f01003a6:	e9 9b 00 00 00       	jmp    f0100446 <cons_putc+0x13d>
f01003ab:	83 f8 0a             	cmp    $0xa,%eax
f01003ae:	66 90                	xchg   %ax,%ax
f01003b0:	74 3a                	je     f01003ec <cons_putc+0xe3>
f01003b2:	83 f8 0d             	cmp    $0xd,%eax
f01003b5:	74 3d                	je     f01003f4 <cons_putc+0xeb>
f01003b7:	e9 8a 00 00 00       	jmp    f0100446 <cons_putc+0x13d>
	case '\b':
		if (crt_pos > 0) {
f01003bc:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003c3:	66 85 c0             	test   %ax,%ax
f01003c6:	0f 84 e5 00 00 00    	je     f01004b1 <cons_putc+0x1a8>
			crt_pos--;
f01003cc:	83 e8 01             	sub    $0x1,%eax
f01003cf:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003d5:	0f b7 c0             	movzwl %ax,%eax
f01003d8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003dd:	83 cf 20             	or     $0x20,%edi
f01003e0:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003e6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003ea:	eb 78                	jmp    f0100464 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003ec:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003f3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003f4:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003fb:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100401:	c1 e8 16             	shr    $0x16,%eax
f0100404:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100407:	c1 e0 04             	shl    $0x4,%eax
f010040a:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100410:	eb 52                	jmp    f0100464 <cons_putc+0x15b>
		break;
	case '\t':
		cons_putc(' ');
f0100412:	b8 20 00 00 00       	mov    $0x20,%eax
f0100417:	e8 ed fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010041c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100421:	e8 e3 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100426:	b8 20 00 00 00       	mov    $0x20,%eax
f010042b:	e8 d9 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100430:	b8 20 00 00 00       	mov    $0x20,%eax
f0100435:	e8 cf fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010043a:	b8 20 00 00 00       	mov    $0x20,%eax
f010043f:	e8 c5 fe ff ff       	call   f0100309 <cons_putc>
f0100444:	eb 1e                	jmp    f0100464 <cons_putc+0x15b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100446:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010044d:	8d 50 01             	lea    0x1(%eax),%edx
f0100450:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f0100457:	0f b7 c0             	movzwl %ax,%eax
f010045a:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100460:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100464:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010046b:	cf 07 
f010046d:	76 42                	jbe    f01004b1 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010046f:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100474:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010047b:	00 
f010047c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100482:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100486:	89 04 24             	mov    %eax,(%esp)
f0100489:	e8 e6 10 00 00       	call   f0101574 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010048e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100494:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100499:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010049f:	83 c0 01             	add    $0x1,%eax
f01004a2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004a7:	75 f0                	jne    f0100499 <cons_putc+0x190>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004a9:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004b0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004b1:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004b7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004bc:	89 ca                	mov    %ecx,%edx
f01004be:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004bf:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004c6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004c9:	89 d8                	mov    %ebx,%eax
f01004cb:	66 c1 e8 08          	shr    $0x8,%ax
f01004cf:	89 f2                	mov    %esi,%edx
f01004d1:	ee                   	out    %al,(%dx)
f01004d2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004d7:	89 ca                	mov    %ecx,%edx
f01004d9:	ee                   	out    %al,(%dx)
f01004da:	89 d8                	mov    %ebx,%eax
f01004dc:	89 f2                	mov    %esi,%edx
f01004de:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004df:	83 c4 1c             	add    $0x1c,%esp
f01004e2:	5b                   	pop    %ebx
f01004e3:	5e                   	pop    %esi
f01004e4:	5f                   	pop    %edi
f01004e5:	5d                   	pop    %ebp
f01004e6:	c3                   	ret    

f01004e7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004e7:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004ee:	74 11                	je     f0100501 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004f0:	55                   	push   %ebp
f01004f1:	89 e5                	mov    %esp,%ebp
f01004f3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004f6:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004fb:	e8 bc fc ff ff       	call   f01001bc <cons_intr>
}
f0100500:	c9                   	leave  
f0100501:	f3 c3                	repz ret 

f0100503 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100503:	55                   	push   %ebp
f0100504:	89 e5                	mov    %esp,%ebp
f0100506:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100509:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f010050e:	e8 a9 fc ff ff       	call   f01001bc <cons_intr>
}
f0100513:	c9                   	leave  
f0100514:	c3                   	ret    

f0100515 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100515:	55                   	push   %ebp
f0100516:	89 e5                	mov    %esp,%ebp
f0100518:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010051b:	e8 c7 ff ff ff       	call   f01004e7 <serial_intr>
	kbd_intr();
f0100520:	e8 de ff ff ff       	call   f0100503 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100525:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010052a:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100530:	74 26                	je     f0100558 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100532:	8d 50 01             	lea    0x1(%eax),%edx
f0100535:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010053b:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100542:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100544:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010054a:	75 11                	jne    f010055d <cons_getc+0x48>
			cons.rpos = 0;
f010054c:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100553:	00 00 00 
f0100556:	eb 05                	jmp    f010055d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100558:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010055d:	c9                   	leave  
f010055e:	c3                   	ret    

f010055f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010055f:	55                   	push   %ebp
f0100560:	89 e5                	mov    %esp,%ebp
f0100562:	57                   	push   %edi
f0100563:	56                   	push   %esi
f0100564:	53                   	push   %ebx
f0100565:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100568:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010056f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100576:	5a a5 
	if (*cp != 0xA55A) {
f0100578:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010057f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100583:	74 11                	je     f0100596 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100585:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f010058c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010058f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100594:	eb 16                	jmp    f01005ac <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100596:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010059d:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005a4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005a7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005ac:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01005b2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005b7:	89 ca                	mov    %ecx,%edx
f01005b9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ba:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005bd:	89 da                	mov    %ebx,%edx
f01005bf:	ec                   	in     (%dx),%al
f01005c0:	0f b6 f0             	movzbl %al,%esi
f01005c3:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005cb:	89 ca                	mov    %ecx,%edx
f01005cd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ce:	89 da                	mov    %ebx,%edx
f01005d0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005d1:	89 3d 2c 25 11 f0    	mov    %edi,0xf011252c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005d7:	0f b6 d8             	movzbl %al,%ebx
f01005da:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005dc:	66 89 35 28 25 11 f0 	mov    %si,0xf0112528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005e3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005e8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ed:	89 f2                	mov    %esi,%edx
f01005ef:	ee                   	out    %al,(%dx)
f01005f0:	b2 fb                	mov    $0xfb,%dl
f01005f2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005fd:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100602:	89 da                	mov    %ebx,%edx
f0100604:	ee                   	out    %al,(%dx)
f0100605:	b2 f9                	mov    $0xf9,%dl
f0100607:	b8 00 00 00 00       	mov    $0x0,%eax
f010060c:	ee                   	out    %al,(%dx)
f010060d:	b2 fb                	mov    $0xfb,%dl
f010060f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 fc                	mov    $0xfc,%dl
f0100617:	b8 00 00 00 00       	mov    $0x0,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 f9                	mov    $0xf9,%dl
f010061f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100624:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100625:	b2 fd                	mov    $0xfd,%dl
f0100627:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100628:	3c ff                	cmp    $0xff,%al
f010062a:	0f 95 c1             	setne  %cl
f010062d:	88 0d 34 25 11 f0    	mov    %cl,0xf0112534
f0100633:	89 f2                	mov    %esi,%edx
f0100635:	ec                   	in     (%dx),%al
f0100636:	89 da                	mov    %ebx,%edx
f0100638:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100639:	84 c9                	test   %cl,%cl
f010063b:	75 0c                	jne    f0100649 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010063d:	c7 04 24 50 1a 10 f0 	movl   $0xf0101a50,(%esp)
f0100644:	e8 45 03 00 00       	call   f010098e <cprintf>
}
f0100649:	83 c4 1c             	add    $0x1c,%esp
f010064c:	5b                   	pop    %ebx
f010064d:	5e                   	pop    %esi
f010064e:	5f                   	pop    %edi
f010064f:	5d                   	pop    %ebp
f0100650:	c3                   	ret    

f0100651 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100651:	55                   	push   %ebp
f0100652:	89 e5                	mov    %esp,%ebp
f0100654:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100657:	8b 45 08             	mov    0x8(%ebp),%eax
f010065a:	e8 aa fc ff ff       	call   f0100309 <cons_putc>
}
f010065f:	c9                   	leave  
f0100660:	c3                   	ret    

f0100661 <getchar>:

int
getchar(void)
{
f0100661:	55                   	push   %ebp
f0100662:	89 e5                	mov    %esp,%ebp
f0100664:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100667:	e8 a9 fe ff ff       	call   f0100515 <cons_getc>
f010066c:	85 c0                	test   %eax,%eax
f010066e:	74 f7                	je     f0100667 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100670:	c9                   	leave  
f0100671:	c3                   	ret    

f0100672 <iscons>:

int
iscons(int fdnum)
{
f0100672:	55                   	push   %ebp
f0100673:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100675:	b8 01 00 00 00       	mov    $0x1,%eax
f010067a:	5d                   	pop    %ebp
f010067b:	c3                   	ret    
f010067c:	66 90                	xchg   %ax,%ax
f010067e:	66 90                	xchg   %ax,%ax

f0100680 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100686:	c7 44 24 08 a0 1c 10 	movl   $0xf0101ca0,0x8(%esp)
f010068d:	f0 
f010068e:	c7 44 24 04 be 1c 10 	movl   $0xf0101cbe,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 c3 1c 10 f0 	movl   $0xf0101cc3,(%esp)
f010069d:	e8 ec 02 00 00       	call   f010098e <cprintf>
f01006a2:	c7 44 24 08 3c 1d 10 	movl   $0xf0101d3c,0x8(%esp)
f01006a9:	f0 
f01006aa:	c7 44 24 04 cc 1c 10 	movl   $0xf0101ccc,0x4(%esp)
f01006b1:	f0 
f01006b2:	c7 04 24 c3 1c 10 f0 	movl   $0xf0101cc3,(%esp)
f01006b9:	e8 d0 02 00 00       	call   f010098e <cprintf>
	return 0;
}
f01006be:	b8 00 00 00 00       	mov    $0x0,%eax
f01006c3:	c9                   	leave  
f01006c4:	c3                   	ret    

f01006c5 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006c5:	55                   	push   %ebp
f01006c6:	89 e5                	mov    %esp,%ebp
f01006c8:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006cb:	c7 04 24 d5 1c 10 f0 	movl   $0xf0101cd5,(%esp)
f01006d2:	e8 b7 02 00 00       	call   f010098e <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006d7:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006de:	00 
f01006df:	c7 04 24 64 1d 10 f0 	movl   $0xf0101d64,(%esp)
f01006e6:	e8 a3 02 00 00       	call   f010098e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006eb:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006f2:	00 
f01006f3:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006fa:	f0 
f01006fb:	c7 04 24 8c 1d 10 f0 	movl   $0xf0101d8c,(%esp)
f0100702:	e8 87 02 00 00       	call   f010098e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100707:	c7 44 24 08 b7 19 10 	movl   $0x1019b7,0x8(%esp)
f010070e:	00 
f010070f:	c7 44 24 04 b7 19 10 	movl   $0xf01019b7,0x4(%esp)
f0100716:	f0 
f0100717:	c7 04 24 b0 1d 10 f0 	movl   $0xf0101db0,(%esp)
f010071e:	e8 6b 02 00 00       	call   f010098e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100723:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f010072a:	00 
f010072b:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f0100732:	f0 
f0100733:	c7 04 24 d4 1d 10 f0 	movl   $0xf0101dd4,(%esp)
f010073a:	e8 4f 02 00 00       	call   f010098e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010073f:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100746:	00 
f0100747:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f010074e:	f0 
f010074f:	c7 04 24 f8 1d 10 f0 	movl   $0xf0101df8,(%esp)
f0100756:	e8 33 02 00 00       	call   f010098e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010075b:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f0100760:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100765:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010076a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100770:	85 c0                	test   %eax,%eax
f0100772:	0f 48 c2             	cmovs  %edx,%eax
f0100775:	c1 f8 0a             	sar    $0xa,%eax
f0100778:	89 44 24 04          	mov    %eax,0x4(%esp)
f010077c:	c7 04 24 1c 1e 10 f0 	movl   $0xf0101e1c,(%esp)
f0100783:	e8 06 02 00 00       	call   f010098e <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100788:	b8 00 00 00 00       	mov    $0x0,%eax
f010078d:	c9                   	leave  
f010078e:	c3                   	ret    

f010078f <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010078f:	55                   	push   %ebp
f0100790:	89 e5                	mov    %esp,%ebp
f0100792:	56                   	push   %esi
f0100793:	53                   	push   %ebx
f0100794:	83 ec 40             	sub    $0x40,%esp
	uint32_t ebpr = 1;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebpr));
	uint32_t *ptr = (uint32_t*)ebpr ;
f0100797:	89 eb                	mov    %ebp,%ebx
	
	//__asm __volatile("movl %%ebp,%0" : "=r" (ebpr));
	//ptr= (uint32_t*)ebpr;	
	cprintf("EBPR :%08x  ,EIP %08x  ,args:  %08x , %08x \n",ptr,*(ptr+1),*(ptr+2),*(ptr+3));
	address	= *(ptr+1);
	debuginfo_eip(address, &eipinfo);
f0100799:	8d 75 e0             	lea    -0x20(%ebp),%esi
	__asm __volatile("movl %%ebp,%0" : "=r" (ebpr));
	uint32_t *ptr = (uint32_t*)ebpr ;
	uint32_t *temp;
	uint32_t address;
	struct Eipdebuginfo eipinfo;
	while(*ptr!=0)
f010079c:	eb 57                	jmp    f01007f5 <mon_backtrace+0x66>
	{
	
	//__asm __volatile("movl %%ebp,%0" : "=r" (ebpr));
	//ptr= (uint32_t*)ebpr;	
	cprintf("EBPR :%08x  ,EIP %08x  ,args:  %08x , %08x \n",ptr,*(ptr+1),*(ptr+2),*(ptr+3));
f010079e:	8b 43 0c             	mov    0xc(%ebx),%eax
f01007a1:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007a5:	8b 43 08             	mov    0x8(%ebx),%eax
f01007a8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007ac:	8b 43 04             	mov    0x4(%ebx),%eax
f01007af:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007b3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01007b7:	c7 04 24 48 1e 10 f0 	movl   $0xf0101e48,(%esp)
f01007be:	e8 cb 01 00 00       	call   f010098e <cprintf>
	address	= *(ptr+1);
	debuginfo_eip(address, &eipinfo);
f01007c3:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007c7:	8b 43 04             	mov    0x4(%ebx),%eax
f01007ca:	89 04 24             	mov    %eax,(%esp)
f01007cd:	e8 b3 02 00 00       	call   f0100a85 <debuginfo_eip>
	cprintf("%s  , %d  ,  %s \n",eipinfo.eip_file,eipinfo.eip_line,eipinfo.eip_fn_name);
f01007d2:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01007d5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007d9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01007dc:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007e0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01007e3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007e7:	c7 04 24 ee 1c 10 f0 	movl   $0xf0101cee,(%esp)
f01007ee:	e8 9b 01 00 00       	call   f010098e <cprintf>
	temp = ptr;
	ptr = (uint32_t*) *temp;	
f01007f3:	8b 1b                	mov    (%ebx),%ebx
	__asm __volatile("movl %%ebp,%0" : "=r" (ebpr));
	uint32_t *ptr = (uint32_t*)ebpr ;
	uint32_t *temp;
	uint32_t address;
	struct Eipdebuginfo eipinfo;
	while(*ptr!=0)
f01007f5:	83 3b 00             	cmpl   $0x0,(%ebx)
f01007f8:	75 a4                	jne    f010079e <mon_backtrace+0xf>
	cprintf("%s  , %d  ,  %s \n",eipinfo.eip_file,eipinfo.eip_line,eipinfo.eip_fn_name);
	temp = ptr;
	ptr = (uint32_t*) *temp;	
	}	
	return 0;
}
f01007fa:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ff:	83 c4 40             	add    $0x40,%esp
f0100802:	5b                   	pop    %ebx
f0100803:	5e                   	pop    %esi
f0100804:	5d                   	pop    %ebp
f0100805:	c3                   	ret    

f0100806 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100806:	55                   	push   %ebp
f0100807:	89 e5                	mov    %esp,%ebp
f0100809:	57                   	push   %edi
f010080a:	56                   	push   %esi
f010080b:	53                   	push   %ebx
f010080c:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010080f:	c7 04 24 78 1e 10 f0 	movl   $0xf0101e78,(%esp)
f0100816:	e8 73 01 00 00       	call   f010098e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010081b:	c7 04 24 9c 1e 10 f0 	movl   $0xf0101e9c,(%esp)
f0100822:	e8 67 01 00 00       	call   f010098e <cprintf>


	while (1) {
		buf = readline("K> ");
f0100827:	c7 04 24 00 1d 10 f0 	movl   $0xf0101d00,(%esp)
f010082e:	e8 9d 0a 00 00       	call   f01012d0 <readline>
f0100833:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100835:	85 c0                	test   %eax,%eax
f0100837:	74 ee                	je     f0100827 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100839:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100840:	be 00 00 00 00       	mov    $0x0,%esi
f0100845:	eb 0a                	jmp    f0100851 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100847:	c6 03 00             	movb   $0x0,(%ebx)
f010084a:	89 f7                	mov    %esi,%edi
f010084c:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010084f:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100851:	0f b6 03             	movzbl (%ebx),%eax
f0100854:	84 c0                	test   %al,%al
f0100856:	74 63                	je     f01008bb <monitor+0xb5>
f0100858:	0f be c0             	movsbl %al,%eax
f010085b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010085f:	c7 04 24 04 1d 10 f0 	movl   $0xf0101d04,(%esp)
f0100866:	e8 7f 0c 00 00       	call   f01014ea <strchr>
f010086b:	85 c0                	test   %eax,%eax
f010086d:	75 d8                	jne    f0100847 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f010086f:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100872:	74 47                	je     f01008bb <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100874:	83 fe 0f             	cmp    $0xf,%esi
f0100877:	75 16                	jne    f010088f <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100879:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100880:	00 
f0100881:	c7 04 24 09 1d 10 f0 	movl   $0xf0101d09,(%esp)
f0100888:	e8 01 01 00 00       	call   f010098e <cprintf>
f010088d:	eb 98                	jmp    f0100827 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f010088f:	8d 7e 01             	lea    0x1(%esi),%edi
f0100892:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100896:	eb 03                	jmp    f010089b <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100898:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010089b:	0f b6 03             	movzbl (%ebx),%eax
f010089e:	84 c0                	test   %al,%al
f01008a0:	74 ad                	je     f010084f <monitor+0x49>
f01008a2:	0f be c0             	movsbl %al,%eax
f01008a5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008a9:	c7 04 24 04 1d 10 f0 	movl   $0xf0101d04,(%esp)
f01008b0:	e8 35 0c 00 00       	call   f01014ea <strchr>
f01008b5:	85 c0                	test   %eax,%eax
f01008b7:	74 df                	je     f0100898 <monitor+0x92>
f01008b9:	eb 94                	jmp    f010084f <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f01008bb:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008c2:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008c3:	85 f6                	test   %esi,%esi
f01008c5:	0f 84 5c ff ff ff    	je     f0100827 <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008cb:	c7 44 24 04 be 1c 10 	movl   $0xf0101cbe,0x4(%esp)
f01008d2:	f0 
f01008d3:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008d6:	89 04 24             	mov    %eax,(%esp)
f01008d9:	e8 ae 0b 00 00       	call   f010148c <strcmp>
f01008de:	85 c0                	test   %eax,%eax
f01008e0:	74 1b                	je     f01008fd <monitor+0xf7>
f01008e2:	c7 44 24 04 cc 1c 10 	movl   $0xf0101ccc,0x4(%esp)
f01008e9:	f0 
f01008ea:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008ed:	89 04 24             	mov    %eax,(%esp)
f01008f0:	e8 97 0b 00 00       	call   f010148c <strcmp>
f01008f5:	85 c0                	test   %eax,%eax
f01008f7:	75 2f                	jne    f0100928 <monitor+0x122>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008f9:	b0 01                	mov    $0x1,%al
f01008fb:	eb 05                	jmp    f0100902 <monitor+0xfc>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008fd:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100902:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100905:	01 d0                	add    %edx,%eax
f0100907:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010090a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010090e:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100911:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100915:	89 34 24             	mov    %esi,(%esp)
f0100918:	ff 14 85 cc 1e 10 f0 	call   *-0xfefe134(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010091f:	85 c0                	test   %eax,%eax
f0100921:	78 1d                	js     f0100940 <monitor+0x13a>
f0100923:	e9 ff fe ff ff       	jmp    f0100827 <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100928:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010092b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010092f:	c7 04 24 26 1d 10 f0 	movl   $0xf0101d26,(%esp)
f0100936:	e8 53 00 00 00       	call   f010098e <cprintf>
f010093b:	e9 e7 fe ff ff       	jmp    f0100827 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100940:	83 c4 5c             	add    $0x5c,%esp
f0100943:	5b                   	pop    %ebx
f0100944:	5e                   	pop    %esi
f0100945:	5f                   	pop    %edi
f0100946:	5d                   	pop    %ebp
f0100947:	c3                   	ret    

f0100948 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100948:	55                   	push   %ebp
f0100949:	89 e5                	mov    %esp,%ebp
f010094b:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010094e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100951:	89 04 24             	mov    %eax,(%esp)
f0100954:	e8 f8 fc ff ff       	call   f0100651 <cputchar>
	*cnt++;
}
f0100959:	c9                   	leave  
f010095a:	c3                   	ret    

f010095b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010095b:	55                   	push   %ebp
f010095c:	89 e5                	mov    %esp,%ebp
f010095e:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100961:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100968:	8b 45 0c             	mov    0xc(%ebp),%eax
f010096b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010096f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100972:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100976:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100979:	89 44 24 04          	mov    %eax,0x4(%esp)
f010097d:	c7 04 24 48 09 10 f0 	movl   $0xf0100948,(%esp)
f0100984:	e8 5b 04 00 00       	call   f0100de4 <vprintfmt>
	return cnt;
}
f0100989:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010098c:	c9                   	leave  
f010098d:	c3                   	ret    

f010098e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010098e:	55                   	push   %ebp
f010098f:	89 e5                	mov    %esp,%ebp
f0100991:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100994:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100997:	89 44 24 04          	mov    %eax,0x4(%esp)
f010099b:	8b 45 08             	mov    0x8(%ebp),%eax
f010099e:	89 04 24             	mov    %eax,(%esp)
f01009a1:	e8 b5 ff ff ff       	call   f010095b <vcprintf>
	va_end(ap);

	return cnt;
}
f01009a6:	c9                   	leave  
f01009a7:	c3                   	ret    

f01009a8 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void 
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009a8:	55                   	push   %ebp
f01009a9:	89 e5                	mov    %esp,%ebp
f01009ab:	57                   	push   %edi
f01009ac:	56                   	push   %esi
f01009ad:	53                   	push   %ebx
f01009ae:	83 ec 10             	sub    $0x10,%esp
f01009b1:	89 c6                	mov    %eax,%esi
f01009b3:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01009b6:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01009b9:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009bc:	8b 1a                	mov    (%edx),%ebx
f01009be:	8b 01                	mov    (%ecx),%eax
f01009c0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009c3:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f01009ca:	eb 77                	jmp    f0100a43 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f01009cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009cf:	01 d8                	add    %ebx,%eax
f01009d1:	b9 02 00 00 00       	mov    $0x2,%ecx
f01009d6:	99                   	cltd   
f01009d7:	f7 f9                	idiv   %ecx
f01009d9:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009db:	eb 01                	jmp    f01009de <stab_binsearch+0x36>
			m--;
f01009dd:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009de:	39 d9                	cmp    %ebx,%ecx
f01009e0:	7c 1d                	jl     f01009ff <stab_binsearch+0x57>
f01009e2:	6b d1 0c             	imul   $0xc,%ecx,%edx
f01009e5:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f01009ea:	39 fa                	cmp    %edi,%edx
f01009ec:	75 ef                	jne    f01009dd <stab_binsearch+0x35>
f01009ee:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009f1:	6b d1 0c             	imul   $0xc,%ecx,%edx
f01009f4:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f01009f8:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01009fb:	73 18                	jae    f0100a15 <stab_binsearch+0x6d>
f01009fd:	eb 05                	jmp    f0100a04 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009ff:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a02:	eb 3f                	jmp    f0100a43 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a04:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a07:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100a09:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a0c:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a13:	eb 2e                	jmp    f0100a43 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a15:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a18:	73 15                	jae    f0100a2f <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a1a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a1d:	48                   	dec    %eax
f0100a1e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a21:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a24:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a26:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a2d:	eb 14                	jmp    f0100a43 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a2f:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a32:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100a35:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100a37:	ff 45 0c             	incl   0xc(%ebp)
f0100a3a:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a3c:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a43:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a46:	7e 84                	jle    f01009cc <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a48:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a4c:	75 0d                	jne    f0100a5b <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100a4e:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a51:	8b 00                	mov    (%eax),%eax
f0100a53:	48                   	dec    %eax
f0100a54:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100a57:	89 07                	mov    %eax,(%edi)
f0100a59:	eb 22                	jmp    f0100a7d <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a5b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a5e:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a60:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a63:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a65:	eb 01                	jmp    f0100a68 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a67:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a68:	39 c1                	cmp    %eax,%ecx
f0100a6a:	7d 0c                	jge    f0100a78 <stab_binsearch+0xd0>
f0100a6c:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100a6f:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a74:	39 fa                	cmp    %edi,%edx
f0100a76:	75 ef                	jne    f0100a67 <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a78:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100a7b:	89 07                	mov    %eax,(%edi)
	}
}
f0100a7d:	83 c4 10             	add    $0x10,%esp
f0100a80:	5b                   	pop    %ebx
f0100a81:	5e                   	pop    %esi
f0100a82:	5f                   	pop    %edi
f0100a83:	5d                   	pop    %ebp
f0100a84:	c3                   	ret    

f0100a85 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a85:	55                   	push   %ebp
f0100a86:	89 e5                	mov    %esp,%ebp
f0100a88:	57                   	push   %edi
f0100a89:	56                   	push   %esi
f0100a8a:	53                   	push   %ebx
f0100a8b:	83 ec 3c             	sub    $0x3c,%esp
f0100a8e:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a91:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a94:	c7 03 dc 1e 10 f0    	movl   $0xf0101edc,(%ebx)
	info->eip_line = 0;
f0100a9a:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100aa1:	c7 43 08 dc 1e 10 f0 	movl   $0xf0101edc,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100aa8:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100aaf:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100ab2:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ab9:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100abf:	76 12                	jbe    f0100ad3 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ac1:	b8 6c 73 10 f0       	mov    $0xf010736c,%eax
f0100ac6:	3d 79 5a 10 f0       	cmp    $0xf0105a79,%eax
f0100acb:	0f 86 b9 01 00 00    	jbe    f0100c8a <debuginfo_eip+0x205>
f0100ad1:	eb 1c                	jmp    f0100aef <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100ad3:	c7 44 24 08 e6 1e 10 	movl   $0xf0101ee6,0x8(%esp)
f0100ada:	f0 
f0100adb:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100ae2:	00 
f0100ae3:	c7 04 24 f3 1e 10 f0 	movl   $0xf0101ef3,(%esp)
f0100aea:	e8 09 f6 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100aef:	80 3d 6b 73 10 f0 00 	cmpb   $0x0,0xf010736b
f0100af6:	0f 85 95 01 00 00    	jne    f0100c91 <debuginfo_eip+0x20c>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100afc:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b03:	b8 78 5a 10 f0       	mov    $0xf0105a78,%eax
f0100b08:	2d 30 21 10 f0       	sub    $0xf0102130,%eax
f0100b0d:	c1 f8 02             	sar    $0x2,%eax
f0100b10:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b16:	83 e8 01             	sub    $0x1,%eax
f0100b19:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b1c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b20:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b27:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b2a:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b2d:	b8 30 21 10 f0       	mov    $0xf0102130,%eax
f0100b32:	e8 71 fe ff ff       	call   f01009a8 <stab_binsearch>
	if (lfile == 0)
f0100b37:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b3a:	85 c0                	test   %eax,%eax
f0100b3c:	0f 84 56 01 00 00    	je     f0100c98 <debuginfo_eip+0x213>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b42:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b45:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b48:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b4b:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b4f:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100b56:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b59:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b5c:	b8 30 21 10 f0       	mov    $0xf0102130,%eax
f0100b61:	e8 42 fe ff ff       	call   f01009a8 <stab_binsearch>

	if (lfun <= rfun) {
f0100b66:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b69:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100b6c:	39 d0                	cmp    %edx,%eax
f0100b6e:	7f 3d                	jg     f0100bad <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		// .stab contains an array of fixed length structures, one struct per stab
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b70:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100b73:	8d b9 30 21 10 f0    	lea    -0xfefded0(%ecx),%edi
f0100b79:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100b7c:	8b 89 30 21 10 f0    	mov    -0xfefded0(%ecx),%ecx
f0100b82:	bf 6c 73 10 f0       	mov    $0xf010736c,%edi
f0100b87:	81 ef 79 5a 10 f0    	sub    $0xf0105a79,%edi
f0100b8d:	39 f9                	cmp    %edi,%ecx
f0100b8f:	73 09                	jae    f0100b9a <debuginfo_eip+0x115>
		{
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b91:	81 c1 79 5a 10 f0    	add    $0xf0105a79,%ecx
f0100b97:	89 4b 08             	mov    %ecx,0x8(%ebx)
			//cprintf("info->eip_fn_name%s,stabstr%s,stabs[lfun].n_strx%d\n",info->eip_fn_name,*stabstr,stabs[lfun].n_strx);
		}		
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b9a:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100b9d:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100ba0:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100ba3:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100ba5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100ba8:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100bab:	eb 0f                	jmp    f0100bbc <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bad:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bb0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bb3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100bb6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bb9:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bbc:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100bc3:	00 
f0100bc4:	8b 43 08             	mov    0x8(%ebx),%eax
f0100bc7:	89 04 24             	mov    %eax,(%esp)
f0100bca:	e8 3c 09 00 00       	call   f010150b <strfind>
f0100bcf:	2b 43 08             	sub    0x8(%ebx),%eax
f0100bd2:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100bd5:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bd9:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100be0:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100be3:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100be6:	b8 30 21 10 f0       	mov    $0xf0102130,%eax
f0100beb:	e8 b8 fd ff ff       	call   f01009a8 <stab_binsearch>
	info->eip_line = stabs[lline].n_value;
f0100bf0:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100bf3:	6b c2 0c             	imul   $0xc,%edx,%eax
f0100bf6:	05 30 21 10 f0       	add    $0xf0102130,%eax
f0100bfb:	8b 48 08             	mov    0x8(%eax),%ecx
f0100bfe:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c01:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c04:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100c07:	eb 06                	jmp    f0100c0f <debuginfo_eip+0x18a>
f0100c09:	83 ea 01             	sub    $0x1,%edx
f0100c0c:	83 e8 0c             	sub    $0xc,%eax
f0100c0f:	89 d6                	mov    %edx,%esi
f0100c11:	39 55 c4             	cmp    %edx,-0x3c(%ebp)
f0100c14:	7f 33                	jg     f0100c49 <debuginfo_eip+0x1c4>
	       && stabs[lline].n_type != N_SOL
f0100c16:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100c1a:	80 f9 84             	cmp    $0x84,%cl
f0100c1d:	74 0b                	je     f0100c2a <debuginfo_eip+0x1a5>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c1f:	80 f9 64             	cmp    $0x64,%cl
f0100c22:	75 e5                	jne    f0100c09 <debuginfo_eip+0x184>
f0100c24:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c28:	74 df                	je     f0100c09 <debuginfo_eip+0x184>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c2a:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100c2d:	8b 86 30 21 10 f0    	mov    -0xfefded0(%esi),%eax
f0100c33:	ba 6c 73 10 f0       	mov    $0xf010736c,%edx
f0100c38:	81 ea 79 5a 10 f0    	sub    $0xf0105a79,%edx
f0100c3e:	39 d0                	cmp    %edx,%eax
f0100c40:	73 07                	jae    f0100c49 <debuginfo_eip+0x1c4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c42:	05 79 5a 10 f0       	add    $0xf0105a79,%eax
f0100c47:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c49:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c4c:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c4f:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c54:	39 ca                	cmp    %ecx,%edx
f0100c56:	7d 4c                	jge    f0100ca4 <debuginfo_eip+0x21f>
		for (lline = lfun + 1;
f0100c58:	8d 42 01             	lea    0x1(%edx),%eax
f0100c5b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100c5e:	89 c2                	mov    %eax,%edx
f0100c60:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c63:	05 30 21 10 f0       	add    $0xf0102130,%eax
f0100c68:	89 ce                	mov    %ecx,%esi
f0100c6a:	eb 04                	jmp    f0100c70 <debuginfo_eip+0x1eb>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c6c:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c70:	39 d6                	cmp    %edx,%esi
f0100c72:	7e 2b                	jle    f0100c9f <debuginfo_eip+0x21a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c74:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100c78:	83 c2 01             	add    $0x1,%edx
f0100c7b:	83 c0 0c             	add    $0xc,%eax
f0100c7e:	80 f9 a0             	cmp    $0xa0,%cl
f0100c81:	74 e9                	je     f0100c6c <debuginfo_eip+0x1e7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c83:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c88:	eb 1a                	jmp    f0100ca4 <debuginfo_eip+0x21f>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c8a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c8f:	eb 13                	jmp    f0100ca4 <debuginfo_eip+0x21f>
f0100c91:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c96:	eb 0c                	jmp    f0100ca4 <debuginfo_eip+0x21f>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100c98:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c9d:	eb 05                	jmp    f0100ca4 <debuginfo_eip+0x21f>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c9f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100ca4:	83 c4 3c             	add    $0x3c,%esp
f0100ca7:	5b                   	pop    %ebx
f0100ca8:	5e                   	pop    %esi
f0100ca9:	5f                   	pop    %edi
f0100caa:	5d                   	pop    %ebp
f0100cab:	c3                   	ret    
f0100cac:	66 90                	xchg   %ax,%ax
f0100cae:	66 90                	xchg   %ax,%ax

f0100cb0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100cb0:	55                   	push   %ebp
f0100cb1:	89 e5                	mov    %esp,%ebp
f0100cb3:	57                   	push   %edi
f0100cb4:	56                   	push   %esi
f0100cb5:	53                   	push   %ebx
f0100cb6:	83 ec 3c             	sub    $0x3c,%esp
f0100cb9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100cbc:	89 d7                	mov    %edx,%edi
f0100cbe:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cc1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100cc4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100cc7:	89 c3                	mov    %eax,%ebx
f0100cc9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100ccc:	8b 45 10             	mov    0x10(%ebp),%eax
f0100ccf:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100cd2:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100cd7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100cda:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100cdd:	39 d9                	cmp    %ebx,%ecx
f0100cdf:	72 05                	jb     f0100ce6 <printnum+0x36>
f0100ce1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100ce4:	77 69                	ja     f0100d4f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100ce6:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100ce9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100ced:	83 ee 01             	sub    $0x1,%esi
f0100cf0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100cf4:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100cf8:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100cfc:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100d00:	89 c3                	mov    %eax,%ebx
f0100d02:	89 d6                	mov    %edx,%esi
f0100d04:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100d07:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100d0a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100d0e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100d12:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d15:	89 04 24             	mov    %eax,(%esp)
f0100d18:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d1b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d1f:	e8 0c 0a 00 00       	call   f0101730 <__udivdi3>
f0100d24:	89 d9                	mov    %ebx,%ecx
f0100d26:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100d2a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d2e:	89 04 24             	mov    %eax,(%esp)
f0100d31:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100d35:	89 fa                	mov    %edi,%edx
f0100d37:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d3a:	e8 71 ff ff ff       	call   f0100cb0 <printnum>
f0100d3f:	eb 1b                	jmp    f0100d5c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d41:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d45:	8b 45 18             	mov    0x18(%ebp),%eax
f0100d48:	89 04 24             	mov    %eax,(%esp)
f0100d4b:	ff d3                	call   *%ebx
f0100d4d:	eb 03                	jmp    f0100d52 <printnum+0xa2>
f0100d4f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d52:	83 ee 01             	sub    $0x1,%esi
f0100d55:	85 f6                	test   %esi,%esi
f0100d57:	7f e8                	jg     f0100d41 <printnum+0x91>
f0100d59:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d5c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d60:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100d64:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100d67:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d6a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d6e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100d72:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d75:	89 04 24             	mov    %eax,(%esp)
f0100d78:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d7b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d7f:	e8 dc 0a 00 00       	call   f0101860 <__umoddi3>
f0100d84:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d88:	0f be 80 01 1f 10 f0 	movsbl -0xfefe0ff(%eax),%eax
f0100d8f:	89 04 24             	mov    %eax,(%esp)
f0100d92:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d95:	ff d0                	call   *%eax
}
f0100d97:	83 c4 3c             	add    $0x3c,%esp
f0100d9a:	5b                   	pop    %ebx
f0100d9b:	5e                   	pop    %esi
f0100d9c:	5f                   	pop    %edi
f0100d9d:	5d                   	pop    %ebp
f0100d9e:	c3                   	ret    

f0100d9f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d9f:	55                   	push   %ebp
f0100da0:	89 e5                	mov    %esp,%ebp
f0100da2:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100da5:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100da9:	8b 10                	mov    (%eax),%edx
f0100dab:	3b 50 04             	cmp    0x4(%eax),%edx
f0100dae:	73 0a                	jae    f0100dba <sprintputch+0x1b>
		*b->buf++ = ch;
f0100db0:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100db3:	89 08                	mov    %ecx,(%eax)
f0100db5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100db8:	88 02                	mov    %al,(%edx)
}
f0100dba:	5d                   	pop    %ebp
f0100dbb:	c3                   	ret    

f0100dbc <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100dbc:	55                   	push   %ebp
f0100dbd:	89 e5                	mov    %esp,%ebp
f0100dbf:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100dc2:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100dc5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100dc9:	8b 45 10             	mov    0x10(%ebp),%eax
f0100dcc:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dd0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100dd3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dd7:	8b 45 08             	mov    0x8(%ebp),%eax
f0100dda:	89 04 24             	mov    %eax,(%esp)
f0100ddd:	e8 02 00 00 00       	call   f0100de4 <vprintfmt>
	va_end(ap);
}
f0100de2:	c9                   	leave  
f0100de3:	c3                   	ret    

f0100de4 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100de4:	55                   	push   %ebp
f0100de5:	89 e5                	mov    %esp,%ebp
f0100de7:	57                   	push   %edi
f0100de8:	56                   	push   %esi
f0100de9:	53                   	push   %ebx
f0100dea:	83 ec 3c             	sub    $0x3c,%esp
f0100ded:	8b 75 08             	mov    0x8(%ebp),%esi
f0100df0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100df3:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100df6:	eb 11                	jmp    f0100e09 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100df8:	85 c0                	test   %eax,%eax
f0100dfa:	0f 84 48 04 00 00    	je     f0101248 <vprintfmt+0x464>
				return;
			putch(ch, putdat);
f0100e00:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e04:	89 04 24             	mov    %eax,(%esp)
f0100e07:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e09:	83 c7 01             	add    $0x1,%edi
f0100e0c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100e10:	83 f8 25             	cmp    $0x25,%eax
f0100e13:	75 e3                	jne    f0100df8 <vprintfmt+0x14>
f0100e15:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100e19:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100e20:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e27:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100e2e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e33:	eb 1f                	jmp    f0100e54 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e35:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e38:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0100e3c:	eb 16                	jmp    f0100e54 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e3e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e41:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100e45:	eb 0d                	jmp    f0100e54 <vprintfmt+0x70>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100e47:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100e4a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e4d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e54:	8d 47 01             	lea    0x1(%edi),%eax
f0100e57:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e5a:	0f b6 17             	movzbl (%edi),%edx
f0100e5d:	0f b6 c2             	movzbl %dl,%eax
f0100e60:	83 ea 23             	sub    $0x23,%edx
f0100e63:	80 fa 55             	cmp    $0x55,%dl
f0100e66:	0f 87 bf 03 00 00    	ja     f010122b <vprintfmt+0x447>
f0100e6c:	0f b6 d2             	movzbl %dl,%edx
f0100e6f:	ff 24 95 a0 1f 10 f0 	jmp    *-0xfefe060(,%edx,4)
f0100e76:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e79:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e7e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e81:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100e84:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0100e88:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0100e8b:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100e8e:	83 f9 09             	cmp    $0x9,%ecx
f0100e91:	77 3c                	ja     f0100ecf <vprintfmt+0xeb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e93:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e96:	eb e9                	jmp    f0100e81 <vprintfmt+0x9d>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e98:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e9b:	8b 00                	mov    (%eax),%eax
f0100e9d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100ea0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ea3:	8d 40 04             	lea    0x4(%eax),%eax
f0100ea6:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ea9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100eac:	eb 27                	jmp    f0100ed5 <vprintfmt+0xf1>
f0100eae:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100eb1:	85 d2                	test   %edx,%edx
f0100eb3:	b8 00 00 00 00       	mov    $0x0,%eax
f0100eb8:	0f 49 c2             	cmovns %edx,%eax
f0100ebb:	89 45 e0             	mov    %eax,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ebe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ec1:	eb 91                	jmp    f0100e54 <vprintfmt+0x70>
f0100ec3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100ec6:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100ecd:	eb 85                	jmp    f0100e54 <vprintfmt+0x70>
f0100ecf:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100ed2:	89 55 d0             	mov    %edx,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100ed5:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100ed9:	0f 89 75 ff ff ff    	jns    f0100e54 <vprintfmt+0x70>
f0100edf:	e9 63 ff ff ff       	jmp    f0100e47 <vprintfmt+0x63>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100ee4:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ee7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100eea:	e9 65 ff ff ff       	jmp    f0100e54 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eef:	8b 45 14             	mov    0x14(%ebp),%eax
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ef2:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100ef6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100efa:	8b 00                	mov    (%eax),%eax
f0100efc:	89 04 24             	mov    %eax,(%esp)
f0100eff:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f01:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100f04:	e9 00 ff ff ff       	jmp    f0100e09 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f09:	8b 45 14             	mov    0x14(%ebp),%eax
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f0c:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100f10:	8b 00                	mov    (%eax),%eax
f0100f12:	99                   	cltd   
f0100f13:	31 d0                	xor    %edx,%eax
f0100f15:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f17:	83 f8 07             	cmp    $0x7,%eax
f0100f1a:	7f 0b                	jg     f0100f27 <vprintfmt+0x143>
f0100f1c:	8b 14 85 00 21 10 f0 	mov    -0xfefdf00(,%eax,4),%edx
f0100f23:	85 d2                	test   %edx,%edx
f0100f25:	75 20                	jne    f0100f47 <vprintfmt+0x163>
				printfmt(putch, putdat, "error %d", err);
f0100f27:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f2b:	c7 44 24 08 19 1f 10 	movl   $0xf0101f19,0x8(%esp)
f0100f32:	f0 
f0100f33:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f37:	89 34 24             	mov    %esi,(%esp)
f0100f3a:	e8 7d fe ff ff       	call   f0100dbc <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f3f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f42:	e9 c2 fe ff ff       	jmp    f0100e09 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0100f47:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100f4b:	c7 44 24 08 22 1f 10 	movl   $0xf0101f22,0x8(%esp)
f0100f52:	f0 
f0100f53:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f57:	89 34 24             	mov    %esi,(%esp)
f0100f5a:	e8 5d fe ff ff       	call   f0100dbc <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f5f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f62:	e9 a2 fe ff ff       	jmp    f0100e09 <vprintfmt+0x25>
f0100f67:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f6a:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100f6d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f70:	89 4d cc             	mov    %ecx,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f73:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100f77:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100f79:	85 ff                	test   %edi,%edi
f0100f7b:	b8 12 1f 10 f0       	mov    $0xf0101f12,%eax
f0100f80:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100f83:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100f87:	0f 84 92 00 00 00    	je     f010101f <vprintfmt+0x23b>
f0100f8d:	85 c9                	test   %ecx,%ecx
f0100f8f:	0f 8e 98 00 00 00    	jle    f010102d <vprintfmt+0x249>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f95:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100f99:	89 3c 24             	mov    %edi,(%esp)
f0100f9c:	e8 17 04 00 00       	call   f01013b8 <strnlen>
f0100fa1:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100fa4:	29 c1                	sub    %eax,%ecx
f0100fa6:	89 4d cc             	mov    %ecx,-0x34(%ebp)
					putch(padc, putdat);
f0100fa9:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100fad:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fb0:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100fb3:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fb5:	eb 0f                	jmp    f0100fc6 <vprintfmt+0x1e2>
					putch(padc, putdat);
f0100fb7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fbb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100fbe:	89 04 24             	mov    %eax,(%esp)
f0100fc1:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fc3:	83 ef 01             	sub    $0x1,%edi
f0100fc6:	85 ff                	test   %edi,%edi
f0100fc8:	7f ed                	jg     f0100fb7 <vprintfmt+0x1d3>
f0100fca:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100fcd:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100fd0:	85 c9                	test   %ecx,%ecx
f0100fd2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fd7:	0f 49 c1             	cmovns %ecx,%eax
f0100fda:	29 c1                	sub    %eax,%ecx
f0100fdc:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fdf:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fe2:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fe5:	89 cb                	mov    %ecx,%ebx
f0100fe7:	eb 50                	jmp    f0101039 <vprintfmt+0x255>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fe9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100fed:	74 1e                	je     f010100d <vprintfmt+0x229>
f0100fef:	0f be d2             	movsbl %dl,%edx
f0100ff2:	83 ea 20             	sub    $0x20,%edx
f0100ff5:	83 fa 5e             	cmp    $0x5e,%edx
f0100ff8:	76 13                	jbe    f010100d <vprintfmt+0x229>
					putch('?', putdat);
f0100ffa:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ffd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101001:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101008:	ff 55 08             	call   *0x8(%ebp)
f010100b:	eb 0d                	jmp    f010101a <vprintfmt+0x236>
				else
					putch(ch, putdat);
f010100d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101010:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101014:	89 04 24             	mov    %eax,(%esp)
f0101017:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010101a:	83 eb 01             	sub    $0x1,%ebx
f010101d:	eb 1a                	jmp    f0101039 <vprintfmt+0x255>
f010101f:	89 75 08             	mov    %esi,0x8(%ebp)
f0101022:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101025:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101028:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010102b:	eb 0c                	jmp    f0101039 <vprintfmt+0x255>
f010102d:	89 75 08             	mov    %esi,0x8(%ebp)
f0101030:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101033:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101036:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101039:	83 c7 01             	add    $0x1,%edi
f010103c:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0101040:	0f be c2             	movsbl %dl,%eax
f0101043:	85 c0                	test   %eax,%eax
f0101045:	74 25                	je     f010106c <vprintfmt+0x288>
f0101047:	85 f6                	test   %esi,%esi
f0101049:	78 9e                	js     f0100fe9 <vprintfmt+0x205>
f010104b:	83 ee 01             	sub    $0x1,%esi
f010104e:	79 99                	jns    f0100fe9 <vprintfmt+0x205>
f0101050:	89 df                	mov    %ebx,%edi
f0101052:	8b 75 08             	mov    0x8(%ebp),%esi
f0101055:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101058:	eb 1a                	jmp    f0101074 <vprintfmt+0x290>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010105a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010105e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101065:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101067:	83 ef 01             	sub    $0x1,%edi
f010106a:	eb 08                	jmp    f0101074 <vprintfmt+0x290>
f010106c:	89 df                	mov    %ebx,%edi
f010106e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101071:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101074:	85 ff                	test   %edi,%edi
f0101076:	7f e2                	jg     f010105a <vprintfmt+0x276>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101078:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010107b:	e9 89 fd ff ff       	jmp    f0100e09 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101080:	83 f9 01             	cmp    $0x1,%ecx
f0101083:	7e 19                	jle    f010109e <vprintfmt+0x2ba>
		return va_arg(*ap, long long);
f0101085:	8b 45 14             	mov    0x14(%ebp),%eax
f0101088:	8b 50 04             	mov    0x4(%eax),%edx
f010108b:	8b 00                	mov    (%eax),%eax
f010108d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101090:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101093:	8b 45 14             	mov    0x14(%ebp),%eax
f0101096:	8d 40 08             	lea    0x8(%eax),%eax
f0101099:	89 45 14             	mov    %eax,0x14(%ebp)
f010109c:	eb 38                	jmp    f01010d6 <vprintfmt+0x2f2>
	else if (lflag)
f010109e:	85 c9                	test   %ecx,%ecx
f01010a0:	74 1b                	je     f01010bd <vprintfmt+0x2d9>
		return va_arg(*ap, long);
f01010a2:	8b 45 14             	mov    0x14(%ebp),%eax
f01010a5:	8b 00                	mov    (%eax),%eax
f01010a7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010aa:	89 c1                	mov    %eax,%ecx
f01010ac:	c1 f9 1f             	sar    $0x1f,%ecx
f01010af:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01010b2:	8b 45 14             	mov    0x14(%ebp),%eax
f01010b5:	8d 40 04             	lea    0x4(%eax),%eax
f01010b8:	89 45 14             	mov    %eax,0x14(%ebp)
f01010bb:	eb 19                	jmp    f01010d6 <vprintfmt+0x2f2>
	else
		return va_arg(*ap, int);
f01010bd:	8b 45 14             	mov    0x14(%ebp),%eax
f01010c0:	8b 00                	mov    (%eax),%eax
f01010c2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010c5:	89 c1                	mov    %eax,%ecx
f01010c7:	c1 f9 1f             	sar    $0x1f,%ecx
f01010ca:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01010cd:	8b 45 14             	mov    0x14(%ebp),%eax
f01010d0:	8d 40 04             	lea    0x4(%eax),%eax
f01010d3:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01010d6:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01010d9:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01010dc:	bf 0a 00 00 00       	mov    $0xa,%edi
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01010e1:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01010e5:	0f 89 04 01 00 00    	jns    f01011ef <vprintfmt+0x40b>
				putch('-', putdat);
f01010eb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010ef:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01010f6:	ff d6                	call   *%esi
				num = -(long long) num;
f01010f8:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01010fb:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01010fe:	f7 da                	neg    %edx
f0101100:	83 d1 00             	adc    $0x0,%ecx
f0101103:	f7 d9                	neg    %ecx
f0101105:	e9 e5 00 00 00       	jmp    f01011ef <vprintfmt+0x40b>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010110a:	83 f9 01             	cmp    $0x1,%ecx
f010110d:	7e 10                	jle    f010111f <vprintfmt+0x33b>
		return va_arg(*ap, unsigned long long);
f010110f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101112:	8b 10                	mov    (%eax),%edx
f0101114:	8b 48 04             	mov    0x4(%eax),%ecx
f0101117:	8d 40 08             	lea    0x8(%eax),%eax
f010111a:	89 45 14             	mov    %eax,0x14(%ebp)
f010111d:	eb 26                	jmp    f0101145 <vprintfmt+0x361>
	else if (lflag)
f010111f:	85 c9                	test   %ecx,%ecx
f0101121:	74 12                	je     f0101135 <vprintfmt+0x351>
		return va_arg(*ap, unsigned long);
f0101123:	8b 45 14             	mov    0x14(%ebp),%eax
f0101126:	8b 10                	mov    (%eax),%edx
f0101128:	b9 00 00 00 00       	mov    $0x0,%ecx
f010112d:	8d 40 04             	lea    0x4(%eax),%eax
f0101130:	89 45 14             	mov    %eax,0x14(%ebp)
f0101133:	eb 10                	jmp    f0101145 <vprintfmt+0x361>
	else
		return va_arg(*ap, unsigned int);
f0101135:	8b 45 14             	mov    0x14(%ebp),%eax
f0101138:	8b 10                	mov    (%eax),%edx
f010113a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010113f:	8d 40 04             	lea    0x4(%eax),%eax
f0101142:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101145:	bf 0a 00 00 00       	mov    $0xa,%edi
			goto number;
f010114a:	e9 a0 00 00 00       	jmp    f01011ef <vprintfmt+0x40b>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f010114f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101153:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f010115a:	ff d6                	call   *%esi
			putch('X', putdat);
f010115c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101160:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101167:	ff d6                	call   *%esi
			putch('X', putdat);
f0101169:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010116d:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101174:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101176:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0101179:	e9 8b fc ff ff       	jmp    f0100e09 <vprintfmt+0x25>

		// pointer
		case 'p':
			putch('0', putdat);
f010117e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101182:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101189:	ff d6                	call   *%esi
			putch('x', putdat);
f010118b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010118f:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101196:	ff d6                	call   *%esi
			num = (unsigned long long)
f0101198:	8b 45 14             	mov    0x14(%ebp),%eax
f010119b:	8b 10                	mov    (%eax),%edx
f010119d:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
f01011a2:	8d 40 04             	lea    0x4(%eax),%eax
f01011a5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01011a8:	bf 10 00 00 00       	mov    $0x10,%edi
			goto number;
f01011ad:	eb 40                	jmp    f01011ef <vprintfmt+0x40b>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01011af:	83 f9 01             	cmp    $0x1,%ecx
f01011b2:	7e 10                	jle    f01011c4 <vprintfmt+0x3e0>
		return va_arg(*ap, unsigned long long);
f01011b4:	8b 45 14             	mov    0x14(%ebp),%eax
f01011b7:	8b 10                	mov    (%eax),%edx
f01011b9:	8b 48 04             	mov    0x4(%eax),%ecx
f01011bc:	8d 40 08             	lea    0x8(%eax),%eax
f01011bf:	89 45 14             	mov    %eax,0x14(%ebp)
f01011c2:	eb 26                	jmp    f01011ea <vprintfmt+0x406>
	else if (lflag)
f01011c4:	85 c9                	test   %ecx,%ecx
f01011c6:	74 12                	je     f01011da <vprintfmt+0x3f6>
		return va_arg(*ap, unsigned long);
f01011c8:	8b 45 14             	mov    0x14(%ebp),%eax
f01011cb:	8b 10                	mov    (%eax),%edx
f01011cd:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011d2:	8d 40 04             	lea    0x4(%eax),%eax
f01011d5:	89 45 14             	mov    %eax,0x14(%ebp)
f01011d8:	eb 10                	jmp    f01011ea <vprintfmt+0x406>
	else
		return va_arg(*ap, unsigned int);
f01011da:	8b 45 14             	mov    0x14(%ebp),%eax
f01011dd:	8b 10                	mov    (%eax),%edx
f01011df:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011e4:	8d 40 04             	lea    0x4(%eax),%eax
f01011e7:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01011ea:	bf 10 00 00 00       	mov    $0x10,%edi
		number:
			printnum(putch, putdat, num, base, width, padc);
f01011ef:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01011f3:	89 44 24 10          	mov    %eax,0x10(%esp)
f01011f7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01011fa:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011fe:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101202:	89 14 24             	mov    %edx,(%esp)
f0101205:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101209:	89 da                	mov    %ebx,%edx
f010120b:	89 f0                	mov    %esi,%eax
f010120d:	e8 9e fa ff ff       	call   f0100cb0 <printnum>
			break;
f0101212:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101215:	e9 ef fb ff ff       	jmp    f0100e09 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010121a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010121e:	89 04 24             	mov    %eax,(%esp)
f0101221:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101223:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101226:	e9 de fb ff ff       	jmp    f0100e09 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010122b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010122f:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101236:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101238:	eb 03                	jmp    f010123d <vprintfmt+0x459>
f010123a:	83 ef 01             	sub    $0x1,%edi
f010123d:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101241:	75 f7                	jne    f010123a <vprintfmt+0x456>
f0101243:	e9 c1 fb ff ff       	jmp    f0100e09 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f0101248:	83 c4 3c             	add    $0x3c,%esp
f010124b:	5b                   	pop    %ebx
f010124c:	5e                   	pop    %esi
f010124d:	5f                   	pop    %edi
f010124e:	5d                   	pop    %ebp
f010124f:	c3                   	ret    

f0101250 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101250:	55                   	push   %ebp
f0101251:	89 e5                	mov    %esp,%ebp
f0101253:	83 ec 28             	sub    $0x28,%esp
f0101256:	8b 45 08             	mov    0x8(%ebp),%eax
f0101259:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010125c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010125f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101263:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101266:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010126d:	85 c0                	test   %eax,%eax
f010126f:	74 30                	je     f01012a1 <vsnprintf+0x51>
f0101271:	85 d2                	test   %edx,%edx
f0101273:	7e 2c                	jle    f01012a1 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101275:	8b 45 14             	mov    0x14(%ebp),%eax
f0101278:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010127c:	8b 45 10             	mov    0x10(%ebp),%eax
f010127f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101283:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101286:	89 44 24 04          	mov    %eax,0x4(%esp)
f010128a:	c7 04 24 9f 0d 10 f0 	movl   $0xf0100d9f,(%esp)
f0101291:	e8 4e fb ff ff       	call   f0100de4 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101296:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101299:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010129c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010129f:	eb 05                	jmp    f01012a6 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01012a1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01012a6:	c9                   	leave  
f01012a7:	c3                   	ret    

f01012a8 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01012a8:	55                   	push   %ebp
f01012a9:	89 e5                	mov    %esp,%ebp
f01012ab:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01012ae:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01012b1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012b5:	8b 45 10             	mov    0x10(%ebp),%eax
f01012b8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012bc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012bf:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012c3:	8b 45 08             	mov    0x8(%ebp),%eax
f01012c6:	89 04 24             	mov    %eax,(%esp)
f01012c9:	e8 82 ff ff ff       	call   f0101250 <vsnprintf>
	va_end(ap);

	return rc;
}
f01012ce:	c9                   	leave  
f01012cf:	c3                   	ret    

f01012d0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01012d0:	55                   	push   %ebp
f01012d1:	89 e5                	mov    %esp,%ebp
f01012d3:	57                   	push   %edi
f01012d4:	56                   	push   %esi
f01012d5:	53                   	push   %ebx
f01012d6:	83 ec 1c             	sub    $0x1c,%esp
f01012d9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01012dc:	85 c0                	test   %eax,%eax
f01012de:	74 10                	je     f01012f0 <readline+0x20>
		cprintf("%s", prompt);
f01012e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012e4:	c7 04 24 22 1f 10 f0 	movl   $0xf0101f22,(%esp)
f01012eb:	e8 9e f6 ff ff       	call   f010098e <cprintf>

	i = 0;
	echoing = iscons(0);
f01012f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012f7:	e8 76 f3 ff ff       	call   f0100672 <iscons>
f01012fc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01012fe:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101303:	e8 59 f3 ff ff       	call   f0100661 <getchar>
f0101308:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010130a:	85 c0                	test   %eax,%eax
f010130c:	79 17                	jns    f0101325 <readline+0x55>
			cprintf("read error: %e\n", c);
f010130e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101312:	c7 04 24 20 21 10 f0 	movl   $0xf0102120,(%esp)
f0101319:	e8 70 f6 ff ff       	call   f010098e <cprintf>
			return NULL;
f010131e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101323:	eb 6d                	jmp    f0101392 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101325:	83 f8 7f             	cmp    $0x7f,%eax
f0101328:	74 05                	je     f010132f <readline+0x5f>
f010132a:	83 f8 08             	cmp    $0x8,%eax
f010132d:	75 19                	jne    f0101348 <readline+0x78>
f010132f:	85 f6                	test   %esi,%esi
f0101331:	7e 15                	jle    f0101348 <readline+0x78>
			if (echoing)
f0101333:	85 ff                	test   %edi,%edi
f0101335:	74 0c                	je     f0101343 <readline+0x73>
				cputchar('\b');
f0101337:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010133e:	e8 0e f3 ff ff       	call   f0100651 <cputchar>
			i--;
f0101343:	83 ee 01             	sub    $0x1,%esi
f0101346:	eb bb                	jmp    f0101303 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101348:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010134e:	7f 1c                	jg     f010136c <readline+0x9c>
f0101350:	83 fb 1f             	cmp    $0x1f,%ebx
f0101353:	7e 17                	jle    f010136c <readline+0x9c>
			if (echoing)
f0101355:	85 ff                	test   %edi,%edi
f0101357:	74 08                	je     f0101361 <readline+0x91>
				cputchar(c);
f0101359:	89 1c 24             	mov    %ebx,(%esp)
f010135c:	e8 f0 f2 ff ff       	call   f0100651 <cputchar>
			buf[i++] = c;
f0101361:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101367:	8d 76 01             	lea    0x1(%esi),%esi
f010136a:	eb 97                	jmp    f0101303 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010136c:	83 fb 0d             	cmp    $0xd,%ebx
f010136f:	74 05                	je     f0101376 <readline+0xa6>
f0101371:	83 fb 0a             	cmp    $0xa,%ebx
f0101374:	75 8d                	jne    f0101303 <readline+0x33>
			if (echoing)
f0101376:	85 ff                	test   %edi,%edi
f0101378:	74 0c                	je     f0101386 <readline+0xb6>
				cputchar('\n');
f010137a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101381:	e8 cb f2 ff ff       	call   f0100651 <cputchar>
			buf[i] = 0;
f0101386:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010138d:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101392:	83 c4 1c             	add    $0x1c,%esp
f0101395:	5b                   	pop    %ebx
f0101396:	5e                   	pop    %esi
f0101397:	5f                   	pop    %edi
f0101398:	5d                   	pop    %ebp
f0101399:	c3                   	ret    
f010139a:	66 90                	xchg   %ax,%ax
f010139c:	66 90                	xchg   %ax,%ax
f010139e:	66 90                	xchg   %ax,%ax

f01013a0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01013a0:	55                   	push   %ebp
f01013a1:	89 e5                	mov    %esp,%ebp
f01013a3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01013a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01013ab:	eb 03                	jmp    f01013b0 <strlen+0x10>
		n++;
f01013ad:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01013b0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01013b4:	75 f7                	jne    f01013ad <strlen+0xd>
		n++;
	return n;
}
f01013b6:	5d                   	pop    %ebp
f01013b7:	c3                   	ret    

f01013b8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01013b8:	55                   	push   %ebp
f01013b9:	89 e5                	mov    %esp,%ebp
f01013bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013be:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013c1:	b8 00 00 00 00       	mov    $0x0,%eax
f01013c6:	eb 03                	jmp    f01013cb <strnlen+0x13>
		n++;
f01013c8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013cb:	39 d0                	cmp    %edx,%eax
f01013cd:	74 06                	je     f01013d5 <strnlen+0x1d>
f01013cf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01013d3:	75 f3                	jne    f01013c8 <strnlen+0x10>
		n++;
	return n;
}
f01013d5:	5d                   	pop    %ebp
f01013d6:	c3                   	ret    

f01013d7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01013d7:	55                   	push   %ebp
f01013d8:	89 e5                	mov    %esp,%ebp
f01013da:	53                   	push   %ebx
f01013db:	8b 45 08             	mov    0x8(%ebp),%eax
f01013de:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01013e1:	89 c2                	mov    %eax,%edx
f01013e3:	83 c2 01             	add    $0x1,%edx
f01013e6:	83 c1 01             	add    $0x1,%ecx
f01013e9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01013ed:	88 5a ff             	mov    %bl,-0x1(%edx)
f01013f0:	84 db                	test   %bl,%bl
f01013f2:	75 ef                	jne    f01013e3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01013f4:	5b                   	pop    %ebx
f01013f5:	5d                   	pop    %ebp
f01013f6:	c3                   	ret    

f01013f7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01013f7:	55                   	push   %ebp
f01013f8:	89 e5                	mov    %esp,%ebp
f01013fa:	53                   	push   %ebx
f01013fb:	83 ec 08             	sub    $0x8,%esp
f01013fe:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101401:	89 1c 24             	mov    %ebx,(%esp)
f0101404:	e8 97 ff ff ff       	call   f01013a0 <strlen>
	strcpy(dst + len, src);
f0101409:	8b 55 0c             	mov    0xc(%ebp),%edx
f010140c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101410:	01 d8                	add    %ebx,%eax
f0101412:	89 04 24             	mov    %eax,(%esp)
f0101415:	e8 bd ff ff ff       	call   f01013d7 <strcpy>
	return dst;
}
f010141a:	89 d8                	mov    %ebx,%eax
f010141c:	83 c4 08             	add    $0x8,%esp
f010141f:	5b                   	pop    %ebx
f0101420:	5d                   	pop    %ebp
f0101421:	c3                   	ret    

f0101422 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101422:	55                   	push   %ebp
f0101423:	89 e5                	mov    %esp,%ebp
f0101425:	56                   	push   %esi
f0101426:	53                   	push   %ebx
f0101427:	8b 75 08             	mov    0x8(%ebp),%esi
f010142a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010142d:	89 f3                	mov    %esi,%ebx
f010142f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101432:	89 f2                	mov    %esi,%edx
f0101434:	eb 0f                	jmp    f0101445 <strncpy+0x23>
		*dst++ = *src;
f0101436:	83 c2 01             	add    $0x1,%edx
f0101439:	0f b6 01             	movzbl (%ecx),%eax
f010143c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010143f:	80 39 01             	cmpb   $0x1,(%ecx)
f0101442:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101445:	39 da                	cmp    %ebx,%edx
f0101447:	75 ed                	jne    f0101436 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101449:	89 f0                	mov    %esi,%eax
f010144b:	5b                   	pop    %ebx
f010144c:	5e                   	pop    %esi
f010144d:	5d                   	pop    %ebp
f010144e:	c3                   	ret    

f010144f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010144f:	55                   	push   %ebp
f0101450:	89 e5                	mov    %esp,%ebp
f0101452:	56                   	push   %esi
f0101453:	53                   	push   %ebx
f0101454:	8b 75 08             	mov    0x8(%ebp),%esi
f0101457:	8b 55 0c             	mov    0xc(%ebp),%edx
f010145a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010145d:	89 f0                	mov    %esi,%eax
f010145f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101463:	85 c9                	test   %ecx,%ecx
f0101465:	75 0b                	jne    f0101472 <strlcpy+0x23>
f0101467:	eb 1d                	jmp    f0101486 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101469:	83 c0 01             	add    $0x1,%eax
f010146c:	83 c2 01             	add    $0x1,%edx
f010146f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101472:	39 d8                	cmp    %ebx,%eax
f0101474:	74 0b                	je     f0101481 <strlcpy+0x32>
f0101476:	0f b6 0a             	movzbl (%edx),%ecx
f0101479:	84 c9                	test   %cl,%cl
f010147b:	75 ec                	jne    f0101469 <strlcpy+0x1a>
f010147d:	89 c2                	mov    %eax,%edx
f010147f:	eb 02                	jmp    f0101483 <strlcpy+0x34>
f0101481:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0101483:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0101486:	29 f0                	sub    %esi,%eax
}
f0101488:	5b                   	pop    %ebx
f0101489:	5e                   	pop    %esi
f010148a:	5d                   	pop    %ebp
f010148b:	c3                   	ret    

f010148c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010148c:	55                   	push   %ebp
f010148d:	89 e5                	mov    %esp,%ebp
f010148f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101492:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101495:	eb 06                	jmp    f010149d <strcmp+0x11>
		p++, q++;
f0101497:	83 c1 01             	add    $0x1,%ecx
f010149a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010149d:	0f b6 01             	movzbl (%ecx),%eax
f01014a0:	84 c0                	test   %al,%al
f01014a2:	74 04                	je     f01014a8 <strcmp+0x1c>
f01014a4:	3a 02                	cmp    (%edx),%al
f01014a6:	74 ef                	je     f0101497 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01014a8:	0f b6 c0             	movzbl %al,%eax
f01014ab:	0f b6 12             	movzbl (%edx),%edx
f01014ae:	29 d0                	sub    %edx,%eax
}
f01014b0:	5d                   	pop    %ebp
f01014b1:	c3                   	ret    

f01014b2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01014b2:	55                   	push   %ebp
f01014b3:	89 e5                	mov    %esp,%ebp
f01014b5:	53                   	push   %ebx
f01014b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01014b9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014bc:	89 c3                	mov    %eax,%ebx
f01014be:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01014c1:	eb 06                	jmp    f01014c9 <strncmp+0x17>
		n--, p++, q++;
f01014c3:	83 c0 01             	add    $0x1,%eax
f01014c6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01014c9:	39 d8                	cmp    %ebx,%eax
f01014cb:	74 15                	je     f01014e2 <strncmp+0x30>
f01014cd:	0f b6 08             	movzbl (%eax),%ecx
f01014d0:	84 c9                	test   %cl,%cl
f01014d2:	74 04                	je     f01014d8 <strncmp+0x26>
f01014d4:	3a 0a                	cmp    (%edx),%cl
f01014d6:	74 eb                	je     f01014c3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01014d8:	0f b6 00             	movzbl (%eax),%eax
f01014db:	0f b6 12             	movzbl (%edx),%edx
f01014de:	29 d0                	sub    %edx,%eax
f01014e0:	eb 05                	jmp    f01014e7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01014e2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01014e7:	5b                   	pop    %ebx
f01014e8:	5d                   	pop    %ebp
f01014e9:	c3                   	ret    

f01014ea <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01014ea:	55                   	push   %ebp
f01014eb:	89 e5                	mov    %esp,%ebp
f01014ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01014f0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01014f4:	eb 07                	jmp    f01014fd <strchr+0x13>
		if (*s == c)
f01014f6:	38 ca                	cmp    %cl,%dl
f01014f8:	74 0f                	je     f0101509 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01014fa:	83 c0 01             	add    $0x1,%eax
f01014fd:	0f b6 10             	movzbl (%eax),%edx
f0101500:	84 d2                	test   %dl,%dl
f0101502:	75 f2                	jne    f01014f6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101504:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101509:	5d                   	pop    %ebp
f010150a:	c3                   	ret    

f010150b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010150b:	55                   	push   %ebp
f010150c:	89 e5                	mov    %esp,%ebp
f010150e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101511:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101515:	eb 07                	jmp    f010151e <strfind+0x13>
		if (*s == c)
f0101517:	38 ca                	cmp    %cl,%dl
f0101519:	74 0a                	je     f0101525 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010151b:	83 c0 01             	add    $0x1,%eax
f010151e:	0f b6 10             	movzbl (%eax),%edx
f0101521:	84 d2                	test   %dl,%dl
f0101523:	75 f2                	jne    f0101517 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0101525:	5d                   	pop    %ebp
f0101526:	c3                   	ret    

f0101527 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101527:	55                   	push   %ebp
f0101528:	89 e5                	mov    %esp,%ebp
f010152a:	57                   	push   %edi
f010152b:	56                   	push   %esi
f010152c:	53                   	push   %ebx
f010152d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101530:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101533:	85 c9                	test   %ecx,%ecx
f0101535:	74 36                	je     f010156d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101537:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010153d:	75 28                	jne    f0101567 <memset+0x40>
f010153f:	f6 c1 03             	test   $0x3,%cl
f0101542:	75 23                	jne    f0101567 <memset+0x40>
		c &= 0xFF;
f0101544:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101548:	89 d3                	mov    %edx,%ebx
f010154a:	c1 e3 08             	shl    $0x8,%ebx
f010154d:	89 d6                	mov    %edx,%esi
f010154f:	c1 e6 18             	shl    $0x18,%esi
f0101552:	89 d0                	mov    %edx,%eax
f0101554:	c1 e0 10             	shl    $0x10,%eax
f0101557:	09 f0                	or     %esi,%eax
f0101559:	09 c2                	or     %eax,%edx
f010155b:	89 d0                	mov    %edx,%eax
f010155d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010155f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101562:	fc                   	cld    
f0101563:	f3 ab                	rep stos %eax,%es:(%edi)
f0101565:	eb 06                	jmp    f010156d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101567:	8b 45 0c             	mov    0xc(%ebp),%eax
f010156a:	fc                   	cld    
f010156b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010156d:	89 f8                	mov    %edi,%eax
f010156f:	5b                   	pop    %ebx
f0101570:	5e                   	pop    %esi
f0101571:	5f                   	pop    %edi
f0101572:	5d                   	pop    %ebp
f0101573:	c3                   	ret    

f0101574 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101574:	55                   	push   %ebp
f0101575:	89 e5                	mov    %esp,%ebp
f0101577:	57                   	push   %edi
f0101578:	56                   	push   %esi
f0101579:	8b 45 08             	mov    0x8(%ebp),%eax
f010157c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010157f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101582:	39 c6                	cmp    %eax,%esi
f0101584:	73 35                	jae    f01015bb <memmove+0x47>
f0101586:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101589:	39 d0                	cmp    %edx,%eax
f010158b:	73 2e                	jae    f01015bb <memmove+0x47>
		s += n;
		d += n;
f010158d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0101590:	89 d6                	mov    %edx,%esi
f0101592:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101594:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010159a:	75 13                	jne    f01015af <memmove+0x3b>
f010159c:	f6 c1 03             	test   $0x3,%cl
f010159f:	75 0e                	jne    f01015af <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01015a1:	83 ef 04             	sub    $0x4,%edi
f01015a4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01015a7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01015aa:	fd                   	std    
f01015ab:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015ad:	eb 09                	jmp    f01015b8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01015af:	83 ef 01             	sub    $0x1,%edi
f01015b2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01015b5:	fd                   	std    
f01015b6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01015b8:	fc                   	cld    
f01015b9:	eb 1d                	jmp    f01015d8 <memmove+0x64>
f01015bb:	89 f2                	mov    %esi,%edx
f01015bd:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015bf:	f6 c2 03             	test   $0x3,%dl
f01015c2:	75 0f                	jne    f01015d3 <memmove+0x5f>
f01015c4:	f6 c1 03             	test   $0x3,%cl
f01015c7:	75 0a                	jne    f01015d3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01015c9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01015cc:	89 c7                	mov    %eax,%edi
f01015ce:	fc                   	cld    
f01015cf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015d1:	eb 05                	jmp    f01015d8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01015d3:	89 c7                	mov    %eax,%edi
f01015d5:	fc                   	cld    
f01015d6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01015d8:	5e                   	pop    %esi
f01015d9:	5f                   	pop    %edi
f01015da:	5d                   	pop    %ebp
f01015db:	c3                   	ret    

f01015dc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01015dc:	55                   	push   %ebp
f01015dd:	89 e5                	mov    %esp,%ebp
f01015df:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01015e2:	8b 45 10             	mov    0x10(%ebp),%eax
f01015e5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01015e9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015ec:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015f0:	8b 45 08             	mov    0x8(%ebp),%eax
f01015f3:	89 04 24             	mov    %eax,(%esp)
f01015f6:	e8 79 ff ff ff       	call   f0101574 <memmove>
}
f01015fb:	c9                   	leave  
f01015fc:	c3                   	ret    

f01015fd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01015fd:	55                   	push   %ebp
f01015fe:	89 e5                	mov    %esp,%ebp
f0101600:	56                   	push   %esi
f0101601:	53                   	push   %ebx
f0101602:	8b 55 08             	mov    0x8(%ebp),%edx
f0101605:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101608:	89 d6                	mov    %edx,%esi
f010160a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010160d:	eb 1a                	jmp    f0101629 <memcmp+0x2c>
		if (*s1 != *s2)
f010160f:	0f b6 02             	movzbl (%edx),%eax
f0101612:	0f b6 19             	movzbl (%ecx),%ebx
f0101615:	38 d8                	cmp    %bl,%al
f0101617:	74 0a                	je     f0101623 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101619:	0f b6 c0             	movzbl %al,%eax
f010161c:	0f b6 db             	movzbl %bl,%ebx
f010161f:	29 d8                	sub    %ebx,%eax
f0101621:	eb 0f                	jmp    f0101632 <memcmp+0x35>
		s1++, s2++;
f0101623:	83 c2 01             	add    $0x1,%edx
f0101626:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101629:	39 f2                	cmp    %esi,%edx
f010162b:	75 e2                	jne    f010160f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010162d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101632:	5b                   	pop    %ebx
f0101633:	5e                   	pop    %esi
f0101634:	5d                   	pop    %ebp
f0101635:	c3                   	ret    

f0101636 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101636:	55                   	push   %ebp
f0101637:	89 e5                	mov    %esp,%ebp
f0101639:	8b 45 08             	mov    0x8(%ebp),%eax
f010163c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010163f:	89 c2                	mov    %eax,%edx
f0101641:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101644:	eb 07                	jmp    f010164d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101646:	38 08                	cmp    %cl,(%eax)
f0101648:	74 07                	je     f0101651 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010164a:	83 c0 01             	add    $0x1,%eax
f010164d:	39 d0                	cmp    %edx,%eax
f010164f:	72 f5                	jb     f0101646 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101651:	5d                   	pop    %ebp
f0101652:	c3                   	ret    

f0101653 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101653:	55                   	push   %ebp
f0101654:	89 e5                	mov    %esp,%ebp
f0101656:	57                   	push   %edi
f0101657:	56                   	push   %esi
f0101658:	53                   	push   %ebx
f0101659:	8b 55 08             	mov    0x8(%ebp),%edx
f010165c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010165f:	eb 03                	jmp    f0101664 <strtol+0x11>
		s++;
f0101661:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101664:	0f b6 0a             	movzbl (%edx),%ecx
f0101667:	80 f9 09             	cmp    $0x9,%cl
f010166a:	74 f5                	je     f0101661 <strtol+0xe>
f010166c:	80 f9 20             	cmp    $0x20,%cl
f010166f:	74 f0                	je     f0101661 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101671:	80 f9 2b             	cmp    $0x2b,%cl
f0101674:	75 0a                	jne    f0101680 <strtol+0x2d>
		s++;
f0101676:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101679:	bf 00 00 00 00       	mov    $0x0,%edi
f010167e:	eb 11                	jmp    f0101691 <strtol+0x3e>
f0101680:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101685:	80 f9 2d             	cmp    $0x2d,%cl
f0101688:	75 07                	jne    f0101691 <strtol+0x3e>
		s++, neg = 1;
f010168a:	8d 52 01             	lea    0x1(%edx),%edx
f010168d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101691:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0101696:	75 15                	jne    f01016ad <strtol+0x5a>
f0101698:	80 3a 30             	cmpb   $0x30,(%edx)
f010169b:	75 10                	jne    f01016ad <strtol+0x5a>
f010169d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01016a1:	75 0a                	jne    f01016ad <strtol+0x5a>
		s += 2, base = 16;
f01016a3:	83 c2 02             	add    $0x2,%edx
f01016a6:	b8 10 00 00 00       	mov    $0x10,%eax
f01016ab:	eb 10                	jmp    f01016bd <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f01016ad:	85 c0                	test   %eax,%eax
f01016af:	75 0c                	jne    f01016bd <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01016b1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01016b3:	80 3a 30             	cmpb   $0x30,(%edx)
f01016b6:	75 05                	jne    f01016bd <strtol+0x6a>
		s++, base = 8;
f01016b8:	83 c2 01             	add    $0x1,%edx
f01016bb:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f01016bd:	bb 00 00 00 00       	mov    $0x0,%ebx
f01016c2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01016c5:	0f b6 0a             	movzbl (%edx),%ecx
f01016c8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01016cb:	89 f0                	mov    %esi,%eax
f01016cd:	3c 09                	cmp    $0x9,%al
f01016cf:	77 08                	ja     f01016d9 <strtol+0x86>
			dig = *s - '0';
f01016d1:	0f be c9             	movsbl %cl,%ecx
f01016d4:	83 e9 30             	sub    $0x30,%ecx
f01016d7:	eb 20                	jmp    f01016f9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f01016d9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01016dc:	89 f0                	mov    %esi,%eax
f01016de:	3c 19                	cmp    $0x19,%al
f01016e0:	77 08                	ja     f01016ea <strtol+0x97>
			dig = *s - 'a' + 10;
f01016e2:	0f be c9             	movsbl %cl,%ecx
f01016e5:	83 e9 57             	sub    $0x57,%ecx
f01016e8:	eb 0f                	jmp    f01016f9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f01016ea:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01016ed:	89 f0                	mov    %esi,%eax
f01016ef:	3c 19                	cmp    $0x19,%al
f01016f1:	77 16                	ja     f0101709 <strtol+0xb6>
			dig = *s - 'A' + 10;
f01016f3:	0f be c9             	movsbl %cl,%ecx
f01016f6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01016f9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01016fc:	7d 0f                	jge    f010170d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f01016fe:	83 c2 01             	add    $0x1,%edx
f0101701:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0101705:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0101707:	eb bc                	jmp    f01016c5 <strtol+0x72>
f0101709:	89 d8                	mov    %ebx,%eax
f010170b:	eb 02                	jmp    f010170f <strtol+0xbc>
f010170d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010170f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101713:	74 05                	je     f010171a <strtol+0xc7>
		*endptr = (char *) s;
f0101715:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101718:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010171a:	f7 d8                	neg    %eax
f010171c:	85 ff                	test   %edi,%edi
f010171e:	0f 44 c3             	cmove  %ebx,%eax
}
f0101721:	5b                   	pop    %ebx
f0101722:	5e                   	pop    %esi
f0101723:	5f                   	pop    %edi
f0101724:	5d                   	pop    %ebp
f0101725:	c3                   	ret    
f0101726:	66 90                	xchg   %ax,%ax
f0101728:	66 90                	xchg   %ax,%ax
f010172a:	66 90                	xchg   %ax,%ax
f010172c:	66 90                	xchg   %ax,%ax
f010172e:	66 90                	xchg   %ax,%ax

f0101730 <__udivdi3>:
f0101730:	55                   	push   %ebp
f0101731:	57                   	push   %edi
f0101732:	56                   	push   %esi
f0101733:	83 ec 0c             	sub    $0xc,%esp
f0101736:	8b 44 24 28          	mov    0x28(%esp),%eax
f010173a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010173e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101742:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101746:	85 c0                	test   %eax,%eax
f0101748:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010174c:	89 ea                	mov    %ebp,%edx
f010174e:	89 0c 24             	mov    %ecx,(%esp)
f0101751:	75 2d                	jne    f0101780 <__udivdi3+0x50>
f0101753:	39 e9                	cmp    %ebp,%ecx
f0101755:	77 61                	ja     f01017b8 <__udivdi3+0x88>
f0101757:	85 c9                	test   %ecx,%ecx
f0101759:	89 ce                	mov    %ecx,%esi
f010175b:	75 0b                	jne    f0101768 <__udivdi3+0x38>
f010175d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101762:	31 d2                	xor    %edx,%edx
f0101764:	f7 f1                	div    %ecx
f0101766:	89 c6                	mov    %eax,%esi
f0101768:	31 d2                	xor    %edx,%edx
f010176a:	89 e8                	mov    %ebp,%eax
f010176c:	f7 f6                	div    %esi
f010176e:	89 c5                	mov    %eax,%ebp
f0101770:	89 f8                	mov    %edi,%eax
f0101772:	f7 f6                	div    %esi
f0101774:	89 ea                	mov    %ebp,%edx
f0101776:	83 c4 0c             	add    $0xc,%esp
f0101779:	5e                   	pop    %esi
f010177a:	5f                   	pop    %edi
f010177b:	5d                   	pop    %ebp
f010177c:	c3                   	ret    
f010177d:	8d 76 00             	lea    0x0(%esi),%esi
f0101780:	39 e8                	cmp    %ebp,%eax
f0101782:	77 24                	ja     f01017a8 <__udivdi3+0x78>
f0101784:	0f bd e8             	bsr    %eax,%ebp
f0101787:	83 f5 1f             	xor    $0x1f,%ebp
f010178a:	75 3c                	jne    f01017c8 <__udivdi3+0x98>
f010178c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101790:	39 34 24             	cmp    %esi,(%esp)
f0101793:	0f 86 9f 00 00 00    	jbe    f0101838 <__udivdi3+0x108>
f0101799:	39 d0                	cmp    %edx,%eax
f010179b:	0f 82 97 00 00 00    	jb     f0101838 <__udivdi3+0x108>
f01017a1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01017a8:	31 d2                	xor    %edx,%edx
f01017aa:	31 c0                	xor    %eax,%eax
f01017ac:	83 c4 0c             	add    $0xc,%esp
f01017af:	5e                   	pop    %esi
f01017b0:	5f                   	pop    %edi
f01017b1:	5d                   	pop    %ebp
f01017b2:	c3                   	ret    
f01017b3:	90                   	nop
f01017b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017b8:	89 f8                	mov    %edi,%eax
f01017ba:	f7 f1                	div    %ecx
f01017bc:	31 d2                	xor    %edx,%edx
f01017be:	83 c4 0c             	add    $0xc,%esp
f01017c1:	5e                   	pop    %esi
f01017c2:	5f                   	pop    %edi
f01017c3:	5d                   	pop    %ebp
f01017c4:	c3                   	ret    
f01017c5:	8d 76 00             	lea    0x0(%esi),%esi
f01017c8:	89 e9                	mov    %ebp,%ecx
f01017ca:	8b 3c 24             	mov    (%esp),%edi
f01017cd:	d3 e0                	shl    %cl,%eax
f01017cf:	89 c6                	mov    %eax,%esi
f01017d1:	b8 20 00 00 00       	mov    $0x20,%eax
f01017d6:	29 e8                	sub    %ebp,%eax
f01017d8:	89 c1                	mov    %eax,%ecx
f01017da:	d3 ef                	shr    %cl,%edi
f01017dc:	89 e9                	mov    %ebp,%ecx
f01017de:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01017e2:	8b 3c 24             	mov    (%esp),%edi
f01017e5:	09 74 24 08          	or     %esi,0x8(%esp)
f01017e9:	89 d6                	mov    %edx,%esi
f01017eb:	d3 e7                	shl    %cl,%edi
f01017ed:	89 c1                	mov    %eax,%ecx
f01017ef:	89 3c 24             	mov    %edi,(%esp)
f01017f2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01017f6:	d3 ee                	shr    %cl,%esi
f01017f8:	89 e9                	mov    %ebp,%ecx
f01017fa:	d3 e2                	shl    %cl,%edx
f01017fc:	89 c1                	mov    %eax,%ecx
f01017fe:	d3 ef                	shr    %cl,%edi
f0101800:	09 d7                	or     %edx,%edi
f0101802:	89 f2                	mov    %esi,%edx
f0101804:	89 f8                	mov    %edi,%eax
f0101806:	f7 74 24 08          	divl   0x8(%esp)
f010180a:	89 d6                	mov    %edx,%esi
f010180c:	89 c7                	mov    %eax,%edi
f010180e:	f7 24 24             	mull   (%esp)
f0101811:	39 d6                	cmp    %edx,%esi
f0101813:	89 14 24             	mov    %edx,(%esp)
f0101816:	72 30                	jb     f0101848 <__udivdi3+0x118>
f0101818:	8b 54 24 04          	mov    0x4(%esp),%edx
f010181c:	89 e9                	mov    %ebp,%ecx
f010181e:	d3 e2                	shl    %cl,%edx
f0101820:	39 c2                	cmp    %eax,%edx
f0101822:	73 05                	jae    f0101829 <__udivdi3+0xf9>
f0101824:	3b 34 24             	cmp    (%esp),%esi
f0101827:	74 1f                	je     f0101848 <__udivdi3+0x118>
f0101829:	89 f8                	mov    %edi,%eax
f010182b:	31 d2                	xor    %edx,%edx
f010182d:	e9 7a ff ff ff       	jmp    f01017ac <__udivdi3+0x7c>
f0101832:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101838:	31 d2                	xor    %edx,%edx
f010183a:	b8 01 00 00 00       	mov    $0x1,%eax
f010183f:	e9 68 ff ff ff       	jmp    f01017ac <__udivdi3+0x7c>
f0101844:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101848:	8d 47 ff             	lea    -0x1(%edi),%eax
f010184b:	31 d2                	xor    %edx,%edx
f010184d:	83 c4 0c             	add    $0xc,%esp
f0101850:	5e                   	pop    %esi
f0101851:	5f                   	pop    %edi
f0101852:	5d                   	pop    %ebp
f0101853:	c3                   	ret    
f0101854:	66 90                	xchg   %ax,%ax
f0101856:	66 90                	xchg   %ax,%ax
f0101858:	66 90                	xchg   %ax,%ax
f010185a:	66 90                	xchg   %ax,%ax
f010185c:	66 90                	xchg   %ax,%ax
f010185e:	66 90                	xchg   %ax,%ax

f0101860 <__umoddi3>:
f0101860:	55                   	push   %ebp
f0101861:	57                   	push   %edi
f0101862:	56                   	push   %esi
f0101863:	83 ec 14             	sub    $0x14,%esp
f0101866:	8b 44 24 28          	mov    0x28(%esp),%eax
f010186a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010186e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101872:	89 c7                	mov    %eax,%edi
f0101874:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101878:	8b 44 24 30          	mov    0x30(%esp),%eax
f010187c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101880:	89 34 24             	mov    %esi,(%esp)
f0101883:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101887:	85 c0                	test   %eax,%eax
f0101889:	89 c2                	mov    %eax,%edx
f010188b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010188f:	75 17                	jne    f01018a8 <__umoddi3+0x48>
f0101891:	39 fe                	cmp    %edi,%esi
f0101893:	76 4b                	jbe    f01018e0 <__umoddi3+0x80>
f0101895:	89 c8                	mov    %ecx,%eax
f0101897:	89 fa                	mov    %edi,%edx
f0101899:	f7 f6                	div    %esi
f010189b:	89 d0                	mov    %edx,%eax
f010189d:	31 d2                	xor    %edx,%edx
f010189f:	83 c4 14             	add    $0x14,%esp
f01018a2:	5e                   	pop    %esi
f01018a3:	5f                   	pop    %edi
f01018a4:	5d                   	pop    %ebp
f01018a5:	c3                   	ret    
f01018a6:	66 90                	xchg   %ax,%ax
f01018a8:	39 f8                	cmp    %edi,%eax
f01018aa:	77 54                	ja     f0101900 <__umoddi3+0xa0>
f01018ac:	0f bd e8             	bsr    %eax,%ebp
f01018af:	83 f5 1f             	xor    $0x1f,%ebp
f01018b2:	75 5c                	jne    f0101910 <__umoddi3+0xb0>
f01018b4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01018b8:	39 3c 24             	cmp    %edi,(%esp)
f01018bb:	0f 87 e7 00 00 00    	ja     f01019a8 <__umoddi3+0x148>
f01018c1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01018c5:	29 f1                	sub    %esi,%ecx
f01018c7:	19 c7                	sbb    %eax,%edi
f01018c9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018cd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018d1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01018d5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01018d9:	83 c4 14             	add    $0x14,%esp
f01018dc:	5e                   	pop    %esi
f01018dd:	5f                   	pop    %edi
f01018de:	5d                   	pop    %ebp
f01018df:	c3                   	ret    
f01018e0:	85 f6                	test   %esi,%esi
f01018e2:	89 f5                	mov    %esi,%ebp
f01018e4:	75 0b                	jne    f01018f1 <__umoddi3+0x91>
f01018e6:	b8 01 00 00 00       	mov    $0x1,%eax
f01018eb:	31 d2                	xor    %edx,%edx
f01018ed:	f7 f6                	div    %esi
f01018ef:	89 c5                	mov    %eax,%ebp
f01018f1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01018f5:	31 d2                	xor    %edx,%edx
f01018f7:	f7 f5                	div    %ebp
f01018f9:	89 c8                	mov    %ecx,%eax
f01018fb:	f7 f5                	div    %ebp
f01018fd:	eb 9c                	jmp    f010189b <__umoddi3+0x3b>
f01018ff:	90                   	nop
f0101900:	89 c8                	mov    %ecx,%eax
f0101902:	89 fa                	mov    %edi,%edx
f0101904:	83 c4 14             	add    $0x14,%esp
f0101907:	5e                   	pop    %esi
f0101908:	5f                   	pop    %edi
f0101909:	5d                   	pop    %ebp
f010190a:	c3                   	ret    
f010190b:	90                   	nop
f010190c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101910:	8b 04 24             	mov    (%esp),%eax
f0101913:	be 20 00 00 00       	mov    $0x20,%esi
f0101918:	89 e9                	mov    %ebp,%ecx
f010191a:	29 ee                	sub    %ebp,%esi
f010191c:	d3 e2                	shl    %cl,%edx
f010191e:	89 f1                	mov    %esi,%ecx
f0101920:	d3 e8                	shr    %cl,%eax
f0101922:	89 e9                	mov    %ebp,%ecx
f0101924:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101928:	8b 04 24             	mov    (%esp),%eax
f010192b:	09 54 24 04          	or     %edx,0x4(%esp)
f010192f:	89 fa                	mov    %edi,%edx
f0101931:	d3 e0                	shl    %cl,%eax
f0101933:	89 f1                	mov    %esi,%ecx
f0101935:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101939:	8b 44 24 10          	mov    0x10(%esp),%eax
f010193d:	d3 ea                	shr    %cl,%edx
f010193f:	89 e9                	mov    %ebp,%ecx
f0101941:	d3 e7                	shl    %cl,%edi
f0101943:	89 f1                	mov    %esi,%ecx
f0101945:	d3 e8                	shr    %cl,%eax
f0101947:	89 e9                	mov    %ebp,%ecx
f0101949:	09 f8                	or     %edi,%eax
f010194b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010194f:	f7 74 24 04          	divl   0x4(%esp)
f0101953:	d3 e7                	shl    %cl,%edi
f0101955:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101959:	89 d7                	mov    %edx,%edi
f010195b:	f7 64 24 08          	mull   0x8(%esp)
f010195f:	39 d7                	cmp    %edx,%edi
f0101961:	89 c1                	mov    %eax,%ecx
f0101963:	89 14 24             	mov    %edx,(%esp)
f0101966:	72 2c                	jb     f0101994 <__umoddi3+0x134>
f0101968:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010196c:	72 22                	jb     f0101990 <__umoddi3+0x130>
f010196e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101972:	29 c8                	sub    %ecx,%eax
f0101974:	19 d7                	sbb    %edx,%edi
f0101976:	89 e9                	mov    %ebp,%ecx
f0101978:	89 fa                	mov    %edi,%edx
f010197a:	d3 e8                	shr    %cl,%eax
f010197c:	89 f1                	mov    %esi,%ecx
f010197e:	d3 e2                	shl    %cl,%edx
f0101980:	89 e9                	mov    %ebp,%ecx
f0101982:	d3 ef                	shr    %cl,%edi
f0101984:	09 d0                	or     %edx,%eax
f0101986:	89 fa                	mov    %edi,%edx
f0101988:	83 c4 14             	add    $0x14,%esp
f010198b:	5e                   	pop    %esi
f010198c:	5f                   	pop    %edi
f010198d:	5d                   	pop    %ebp
f010198e:	c3                   	ret    
f010198f:	90                   	nop
f0101990:	39 d7                	cmp    %edx,%edi
f0101992:	75 da                	jne    f010196e <__umoddi3+0x10e>
f0101994:	8b 14 24             	mov    (%esp),%edx
f0101997:	89 c1                	mov    %eax,%ecx
f0101999:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010199d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f01019a1:	eb cb                	jmp    f010196e <__umoddi3+0x10e>
f01019a3:	90                   	nop
f01019a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019a8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f01019ac:	0f 82 0f ff ff ff    	jb     f01018c1 <__umoddi3+0x61>
f01019b2:	e9 1a ff ff ff       	jmp    f01018d1 <__umoddi3+0x71>
