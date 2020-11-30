# RISC-V Maze game
# Created by Enda Kilgarriff (17351606) - Maya McDevitt (17309601), National University of Ireland, Galway
# Creation date: Nov 2020
#
#==============================

# Copy/modify/paste this assembly program to Venus online assembler / simulator (Editor Window TAB) 
# Venus https://www.kvakil.me/venus/

# Convert Venus program dump (column of 32-bit instrs) to vicilogic instruction memory format (rows of 8x32-bit instrs)
# https://www.vicilogic.com/static/ext/RISCV/programExamples/convert_VenusProgramDump_to_vicilogicInstructionMemoryFormat.pdf

# Load machine code into vicilogic (256 arena): 
# https://www.vicilogic.com/vicilearn/run_step/?s_id=1762

# assembly program   # Notes  (default imm format is decimal 0d and hex 0x0)

# register allocation
#  x1  Return Address for the Stack, Seed With 0xFFFFFFFFFFFFFFF0
#  x2  Stack Pointer, Seed With 0x100
#  x10 User Position Memory Reference, Seed With 0x800000
#  x11 User Row Memory Reference, Seed With 0x00 
#  x12 User Movement Register
#  x13 General Use Register 
#  x14 General Use Register 
#  x15 General Use Register 
#  x16 Read Inport Address = 0x001000c
#  x17 OneSecDelay Counter
#  x18 Determine User Input Action
#  x19 Read Count Address = 0x0010008
#  x20 Move Right Input, Seed With 0x1
#  x21 Move Left Input, Seed With 0x2
#  x22 Move Up Input, Seed With 0x4
#  x23 Move Down Input, Seed With 0x8
#  x24 Check If Move is Valid
#  x25 Check If Move is Valid

addi sp zero 0x100 #Initializing the stack on register x2
addi sp sp -16 #reserving 16byte stack
lui x16 0x0010 # Set Read Inport Address
addi x16 x16 0xc 
lui x19 0x0010 # Set Read Count Address
addi x19 x19 0x8 
jal ra InitializeDisplay 
jal zero pollInport # Program contained in this loop

# Error handling - DEAD written to x10 to indicate error
Error:
    lui x10 0xDEAD          # Exited program
    loop: jal zero loop     # Loop forever 

#Draws the maze and adds user in on location (0,0)
InitializeDisplay:
    sw ra 0(sp)  #Pushing the return address to the stack pointer.
    addi sp sp 4
    #Setting up maze.
    addi x13 x0 0xfffffffe
    sw x13 0x38(x0)
    lui x13 0x82014
    addi x13 x13 0x104
    sw x13 0x34(x0)
    lui x13 0xbabd7
    addi x13 x13 0x6aa
    addi x13 x13 0x6ab
    sw x13 0x30(x0)
    lui x13 0xaaa14
    addi x13 x13 0x15d
    sw x13 0x2c(x0)
    lui x13 0xaaaf5
    addi x13 x13 0x6a2
    addi x13 x13 0x6a3
    sw x13 0x28(x0)
    lui x13 0xaea04
    addi x13 x13 0x57d
    sw x13 0x24(x0)
    lui x13 0xa8bff
    addi x13 x13 0x541
    sw x13 0x20(x0)
    lui x13 0xab811
    addi x13 x13 0x55f
    sw x13 0x1c(x0)
    lui x13 0x88fd5
    addi x13 x13 0x551
    sw x13 0x18(x0)
    lui x13 0xbe055
    addi x13 x13 0x555
    sw x13 0x14(x0)
    lui x13 0xa3f55
    addi x13 x13 0x555
    sw x13 0x10(x0)
    lui x13 0xb8055
    addi x13 x13 0x545
    sw x13 0x0c(x0)
    lui x13 0x8ff55
    addi x13 x13 0x57d
    sw x13 0x08(x0)
    lui x13 0xa0044
    addi x13 x13 0x401
    sw x13 0x04(x0)
    lui x13 0x3ffff
    addi x13 x13 0x7ff
    addi x13 x13 0x7ff
    addi x13 x13 0x1
    # Adding in user at location (0,00) and the final row of maze.
    lui x10 0x80000     # User bit memory reference
    or x12 x13 x10      # Used User Movement Register x12 to store user location and maze bits.
    addi x11 x0 0       # Users Row Memory Reference
    sw x12 0x00(x11)    # Writing the user and maze to display
    #Blinking The User Three Times
    jal ra blinkUser 
    jal ra blinkUser
    jal ra blinkUser
    #Starting the counter
    addi x12 x0 3
    lui x13 0x0010
    sw x12 0(x13)
    addi sp sp -4
    lw ra 0(sp)
    jalr  ra

# Main loop - checking what move user wants to make
pollInport:
    lw x3 0x0(x19)  # Get Count Value 
    sw x3 0x3c(x0)  # Writing score to top row each time opertion returns
    addi x20 x0 1   # Right
    addi x21 x0 2   # Left
    addi x22 x0 4   # Up
    addi x23 x0 8   # Down
    lw x18 0x0(x16)             # Get inport values 
    beq x18 x20 moveUser_right
    beq x18 x21 moveUser_left
    beq x18 x22 moveUser_up
    beq x18 x23 moveUser_down
    beq x0 x0 pollInport        # Else keep looping
    jal zero Error              # Should never return - error handeling 

moveUser_right:
    jal ra checkRightValid
	jal ra restoreRowToDefault
    srli x10 x10 0x1            # Shift user right 1
    xor x12 x12 x10             # Draw user into row
    sw x12 0x0(x11)
    jal ra oneSecDelay
    jal zero pollInport

moveUser_left:
    jal ra checkLeftValid
    jal ra restoreRowToDefault
    slli x10 x10 0x1            # Shift user right 1
    xor x12 x12 x10             # Draw user into row
    sw x12 0x0(x11)
    jal ra oneSecDelay
    jal zero pollInport

moveUser_up:
    jal ra checkUpValid
    jal ra restoreRowToDefault 
    addi x11 x11 0x4            # Update User row reference with new current position 
    lw x13 0x0(x11)
    xor x12 x10 x13             # Draw user into row
    sw x12 0x0(x11)
    jal ra oneSecDelay
    jal zero pollInport

moveUser_down:
    jal ra checkDownValid
    jal ra restoreRowToDefault   
    addi x11 x11 0xFFFFFFFC     # Update User row reference with new current position 
    lw x13 0x0(x11)             # Store maze values one row below current user row
    xor x12 x10 x13             # Draw user into row
    sw x12 0x0(x11)
    jal ra oneSecDelay
    jal zero pollInport         

# Redraw maze row without user 
restoreRowToDefault:
    lw x12 0x0(x11) 
    xor x12 x12 x10             # Unset user from the row
    sw x12 0x0(x11) 
    ret

# If user at arena top boundary or above bit next to user is high return to checking inport value
# Else valid move - return to make move
checkUpValid:
	addi x21 x0 0x38
    beq x11 x21 endDetection    # Check if user is in most up location - if yes Game win
    lw x24 0x4(x11)             # Get row above
    and x21 x24 x10             # If user can move up AND should be 0 
    bne x21 x0 pollInport       # Return to checking if above is high
	ret

# If user at arena bottom boundary or below bit next to user is high return to checking inport value
# Else valid move - return to make move
checkDownValid:
    beq x11 x0 pollInport 
    lw x24 0xFFFFFFFC(x11)  # get row below
    and x22 x24 x10         # If user can move down 
    bne x22 x0 pollInport
    ret

# If user at left boundary or left bit next to user is high return to checking inport value
# Else valid move - return to make move
checkLeftValid:
    lui x13 0x80000
    beq x13 x10 pollInport # go back to poll if at most left
    lw x24 0x0(x11)
    slli x14 x10 1 
    and x14 x24 x14
    bne x14 x0 pollInport
    ret

# If user at right boundary or right bit next to user is high return to checking inport value
# Else valid move - return to make move 
 checkRightValid:
    addi x13 x0 0x1
    beq x10 x13 pollInport  # Return to checking inport if at right arena wall
    lw x24 0(x11)
    srli x14 x10 1          # Shift user position right 1 bit
    and x14 x24 x14
    bne x14 x0 pollInport   # If bit at right of user high return to checking inport
    ret

#Makes The User Bit LED Flash Once
blinkUser: 
    sw ra 0(sp)                # Pushing the return address to the stack pointer.
    addi sp sp 4
    jal ra restoreRowToDefault # Remove User From The Row.
    jal ra oneSecDelay 
    xor x12 x12 x10
    sw x12 0x0(x11) 
    jal ra oneSecDelay
    addi sp sp -4
    lw ra 0(sp)
    ret

oneSecDelay: 
    sw ra 0(sp)  
    addi sp sp 4
    lui x17 0x00601
    jal ra oneSecLoop   # Loop till x17 equals 0
    addi sp sp -4
    lw ra 0(sp)
    ret

oneSecLoop:  
    addi x17 x17 -1             # Decr delay counter
    bne  x17 x0, oneSecLoop     # Branch: loop if x17 != 0
    ret

# User at highest position - Check if at most right
endDetection:
    addi x13 x0 0x1 
    beq x10 x13 gameEnd     # If true game won
    jal zero pollInport

# Blink user until game reset - Game over
gameEnd: 
    jal ra blinkUser
    #Stopping the counter
    lui x13 0x0010
    sw x0 0(x13)
    beq zero zero gameEnd


============================
Venus 'dump' program binary. No of instructions n = 170
10000113
ff010113
00010837
00c80813
000109b7
00898993
010000ef
1040006f
0dead537
0000006f
00112023
00410113
ffe00693
02d02c23
820146b7
10468693
02d02a23
babd76b7
6aa68693
6ab68693
02d02823
aaa146b7
15d68693
02d02623
aaaf56b7
6a268693
6a368693
02d02423
aea046b7
57d68693
02d02223
a8bff6b7
54168693
02d02023
ab8116b7
55f68693
00d02e23
88fd56b7
55168693
00d02c23
be0556b7
55568693
00d02a23
a3f556b7
55568693
00d02823
b80556b7
54568693
00d02623
8ff556b7
57d68693
00d02423
a00446b7
40168693
00d02223
3ffff6b7
7ff68693
7ff68693
00168693
80000537
00a6e633
00000593
00c5a023
144000ef
140000ef
13c000ef
00300613
000106b7
00c6a023
ffc10113
00012083
000080e7
0009a183
02302e23
00100a13
00200a93
00400b13
00800b93
00082903
01490c63
03590863
05690463
07790263
fc000ae3
ed1ff06f
0d0000ef
074000ef
00155513
00a64633
00c5a023
100000ef
fb5ff06f
098000ef
058000ef
00151513
00a64633
00c5a023
0e4000ef
f99ff06f
050000ef
03c000ef
00458593
0005a683
00d54633
00c5a023
0c4000ef
f79ff06f
048000ef
01c000ef
ffc58593
0005a683
00d54633
00c5a023
0a4000ef
f59ff06f
0005a603
00a64633
00c5a023
00008067
03800a93
0b558863
0045ac03
00ac7ab3
f20a9ae3
00008067
f20586e3
ffc5ac03
00ac7b33
f20b10e3
00008067
800006b7
f0a68ae3
0005ac03
00151713
00ec7733
f00712e3
00008067
00100693
eed50ce3
0005ac03
00155713
00ec7733
ee0714e3
00008067
00112023
00410113
f85ff0ef
01c000ef
00a64633
00c5a023
010000ef
ffc10113
00012083
00008067
00112023
00410113
006018b7
010000ef
ffc10113
00012083
00008067
fff88893
fe089ee3
00008067
00100693
00d50463
e89ff06f
fa5ff0ef
000106b7
0006a023
fe000ae3


============================
Program binary formatted, for use in vicilogic online RISC-V processor
i.e, 8x32-bit instructions, 
format: m = mod(n/8)+1 = mod(11/8)+1



