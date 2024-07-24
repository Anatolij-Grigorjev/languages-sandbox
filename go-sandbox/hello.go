package main

import (
	"fmt"
	"strings"
)

func main() {
	var something string = ""
	fmt.Scanln(&something)
	something = strings.TrimSpace(something)
	fmt.Printf("hello, %s!", something)
}
