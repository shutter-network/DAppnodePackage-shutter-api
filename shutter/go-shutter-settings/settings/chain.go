package settings

import (
	"fmt"
	"os"
	"reflect"
	"strings"
)

type ChainConfig struct {
	Moniker      string `env:"KEYPER_NAME"`
	Genesis_file string `env:"ASSETS_GENESIS_FILE"`
	P2P          struct {
		Seeds            string `env:"_ASSETS_SHUTTERMINT_SEED_NODES"`
		External_address string `env:"SHUTTER_EXTERNAL_ADDRESS"`
		Addr_book_strict bool   `env:"SHUTTER_ADDR_BOOK_STRICT"`
		Pex              bool   `env:"SHUTTER_P2P_PEX"`
		Laddr            string `env:"SHUTTER_P2P_LADDR"`
	}
	Instrumentation struct {
		Prometheus             bool   `env:"SHUTTER_PUSH_METRICS_ENABLED"`
		Prometheus_listen_addr string `env:"SHUTTER_PROMETHEUS_LISTEN_ADDR"`
	}
}

func AddSettingsToChain(generatedFilePath, outputFilePath string) error {
	var generatedConfig map[string]interface{}

	fmt.Println("Adding user settings to chain...")

	if _, err := os.Stat(generatedFilePath); os.IsNotExist(err) {
		return fmt.Errorf("generated file does not exist: %s", generatedFilePath)
	}

	// Read and unmarshal the keyper config file
	if err := UnmarshallFromFile(generatedFilePath, &generatedConfig); err != nil {
		return err
	}

	chainConfig := getChainConfigFromEnvs()

	// ToLower is used because chain cofig file fields are lower case, but the struct
	// fields are upper case to be exported
	ApplyConfigToGenerated(reflect.ValueOf(chainConfig), &generatedConfig, strings.ToLower)

	MarshalToFile(outputFilePath, generatedConfig)

	fmt.Println("Chain TOML file modified successfully and saved to", outputFilePath)

	return nil
}

func getChainConfigFromEnvs() ChainConfig {
	chainConfig := ChainConfig{}
	PopulateFromEnv(&chainConfig)
	return chainConfig
}
