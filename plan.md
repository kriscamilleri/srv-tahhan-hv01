# Plan: Integrate Google Coral TPU with Frigate in Proxmox LXC

## Current Environment
- **Proxmox Host:** 192.168.0.100
- **Frigate LXC:** ID 151 (`dk-tahhan-fri01`)
- **Deployment:** Frigate runs as a privileged Docker container inside the LXC.
- **Coral Device:** Detected on host at `Bus 002 Device 002` (ID `1a6e:089a`).

## Implementation Steps

### 1. Configure LXC USB Passthrough
To ensure the Coral remains accessible even if its Device ID changes after initialization, we will pass through the entire USB bus.
- **File:** `/etc/pve/lxc/151.conf` on the host.
- **Action:** Add the following lines:
  ```
  lxc.cgroup2.devices.allow: c 189:* rwm
  lxc.mount.entry: /dev/bus/usb/002 dev/bus/usb/002 none bind,optional,create=dir
  ```
  *Note: Already some `lxc.cgroup2.devices.allow: c 189:* rwm` exists, will verify and merge.*

### 2. Verify Device inside LXC
After restarting the LXC, verify that `/dev/bus/usb/002/` exists and contains the Coral device.

### 3. Update Frigate Configuration
Modify the Frigate `config.yml` to use the EdgeTPU for inference and enable detection.
- **File:** `/root/frigate/config/config.yml` (inside LXC).
- **Actions:**
  - **Add Detector:**
    ```yaml
    detectors:
      coral:
        type: edgetpu
        device: usb
    ```
  - **Enable Global/Camera Detection:**
    Update the `motion` and `detect` blocks for each camera (or globally) from `enabled: false` to `enabled: true`.
    ```yaml
    # Example for Doorbell
    cameras:
      Doorbell:
        ffmpeg:
          inputs:
            - path: rtsp://admin:THX1Logitech@192.168.254.14/onvif1
              roles:
                - record
                - detect  # Add detect role to the stream
        motion:
          enabled: true
        detect:
          enabled: true
    ```
  - **Define Objects:**
    Specify which objects to track globally or per camera:
    ```yaml
    objects:
      track:
        - person
        - dog
        - cat
        - car
    ```

### 4. Optimize Hardware Acceleration (Optional)
The current configuration uses `preset-vaapi`. We should ensure the `detect` role is assigned to the appropriate RTSP streams to trigger the Coral.

### 5. Restart and Validation
1. Restart the LXC container: `pct reboot 151`.
2. Check Frigate logs: `docker logs frigate`.
3. Verify the "System" tab in Frigate UI shows the TPU as the detector.
