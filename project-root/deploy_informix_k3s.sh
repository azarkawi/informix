#!/bin/bash

# Directory waar de templates zijn opgeslagen
TEMPLATE_DIR="./templates"

# Directory waar de gegenereerde YAML-bestanden per student worden opgeslagen
OUTPUT_DIR="./generated"

# Parameters
read -p "Voer het aantal cursisten in: " NUM_STUDENTS
read -p "Voer de Informix database versie in (bijv. 14.10.FC7W1DE of 12.10.FC12W1DE): " DB_VERSION
BASE_PORT=30000  # Startpoort voor NodePort binnen k3s standaard range

# Verkrijg het IP-adres van de k3s-node
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "Gebruikmakend van Node IP: $NODE_IP"

# Bestand om verbindingsinformatie op te slaan
INFO_FILE="connection_info.txt"
> $INFO_FILE  # Maak het bestand leeg

# Zorg dat de output directory bestaat
mkdir -p $OUTPUT_DIR
# Loop door het aantal cursisten
for ((i=1; i<=NUM_STUDENTS; i++))
do
  STUDENT="student-$i"
  NAMESPACE="${STUDENT}-ns"
  PVC_NAME="${STUDENT}-pvc"
  SECRET_NAME="${STUDENT}-secret"
  CONFIGMAP_NAME="${STUDENT}-config"
  DEPLOYMENT_NAME="${STUDENT}-deploy"
  SERVICE_NAME="${STUDENT}-service"
  NODE_PORT=$((BASE_PORT + i * 2 - 1))  # Unieke nodePort per cursist (2 poorten per service)
  NODE_PORT_PLUS_ONE=$((NODE_PORT + 1))

  echo "Deploying voor $STUDENT..."

  # Maak een unieke directory voor de student
  STUDENT_DIR="${OUTPUT_DIR}/${STUDENT}"
  mkdir -p "$STUDENT_DIR"

  # Vervang placeholders in de templates en sla ze op als specifieke YAML-bestanden
  sed -e "s/{{NAMESPACE}}/${NAMESPACE}/g" \
      -e "s/{{DB_VERSION}}/${DB_VERSION}/g" \
      "$TEMPLATE_DIR/namespace-template.yaml" > "$STUDENT_DIR/namespace.yaml"

  sed -e "s/{{NAMESPACE}}/${NAMESPACE}/g" \
      -e "s/{{DB_VERSION}}/${DB_VERSION}/g" \
      "$TEMPLATE_DIR/configmap-template.yaml" > "$STUDENT_DIR/configmap.yaml"

  sed -e "s/{{NAMESPACE}}/${NAMESPACE}/g" \
      "$TEMPLATE_DIR/pvc-template.yaml" > "$STUDENT_DIR/pvc.yaml"

  sed -e "s/{{NAMESPACE}}/${NAMESPACE}/g" \
      -e "s/{{ENCODED_PASSWORD}}/${ENCODED_PASSWORD}/g" \
      "$TEMPLATE_DIR/secret-template.yaml" > "$STUDENT_DIR/secret.yaml"

  sed -e "s/{{NAMESPACE}}/${NAMESPACE}/g" \
      -e "s/{{DB_VERSION}}/${DB_VERSION}/g" \
      "$TEMPLATE_DIR/deployment-template.yaml" > "$STUDENT_DIR/deployment.yaml"

  sed -e "s/{{NAMESPACE}}/${NAMESPACE}/g" \
      -e "s/{{NODE_PORT}}/${NODE_PORT}/g" \
      -e "s/{{NODE_PORT_PLUS_ONE}}/${NODE_PORT_PLUS_ONE}/g" \
      "$TEMPLATE_DIR/service-template.yaml" > "$STUDENT_DIR/service.yaml"

  sed -e "s/{{NAMESPACE}}/${NAMESPACE}/g" \
      "$TEMPLATE_DIR/pv-template.yaml" > "$STUDENT_DIR/pv.yaml"

  sed -e "s/{{NAMESPACE}}/${NAMESPACE}/g" \
      "$TEMPLATE_DIR/init-informix-permissions-template.yaml" > "$STUDENT_DIR/init-informix-permissions.yaml"

  # Toepassen van de YAML-bestanden op het cluster
  kubectl apply -f "$STUDENT_DIR/namespace.yaml"
  kubectl apply -f "$STUDENT_DIR/pv.yaml"
  kubectl apply -f "$STUDENT_DIR/pvc.yaml"
  kubectl apply -f "$STUDENT_DIR/configmap.yaml"
  kubectl apply -f "$STUDENT_DIR/secret.yaml"
  kubectl apply -f "$STUDENT_DIR/deployment.yaml"
  kubectl apply -f "$STUDENT_DIR/service.yaml"
  kubectl apply -f "$STUDENT_DIR/init-informix-permissions.yaml"

  # Verbindingsinformatie opslaan
  echo "${STUDENT}:${PASSWORD} ${NODE_IP}:${NODE_PORT}" >> $INFO_FILE

  echo "${STUDENT} is succesvol gedeployed in namespace ${NAMESPACE}."
done
