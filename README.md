[![EN](https://user-images.githubusercontent.com/9499881/33184537-7be87e86-d096-11e7-89bb-f3286f752bc6.png)](https://github.com/litecatalog/LiteCatalog/) 
[![RU](https://user-images.githubusercontent.com/9499881/27683795-5b0fbac6-5cd8-11e7-929c-057833e01fb1.png)](https://github.com/litecatalog/LiteCatalog/blob/master/README.RU.md)
 ← Choose language | Выберите язык

# Lite Catalog
Catalog of open-source, free, and useful applications for Windows, with download and installation support.

## 🖼️ Screenshots
[![](https://github.com/user-attachments/assets/01fb6dff-4ca4-41d8-9068-ec7d48015bb0)](https://github.com/user-attachments/assets/a1a3dd20-a728-4aec-9b53-4292c6ef1a21)
[![](https://github.com/user-attachments/assets/926fdee4-6a3f-48b6-9848-bbd57e0f8896)](https://github.com/user-attachments/assets/2c62c9af-2ae6-4eca-8abd-3473298168b4)
[![](https://github.com/user-attachments/assets/fd14950e-faaa-4654-915a-aa1152d695d3)](https://github.com/user-attachments/assets/9a1d3e9d-7550-4b85-8f89-4ed0732ac751)
[![](https://github.com/user-attachments/assets/c411ee04-1ec7-4ee0-be66-a336b71a8afd)](https://github.com/user-attachments/assets/3d181cee-2f3d-4003-b2b6-9ed83ef89c17)
[![](https://github.com/user-attachments/assets/321ff138-2c96-42ea-b811-dfc898795a65)](https://github.com/user-attachments/assets/1e6c4b74-df0b-4c51-af44-9e0817bad54b)

## ✨ Features
✔️ **Checksum verification** - most downloaded files are verified using SHA-1 hashes, ensuring the authenticity and integrity of the downloaded files.<br>
✔️ **Older versions** - archived versions are available for some programs, compatible with legacy Windows versions.<br>
✔️ **Automatic installation of portable applications** - archives (`zip`, `7z`, `rar`) are automatically extracted to the programs folder (`C:\Programs\` by default), with desktop shortcuts created automatically.<br>
✔️ **Silent installation mode** - installation can be performed in the background without dialog windows.<br>

## ❤️ Support the Project

You can support the project with a one-time donation or a subscription [here](https://boosty.to/r57).


Your contribution helps develop and maintain the project.

## 🚀 Download
>Version for Windows 10 and 11.

**[Download](https://github.com/litecatalog/LiteCatalog/releases)**

## 📂 Application Categories

| Category | Description |
|----------|-------------|
| 🌐 Internet and Networking | Browsers, messengers, VPNs, FTP clients |
| 📄 Office and Productivity | Office suites, editors, readers |
| 🎵 Multimedia | Media players, image editors, audio/video tools |
| 🎮 Games and Utilities | Gaming utilities and helper tools |
| 🛠️ System Utilities | System, cleanup, and monitoring tools |
| 💻 Development and Engineering | IDEs, code editors, developer tools |
| 📦 Other | Other useful applications |


## 📦 Adding Applications

### Suggest an Application

The catalog aims to collect the best: popular, useful, and time-tested programs with minimal duplicates. If you know a worthy candidate, suggest it via [Issues](https://github.com/litecatalog/AppsDB/issues). Having a Wikipedia article and a repository with releases on GitHub will be a plus.

If an application hasn’t been added, don’t be discouraged. There may already be a good alternative in the catalog. If you think otherwise, provide arguments — this will help make the right decision.

### Add by Yourself

Each application is described with an INI file in the `Apps\<Category>\` folder. After creating it, you can [propose a Pull Request](https://github.com/litecatalog/AppsDB/pulls) or [submit a ready-made file](https://github.com/litecatalog/AppsDB/issues).

Key fields:

| Field | Description |
|------|------------|
| `DownloadURL.x86` / `DownloadURL.x64` | Direct download links |
| `SHA1.x86` / `SHA1.x64` | File checksums |
| `SizeBytes.x86` / `SizeBytes.x64` | File size in bytes |
| `HashCheck` | Hash verification (1 - yes, 0 - no) |
| `SilentParams` | Silent installation parameters, "%PROGRAMS%" is replaced with the selected programs folder |
| `NoArchiveNoInstaller` | The file is a standalone program (e.g., the link points directly to an exe file) |
| `ArchiveDesktopShortcuts` | Shortcuts for portable apps (`<Name>=<Path in archive to app>`, separated by `;`) |
| `ArchiveHasInstaller` | The archive contains an installer (1 - yes) |
| `ArchiveInstallerName` | Installer name inside the archive |

To automatically calculate file hashes and sizes, use the debug tool. Enable debug mode by setting `Debug` to `1` in the `Config.ini` file. Then, in the menu, choose `Calculate hashes and URL sizes from config`. You can also view the shortened locale name there.

To translate to other languages, create a section with the necessary parameters: `[App.Locale.<locale_name>]`.


Older versions of programs for specific Windows versions can be specified in the corresponding sections: `[App.Windows10]`, `[App.Windows8.1]`, `[App.Windows8]`, `[App.Windows7]`, `[App.WindowsVista]`, and `[App.WindowsXP]`.

## 📧 Feedback
`r57zone[at]gmail.com`