# old_customChat

A modern, lightweight, and customizable chat resource for FiveM built with React 19 and Vite. Designed to replace the default CFX chat with high performance, dark glassmorphism styling, and rich interaction features.

![Preview](preview.gif)

---

## Features

* **Auto-Suggestions**: Displays active command suggestions dynamically with argument highlighting.
* **Dynamic Argument Highlighting**: Visual feedback on typed arguments, indicating current parameters in real time.
* **Native Emoji Picker**: Integrated via `emoji-picker-react` with categories, search, and native keyboard navigation.
* **Blacklist System**: Configurable blacklist for specific emojis and sensitive/prohibited words.
* **Built-in Chat Settings (`/chatsettings`)**:
* Message fadeout cooldown slider (including instant hide).
* Background opacity slider.
* Global UI scaling (75% to 125%).
* Persistent settings stored via browser `localStorage`.

* **CFX Compatibility**: Supports standard FiveM chat events (`chat:addMessage`, `chatMessage`, `chat:clear`, `chat:addSuggestion`, and `chat:addSuggestions`).

---

## Default Controls

| Action | Shortcut |
| --- | --- |
| **Open Chat** | `T` |
| **Close Chat / Settings / Emoji Picker** | `Escape` |
| **Toggle Emoji Picker** | `Shift` + `E` |
| **Autocomplete Command** | `Tab` |
| **Navigate Suggestions** | `Shift` + `↑` / `↓` |
| **Command History** | `↑` / `↓` |
| **Scroll Message History** | `Shift` + `Mouse Wheel` |

---

## Installation

1. Clone or download this repository into your FiveM server's `resources` directory:
```bash
resources/[local]/old_customChat

```


2. Ensure the resource in your `server.cfg`:
```cfg
ensure old_customChat

```



> **Note**: Disable the default CFX `chat` resource to prevent key conflict and double message rendering.

---
