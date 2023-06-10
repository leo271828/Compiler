.source hw3.j
.class public Main
.super java/lang/Object
.method public static main([Ljava/lang/String;)V
.limit stack 100
.limit locals 100
	ldc 0.000000
	fstore 0
	ldc 0.000000
	fstore 1
	ldc 0
	istore 2
	fload 0
	ldc 1.800000
	fstore 0
	iload 2
	ldc 9
	istore 2
	fload 1
	iload 2
	i2f
	ldc 3.200000
	fmul
	fload 0
	fadd
	fstore 1
	fload 0
	fload 1
	fstore 0
	fload 0
	getstatic java/lang/System/out Ljava/io/PrintStream;
	swap
	invokevirtual java/io/PrintStream/print(F)V
	return
.end method

