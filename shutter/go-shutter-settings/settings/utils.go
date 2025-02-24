package settings

import (
	"fmt"
	"os"
	"reflect"
	"strconv"
	"strings"

	"github.com/pelletier/go-toml/v2"
)

func UnmarshallFromFile(filePath string, destination interface{}) error {
	// Read the file
	fileContent, err := os.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("error reading file %s: %v", filePath, err)
	}

	// Unmarshal the file content into the destination
	err = toml.Unmarshal(fileContent, destination)
	if err != nil {
		return fmt.Errorf("error unmarshalling file %s: %v", filePath, err)
	}

	return nil
}

func MarshalToFile(filePath string, data interface{}) error {
	    // Marshal the modified configuration to TOML format
		modifiedConfig, err := toml.Marshal(data)
		if err != nil {
			return fmt.Errorf("error marshalling modified config to TOML: %v", err)
		}
	
		// Write the modified configuration to the output file
		err = os.WriteFile(filePath, modifiedConfig, 0644)
		if err != nil {
			return fmt.Errorf("error writing modified TOML file: %v", err)
		}

		return nil
}

// populateFromEnv uses reflection to populate struct fields based on the `env` tag
func PopulateFromEnv(cfg interface{}) {
	v := reflect.ValueOf(cfg).Elem()
	t := v.Type()

	for i := 0; i < v.NumField(); i++ {
		field := v.Field(i)
		structField := t.Field(i)
		tag := structField.Tag.Get("env")

		if tag != "" {
			// Handle basic types (string, bool, int, etc.)
			envValue := os.Getenv(tag)
			if envValue != "" {
				SetFieldValue(field, envValue)
			}
		}

		// If the field is another struct, recurse into it
		if field.Kind() == reflect.Struct {
			PopulateFromEnv(field.Addr().Interface())
		}
	}
}

func SetFieldValue(field reflect.Value, envValue string) {
	switch field.Kind() {
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		// Convert string to integer
		intValue, _ := strconv.ParseInt(envValue, 10, 64)
		field.SetInt(intValue)
	case reflect.Bool:
		// Convert string to boolean
		boolValue, _ := strconv.ParseBool(envValue)
		field.SetBool(boolValue)
	case reflect.Slice:
		// Remove brackets from the string
		envValue = strings.TrimSpace(envValue[1 : len(envValue)-1])

		// Remove quotes
		envValue = strings.ReplaceAll(envValue, `"`, "")
		
		// Split by commas
		slice := strings.Split(envValue, ",")

		// Trim spaces from each element
		for i := range slice {
			slice[i] = strings.TrimSpace(slice[i])
		}
		field.Set(reflect.ValueOf(slice))
	default:
		field.SetString(envValue)
	}
}

func ApplyConfigToGenerated(config reflect.Value, generatedConfig *map[string]interface{}, fieldNameFormatter func(string) string) {
	// Get the type of the config
	configType := config.Type()

	// Iterate through all the fields in the keyper config
	for i := 0; i < config.NumField(); i++ {
		fieldValue := config.Field(i)
		fieldType := configType.Field(i)

		fieldName := fieldType.Name
		if fieldNameFormatter != nil {
			// To avoid issues with private fields, use the field name formatter
			fieldName = fieldNameFormatter(fieldType.Name)
		}
		

		// Convert the field name to its TOML equivalent
		if fieldValue.Kind() == reflect.Struct {
			// If the field is a struct, recursively apply its fields
			if nestedGenerated, ok := (*generatedConfig)[fieldName].(map[string]interface{}); ok {
				ApplyConfigToGenerated(fieldValue, &nestedGenerated, fieldNameFormatter)
				(*generatedConfig)[fieldName] = nestedGenerated
			}
		} else {
			// If the field is not a struct, apply its value to the generated if the key exists
			if _, ok := (*generatedConfig)[fieldName]; ok && !isZeroValue(fieldValue) {
				(*generatedConfig)[fieldName] = fieldValue.Interface()
			}
		}
	}
}

// Helper function to check if a value is the zero value of its type
func isZeroValue(value reflect.Value) bool {
	switch value.Kind() {
	case reflect.Slice, reflect.Array:
		// For slices and arrays, a zero value is when the length is zero
		return value.Len() == 0
	default:
		// Use reflect.Zero comparison for other types
		return reflect.DeepEqual(value.Interface(), reflect.Zero(value.Type()).Interface())
	}
}