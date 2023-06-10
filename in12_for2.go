package main

func main() {
	var sum int32 = 0
	var i int32
	for i = 0; i < 10; i++ {
		sum += i
	}
	println(sum)
}