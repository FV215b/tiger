	.globl main
	.data

	.text
main:
	sw	$fp	0($sp)
	move	$fp	$sp
	addiu	$sp	$sp	-20
L14:
sw $fp, 4($a0)
move $t0, $ra
move $ra, $s0
move $k1, $s1
move $k0, $s2
move $gp, $s3
move $a3, $s4
move $a2, $s5
move $a1, $s6
move $a0, $s7
lw $rv, -4($fp)


move $s7, $a0
move $s6, $a1
move $s5, $a2
move $s4, $a3
move $s3, $gp
move $s2, $k0
move $s1, $k1
move $s0, $ra
move $ra, $t0
b L13
L13:

	move	$sp	$fp
	lw	$fp	0($sp)
	jr	$ra

