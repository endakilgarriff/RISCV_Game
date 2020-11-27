# RISC-V Maze game
# Created by Enda Kilgarriff (17351606) - Maya McDevitt , National University of Ireland, Galway
# Creation date: Nov 2020
#
#==============================

# Copy/modify/paste this assembly program to Venus online assembler / simulator (Editor Window TAB) 
# Venus https://www.kvakil.me/venus/

# Convert Venus program dump (column of 32-bit instrs) to vicilogic instruction memory format (rows of 8x32-bit instrs)
# https://www.vicilogic.com/static/ext/RISCV/programExamples/convert_VenusProgramDump_to_vicilogicInstructionMemoryFormat.pdf

# Load machine code into vicilogic (256 arena): 
# https://www.vicilogic.com/vicilearn/run_step/?s_id=1762

# assembly program   # Notes  (default imm format is decimal 0d)

# register allocation
#  x7  newTargetLoopCount = 8
#  x8  0x80000000, bit 31 asserted  
#  x9  general use register 
#  x10 target register, seed with 0x801000
#  x11 player register, seed with 0x080000 
#  x12  general use register 
#  x13 loopCount 
#  x14  general use register 
#  x15  peripheral counter base address = 0x00010000
#   Address offsets:
#    Input: 
#	   control0 register address  offset = 0,    (2:0) = Counter load, up, countCE
#      X"0000" & loadDat(15:0)    offset = 4,    counter loadDat(15:0)
#      X"0000" & count(15:0)      offset = 8,    count(15:0) 
#      X"0000" & rinport(15:0)    offset = 0xc,  Registered inport value (inport delayed by one clk period)
#    Output:
#      X"0000" & outport(15:0)    offset = 0x10, outport(15:0) value

addi sp zero 0x100 #Initializing the stack on register x2
addi sp sp -16 #reserving 16byte stack
lui x16 0x0010 # set inport
addi x16 x16 0xc
jal ra InitializeDisplay #Storing PC+4 in the return address register x1
lui x9 0xBEEF # Play location out of bound - exited program
jal zero pollInport # Program contained in this loop

Error:
lui x10 0xDEAD # Play location out of bound - exited program
loop: jal zero loop # Loop forever 

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
    #Adding in user at location (0,00)
    lui x10 0x80000 #user bit memory reference
    or x12 x13 x10 #Used temp register 12 to store user location and maze bits.
    addi x11 x0 0 #Users row position reference 
    sw x12 0x00(x11) #writing the user and maze to display
    jal ra blinkUser
    jal ra blinkUser
    jal ra blinkUser
    addi sp sp -4
    lw ra 0(sp)
    jalr  ra

pollInport:
    addi x20 x0 1 # Right
    addi x21 x0 2 # Left
    addi x22 x0 4 # Up
    addi x23 x0 8 # Down
    lw x18 0x0(x16) # getValues 
    beq x18 x20 moveUser_right
    beq x18 x21 moveUser_left
    beq x18 x22 moveUser_up
    beq x18 x23 moveUser_down
    beq x0 x0 pollInport # else keep looping
    jal zero Error # Should never return

moveUser_right:
    jal ra checkRightValid
	jal ra restoreRowToDefault
    srli x10 x10 0x1 # Shift user right 1
    xor x12 x12 x10 # Draw user into row
    sw x12 0x0(x11)
    jal ra oneSecDelay
    jal zero pollInport

moveUser_left:
    jal ra checkLeftValid
    jal ra restoreRowToDefault
    slli x10 x10 0x1 # Shift user right 1
    xor x12 x12 x10 # Draw user into row
    sw x12 0x0(x11)
    jal ra oneSecDelay
    jal zero pollInport

moveUser_up:
    jal ra checkUpValid
    jal ra restoreRowToDefault   # jump to restore default
    addi x11 x11 0x4 # update User row reference with new current position 
    lw x13 0x0(x11)
    xor x12 x10 x13 # draw user into row
    sw x12 0x0(x11)
    jal ra oneSecDelay
    jal zero pollInport

moveUser_down:
    jal ra checkDownValid
    jal ra restoreRowToDefault   # jump to   and save position to ra
    addi x11 x11 0xFFFFFFFC # update User row reference with new current position 
    lw x13 0x0(x11) # Store maze values one row below current user row
    xor x12 x10 x13 # draw user into row
    sw x12 0x0(x11)
    jal ra oneSecDelay
    jal zero pollInport

restoreRowToDefault:
    lw x12 0x0(x11) # Read memory of row that user is currently on (User row stored in x11, x13 temp reg)
    xori x13 x10 0xFFFFFFFF # Invert user current location in row (x14 temp, x10 user pos)
    and x12 x13 x12 # AND original row with inverted user to restore to default 
    sw x12 0x0(x11) # Restore current row to default no immediate value - write to user current row
    ret

checkUpValid:
	addi x21 x0 0x38
    beq x11 x21 pollInport
    lw x24 0x4(x11) # get row above
    and x21 x24 x10 # if user can move up AND should be 0 
    bne x21 x0 pollInport #return to checking if above is high
	ret

checkDownValid:
    beq x11 x0 pollInport # If row is 0 don't move down
    lw x24 0xFFFFFFFC(x11) # get row below
    and x22 x24 x10 # if user can move down 
    bne x22 x0 pollInport
    ret

checkLeftValid:
    lui x13 0x80000
    beq x13 x10 pollInport # go back to poll if at most left
    lw x24 0x0(x11)
    slli x14 x10 1 
    and x14 x24 x14
    bne x14 x0 pollInport
    ret

 checkRightValid:
    addi x13 x0 0x1
    beq x10 x13 pollInport # return to poll if at right arena wall
    lw x24 0(x11)
    srli x14 x10 1
    and x14 x24 x14
    bne x14 x0 pollInport
    ret

blinkUser:
    sw ra 0(sp)  #Pushing the return address to the stack pointer.
    addi sp sp 4
    jal ra restoreRowToDefault # remove
    jal ra oneSecDelay
    xor x12 x12 x10
    sw x12 0x0(x11) # add
    jal ra oneSecDelay
    addi sp sp -4
    lw ra 0(sp)
    ret

oneSecDelay:
    sw ra 0(sp)  #Pushing the return address to the stack pointer.
    addi sp sp 4
    lui x17 0x00601
    jal ra oneSecLoop
    addi sp sp -4
    lw ra 0(sp)
    ret

oneSecLoop:   
    addi x17 x17 -1           # decr delay counter
    bne  x17 x0, oneSecLoop # branch: loop if x12 != 0
    ret
