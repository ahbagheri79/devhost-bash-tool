# devhost-bash-tool

Lightweight Bash utility for managing local Apache VirtualHosts with custom `.test` domains, hosts file automation, and optional permission fixes. Designed for fast local dev setup.

---

## 🚀 Why Use This Script?

Managing local virtual hosts manually is repetitive and error-prone. This tool fully automates the process:
- Quickly generate VirtualHost configs.
- Automatically map `.test` domains in `/etc/hosts`.
- Handle custom document roots via simple config files.
- Instantly remove projects when no longer needed.
- Laravel-friendly permission fixing.
- Fully portable with no Apache manual editing required.

---

## ✅ Features

- [x] Auto-create VirtualHosts from project folders
- [x] Optional `public-route.txt` for custom document roots
- [x] Auto-update `/etc/hosts`
- [x] Remove domains with `--remove`
- [x] Fix folder permissions with `--fix-permissions`
- [x] Check status with `--status`
- [x] Simple root directory management via `settings.txt`
- [x] Pure Bash, no dependencies

---

## 🛠️ Quick Start

1. Clone this repository.
2. Configure your project root in `settings.txt`:
   ```
   ROOT_DIR=/home/your-user/sites
   ```
3. Place your projects in `$ROOT_DIR/projectname`
4. (Optional) Add `public-route.txt` inside a project if your public folder is not the root.
5. Run the script with any of these options:

---

### Create All Domains:
```bash
sudo bash auto_virtualhosts.sh
```

### Remove a Domain:
```bash
sudo bash auto_virtualhosts.sh --remove:projectname
```

### Fix Laravel Permissions:
```bash
sudo bash auto_virtualhosts.sh --fix-permissions:projectname
```

### Check Domain Status:
```bash
sudo bash auto_virtualhosts.sh --status:projectname
```

---

## 📂 Folder Structure

```
/home/your-user/sites/
│
├── project1/
│   └── public/
│   └── public-route.txt
│
└── domains.txt
└── auto_virtualhosts.sh
└── settings.txt
```

---

## 💡 Notes

- Only tested on Ubuntu (Debian-based distros).
- Sudo required for Apache and hosts file changes.
- Intended for local development purposes only.

---

## 📜 License

MIT License — free to use and modify.
