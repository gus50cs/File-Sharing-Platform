package main

import (
	"fmt"
	"sort"
	"time"
)

type Document struct {
	Name      string
	ShipName  string
	Timestamp []string
	Names     []string // Add the Names field
}

func main() {
	// Create an array of Document instances
	documents := []Document{
		{
			Name:     "DocumentLNG",
			ShipName: "Ship1",
			Timestamp: []string{
				"02:38:04 01-10-2023",
				"01:14:59 01-10-2023",
				"02:37:10 01-10-2023",
			},
			Names: []string{ // Add corresponding Names entries
				"John",
				"Mike",
				"Albon",
			},
		},
		{
			Name:     "Document1",
			ShipName: "Ship2",
			Timestamp: []string{
				"19:01:01 01-10-2023",
				"21:29:32 02-10-2023",
				"20:35:41 02-10-2023",
			},
			Names: []string{ // Add corresponding Names entries
				"Anna",
				"Bob",
				"Charlie",
			},
		},
		// Add other Document instances here...
	}

	// Sort the Timestamp arrays and apply the same order to Names for each Document
	for i := range documents {
		sortTimestampsAndNames(&documents[i])
	}

	// Print the sorted documents with Names
	for _, doc := range documents {
		fmt.Printf("Name: %s, Ship: %s, Timestamps in chronological order:\n", doc.Name, doc.ShipName)
		for i, ts := range doc.Timestamp {
			fmt.Printf("%s (%s)\n", ts, doc.Names[i])
		}
	}
}

// Function to reorder Timestamps and Names based on Timestamps
func sortTimestampsAndNames(doc *Document) {
	sortedData := make([]struct {
		Timestamp string
		Name      string
	}, len(doc.Timestamp))

	// Populate the sortedData slice
	for i := range doc.Timestamp {
		sortedData[i] = struct {
			Timestamp string
			Name      string
		}{doc.Timestamp[i], doc.Names[i]}
	}

	// Sort the sortedData slice based on Timestamps
	sort.SliceStable(sortedData, func(i, j int) bool {
		timeI, _ := time.Parse("15:04:05 02-01-2006", sortedData[i].Timestamp)
		timeJ, _ := time.Parse("15:04:05 02-01-2006", sortedData[j].Timestamp)
		return timeI.Before(timeJ)
	})

	// Update the Timestamps and Names fields based on sortedData
	for i, data := range sortedData {
		doc.Timestamp[i] = data.Timestamp
		doc.Names[i] = data.Name
	}
}
