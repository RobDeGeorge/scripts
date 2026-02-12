#!/usr/bin/env python3
"""Power menu popup bar for Hyprland - appears at bottom-center with power options."""

import json
import logging
import os
import signal
import subprocess
import sys

from PyQt6.QtCore import Qt, QTimer
from PyQt6.QtGui import QFont, QCursor
from PyQt6.QtWidgets import QApplication, QWidget, QHBoxLayout, QPushButton

logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(os.path.expanduser("~/power-menu-bar.log")),
        logging.StreamHandler(),
    ],
)
log = logging.getLogger(__name__)

LOCK_FILE = os.path.expanduser("~/.cache/power-menu-bar.pid")
OTHER_LOCK_FILES = [
    os.path.expanduser("~/.cache/screenshot-bar.pid"),
]


def kill_existing():
    """Kill any other running instance via PID lock file. Returns True if one was killed."""
    my_pid = os.getpid()
    log.debug(f"kill_existing: my_pid={my_pid}")
    try:
        with open(LOCK_FILE) as f:
            old_pid = int(f.read().strip())
        if old_pid != my_pid:
            log.info(f"Found existing instance pid={old_pid}, killing it")
            os.kill(old_pid, signal.SIGKILL)
            os.remove(LOCK_FILE)
            return True
    except (FileNotFoundError, ValueError):
        log.debug("No lock file or invalid contents")
    except ProcessLookupError:
        log.debug("Stale lock file, process already dead")
        os.remove(LOCK_FILE)
    return False


def kill_other_bars():
    """Kill any other popup bars so only one is open at a time."""
    for lock_path in OTHER_LOCK_FILES:
        try:
            with open(lock_path) as f:
                pid = int(f.read().strip())
            log.info(f"Killing other bar pid={pid} from {lock_path}")
            os.kill(pid, signal.SIGKILL)
            os.remove(lock_path)
        except (FileNotFoundError, ValueError):
            pass
        except ProcessLookupError:
            try:
                os.remove(lock_path)
            except FileNotFoundError:
                pass


def write_lock():
    os.makedirs(os.path.dirname(LOCK_FILE), exist_ok=True)
    with open(LOCK_FILE, "w") as f:
        f.write(str(os.getpid()))


def remove_lock():
    try:
        os.remove(LOCK_FILE)
    except FileNotFoundError:
        pass


def run_power_action(action: str):
    """Execute the chosen power action."""
    commands = {
        "shutdown": ["systemctl", "poweroff"],
        "restart": ["systemctl", "reboot"],
        "sleep": ["systemctl", "suspend"],
        "logout": ["hyprctl", "dispatch", "exit"],
    }
    cmd = commands.get(action)
    if cmd:
        log.info(f"Executing power action: {action} -> {cmd}")
        subprocess.Popen(cmd)


def get_monitor_geometry():
    """Get focused monitor geometry."""
    try:
        out = subprocess.check_output(["hyprctl", "monitors", "-j"], text=True)
        monitors = json.loads(out)
        focused = next((m for m in monitors if m.get("focused")), monitors[0])
        mx, my = focused["x"], focused["y"]
        mw, mh = focused["width"], focused["height"]
        scale = focused.get("scale", 1.0)
        mw = int(mw / scale)
        mh = int(mh / scale)
        return mx, my, mw, mh
    except Exception as e:
        log.warning(f"Failed to get monitor info: {e}")
        return 0, 0, 1920, 1080


class PowerMenuBar(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowFlags(
            Qt.WindowType.FramelessWindowHint
            | Qt.WindowType.WindowStaysOnTopHint
        )
        self.setWindowTitle("power-menu-bar")
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.setStyleSheet(self._stylesheet())
        self._build_ui()

    def _stylesheet(self):
        return """
            QWidget#bar {
                background-color: rgba(20, 22, 28, 180);
                border-radius: 12px;
                border: 1px solid rgba(100, 110, 130, 77);
            }
            QPushButton {
                background-color: transparent;
                color: #b0b8c4;
                border: none;
                border-radius: 8px;
                padding: 12px 24px;
                font-size: 14px;
                outline: none;
            }
            QPushButton:hover {
                background-color: rgba(80, 100, 130, 51);
                color: #e0e4ea;
            }
            QPushButton:pressed {
                background-color: rgba(100, 120, 150, 77);
            }
            QPushButton:focus {
                background-color: rgba(80, 100, 130, 51);
                color: #e0e4ea;
            }
        """

    def _build_ui(self):
        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(4)

        container = QWidget(self)
        container.setObjectName("bar")
        inner = QHBoxLayout(container)
        inner.setContentsMargins(8, 8, 8, 8)
        inner.setSpacing(4)

        font = QFont("VictorMono Nerd Font", 14)

        buttons = [
            ("⏻  Shutdown", "shutdown"),
            ("\U000f0709  Restart", "restart"),
            ("󰒲  Sleep", "sleep"),
            ("󰍃  Logout", "logout"),
        ]
        for i, (label, action) in enumerate(buttons):
            btn = QPushButton(label)
            btn.setFont(font)
            btn.setCursor(QCursor(Qt.CursorShape.PointingHandCursor))
            btn.clicked.connect(lambda checked, a=action: self._on_click(a))
            inner.addWidget(btn)
            if i == 0:
                self._first_btn = btn

        layout.addWidget(container)

    def _on_click(self, action: str):
        log.info(f"Button clicked: {action}")
        self.hide()
        QTimer.singleShot(200, lambda: self._run_and_exit(action))

    def _run_and_exit(self, action: str):
        run_power_action(action)
        QApplication.instance().quit()

    def keyPressEvent(self, event):
        key = event.key()
        if key in (Qt.Key.Key_Return, Qt.Key.Key_Enter):
            focused = QApplication.focusWidget()
            if isinstance(focused, QPushButton):
                focused.click()
            return
        if key in (Qt.Key.Key_Left, Qt.Key.Key_Right, Qt.Key.Key_Tab, Qt.Key.Key_Space):
            super().keyPressEvent(event)
            return
        log.info(f"Key pressed: {key}, quitting")
        QApplication.instance().quit()

    def showEvent(self, event):
        super().showEvent(event)
        QTimer.singleShot(50, self._first_btn.setFocus)


def main():
    log.info("power-menu-bar starting")
    if kill_existing():
        log.info("Killed existing instance, exiting")
        sys.exit(0)

    kill_other_bars()
    write_lock()
    app = QApplication(sys.argv)
    app.aboutToQuit.connect(remove_lock)

    bar = PowerMenuBar()
    bar.adjustSize()
    dpr = app.primaryScreen().devicePixelRatio()
    w = int(bar.sizeHint().width() * dpr)
    h = int(bar.sizeHint().height() * dpr)

    mx, my, mw, mh = get_monitor_geometry()
    x = mx + (mw - w) // 2
    y = my + mh - h - 80
    log.debug(f"Target position: ({x},{y}), bar={w}x{h}, dpr={dpr}, monitor={mw}x{mh}")

    # Set a move rule BEFORE showing so Hyprland places it correctly on first frame
    subprocess.run(
        ["hyprctl", "keyword", "windowrule", f"move {x} {y}, match:title ^power-menu-bar$"],
        capture_output=True
    )

    bar.show()
    bar.activateWindow()

    # Remove the move rule so it doesn't affect future launches with stale coords
    def cleanup_rule():
        subprocess.run(
            ["hyprctl", "keyword", "windowrule", f"unset move, match:title ^power-menu-bar$"],
            capture_output=True
        )
    QTimer.singleShot(200, cleanup_rule)
    log.info("Bar shown, entering event loop")
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
