#!/bin/bash

# Verify and prepare GCP Service Account Key for GitHub Secrets

echo "=========================================="
echo "GCP Key Verification Tool"
echo "=========================================="
echo ""

# Check if gcp-key.json exists
if [ ! -f "gcp-key.json" ]; then
    echo "❌ gcp-key.json not found!"
    echo "Run: ./fix-gcp-permissions.sh your-project-id"
    exit 1
fi

echo "✅ gcp-key.json found"
echo ""

# Validate JSON format
if ! jq empty gcp-key.json 2>/dev/null; then
    echo "❌ gcp-key.json is not valid JSON"
    exit 1
fi

echo "✅ JSON format is valid"
echo ""

# Extract key info
PROJECT_ID=$(jq -r '.project_id' gcp-key.json)
EMAIL=$(jq -r '.client_email' gcp-key.json)

echo "📋 Service Account Details:"
echo "   Project ID: $PROJECT_ID"
echo "   Email: $EMAIL"
echo ""

# Display instructions
echo "=========================================="
echo "Instructions for GitHub Secrets"
echo "=========================================="
echo ""
echo "1. Go to GitHub Repository"
echo "2. Settings → Secrets and variables → Actions"
echo ""
echo "3. Create/Update these secrets:"
echo ""
echo "   Secret 1: GCP_PROJECT_ID"
echo "   ├─ Value: $PROJECT_ID"
echo ""
echo "   Secret 2: GCP_SA_KEY"
echo "   ├─ IMPORTANT: Paste the ENTIRE content below"
echo "   ├─ Include all line breaks and formatting"
echo ""
echo "---BEGIN COPY FROM HERE---"
cat gcp-key.json
echo ""
echo "---END COPY HERE---"
echo ""

# Count characters for verification
CHAR_COUNT=$(wc -c < gcp-key.json)
echo "📊 Total characters: $CHAR_COUNT"
echo ""

# Verify required fields
REQUIRED_FIELDS=("type" "project_id" "private_key_id" "private_key" "client_email" "token_uri")
MISSING_FIELDS=()

for field in "${REQUIRED_FIELDS[@]}"; do
    if ! jq -e ".$field" gcp-key.json > /dev/null 2>&1; then
        MISSING_FIELDS+=("$field")
    fi
done

if [ ${#MISSING_FIELDS[@]} -eq 0 ]; then
    echo "✅ All required fields are present in the key"
else
    echo "❌ Missing fields: ${MISSING_FIELDS[*]}"
    exit 1
fi

echo ""
echo "✅ Key verification complete!"
