	.globl main
	.data

	.text
main:
	sw	$fp	0($sp)
	move	$fp	$sp
	addiu	$sp	$sp	-20
L8:
sw $fp, 4($a0)
move $t1, $ra
move $t0, $s0
move $s0, $s1
move $ra, $s2
move $k1, $s3
move $k0, $s4
move $gp, $s5
move $a3, $s6
move $a2, $s7
li $a0, 3
sw $fp, -4($a0)
lw $a1, -4($fp)
li $a0, 3
blt $a1, $a0, L4
b L5
L5:
lw $a0, -4($fp)
addiu $a0, $a0, -3
move $a0, $a0
L6:
move $rv, $a0
move $s7, $a2
move $s6, $a3
move $s5, $gp
move $s4, $k0
move $s3, $k1
move $s2, $ra
move $s1, $s0
move $s0, $t0
move $ra, $t1
b L7
L4:
lw $a0, -4($fp)
b L6
L7:

	move	$sp	$fp
	lw	$fp	0($sp)
	jr	$ra

