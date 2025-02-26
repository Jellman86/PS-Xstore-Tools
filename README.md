# PS-Xstore-Tools

A collection of administrative Oracle xStore scripts written in PowerShell. These scripts are designed to help manage and configure Oracle xStore environments. They have been tested against Oracle xStore v20. The variables have been obfuscated behind an `.env` file to allow for generic use and to prevent leaking any sensitive information.

## Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Scripts](#scripts)
  - [update-email-rcpt-sequential-config.ps1](#update-email-rcpt-sequential-configps1)
  - [update-email-rcpt-threaded-config.ps1](#update-email-rcpt-threaded-configps1)

## Introduction

This repository contains PowerShell scripts for managing Oracle xStore environments. The scripts are designed to automate various administrative tasks, such as updating configuration files across multiple machines.

## Prerequisites

Before using these scripts, ensure you have the following prerequisites:

- PowerShell 5.1 or later
- Oracle xStore v20
- Remote management enabled on target machines
- `.env` file with the necessary configuration variables

## Installation

1. Clone the repository to your local machine:

    ```sh
    git clone https://github.com/yourusername/PS-Xstore-Tools.git
    ```

2. Navigate to the repository directory:

    ```sh
    cd PS-Xstore-Tools
    ```

## Configuration

Create a `.env` file in the root directory of the repository with the necessary configuration variables. The `.env` file should contain key-value pairs for the configuration settings required by the scripts. For example:

```env
target.file.path=C:\path\to\config\file
retail.store.machine.list.path=C:\path\to\store\machine\list.xml
email.server.host=smtp.example.com
email.server.port=587
email.server.auth=true
email.server.debug=false
email.user.name=user@example.com
email.user.password=yourpassword
```

## Usage
To use the scripts, open a PowerShell terminal and navigate to the repository directory. Run the desired script with the appropriate parameters.

## Example
To run the update-email-rcpt-sequential-config.ps1 script:

```
.\update-email-rcpt-sequential-config.ps1
```

## Scripts

### update-email-rcpt-sequential-config.ps1
This script updates the email receipt configuration for Oracle xStore environments sequentially. It reads the configuration from the .env file and updates the specified configuration file on each target machine.

### update-email-rcpt-threaded-config.ps1
This script updates the email receipt configuration for Oracle xStore environments in parallel using PowerShell jobs. It reads the configuration from the .env file and updates the specified configuration file on each target machine, with a limit on the number of concurrent jobs.