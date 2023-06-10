package main

func main() {
	var a float32 
	var b float32 
	var c int32
	a = 1.8
	c = 9
	b = float32(c) * 3.2 + a
	a = b
	print(a) 
}