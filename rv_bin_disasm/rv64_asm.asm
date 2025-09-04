
rv64_bin:     file format binary


Disassembly of section .data:

0000000000000000 <.data>:
   0:	00000013          	addi	x0,x0,0
   4:	00000013          	addi	x0,x0,0
   8:	02100813          	addi	x16,x0,33
   c:	717d                	c.addi16sp	x2,-16
   e:	e422                	c.sdsp	x8,8(x2)
  10:	0800                	c.addi4spn	x8,x2,16
  12:	050d                	c.addi	x10,3
  14:	55ed                	c.li	x11,-5
  16:	05f6                	c.slli	x11,0x1d
  18:	08158593          	addi	x11,x11,129
  1c:	05b2                	c.slli	x11,0xc
  1e:	bd158593          	addi	x11,x11,-1071
  22:	05b2                	c.slli	x11,0xc
  24:	c0058593          	addi	x11,x11,-1024
  28:	4605                	c.li	x12,1
  2a:	1602                	c.slli	x12,0x20
  2c:	9201                	c.srli	x12,0x20
  2e:	1602                	c.slli	x12,0x20
  30:	9201                	c.srli	x12,0x20
  32:	0245e303          	lwu	x6,36(x11)
  36:	02667263          	bgeu	x12,x6,0x5a
  3a:	187d                	c.addi	x16,-1
  3c:	00084f63          	blt	x16,x0,0x5a
  40:	00361393          	slli	x7,x12,0x3
  44:	93ae                	c.add	x7,x11
  46:	1503b383          	ld	x7,336(x7)
  4a:	00038863          	beq	x7,x0,0x5a
  4e:	0303be03          	ld	x28,48(x7)
  52:	6422                	c.ldsp	x8,8(x2)
  54:	6141                	c.addi16sp	x2,16
  56:	00ce0067          	jalr	x0,12(x28)
  5a:	57fd                	c.li	x15,-1
  5c:	6422                	c.ldsp	x8,8(x2)
  5e:	6141                	c.addi16sp	x2,16
  60:	0007851b          	addiw	x10,x15,0
  64:	8082                	c.jr	x1
