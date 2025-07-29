# 🃏 Mindi Coat - Card Game (Made with Godot)

A modern digital version of the classic Indian card game **Mindi Coat (Dehla Pakad)**, developed using the **Godot Engine** with a focus on **mobile-friendly performance** and **clean UI**.

---

🎮 A small indie game by **cow2studios**

🐄 Twitter: @cow2studios | 💌 cow2studios@gmail.com

---

## 🎯 Features

- 2D card game built from scratch in Godot
- Fully working card deck generation and shuffle
- Player hand and trick system
- Core Mindi Coat rules implemented:
  - Trump suit reveal
  - Catching the Mindis (7s)
  - Winning Dehla (10s)
- Local multiplayer support (planned)
- Optimized for mobile devices
- Clean, responsive UI
- Minimalist animations and effects

---

## 📱 Platforms

- Android (Primary target)
- Windows (for testing/debugging)

---

## 🚧 Roadmap

- [x] Card scene and logic system
- [x] Basic player hand and trick-taking
- [ ] Trump suit handling
- [ ] Scoring system
- [ ] Full Mindi/Dehla logic
- [ ] AI opponent (optional)
- [ ] Local multiplayer
- [ ] Online multiplayer (stretch goal)

---

## 🗂️ Project Structure

```
res://
├── scenes/
│   ├── Game.tscn        # Main game scene
│   ├── Card.tscn        # Individual card scene
│   ├── Player.tscn      # Player UI and logic
├── scripts/
│   ├── Game.gd
│   ├── Card.gd
│   ├── Player.gd
├── assets/
│   ├── cards/           # Card textures
│   └── ui/              # UI icons, buttons
|   └── Sounds/          # Sounds
```

---

## ▶️ How to Run

1. Clone this repository:

   ```bash
   git clone https://github.com/KavyaJP/MindiCoat.git
   cd MindiCoat
   ```

2. Open the project in [Godot Engine](https://godotengine.org/) (version 4.x recommended)

3. Run the `Game.tscn` scene

---

## 📸 Screenshots

_(Add screenshots here as development progresses)_

---

## 🤝 Contributing

Pull requests are welcome! If you'd like to improve the AI, add UI polish, or help with multiplayer — feel free to fork and submit a PR.

---

## 📜 License

MIT License — Free to use, modify, and share.

---

## 👋 About

Made with ❤️ by **Kau (cow2studios)**  
Follow me on [Twitter](https://twitter.com/cow2studios) for devlogs and updates.

---

## Credits

- [Kenney Playing Cards](https://kenney.nl/assets/playing-cards-pack) for Card Images
- [Kenney Sounds](https://kenney.nl/assets/casino-audio) for sounds
- [Kenny UI Pack](https://kenney.nl/assets/ui-pack) for UI Elements
