#!/usr/bin/env python3
"""
AirPods Pro & Apple Earphones battery monitor for Waybar.
Uses Apple's AAP (Apple Accessory Protocol) over BlueZ Profile1 L2CAP socket.

Based on the implementation by Silverquark:
https://github.com/Silverquark/waybar-airpods-module
AAP protocol and parsing corrections based on:
https://github.com/maniacx/Bluetooth-Battery-Meter
"""

import argparse
import json
import os
import signal
import socket
import subprocess
import sys
import threading
import time
import warnings

warnings.filterwarnings("ignore", category=DeprecationWarning)

import gi
gi.require_version("Gio", "2.0")
gi.require_version("GLib", "2.0")
from gi.repository import Gio, GLib

AIRPODS_UUID = "74ec2172-0bad-4d01-8f77-997b2be0722a"
PROFILE_PATH = "/com/airpods/waybar/profile"

HANDSHAKE = bytes([
    0x00, 0x00, 0x04, 0x00, 0x01, 0x00, 0x02, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
])
SET_SPECIFIC_FEATURES = bytes([
    0x04, 0x00, 0x04, 0x00, 0x4d, 0x00, 0xff, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
])
REQUEST_NOTIFICATIONS = bytes([
    0x04, 0x00, 0x04, 0x00, 0x0f, 0x00, 0xff, 0xff, 0xff, 0xff,
])
BATTERY_PREFIX = bytes([0x04, 0x00, 0x04, 0x00, 0x04, 0x00])

BATT_SINGLE = 0x01
BATT_RIGHT  = 0x02
BATT_LEFT   = 0x04
BATT_CASE   = 0x08

CONNECT_TIMEOUT = 15

PROFILE_XML = """
<node>
  <interface name="org.bluez.Profile1">
    <method name="Release"/>
    <method name="NewConnection">
      <arg type="o" name="device" direction="in"/>
      <arg type="h" name="fd" direction="in"/>
      <arg type="a{sv}" name="fd_properties" direction="in"/>
    </method>
    <method name="RequestDisconnection">
      <arg type="o" name="device" direction="in"/>
    </method>
  </interface>
</node>
"""

# Global state
mac = None
device_path = None
device_name = "AirPods Pro"

state = {
    "left": None, "right": None, "case": None,
    "left_charging": False, "right_charging": False, "case_charging": False,
    "connected": False,
    "connecting": False,
}

_bus = None
_connecting_timer = None


def output():
    if state["connecting"]:
        data = {
            "text": "...",
            "tooltip": f"{device_name}: Connecting…",
            "class": "connecting",
            "alt": "connecting",
        }
    elif not state["connected"]:
        data = {
            "text": "",
            "tooltip": f"{device_name}: Disconnected",
            "class": "disconnected",
            "alt": "disconnected",
        }
    else:
        levels = []
        tooltip_parts = []

        left, right, case = state["left"], state["right"], state["case"]

        if left is not None and right is not None:
            levels.append((left + right) // 2)
            lc = " ⚡" if state["left_charging"] else ""
            rc = " ⚡" if state["right_charging"] else ""
            tooltip_parts.append(f"󰋋 Left: {left}%{lc}  │  󰋋 Right: {right}%{rc}")
        elif left is not None:
            levels.append(left)
            c = " ⚡" if state["left_charging"] else ""
            tooltip_parts.append(f"󰋋 Left: {left}%{c}")
        elif right is not None:
            levels.append(right)
            c = " ⚡" if state["right_charging"] else ""
            tooltip_parts.append(f"󰋋 Right: {right}%{c}")

        if case is not None:
            c = " ⚡" if state["case_charging"] else ""
            tooltip_parts.append(f"󰚥 Case: {case}%{c}")

        if levels:
            avg = levels[0]
            cls = "critical" if avg <= 20 else "warning" if avg <= 40 else "good"
            data = {
                "text": f"{avg:02d}%",
                "tooltip": f"<b>{device_name}</b>\n" + "\n".join(tooltip_parts),
                "class": cls,
                "alt": "connected",
                "percentage": avg,
            }
        elif case is not None:
            cls = "critical" if case <= 20 else "warning" if case <= 40 else "good"
            data = {
                "text": f"{case:02d}%",
                "tooltip": f"<b>{device_name}</b>\n" + "\n".join(tooltip_parts),
                "class": cls,
                "alt": "connected",
                "percentage": case,
            }
        else:
            data = {
                "text": "",
                "tooltip": f"{device_name} connected (retrieving battery status...)",
                "class": "connected",
                "alt": "connected",
            }

    print(json.dumps(data), flush=True)


def parse_battery(data):
    if not data.startswith(BATTERY_PREFIX) or len(data) < 12:
        return
    count = data[6]
    if count < 1 or count > 3:
        return
    pos = 7
    for _ in range(count):
        if pos + 5 > len(data):
            break
        btype = data[pos]
        level_val = data[pos + 2]
        status_byte = data[pos + 3]
        charging = bool(status_byte & 0x01)
        disconnected = (level_val == 0xFF) or bool(status_byte & 0x04)
        level = None if disconnected else max(0, min(level_val, 100))

        if btype == BATT_SINGLE or btype == BATT_LEFT:
            state["left"] = level
            state["left_charging"] = charging if level is not None else False
        elif btype == BATT_RIGHT:
            state["right"] = level
            state["right_charging"] = charging if level is not None else False
        elif btype == BATT_CASE:
            state["case"] = level
            state["case_charging"] = charging if level is not None else False
        pos += 5
    output()


def socket_reader(fd):
    owned_fd = os.dup(fd)
    sock = socket.socket(fileno=owned_fd)
    sock.setblocking(True)
    sock.settimeout(30)
    try:
        sock.sendall(HANDSHAKE)
        time.sleep(0.15)
        sock.sendall(SET_SPECIFIC_FEATURES)
        time.sleep(0.15)
        sock.sendall(REQUEST_NOTIFICATIONS)

        while True:
            try:
                data = sock.recv(1024)
                if not data:
                    break
                parse_battery(data)
            except socket.timeout:
                try:
                    sock.sendall(REQUEST_NOTIFICATIONS)
                except Exception:
                    break
    except Exception as e:
        sys.stderr.write(f"airpods: socket error: {e}\n")
    finally:
        try:
            sock.shutdown(socket.SHUT_RDWR)
        except Exception:
            pass
        sock.close()
        state.update(connected=False, left=None, right=None, case=None)
        output()


class ProfileServer:
    def __init__(self, bus):
        self._bus = bus
        self._reg_id = 0
        self._iface = Gio.DBusNodeInfo.new_for_xml(PROFILE_XML).interfaces[0]

    def register(self):
        self._reg_id = self._bus.register_object(
            PROFILE_PATH, self._iface, self._on_method_call, None, None,
        )
        proxy = Gio.DBusProxy.new_sync(
            self._bus, Gio.DBusProxyFlags.NONE, None,
            "org.bluez", "/org/bluez", "org.bluez.ProfileManager1", None,
        )
        proxy.call_sync(
            "RegisterProfile",
            GLib.Variant.new_tuple(
                GLib.Variant("o", PROFILE_PATH),
                GLib.Variant("s", AIRPODS_UUID),
                GLib.Variant("a{sv}", {
                    "Name": GLib.Variant("s", "AirPods Waybar"),
                    "Role": GLib.Variant("s", "client"),
                    "AutoConnect": GLib.Variant("b", True),
                }),
            ),
            Gio.DBusCallFlags.NONE, -1, None,
        )

    def unregister(self):
        if self._reg_id:
            self._bus.unregister_object(self._reg_id)
            self._reg_id = 0
        try:
            proxy = Gio.DBusProxy.new_sync(
                self._bus, Gio.DBusProxyFlags.NONE, None,
                "org.bluez", "/org/bluez", "org.bluez.ProfileManager1", None,
            )
            proxy.call_sync(
                "UnregisterProfile",
                GLib.Variant.new_tuple(GLib.Variant("o", PROFILE_PATH)),
                Gio.DBusCallFlags.NONE, -1, None,
            )
        except Exception:
            pass

    def _on_method_call(self, conn, sender, path, iface, method, params, invocation):
        if method == "NewConnection":
            _, fd_index, _ = params.unpack()
            fd = invocation.get_message().get_unix_fd_list().get(fd_index)
            state["connected"] = True
            output()
            threading.Thread(target=socket_reader, args=(fd,), daemon=True).start()
        elif method == "RequestDisconnection":
            state.update(connected=False, left=None, right=None, case=None)
            output()
        invocation.return_value(None)


def check_connected(bus):
    if not device_path:
        return False
    try:
        proxy = Gio.DBusProxy.new_sync(
            bus, Gio.DBusProxyFlags.NONE, None,
            "org.bluez", device_path, "org.bluez.Device1", None,
        )
        val = proxy.get_cached_property("Connected")
        return val.get_boolean() if val else False
    except Exception:
        return False


def connect_profile(bus):
    if not device_path:
        return
    proxy = Gio.DBusProxy.new_sync(
        bus, Gio.DBusProxyFlags.NONE, None,
        "org.bluez", device_path, "org.bluez.Device1", None,
    )
    for attempt in range(4):
        try:
            proxy.call_sync(
                "ConnectProfile",
                GLib.Variant.new_tuple(GLib.Variant("s", AIRPODS_UUID)),
                Gio.DBusCallFlags.NONE, 5000, None,
            )
            return
        except Exception as e:
            if "InProgress" in str(e) or "busy" in str(e):
                time.sleep(1 + attempt)
                continue
            sys.stderr.write(f"airpods: ConnectProfile: {e}\n")
            return


def _on_toggle():
    global _connecting_timer

    if state["connecting"]:
        return True

    if state["connected"]:
        threading.Thread(target=_do_disconnect, daemon=True).start()
    else:
        state["connecting"] = True
        output()
        _connecting_timer = threading.Timer(CONNECT_TIMEOUT, _on_connect_timeout)
        _connecting_timer.daemon = True
        _connecting_timer.start()
        threading.Thread(target=_do_connect, daemon=True).start()

    return True


def _do_connect():
    if not mac:
        return
    try:
        subprocess.run(["rfkill", "unblock", "bluetooth"], stderr=subprocess.DEVNULL)
        subprocess.run(
            ["bluetoothctl", "connect", mac],
            timeout=CONNECT_TIMEOUT, capture_output=True,
        )
    except Exception as e:
        sys.stderr.write(f"airpods: connect error: {e}\n")


def _do_disconnect():
    if not mac:
        return
    try:
        subprocess.run(
            ["bluetoothctl", "disconnect", mac],
            timeout=10, capture_output=True,
        )
    except Exception as e:
        sys.stderr.write(f"airpods: disconnect error: {e}\n")


def _on_connect_timeout():
    if state["connecting"] and not state["connected"]:
        state["connecting"] = False
        output()
        sys.stderr.write("airpods: connection timed out\n")


def find_airpods_mac(bus):
    try:
        manager = Gio.DBusProxy.new_sync(
            bus, Gio.DBusProxyFlags.NONE, None,
            "org.bluez", "/", "org.freedesktop.DBus.ObjectManager", None,
        )
        objects = manager.call_sync("GetManagedObjects", None, Gio.DBusCallFlags.NONE, -1, None).unpack()[0]
        for path, ifaces in objects.items():
            if "org.bluez.Device1" in ifaces:
                dev = ifaces["org.bluez.Device1"]
                name = str(dev.get("Name", "") or dev.get("Alias", ""))
                uuids = dev.get("UUIDs", [])
                if "airpod" in name.lower() or AIRPODS_UUID in uuids:
                    return str(dev.get("Address", "")), name
    except Exception as e:
        sys.stderr.write(f"airpods: auto-detect error: {e}\n")
    return None, "AirPods Pro"


def main():
    global mac, device_path, device_name, _bus, _connecting_timer

    parser = argparse.ArgumentParser(description="AirPods battery monitor for Waybar")
    parser.add_argument("mac", nargs="?", default=os.environ.get("AIRPODS_MAC"),
                        help="Bluetooth MAC address (or set AIRPODS_MAC env var)")
    args = parser.parse_args()

    _bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)

    mac = args.mac
    if not mac:
        detected_mac, detected_name = find_airpods_mac(_bus)
        if detected_mac:
            mac = detected_mac
            device_name = detected_name or "AirPods Pro"

    if mac:
        device_path = "/org/bluez/hci0/dev_" + mac.replace(":", "_")

    server = ProfileServer(_bus)
    try:
        server.register()
    except Exception as e:
        print(json.dumps({
            "text": "", "tooltip": f"Profile registration failed: {e}",
            "class": "critical",
        }), flush=True)
        sys.exit(1)

    if device_path and check_connected(_bus):
        state["connected"] = True
        output()
        threading.Thread(target=connect_profile, args=(_bus,), daemon=True).start()

    def on_props_changed(conn, sender, path, iface, signal_name, params):
        global _connecting_timer
        if path != device_path:
            return
        iface_name, changed, _ = params.unpack()
        if iface_name != "org.bluez.Device1" or "Connected" not in changed:
            return
        connected = bool(changed["Connected"])
        state["connected"] = connected
        if connected:
            state["connecting"] = False
            if _connecting_timer:
                _connecting_timer.cancel()
            threading.Thread(target=connect_profile, args=(_bus,), daemon=True).start()
        else:
            state.update(left=None, right=None, case=None)
        output()

    if device_path:
        _bus.signal_subscribe(
            "org.bluez", "org.freedesktop.DBus.Properties", "PropertiesChanged",
            device_path, None, Gio.DBusSignalFlags.NONE, on_props_changed,
        )

    output()

    loop = GLib.MainLoop()
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGUSR1, _on_toggle)
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, loop.quit)
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGINT, loop.quit)

    try:
        loop.run()
    finally:
        server.unregister()


if __name__ == "__main__":
    main()
