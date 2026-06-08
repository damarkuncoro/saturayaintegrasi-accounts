#!/bin/bash
# test_all_core_and_standardization_urls.sh
# Comprehensive testing script for BOTH Satu Raya Core and Satu Raya Standardization API endpoints

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0;0m'
BOLD='\033[1m'

echo -e "${BOLD}================================================================${NC}"
echo -e "${BOLD}       SATU RAYA FULL SYSTEM - ALL URLS TEST SUITE               ${NC}"
echo -e "${BOLD}================================================================${NC}"
echo ""

test_url() {
  local service_name="$1"
  local base_url="$2"
  local path="$3"
  local expected_status="$4" # optional expected status, defaults to 200
  
  if [ -z "$expected_status" ]; then
    expected_status=200
  fi
  
  local url="${base_url}${path}"
  
  echo -n -e "[${BOLD}${service_name}${NC}] Testing ${BOLD}${path}${NC} ... "
  
  # Fetch HTTP status and body length
  local response
  response=$(curl -s -w "\n%{http_code}" "$url")
  local status
  status=$(echo "$response" | tail -n 1)
  local body
  body=$(echo "$response" | sed '$d')
  local size=${#body}
  
  if [ "$status" -eq "$expected_status" ]; then
    echo -e "${GREEN}PASS (${status})${NC} - Received ${size} bytes"
    if [[ "$body" == \{* ]] || [[ "$body" == \[* ]]; then
      echo -e "   Snippet: $(echo "$body" | cut -c1-90)..."
    else
      # Strip HTML tags for clean snippet display
      local clean_text
      clean_text=$(echo "$body" | sed -e 's/<[^>]*>//g' | tr -d '\n' | tr -s ' ' | cut -c1-90)
      echo -e "   Snippet: ${clean_text}..."
    fi
  else
    # Check if a 401 is actually expected or acceptable
    if [ "$status" -eq 401 ] && [ "$expected_status" -eq 401 ]; then
      echo -e "${GREEN}PASS (401 Unauthorized - Expected Auth Required)${NC}"
    else
      echo -e "${RED}FAIL (Got ${status}, Expected ${expected_status})${NC}"
      echo -e "   Error detail: $(echo "$body" | cut -c1-200)"
    fi
  fi
  echo ""
}

# ==========================================
# 1. SATU RAYA STANDARDIZATION SERVICE (PORT 3001)
# ==========================================
echo -e "${BOLD}--- 1. STANDARDIZATION SERVICE (PORT 3001) ---${NC}"
STANDARDIZATION_URL="http://localhost:3001"

test_url "Standardization" "$STANDARDIZATION_URL" "/ready"
test_url "Standardization" "$STANDARDIZATION_URL" "/health"

test_url "Standardization" "$STANDARDIZATION_URL" "/api/v1/kbji?page=1&per_page=2"
test_url "Standardization" "$STANDARDIZATION_URL" "/api/v1/kbli?page=1&per_page=2"
test_url "Standardization" "$STANDARDIZATION_URL" "/api/v1/kbki?page=1&per_page=2"

test_url "Standardization" "$STANDARDIZATION_URL" "/api/v1/kbji/00130"
test_url "Standardization" "$STANDARDIZATION_URL" "/api/v1/kbli/A"
test_url "Standardization" "$STANDARDIZATION_URL" "/api/v1/kbki/00112201"

test_url "Standardization" "$STANDARDIZATION_URL" "/api/v1/en/kbji/all"
test_url "Standardization" "$STANDARDIZATION_URL" "/api/v1/en/kbli/all"
test_url "Standardization" "$STANDARDIZATION_URL" "/api/v1/en/kbki/all"

test_url "Standardization" "$STANDARDIZATION_URL" "/api/v1/en/kbji/00130"
test_url "Standardization" "$STANDARDIZATION_URL" "/api/v1/en/kbli/A"
test_url "Standardization" "$STANDARDIZATION_URL" "/api/v1/en/kbki/00112201"

test_url "Standardization" "$STANDARDIZATION_URL" "/api/v1/en/search/kbji/ANGGOTA?page=1&per_page=2"
test_url "Standardization" "$STANDARDIZATION_URL" "/api/v1/en/search/kbli/Pertanian?page=1&per_page=2"
test_url "Standardization" "$STANDARDIZATION_URL" "/api/v1/en/search/kbki/Jagung?page=1&per_page=2"

echo ""

# ==========================================
# 2. SATU RAYA JOBS SERVICE (PORT 3000)
# ==========================================
echo -e "${BOLD}--- 2. SATU RAYA JOBS SERVICE (PORT 3000) ---${NC}"
JOBS_URL="http://localhost:3000"

test_url "Jobs" "$JOBS_URL" "/ready"
test_url "Jobs" "$JOBS_URL" "/health"
test_url "Jobs" "$JOBS_URL" "/"
test_url "Jobs" "$JOBS_URL" "/login"
test_url "Jobs" "$JOBS_URL" "/register"
test_url "Jobs" "$JOBS_URL" "/api/v1/standardizations"
test_url "Jobs" "$JOBS_URL" "/api/v1/worker_profiles" 401
test_url "Jobs" "$JOBS_URL" "/api/v1/employer_profiles" 401

echo ""

# ==========================================
# 3. SATU RAYA BUSINESS SERVICE (PORT 3003)
# ==========================================
echo -e "${BOLD}--- 3. SATU RAYA BUSINESS SERVICE (PORT 3003) ---${NC}"
BUSINESS_URL="http://localhost:3003"

test_url "Business" "$BUSINESS_URL" "/ready"
test_url "Business" "$BUSINESS_URL" "/health"
test_url "Business" "$BUSINESS_URL" "/login"
test_url "Business" "$BUSINESS_URL" "/register"
test_url "Business" "$BUSINESS_URL" "/api/v1/standardizations"
test_url "Business" "$BUSINESS_URL" "/api/v1/worker_profiles" 401
test_url "Business" "$BUSINESS_URL" "/api/v1/employer_profiles" 401

echo -e "${BOLD}================================================================${NC}"
echo -e "${BOLD}                     ALL FULL SYSTEM TESTS COMPLETED             ${NC}"
echo -e "${BOLD}================================================================${NC}"
