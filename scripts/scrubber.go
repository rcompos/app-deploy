package main

// Delete Kubernetes secrets in concurrent batches

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"strconv"
	"sync"
)

func main() {
	fileName := flag.String("filename", "secrets.txt", "Name of file")
	batchSize := flag.Int("batchsize", 100, "Batch size")
	concurrencyLimit := flag.Int("concurrencylimit", 100, "Concurrency limit")
	flag.Parse()
	fmt.Println("fileName: ", *fileName)
	fmt.Println("batchSize: ", *batchSize)
	fmt.Println("concurrencyLimit: ", *concurrencyLimit)

	file, err := os.Open(*fileName)
	if err != nil {
		fmt.Println("Error opening file:", err)
		return
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	counter := 0   // total count
	listCount := 0 // current count up to batchSize
	nameList := []string{}

	var wg sync.WaitGroup
	semaphore := make(chan struct{}, *concurrencyLimit) // Limits concurrency

	for scanner.Scan() {
		counter++
		line := scanner.Text()
		cLine := compressWhitespace(line)
		header, _ := regexp.MatchString(`^NAME`, cLine)
		if header { // skip header
			fmt.Println("skipping header")
			continue
		}

		var sname string
		var stype string
		var sdata int
		var sage string
		_, err := fmt.Sscan(cLine, &sname, &stype, &sdata, &sage)
		if err != nil {
			fmt.Println("Error scanning:", err)
			return
		}

		ageDays, _ := regexp.MatchString(`\d+d$`, sage)
		isAttestSecret, _ := regexp.MatchString(`^attest-token-secret-`, sname)
		if !isAttestSecret {
			fmt.Println("Skipping:", sname)
			continue
		}
		if ageDays { // Secret age is at least one day old
			days, _ := strconv.Atoi(sage[:len(sage)-1])
			if days > 1 {
				nameList = append(nameList, sname)
				listCount++
			}
		}
		if listCount > *batchSize {
			fmt.Printf("%d> ", counter)
			listCount = 0
			wg.Add(1)
			semaphore <- struct{}{}
			go func(nl []string, count int) {
				defer func() { <-semaphore }()
				runCommand(nl, count, &wg)
			}(nameList, listCount)
			nameList = []string{}
		}
	}

	if err := scanner.Err(); err != nil {
		fmt.Println("Error reading file:", err)
	}

	if listCount > 0 {
		runCommand(nameList, counter, &wg)
		fmt.Printf("%d> ", counter)
		wg.Add(1)
		semaphore <- struct{}{}
		go func(nl []string, count int) {
			defer func() { <-semaphore }()
			runCommand(nl, count, &wg)
		}(nameList, listCount)
	}

	wg.Wait()
	fmt.Println("All commands executed.")
}

func compressWhitespace(s string) string {
	spaceRegex := regexp.MustCompile(`\s+`)
	return spaceRegex.ReplaceAllString(s, " ")
}

func runCommand(n []string, id int, wg *sync.WaitGroup) {
	defer wg.Done()
	args := []string{"-n", "kubetrust-verifier", "delete", "secret"}
	stringCmd := append(args, n...)
	cmd := exec.Command("kubectl", stringCmd...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println("Error:", err)
	}
	fmt.Printf("Output for %s: %s", id, output)
}
