package main

import (
	"flag"
	"fmt"
	"go-shutter-settings/settings"
	"log"
	"os"

	"github.com/joho/godotenv"
)

func main() {
	var generatedFilePath, configFilePath, outputFilePath string

	// Define flags for the generated, config, and output paths
	flag.StringVar(&generatedFilePath, "generated", "", "Path to the generated file where settings will be included")
	flag.StringVar(&configFilePath, "config", "", "Path to the config file where the settings will be read")
	flag.StringVar(&outputFilePath, "output", "", "Path where the modified settings will be saved")

	// Parse the flags
	flag.Parse()

	// Load environment variables from the .env file
	err := godotenv.Load(os.Getenv("ASSETS_DIR") + "/variables.env")
	if err != nil {
		log.Fatalf("Error loading .env file: %v", err)
	}

	// Check for additional arguments, e.g., keyper or chain
	if len(flag.Args()) < 1 {
		fmt.Println("Error: missing argument. Use 'include-keyper-settings' or 'include-chain-settings'.")
		os.Exit(1)
	}

	// Read the argument passed to the program
	argument := flag.Arg(0)

	// Call appropriate function based on the command
	switch argument {
	case "include-keyper-settings":
		// Ensure generated, config, and output paths are provided
		if generatedFilePath == "" || configFilePath == "" || outputFilePath == "" {
			fmt.Println("Error: --generated, --config, and --output flags must be provided for keyper settings.")
			flag.Usage()
			os.Exit(1)
		}

		// Call the function to configure keyper
		err := settings.AddSettingsToKeyper(generatedFilePath, configFilePath, outputFilePath)
		if err != nil {
			log.Fatalf("Failed to configure keyper: %v", err)
		}

	case "include-chain-settings":
		// Ensure config and output paths are provided
		if generatedFilePath == "" || outputFilePath == "" {
			fmt.Println("Error: --config and --output flags must be provided for chain settings.")
			flag.Usage()
			os.Exit(1)
		}

		// Call the function to configure chain
		err := settings.AddSettingsToChain(generatedFilePath, outputFilePath)
		if err != nil {
			log.Fatalf("Failed to configure chain: %v", err)
		}

	default:
		fmt.Println("Invalid argument. Use 'include-keyper-settings' or 'include-chain-settings'.")
		os.Exit(1)
	}

	fmt.Println("Configuration completed successfully!")
}
