#!/bin/bash

# Directory waar de gegenereerde YAML-bestanden per student zijn opgeslagen
OUTPUT_DIR="./generated"

# Bestand met verbindingsinformatie
INFO_FILE="connection_info.txt"

# Verwijderen van Kubernetes resources
cleanup_k8s_resources() {
  echo "Verwijderen van Kubernetes resources..."

  # Controleer of de output directory bestaat
  if [[ ! -d "$OUTPUT_DIR" ]]; then
    echo "Geen gegenereerde bestanden gevonden om te verwijderen."
    return
  fi

  # Loop door alle gegenereerde student directories
  for STUDENT_DIR in "$OUTPUT_DIR"/*; do
    if [[ -d "$STUDENT_DIR" ]]; then
      echo "Verwerken van $STUDENT_DIR..."
      for YAML_FILE in "$STUDENT_DIR"/*.yaml; do
        if [[ -f "$YAML_FILE" ]]; then
          echo "Verwijderen van resource gedefinieerd in $YAML_FILE..."
          kubectl delete -f "$YAML_FILE" --ignore-not-found
        fi
      done
    fi
  done
}

# Verwijderen van gegenereerde bestanden en directories
cleanup_files() {
  echo "Verwijderen van gegenereerde bestanden en directories..."
  if [[ -d "$OUTPUT_DIR" ]]; then
    rm -rf "$OUTPUT_DIR"
    echo "Gegenereerde bestanden en directories verwijderd."
  fi

  if [[ -f "$INFO_FILE" ]]; then
    rm -f "$INFO_FILE"
    echo "Verbindingsinformatiebestand $INFO_FILE verwijderd."
  fi
}

# Uitvoeren van de cleanup functies
cleanup_k8s_resources
cleanup_files

echo "Cleanup voltooid."
