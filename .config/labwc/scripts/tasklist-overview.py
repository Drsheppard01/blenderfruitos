#!/usr/bin/env python3
from datetime import datetime
import json
import os
import math
import subprocess
import shlex
import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Gio", "2.0")
import unicodedata
import re
from gi.repository import Gtk, Gdk, GLib, Pango, Gio

# ---------------- KEYBINDINGS / ACTIONS ---------------- #

ACTIONS = {
    "workspace_prev": {
        "type": "ydotool",
        "command": "key 56:1 105:1 105:0 56:0",  # Alt+Left
    },
    "workspace_next": {
        "type": "ydotool",
        "command": "key 56:1 106:1 106:0 56:0",  # Alt+Right
    },
    "lock_screen": {
        "type": "exec",
        "command": "swaylock -f -c 000000",
    },
    "conf": {
        "type": "exec",
        "command": "labwc-tweaks-gtk",
    },
    "bluetooth": {
        "type": "exec",
        "command": "blueman-manager",
    },
}


def run_action(name):
        action = ACTIONS.get(name)
        if not action:
            print(f"[wloverview] Unknown action: {name}")
            return

        atype = action.get("type")
        cmd = action.get("command")
        if not cmd:
            return

        if atype == "ydotool":
            subprocess.Popen(["ydotool"] + shlex.split(cmd))
        elif atype == "exec":
            subprocess.Popen(shlex.split(cmd))

# ---------------- CSS ---------------- #
CSS = """
#fullblur {
    background-color: rgba(22,22,26,.62);
}

window { background: transparent; }

.tile {
    background-color: #38383b;
    color: white;
    border-radius: 15px;
    padding: 15px;
}
.tile:hover {
    box-shadow: inset 0 0 0 6px rgba(41,128,185,1);
}

.tile label {
    font-size: 15px;
}

.running-dot {
    background-color: white;
    border-radius: 999px;
    min-width: 6px;
    min-height: 6px;
    opacity: 0.9;
}

/* ---- Close button (hover only) ---- */
.tile-close {
    margin: 6px;
    padding: 2px;
    border-radius: 9999px;
    background: rgba(0,0,0,0.6);
    opacity: 0;
    transition: opacity 120ms ease-out, background 120ms ease-out;
}

.tile:hover .tile-close {
    opacity: 1;
}
.tile-close:hover {
    background: rgba(200,60,60,0.9);
}

.round-tile {
    background-color: #38383b;
    border-radius: 9999px;
    padding: 10px;
}
.round-tile:hover { background: #303030; }

.round-tile image {
    color: white;
}

.clock-label {
    color: white;
    font-size: 13px;
    font-weight: 600;
}

/* Dock */
.dock-background {
    padding: 12px;
    background-color: rgba(45,45,50,0.75);
    box-shadow: rgba(255,255,255,0.17) 0 0 0 1px inset;
    border-radius: 28px;
    opacity: 0;
    transform: translateY(10px);
    transition: opacity 140ms ease-out, transform 140ms ease-out;
}
.dock-background.dock-visible {
    opacity: 1;
    transform: translateY(0);
}
.dock-icon {
    padding: 5px;
    border-radius: 15px;
    background:transparent;
    color: white;
}
.dock-icon:hover {
    background-color: rgba(255,255,255,0.10);
}
/* Custom Tooltip Popover */
popover.dock-popover contents {
    background-color: rgba(22, 22, 26, 0.95);
    color: white;
    border-radius: 12px;
    padding: 6px 12px;
    border: 1px solid rgba(255,255,255,0.1);
    box-shadow: 0 4px 12px rgba(0,0,0,0.3);
    margin-bottom: 12px;
}
.dock-popover-label {
    font-size: 13px;
    font-weight: 600;
}
"""

# ---------------- TITLE NORMALIZATION ---------------- #
_DASH_TRANSLATION = str.maketrans({
    "\u2010": "-",  # hyphen
    "\u2011": "-",  # non-breaking hyphen
    "\u2012": "-",  # figure dash
    "\u2013": "-",  # en dash
    "\u2014": "-",  # em dash
    "\u2212": "-",  # minus sign
    "\u2043": "-",  # hyphen bullet
})
_ZERO_WIDTH_RE = re.compile(r"[\u200B-\u200D\uFEFF]")

def normalize_title(s: str) -> str:
    if not s:
        return ""
    s = unicodedata.normalize("NFKC", s)
    s = _ZERO_WIDTH_RE.sub("", s)
    s = s.translate(_DASH_TRANSLATION)
    return " ".join(s.split())

# ---------------- HELPERS ---------------- #
def load_user_css():
    path = os.path.expanduser("~/.config/wloverview/style.css")
    if not os.path.exists(path):
        return

    provider = Gtk.CssProvider()
    try:
        provider.load_from_path(path)
    except Exception as e:
        print(f"[wloverview] Failed to load user CSS: {e}")
        return

    Gtk.StyleContext.add_provider_for_display(
        Gdk.Display.get_default(),
        provider,
        Gtk.STYLE_PROVIDER_PRIORITY_USER,
    )

load_user_css()



def expand_tilde_variants(title: str):
    if "~" not in title:
        return [title]

    home = os.path.expanduser("~")
    return [
        title,
        title.replace("~", home, 1),
    ]


def get_windows():
    """
    wlrctl toplevel list output lines are expected as:
      appid:title
    """
    try:
        raw = subprocess.check_output(["wlrctl", "toplevel", "list"], text=True)
    except Exception:
        return []

    out = []
    for line in raw.splitlines():
        if ":" not in line:
            continue

        appid, title = line.split(":", 1)
        appid = appid.strip()
        title = title.strip()

        # Exclude this overview window
        if appid == "org.broomlabs.wloverview" :
            continue

        out.append((appid, title, normalize_title(title)))

    return out

def load_dock_config():
    path = os.path.expanduser("~/.config/wloverview/config.json")
    if not os.path.exists(path):
        return []
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return []

def expand_tokens(argv):
    return [os.path.expanduser(os.path.expandvars(t)) for t in argv]

_ICON_CACHE = {}

def pick_icon_name(icon_theme: Gtk.IconTheme, appid: str) -> str:
    """
    Resolve an icon name for a tile from an app_id.
    Tries:
      1) Cache lookup
      2) exact appid
      3) dashified appid (common theme naming)
      4) fallback
    """
    if not appid:
        return "applications-system"
    
    if appid in _ICON_CACHE:
        return _ICON_CACHE[appid]

    res = "applications-system"
    if icon_theme.has_icon(appid):
        res = appid
    else:
        dashified = appid.replace(".", "-").replace("_", "-")
        if dashified and icon_theme.has_icon(dashified):
            res = dashified
    
    _ICON_CACHE[appid] = res
    return res

# ---------------- MAIN WINDOW ---------------- #
class MainWindow(Gtk.Window):
    def __init__(self):
        super().__init__()
        self.set_title("wloverview")
        self.set_decorated(False)
        self.fullscreen()

# Load config + actions EARLY
# deal with this later
   #     self.config = load_config()
     #   self.actions = self.config.get("actions", {})
        
        provider = Gtk.CssProvider()
        provider.load_from_string(CSS)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

        overlay = Gtk.Overlay()
        self.set_child(overlay)

        # -------- Background --------
        blur = Gtk.Box(name="fullblur")
        blur.set_hexpand(True)
        blur.set_vexpand(True)
        overlay.set_child(blur)

        # -------- Clock --------
        self.clock = Gtk.Label()
        self.clock.add_css_class("clock-label")
        self.clock.set_halign(Gtk.Align.CENTER)
        self.clock.set_valign(Gtk.Align.START)
        self.clock.set_margin_top(8)
        overlay.add_overlay(self.clock)
        self.update_clock()
        GLib.timeout_add_seconds(60, self.update_clock)

        # Cache windows once
        self.windows = get_windows()

        # -------- Top-left workspace buttons --------
        ws_buttons = Gtk.Box(spacing=8)
        ws_buttons.set_halign(Gtk.Align.START)
        ws_buttons.set_valign(Gtk.Align.START)
        ws_buttons.set_margin_top(12)
        ws_buttons.set_margin_start(12)
        overlay.add_overlay(ws_buttons)

        # Previous workspace
        prev_icon = Gtk.Image.new_from_icon_name("go-previous-symbolic")
        prev_icon.set_pixel_size(18)
        prev_btn = Gtk.Button(child=prev_icon)
        prev_btn.add_css_class("round-tile")
        prev_btn.set_focusable(False)
        prev_btn.connect(
            "clicked",
            lambda *_: (
                run_action("workspace_prev"),
                self.close()
            )
        )
        ws_buttons.append(prev_btn)

        # Next workspace
        next_icon = Gtk.Image.new_from_icon_name("go-next-symbolic")
        next_icon.set_pixel_size(18)
        next_btn = Gtk.Button(child=next_icon)
        next_btn.add_css_class("round-tile")
        next_btn.set_focusable(False)
        next_btn.connect(
            "clicked",
            lambda *_: (
                run_action("workspace_next"),
                self.close()
            )
        )
        ws_buttons.append(next_btn)

        # -------- Top-right buttons --------
        sys_buttons = Gtk.Box(spacing=10)
        sys_buttons.set_halign(Gtk.Align.END)
        sys_buttons.set_valign(Gtk.Align.START)
        sys_buttons.set_margin_top(12)
        sys_buttons.set_margin_end(12)
        overlay.add_overlay(sys_buttons)

        # Volume
        self.vol_icon = Gtk.Image.new_from_icon_name("audio-volume-high-symbolic")
        self.vol_icon.set_pixel_size(18)
        self.vol_btn = Gtk.Button(child=self.vol_icon)
        self.vol_btn.add_css_class("round-tile")
        self.vol_btn.set_focusable(False)
        self.vol_btn.connect("clicked", lambda *_: subprocess.Popen(["pavucontrol"]))
        sys_buttons.append(self.vol_btn)
        
        # Battery (placeholder button)
        self.bat_icon = Gtk.Image()
        self.bat_icon.set_pixel_size(18)
        self.bat_btn = Gtk.Button(child=self.bat_icon)
        self.bat_btn.add_css_class("round-tile")
        self.bat_btn.set_focusable(False)
        self.bat_btn.set_visible(False)
        sys_buttons.append(self.bat_btn)

        # Defer status updates
        def defer_status():
            self.update_volume_icon()
            self._update_battery_status()
            GLib.timeout_add_seconds(60, self._update_battery_status)
            return False

        GLib.idle_add(defer_status)
        GLib.timeout_add(2000, self.update_volume_icon)
        # Bluetooth
        self.add_sys_button(
            sys_buttons,
            "bluetooth-active-symbolic",
            lambda *_: (run_action("bluetooth"), self.close()),
            "Bluetooth"
        )

        # Labwc tweaks
        self.add_sys_button(
            sys_buttons,
            "applications-system-symbolic",
            lambda *_: (run_action("conf"), self.close()),
            "Settings"
        )

        # Lock
        self.add_sys_button(
            sys_buttons,
            "system-lock-screen-symbolic",
            lambda *_: (run_action("lock_screen"), self.close()),
            "Lock Screen"
        )

        # -------- Center --------
        center = Gtk.CenterBox()
        center.set_halign(Gtk.Align.CENTER)
        center.set_valign(Gtk.Align.CENTER)
        overlay.add_overlay(center)

        self.center_overlay = Gtk.Overlay()
        wrapper = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        wrapper.set_halign(Gtk.Align.CENTER)
        wrapper.set_valign(Gtk.Align.CENTER)

        self.grid = Gtk.Grid(column_spacing=22, row_spacing=16)
        wrapper.append(self.grid)

        self.center_overlay.set_child(wrapper)
        center.set_center_widget(self.center_overlay)

        GLib.idle_add(self._update_center_size)
        GLib.idle_add(self.populate)
        self.build_dock(overlay)

        # -------- Background click-to-close --------
        bg_click = Gtk.GestureClick()
        bg_click.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)

        def on_bg_click(_g, _n, x, y):
            picked = self.pick(x, y, Gtk.PickFlags.DEFAULT)
            w = picked
            while w:
                if isinstance(w, Gtk.Button):
                    return
                w = w.get_parent()
            self.close()

        bg_click.connect("pressed", on_bg_click)
        self.add_controller(bg_click)
        self.connect("map", lambda *_: self.populate())
    def _on_size_notify(self, widget, pspec):
        self._width = widget.get_width()
        self._height = widget.get_height()
        self.populate()
        self._update_center_size()    
        
        
    # ---------------- Layout ---------------- #
    def _update_center_size(self):
        w = self.get_width()
        h = self.get_height()
        if w < 200 or h < 200:
            return True
        self.center_overlay.set_size_request(int(w * 0.65), int(h * 0.6))
        return False

    # ---------------- Helpers ---------------- #
    
    
    
    
    
    
    def add_sys_button(self, parent, icon_name, callback, tooltip=None):
        icon = Gtk.Image.new_from_icon_name(icon_name)
        icon.set_pixel_size(18)
        btn = Gtk.Button(child=icon)
        btn.add_css_class("round-tile")
        btn.set_focusable(False)
        if tooltip:
            btn.set_tooltip_text(tooltip)
        btn.connect("clicked", callback)
        parent.append(btn)

    def get_volume_info(self):
        try:
            out = subprocess.check_output(
                ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"],
                text=True
            ).strip()
        except Exception:
            return "audio-volume-muted-symbolic", "Volume: Muted"

        is_muted = "MUTED" in out
        
        try:
            # Output can be "Volume: 0.15" or "Volume: 0.15 [MUTED]"
            # We want the number part.
            parts = out.split()
            vol_val = 0.0
            for p in parts:
                try:
                    vol_val = float(p)
                    break
                except ValueError:
                    continue
            
            vol_pct = int(round(vol_val * 100))
        except Exception:
            vol_pct = 0

        tooltip = f"{vol_pct}%"
        if is_muted:
            tooltip += " (muted)"
            return "audio-volume-muted-symbolic", tooltip

        if vol_pct == 0:
            icon = "audio-volume-muted-symbolic"
        elif vol_pct < 33:
            icon = "audio-volume-low-symbolic"
        elif vol_pct < 66:
            icon = "audio-volume-medium-symbolic"
        else:
            icon = "audio-volume-high-symbolic"
            
        return icon, tooltip

    def update_volume_icon(self):
        icon, tooltip = self.get_volume_info()
        self.vol_icon.set_from_icon_name(icon)
        self.vol_btn.set_tooltip_text(tooltip)
        return True

    def _update_battery_status(self):
        icon, tooltip = self.get_battery_info()
        if icon:
            self.bat_icon.set_from_icon_name(icon)
            self.bat_btn.set_tooltip_text(tooltip)
            self.bat_btn.set_visible(True)
        else:
            self.bat_btn.set_visible(False)
        return True

    def get_battery_info(self):
        """
        Returns (icon_name, tooltip) or (None, None) if no battery found
        """
        try:
            device = subprocess.check_output(
                ["upower", "-e"],
                text=True
            ).splitlines()

            battery = next(d for d in device if "battery" in d)
        except Exception:
            return None, None

        try:
            info = subprocess.check_output(
                ["upower", "-i", battery],
                text=True
            )
        except Exception:
            return None, None

        percentage = None
        state = ""

        for line in info.splitlines():
            if "percentage:" in line:
                percentage = int(line.split(":")[1].strip().rstrip("%"))
            elif "state:" in line:
                state = line.split(":")[1].strip()

        if percentage is None:
            return None, None

        # Icon selection
        if percentage >= 90:
            icon = "battery-full-symbolic"
        elif percentage >= 60:
            icon = "battery-good-symbolic"
        elif percentage >= 30:
            icon = "battery-medium-symbolic"
        elif percentage >= 10:
            icon = "battery-low-symbolic"
        else:
            icon = "battery-caution-symbolic"

        tooltip = f"Battery: {percentage}% ({state})"
        return icon, tooltip




    # ---------- wlrctl  helpers ----------
    def _wlrctl_focus_try(self, appid: str, title: str | None):
        """
        Try both 'app_id' and 'app-id' keys (different wlroots tools differ).
        Uses key:value matchspecs.
        """
        key_variants = ["app_id", "app-id"]
        tries = []

        if appid and title:
            for k in key_variants:
                for t in expand_tilde_variants(title):
                    tries.append(["wlrctl", "toplevel", "focus", f"{k}:{appid}", f"title:{t}"])
        if title:
            tries.append(["wlrctl", "toplevel", "focus", f"title:{title}"])
        if appid:
            for k in key_variants:
                tries.append(["wlrctl", "toplevel", "focus", f"{k}:{appid}"])

        for cmd in tries:
            subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            # If this attempt used a title, stop here to avoid stealing focus
            if "title:" in " ".join(cmd):
                return
                
    def focus_window(self, appid, title_raw, title_norm):
        # Prefer exact appid+title (raw), then appid+title (normalized), then title-only, then appid-only.
        self._wlrctl_focus_try(appid, title_raw)
        if title_norm and title_norm != title_raw:
            self._wlrctl_focus_try(appid, title_norm)

    def focus_appid_best(self, appid: str):
        """
        Dock focusing
        """
        wins = self.windows
        candidates = [(a, tr, tn) for (a, tr, tn) in wins if a == appid]

        if candidates:
            a, tr, tn = candidates[0]
            self.focus_window(a, tr, tn)
        else:
            # fallback
            self._wlrctl_focus_try(appid, None)

    def update_clock(self):
        self.clock.set_text(datetime.now().strftime("%A %b %-d  %H:%M"))
        return True

    # ---------------- UI ---------------- #
    def populate(self):
        self.windows = get_windows()   # ← REQUIRED
        """
        grab window from wlrctl
        """
        child = self.grid.get_first_child()
        while child:
            nxt = child.get_next_sibling()
            self.grid.remove(child)
            child = nxt

        wins = self.windows
        if not wins:
            return False

        w = self.get_width()
        h = self.get_height()
        
        if w < 200 or h < 200:
            return True

        icon_theme = Gtk.IconTheme.get_for_display(Gdk.Display.get_default())  # pylint: disable=no-value-for-parameter

        count = len(wins)
        spacing = 22
        best_cols, best_w = 1, 0

        for cols in range(1, count + 1):
            rows = math.ceil(count / cols)
            max_w = (w * 0.80 - (cols - 1) * spacing) / cols
            max_h = (h * 0.80 - (rows - 1) * spacing) / rows
            tw = min(max_w, max_h * (4 / 3))
            if tw > best_w:
                best_w, best_cols = tw, cols

        rows = math.ceil(count / best_cols)
        tile_w = int(best_w)
        tile_h = int(tile_w * 0.75)

        i = 0
        for r in range(rows):
            for c in range(best_cols):
                if i >= count:
                    break

                appid, title_raw, title_norm = wins[i]

                content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
                content.set_halign(Gtk.Align.CENTER)
                content.set_valign(Gtk.Align.CENTER)

                icon_name = pick_icon_name(icon_theme, appid)
                icon = Gtk.Image.new_from_icon_name(icon_name)
                if tile_w >= 260:
                    icon_size = 96
                elif tile_w >= 200:
                    icon_size = 80
                elif tile_w >= 160:
                    icon_size = 64
                else:
                    icon_size = 48

                icon.set_pixel_size(icon_size)

                label = Gtk.Label(label=title_raw)
                label.set_xalign(0.5)
                label.set_ellipsize(Pango.EllipsizeMode.END)
                label.set_max_width_chars(38)
                label.set_single_line_mode(True)

                content.append(icon)
                content.append(label)

                tile_overlay = Gtk.Overlay()
                tile_overlay.set_child(content)

                close_icon = Gtk.Image.new_from_icon_name("window-close-symbolic")
                close_icon.set_pixel_size(16)
                close_btn = Gtk.Button(child=close_icon)
                close_btn.add_css_class("tile-close")
                close_btn.set_focusable(False)
                close_btn.set_halign(Gtk.Align.END)
                close_btn.set_valign(Gtk.Align.START)

                gesture = Gtk.GestureClick()
                gesture.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)

                def on_close(_g, _n, _x, _y, appid=appid, title=title_norm):
                    subprocess.Popen(
                        ["wlrctl", "toplevel", "close",
                         f"app_id:{appid}", f"title:{title}"]
                    )
                    _g.set_state(Gtk.EventSequenceState.CLAIMED)

                gesture.connect("pressed", on_close)
                close_btn.add_controller(gesture)
                tile_overlay.add_overlay(close_btn)

                btn = Gtk.Button()
                btn.add_css_class("tile")
                btn.set_child(tile_overlay)
                btn.set_size_request(tile_w, tile_h)
                btn.connect(
                    "clicked",
                    lambda _btn, a=appid, tr=title_raw, tn=title_norm:
                        (self.focus_window(a, tr, tn), self.close())
                )

                self.grid.attach(btn, c, r, 1, 1)
                i += 1

        return False

    def build_dock(self, overlay):
        """
        Build and display the dock based on the configuration.

        Args:
            overlay: The Gtk.Overlay widget to add the dock to.
        """
        cfg = load_dock_config()
        if not cfg:
            return

        # Which apps are currently running
        running_apps = {appid for appid, *_ in self.windows}

        dock = Gtk.Box(spacing=4)
        dock.add_css_class("dock-background")
        dock.set_halign(Gtk.Align.CENTER)
        dock.set_valign(Gtk.Align.END)
        dock.set_margin_bottom(8)

        for e in cfg:
            icon = Gtk.Image.new_from_icon_name(e.get("icon"))
            icon.set_pixel_size(64)

            btn = Gtk.Button(child=icon)
            btn.add_css_class("dock-icon")
            btn.set_focusable(False)

            # Custom Tooltip via Popover
            tt_text = e.get("title") or e.get("app_id") or e.get("icon")
            tt_label = Gtk.Label(label=tt_text)
            tt_label.add_css_class("dock-popover-label")

            popover = Gtk.Popover()
            popover.set_child(tt_label)
            popover.set_parent(btn)
            popover.set_has_arrow(False)
            popover.set_position(Gtk.PositionType.TOP)
            popover.add_css_class("dock-popover")
            popover.set_autohide(False)

            hover_ctrl = Gtk.EventControllerMotion()
            hover_ctrl.connect("enter", lambda *_, p=popover: p.popup())
            hover_ctrl.connect("leave", lambda *_, p=popover: p.popdown())
            btn.add_controller(hover_ctrl)

            btn.set_size_request(74, 74)

            overlay_btn = Gtk.Overlay()
            overlay_btn.set_child(btn)

            app_id = e.get("app_id") or e.get("icon")
            cmd = e.get("exec")
            is_running = bool(app_id) and (app_id in running_apps)

            # ---- Running indicator ----
            if is_running:
                dot = Gtk.Box()
                dot.add_css_class("running-dot")
                dot.set_halign(Gtk.Align.CENTER)
                dot.set_valign(Gtk.Align.START)
                dot.set_margin_top(70)  # adjust this to move dot down/up
                overlay_btn.add_overlay(dot)

            # ---- Click handling ----


            gesture = Gtk.GestureClick()
            gesture.set_button(0)  # ← CRITICAL: allow left + middle + right
            gesture.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)

      #      def on_click(g, n_press, x, y, cmd=cmd):
       #         g.set_state(Gtk.EventSequenceState.CLAIMED)
        #        self.launch(cmd)
            def on_click(g, n_press, x, y, cmd=cmd, app_id=app_id, is_running=is_running):
                button = g.get_current_button()
                g.set_state(Gtk.EventSequenceState.CLAIMED)

    # Middle click: always launch a new instance
                if button == 2:
                    self.launch(cmd)
                    return

    # Left click
                if button == 1:
                    if is_running:
                        self.focus_appid_best(app_id)
                        self.close()
                    else:
                        self.launch(cmd)
            
            gesture.connect("pressed", on_click)
            btn.add_controller(gesture)

            dock.append(overlay_btn)

        overlay.add_overlay(dock)
        GLib.idle_add(dock.add_css_class, "dock-visible")

    def launch(self, cmd):
        if not cmd:
            self.close()
            return
        argv = expand_tokens(shlex.split(cmd))
        subprocess.Popen(argv)
        self.close()

def main():
    app = Gtk.Application(
        application_id="org.broomlabs.wloverview"
    )

    def on_activate(app):
        win = app.get_active_window()
        if win:
            win.present()
            return

        w = MainWindow()
        app.add_window(w)
        w.present()

    app.connect("activate", on_activate)
    app.run(None)


if __name__ == "__main__":
    main()
