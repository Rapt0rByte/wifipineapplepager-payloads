#!/bin/bash
# title: Favorites Manager
# Description: Add or remove payloads from the favorites folder
# Author: RootJunky
# Version: 2

BASE_DIR="/root/payloads/user"
DEST_DIR="/root/payloads/user/1-favorites"

CONFIRMATION_DIALOG "This payload allows you to ADD or REMOVE payloads from your favorites folder"

# Ensure favorites exists
mkdir -p "$DEST_DIR"

LOG "What would you like to do?"
LOG "--------------------------"
LOG "1) Add payload to favorites"
LOG "2) Remove payload from favorites"

LOG green "Press the GREEN button once ready"
WAIT_FOR_BUTTON_PRESS A

ACTION=$(NUMBER_PICKER "Enter a number" 1)

#################################
# REMOVE FROM FAVORITES
#################################
if [ "$ACTION" = "2" ]; then

  mapfile -t FAVORITES < <(
    find "$DEST_DIR" -mindepth 1 -maxdepth 1 -type d
  )

  if [ ${#FAVORITES[@]} -eq 0 ]; then
    ALERT "Favorites folder is empty."
    exit 0
  fi

  LOG
  LOG "Select a favorite to remove:"
  LOG "-----------------------------"

  for i in "${!FAVORITES[@]}"; do
    LOG "$((i+1))) $(basename "${FAVORITES[$i]}")"
  done

  LOG green "Press the GREEN button once ready"
  WAIT_FOR_BUTTON_PRESS A

  rasp_rm=$(NUMBER_PICKER "Enter a number" 1)
  RM_CHOICE="$rasp_rm"

  if ! [[ "$RM_CHOICE" =~ ^[0-9]+$ ]] || ((RM_CHOICE < 1 || RM_CHOICE > ${#FAVORITES[@]})); then
    ALERT "Invalid selection."
    exit 0
  fi

  REMOVE_TARGET="${FAVORITES[$((RM_CHOICE-1))]}"
  REMOVE_NAME=$(basename "$REMOVE_TARGET")

  rm -r "$REMOVE_TARGET"

  LOG "🗑️ '$REMOVE_NAME' removed from favorites."
  exit 0
fi

#################################
# ADD TO FAVORITES
#################################

# Get top-level folders (categories)
mapfile -t CATEGORIES < <(
  find "$BASE_DIR" -mindepth 1 -maxdepth 1 -type d \
  ! -path "$DEST_DIR"
)

if [ ${#CATEGORIES[@]} -eq 0 ]; then
  ALERT "No folders found in $BASE_DIR"
  exit 0
fi

LOG
LOG "Select a category:"
LOG "------------------"

for i in "${!CATEGORIES[@]}"; do
  LOG "$((i+1))) $(basename "${CATEGORIES[$i]}")"
done

LOG green "Press the GREEN button once ready"
WAIT_FOR_BUTTON_PRESS A

rasp2=$(NUMBER_PICKER "Enter a number" 1)
CAT_CHOICE="$rasp2"

if ! [[ "$CAT_CHOICE" =~ ^[0-9]+$ ]] || ((CAT_CHOICE < 1 || CAT_CHOICE > ${#CATEGORIES[@]})); then
  ALERT "Invalid selection."
  exit 0
fi

SELECTED_CATEGORY="${CATEGORIES[$((CAT_CHOICE-1))]}"

# Get payload folders inside selected category
mapfile -t PAYLOADS < <(
  find "$SELECTED_CATEGORY" -mindepth 1 -maxdepth 1 -type d
)

if [ ${#PAYLOADS[@]} -eq 0 ]; then
  ALERT "No payload folders found in $(basename "$SELECTED_CATEGORY")"
  exit 0
fi

LOG
LOG "Select a payload to favorite:"
LOG "-----------------------------"

for i in "${!PAYLOADS[@]}"; do
  LOG "$((i+1))) $(basename "${PAYLOADS[$i]}")"
done

LOG green "Press the GREEN button once ready"
WAIT_FOR_BUTTON_PRESS A

rasp3=$(NUMBER_PICKER "Enter a number" 1)
PAYLOAD_CHOICE="$rasp3"

if ! [[ "$PAYLOAD_CHOICE" =~ ^[0-9]+$ ]] || ((PAYLOAD_CHOICE < 1 || PAYLOAD_CHOICE > ${#PAYLOADS[@]})); then
  ALERT "Invalid selection."
  exit 0
fi

SELECTED_PAYLOAD="${PAYLOADS[$((PAYLOAD_CHOICE-1))]}"
PAYLOAD_NAME=$(basename "$SELECTED_PAYLOAD")

LOG
LOG "Copying '$PAYLOAD_NAME' to favorites..."

cp -r "$SELECTED_PAYLOAD" "$DEST_DIR/"

LOG "'$PAYLOAD_NAME' added to favorites."