# Service Version Switcher

A PowerShell script that switches between different installed versions of a Windows service by renaming folders and restarting the service.

---

## 📌 Purpose

This script allows you to quickly switch between major versions of a service installed on a system. It safely stops the service, renames the active and target version folders, and restarts the service.

---

## ⚙️ Requirements

- Windows PowerShell
- Admin rights (to stop/start services and rename folders)
- `Config.json` file in the same directory as the script

---

## 🛠️ Configuration

Create a `Config.json` file like this in the same folder as the script:

```json
{
  "Service": "MyService",
  "ServicePath": "C:\\Path\\To\\MyService\\Installations",
  "VersionList": [201, 202, 203]
}
```

- `Service`: Base name of the service folder and executable (e.g., `MyService.exe`)
- `ServicePath`: Directory containing all version folders
- `VersionList`: Valid major versions to recognize

---

## 🚀 Usage

From PowerShell:

```powershell
.\Flip-Service.ps1 -Version 202
```

The script will:

1. Stop the running service
2. Rename the current root folder to include the version
3. Promote the target version folder to become the root
4. Start the service again
5. Log all actions to `logger.log`

---

## 📂 Folder Structure Example

```
C:\Path\To\MyService\Installations\
├── MyService\
│   └── MyService.exe (v201)
├── MyService 202\
│   └── MyService.exe (v202)
└── MyService 203\
    └── MyService.exe (v203)
```

After flipping to version 202, the structure becomes:

```
C:\Path\To\MyService\Installations\
├── MyService\
│   └── MyService.exe (v202)
├── MyService 201\
│   └── MyService.exe (v201)
└── MyService 203\
    └── MyService.exe (v203)
```

---

## 🧾 Logs

All actions and errors are written to `logger.log` in the script directory.

---

## ✅ Example

```powershell
.\Flip-Service.ps1 -Version 203
```

Output:

```
[2025-05-05 12:00:00] Starting service flip...
[2025-05-05 12:00:01] Stopping service: MyService
[2025-05-05 12:00:02] Renaming root folder to: MyService 201
[2025-05-05 12:00:03] Renaming MyService 203 to: MyService
[2025-05-05 12:00:04] Starting service: MyService
[2025-05-05 12:00:05] Service flip complete. Now running version 203
```

---

## 📝 License

MIT (or your preferred license)
