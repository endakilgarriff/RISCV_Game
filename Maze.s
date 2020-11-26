addi sp zero 0x100 #Initializing the stack on register x2
addi sp sp -16 #reserving 16byte stack
jal ra InitializeDisplay #Storing PC+4 in the return address register x1
lui x9 0xBEEF # Play location out of bound - exited program
jal ra pollInport # Program contained in this loop
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
jal ra blinkUser3
addi sp sp -4
lw ra 0(sp)
jalr  ra

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
    jal x9 restoreRowToDefault
    slli x10 x10 0x1 # Shift user right 1
    xor x12 x12 x10 # Draw user into row
    sw x12 0x0(x11)
    jal x7 oneSecDelay
    jal zero pollInport

moveUser_up:
    jal ra checkUpValid
    jal x9 restoreRowToDefault   # jump to restore default
    addi x11 x11 0x4 # update User row reference with new current position 
    xor x12 x10 x12 # draw user into row
    sw x12 0x0(x11)
    jal x7 oneSecDelay
    jal zero pollInport

moveUser_down:
    jal ra checkDownValid
    jal x9 restoreRowToDefault   # jump to   and save position to ra
    addi x11 x11 0xFFFFFFFC # update User row reference with new current position 
    lw x12 0x0(x11) # Store maze values one row below current user row
    xor x12 x10 x12 # draw user into row
    sw x12 0x0(x11)
    jal x7 oneSecDelay
    jal zero pollInport

restoreRowToDefault:
    lw x12 0x0(x11) # Read memory of row that user is currently on (User row stored in x11, x13 temp reg)
    xori x13 x10 0xFFFFFFFF # Invert user current location in row (x14 temp, x10 user pos)
    and x12 x13 x12 # AND original row with inverted user to restore to default 
    sw x12 0x0(x11) # Restore current row to default no immediate value - write to user current row
    jalr ra

checkUpValid:
	addi x21 x0 0x3c
    beq x11 x21 pollInport
    lw x24 0x4(x11) # get row above
    and x21 x24 x10 # if user can move up AND should be 0 
    bne x21 x0 pollInport #return to checking if above is high
	jalr ra

checkDownValid:
    beq x11 x0 pollInport # If row is 0 don't move down
    lw x24 0xFFFFFFFC(x11) # get row below
    and x22 x24 x10 # if user can move down 
    bne x22 x0 pollInport
    jalr ra

checkLeftValid:
    lui x13 0x80000
    lw x24 0(x11)
    beq x13 x24 pollInport # go back to poll if at most left
    slli x14 x10 1 
    xor x14 x25 x14
    bne x14 x0 pollInport
    jalr ra

 checkRightValid:
    addi x13 x0 0x1
    beq x10 x13 pollInport # return to poll if at right arena wall
    lw x24 0(x11)
    srli x14 x10 1
    xor x14 x25 x14
    bne x14 x0 pollInport
    jalr ra

pollInport:
addi x20 x0 1
addi x21 x0 2
addi x22 x0 4
addi x23 x0 8
lui x12 0x0010 # set inport
addi x12 x12 0xc
lw x15 0x0(x12) # getValues 
beq x15 x20 moveUser_right
beq x15 x21 moveUser_left
beq x15 x22 moveUser_up
beq x15 x23 moveUser_down
beq x0 x0 pollInport # else keep looping

  
blinkUser3:
sw ra 0(sp)  #Pushing the return address to the stack pointer.
addi sp sp 4
lw x12 0x0(x11) #user location and maze bits.
xori x13 x10 0xFFFFFFFF # Invert user current location in row (x14 temp, x10 user pos)
and x15 x13 x12 # NO USER MAZE BITS
sw x15 0x0(x11) # remove
jal ra oneSecDelay
sw x12 0x0(x11) # add
jal ra oneSecDelay
sw x15 0x0(x11) # remove
jal ra oneSecDelay
sw x12 0x0(x11) # add
jal ra oneSecDelay
sw x15 0x0(x11) # remove
jal ra oneSecDelay
sw x12 0x0(x11) # add
addi sp sp -4
lw ra 0(sp)
jalr ra

oneSecDelay:
sw ra 0(sp)  #Pushing the return address to the stack pointer.
addi sp sp 4
lui x14 0x00601
jal ra oneSecLoop
addi sp sp -4
lw ra 0(sp)
jalr ra

oneSecLoop:   
addi x14 x14 -1           # decr delay counter
bne  x14 x0, oneSecLoop # branch: loop if x12 != 0
jalr ra
