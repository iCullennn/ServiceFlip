# 🔁 Service Switcher Script

This PowerShell script allows you to safely switch between two versions of a Windows service by renaming their root folders and restarting the service. It includes logging for auditing and troubleshooting.

---

## 📁 Features
- Stops the running Windows service.
- Renames the current active version to a versioned folder.
- Promotes the alternative version to active.
- Restarts the service.
- Logs all operations to a specified log file.

---

## ⚙️ Parameters

```
-switch $Flip
```

- `-Flip` (optional): Flips to the other version (e.g., from 202 ➝ 212 or vice versa).
- If omitted, it assumes you're flipping back.

---

## 📄 Example

```
.\Switch-Service.ps1 -Flip
```

---

## 📌 Notes
- You must set:
  - `$Service`: The service display name.
  - `$ServicePath`: Path to the directory containing service folders.
  - `$Version202` and `$Version212`: Folder names for each version.
- Make sure both version folders exist in the specified path.