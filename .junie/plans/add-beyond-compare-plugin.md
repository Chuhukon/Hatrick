---
sessionId: session-260916-164805-hsmr
---

# Requirements

### Overview & Goals
Add a plugin for Beyond Compare to the Hatrick system, allowing users to easily install this powerful file and folder comparison tool.

### Scope
- **In Scope**: Creating a plugin script that detects and installs Beyond Compare on Fedora-based systems.
- **Out of Scope**: Providing license keys or managing user registration for Beyond Compare.

### Functional Requirements
- The plugin must accurately detect if Beyond Compare is already installed.
- The plugin must automatically download and install the official RPM package.
- The installation should be performed using `dnf` to ensure dependencies are handled.

# Technical Design

### Current Implementation
Plugins in Hatrick are implemented as standalone shell scripts located in the `plugins/` directory. Each script must define:
- `PLUGIN_DESC`: A short description of the plugin.
- `plugin_detect()`: A function that returns 0 if the software is installed and non-zero otherwise.
- `plugin_install()`: A function that performs the installation.

### Proposed Changes
A new plugin script `plugins/40-tooling/beyond-compare.sh` will be added.

#### Technical Details
- **Detection**: Use `rpm -q bcompare` to check if the package is installed.
- **Installation**: 
    - Target version: `5.2.5.32528` (latest stable as of current research).
    - Download URL: Derived from official Scooter Software patterns.
    - Tool: `sudo dnf install` for the local RPM file.

#### File Structure
- `plugins/40-tooling/beyond-compare.sh` (New file)

#### Implementation Pseudocode
```bash
PLUGIN_DESC="Beyond Compare (file and folder compare/merge tool)"
VERSION="5.2.5.32528"

plugin_detect() {
    rpm -q bcompare >/dev/null 2>&1
}

plugin_install() {
    # Download the RPM
    curl -L -o "$HATRICK_TMP/bcompare.rpm" "https://www.scootersoftware.com/download/bcompare-${VERSION}.x86_64.rpm"
    
    # Install via dnf
    sudo dnf install -y "$HATRICK_TMP/bcompare.rpm"
    
    # Cleanup
    rm "$HATRICK_TMP/bcompare.rpm"
}
```

# Delivery Steps

###   Step 1: implement-beyond-compare-plugin
The Beyond Compare plugin is created and integrated into the system.

- Create `plugins/40-tooling/beyond-compare.sh`.
- Implement `plugin_detect()` to check for the existence of the `bcompare` package using `rpm -q`.
- Implement `plugin_install()` to:
    - Download the latest Beyond Compare RPM package (version 5.2.5.32528) from the official Scooter Software source.
    - Install the package using `sudo dnf install`.
    - Clean up the downloaded RPM file.
- Add `PLUGIN_DESC="Beyond Compare (file and folder compare/merge tool)"`.