	.globl main
	.data

	.text
main:
	sw	$fp	0($sp)
	move	$fp	$sp
	addiu	$sp	$sp	-20
L2:
sw $fp, 4($a0)
move $k0, $ra
move $k1, $s0
move $s0, $s1
move $s1, $s2
move $s2, $s3
move $s3, $s4
move $s4, $s5
move $s5, $s6
move $s6, $s7
addiu $a0, $fp, -4
move $gp, $a0
move $s7, $t0
move $t0, $t1
move $t1, $t2
move $t2, $t3
move $t3, $t4
move $t4, $t5
move $t5, $t6
move $t6, $t7
move $t7, $t8
move $t8, $t9
move $t9, $v0
move $v0, $v1
la $a1, allocRecord
li $a0, 8
move $a0, $a0
jalr $a1
move $v1, $v0
move $v0, $t9
move $t9, $t8
move $t8, $t7
move $t7, $t6
move $t6, $t5
move $t5, $t4
move $t4, $t3
move $t3, $t2
move $t2, $t1
move $t1, $t0
move $t0, $s7
move $a1, $rv
li $a0, 0
sw $a1, 0($a0)
li $a0, 0
sw $a1, 4($a0)
sw $a1, 0($gp)
lw $rv, -4($fp)
move $s7, $s6
move $s6, $s5
move $s5, $s4
move $s4, $s3
move $s3, $s2
move $s2, $s1
move $s1, $s0
move $s0, $k1
move $ra, $k0
b L1
L1:

	move	$sp	$fp
	lw	$fp	0($sp)
	jr	$ra

