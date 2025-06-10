package settings

import (
	"fmt"
	"os"
	"reflect"
)

type KeyperConfig struct {
	InstanceID           int    `env:"_ASSETS_INSTANCE_ID"`
	DatabaseURL          string `env:"SHUTTER_DATABASEURL"`
	BeaconAPIURL         string `env:"SHUTTER_BEACONAPIURL"`
	MaxNumKeysPerMessage int    `env:"_ASSETS_MAX_NUM_KEYS_PER_MESSAGE"`
	Chain                struct {
		EncryptedGasLimit        int `env:"_ASSETS_ENCRYPTED_GAS_LIMIT"`
		MaxTxPointerAge          int `env:"_ASSETS_MAX_TX_POINTER_AGE"`
		GenesisSlotTimestamp     int `env:"_ASSETS_GENESIS_SLOT_TIMESTAMP"`
		SyncStartBlockNumber     int `env:"_ASSETS_SYNC_START_BLOCK_NUMBER"`
		SyncMonitorCheckInterval int `env:"_ASSETS_SYNC_MONITOR_CHECK_INTERVAL"`
		Node                     struct {
			PrivateKey    string `env:"SHUTTER_API_NODE_PRIVATEKEY"`
			ContractsURL  string `env:"SHUTTER_GNOSIS_NODE_CONTRACTSURL"` //Unused
			DeploymentDir string `env:"SHUTTER_DEPLOYMENT_DIR"`           // Unused
			EthereumURL   string `env:"SHUTTER_NETWORK_NODE_ETHEREUMURL"`
		}
		Contracts struct {
			KeyperSetManager     string `env:"_ASSETS_KEYPER_SET_MANAGER"`
			KeyBroadcastContract string `env:"_ASSETS_KEY_BROADCAST_CONTRACT"`
			ShutterRegistry      string `env:"_ASSETS_SHUTTERREGISTRY"`
		}
	}
	P2P struct {
		P2PKey                   string   `env:"SHUTTER_P2P_KEY"`
		ListenAddresses          []string `env:"SHUTTER_P2P_LISTENADDRESSES"`
		AdvertiseAddresses       []string `env:"SHUTTER_P2P_ADVERTISEADDRESSES"`
		CustomBootstrapAddresses []string `env:"_ASSETS_CUSTOM_BOOTSTRAP_ADDRESSES"`
		DiscoveryNamespace       string   `env:"SHUTTER_DISCOVERY_NAMESPACE"`
		FloodSubDiscovery        struct {
			Enabled bool `env:"FLOODSUB_DISCOVERY_ENABLED"`
		}
	}
	Shuttermint struct {
		ShuttermintURL     string `env:"SHUTTER_SHUTTERMINT_SHUTTERMINTURL"`
		ValidatorPublicKey string `env:"VALIDATOR_PUBLIC_KEY"`
		EncryptionKey      string `env:"SHUTTER_SHUTTERMINT_ENCRYPTION_PUBLIC_KEY"`
		DKGPhaseLength     int    `env:"_ASSETS_DKG_PHASE_LENGTH"`
		DKGStartBlockDelta int    `env:"_ASSETS_DKG_START_BLOCK_DELTA"`
	}
	Metrics struct {
		Enabled bool `env:"SHUTTER_METRICS_ENABLED"`
	}
}

// AddSettingsToKeyper modifies the keyper settings by combining the generated, config, and environment variables.
func AddSettingsToKeyper(generatedFilePath, configFilePath, outputFilePath string) error {
	var keyperConfig KeyperConfig
	var generatedConfig map[string]interface{}

	fmt.Println("Adding user settings to keyper...")

	if _, err := os.Stat(generatedFilePath); os.IsNotExist(err) {
		return fmt.Errorf("generated file does not exist: %s", generatedFilePath)
	}

	if _, err := os.Stat(configFilePath); os.IsNotExist(err) {
		return fmt.Errorf("config file does not exist: %s", configFilePath)
	}

	// Read and unmarshal the keyper config file
	if err := UnmarshallFromFile(configFilePath, &keyperConfig); err != nil {
		return err
	}

	PopulateFromEnv(&keyperConfig)

	// Read and unmarshal the generated file
	if err := UnmarshallFromFile(generatedFilePath, &generatedConfig); err != nil {
		return err
	}

	ApplyConfigToGenerated(reflect.ValueOf(keyperConfig), &generatedConfig, nil)

	MarshalToFile(outputFilePath, generatedConfig)

	fmt.Println("Keyper TOML file modified successfully and saved to", outputFilePath)

	return nil
}
