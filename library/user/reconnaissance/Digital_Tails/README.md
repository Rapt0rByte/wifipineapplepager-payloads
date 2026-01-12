# Digital Tails — Persistent Device Tracker  
#Author - Notorious Squirrel
**Hak5 WiFi Pineapple Pager**

Digital Tails is a passive, wardriver-style awareness payload for the WiFi Pineapple Pager.  
Its purpose is to highlight devices that remain persistently nearby over time, which may indicate that a device (and potentially its owner) is staying close to you (tailing you).

⚠️ This is not a tracking or surveillance tool — it does not follow people, inject packets, deauthenticate, or associate with networks.  
It simply analyses existing recon data collected by the Pineapple.

---

- What Digital Tails does

- Reads client device data from `recon.db`
- Tracks how often a device appears across repeated scans
- Highlights devices that:
  - stay nearby for long periods
  - remain close (strong RSSI)
- Displays the most persistent devices on the Pager screen

This is useful for:
- situational awareness while walking or travelling
- spotting unusually persistent nearby devices
- learning how noisy or stable an RF environment is

---

# How it works 

1. Recon data source
   - Reads from:
     ```
     /mmc/root/recon/recon.db
     ```
   - Uses the `wifi_device` table

2. Seen list
   - Builds a list of devices seen in the most recent DB rows
   - Stored as:
     ```
     /tmp/digital_tails/seen.psv
     ```

3. Rolling history
   - Each device is tracked using a rolling bit window
   - Example:
     ```
     011011101101
     ```
   - `1` = seen this scan  
   - `0` = not seen

4. Persistence calculation
   - Counts how many `1`s appear in the window
   - This becomes the **persistence score**

5. Sorting
   - Devices are ranked by:
     1. Persistence count
     2. RSSI strength

6. Display
   - Top devices are shown on screen with:
     - short MAC
     - persistence score
     - RSSI
     - signal bar

---

 Screen output explained 

Example: !! 56:78:9A:BC seen:9/12 rssi:-52 #######


 Symbols
- `!!`  
  Persistent **and** strong signal (likely close)
- `! `  
  Persistent but weaker signal
- (blank)  
  Not persistent enough yet

 Fields
- `56:78:9A:BC`  
  Shortened MAC (last 4 bytes)
- `seen:9/12`  
  Seen in 9 of the last 12 scans
- `rssi:-52`  
  Signal strength (higher = closer)
- `#######`  
  Visual signal bar

---

 Configuration 

```bash
SCAN_INTERVAL=5        # seconds between scans
WINDOW_SCANS=12        # history window (~60 seconds)
PERSIST_MIN=7          # minimum seen count to flag
STRONG_RSSI=-55        # close proximity threshold
MAX_SHOW=8             # max devices shown
SAMPLE_ROWS=2500       # DB rows sampled each loop

