<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:02569B,100:005078&height=200&section=header&text=~/dotfiles&fontSize=60&fontColor=ffffff&animation=fadeIn&fontAlignY=38" alt="Dotfiles Banner"/>

<br/>

_Personal configuration of dotfiles for Linux (multiple distros)_

</div>

## 📂 Installation & Management with GNU Stow

These dotfiles are managed using **GNU Stow**, which automatically creates symbolic links from your home directory pointing to the repository.

### Prerequisites
Make sure GNU Stow is installed on your system (`sudo dnf install stow` on Fedora).

### Applying Configurations
To install or refresh the symbolic links in your home directory, run the following command from the root of the repository:
```bash
stow -v -R -t ~ nvim emacs ghostty zathura tmux
```

### Removing Configurations
To safely remove the symbolic links, run:
```bash
stow -v -D -t ~ nvim emacs ghostty zathura tmux
```

## 📸 Screenshots

### Fedora

#### Hyprland
<img width="1919" height="1081" alt="obraz" src="https://github.com/user-attachments/assets/d622e991-343a-480c-91b8-185246cc236b" />

#### GNOME
<img width="1920" height="1080" alt="Zrzut ekranu z 2026-02-11 22-27-36" src="https://github.com/user-attachments/assets/b643fc74-2028-4343-bc52-b668355c0960" />

### Arch Linux
![obraz](https://github.com/user-attachments/assets/cb3f9911-199b-44ae-8d86-e1385b79f877)

### Prerequisites

- **JetBrains Mono** and **Hack Nerd Font** fonts
- Pywall, for automatic changes of colors, when new wallpaper is being set up
