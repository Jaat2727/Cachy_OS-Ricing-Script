// AGS Config — Hyprland Top Bar
// A dynamic, reactive bar built with AGS (Aylur's Gtk Shell)
// Uses Hyprland services for workspaces, and system services for battery/audio/network

const hyprland = await Service.import("hyprland");
const audio = await Service.import("audio");
const battery = await Service.import("battery");
const network = await Service.import("network");
const systemtray = await Service.import("systemtray");

// ──────────────────────────────────────
// CLOCK WIDGET
// ──────────────────────────────────────
const Clock = () => {
    const time = Variable("", {
        poll: [1000, 'date "+%H:%M"'],
    });

    const date = Variable("", {
        poll: [60000, 'date "+%a, %d %b"'],
    });

    return Widget.Button({
        class_name: "clock",
        child: Widget.Box({
            children: [
                Widget.Label({
                    class_name: "clock-time",
                    label: time.bind(),
                }),
                Widget.Label({
                    class_name: "clock-date",
                    label: date.bind(),
                }),
            ],
        }),
    });
};

// ──────────────────────────────────────
// WORKSPACES WIDGET
// ──────────────────────────────────────
const Workspaces = () => {
    const activeId = hyprland.active.workspace.bind("id");

    const workspaceButtons = activeId.as(() => {
        return Array.from({ length: 5 }, (_, i) => i + 1).map((id) => {
            const isOccupied = hyprland.workspaces.some((ws) => ws.id === id);

            return Widget.Button({
                class_name: activeId.as((activeWs) => {
                    let cls = "workspace-btn";
                    if (activeWs === id) cls += " active";
                    else if (isOccupied) cls += " occupied";
                    return cls;
                }),
                on_clicked: () => {
                    Utils.execAsync(
                        `${Utils.HOME}/.config/hypr/scripts/switch_and_theme.sh ${id}`
                    );
                },
                child: Widget.Label({
                    label: `${id}`,
                }),
            });
        });
    });

    return Widget.Box({
        class_name: "workspaces",
        children: workspaceButtons,
    });
};

// ──────────────────────────────────────
// ACTIVE WINDOW TITLE
// ──────────────────────────────────────
const ActiveWindow = () =>
    Widget.Label({
        class_name: "active-window",
        label: hyprland.active.client.bind("title").as((t) => {
            if (!t) return "";
            return t.length > 40 ? t.substring(0, 40) + "…" : t;
        }),
        truncate: "end",
        max_width_chars: 45,
    });

// ──────────────────────────────────────
// NETWORK WIDGET
// ──────────────────────────────────────
const NetworkIndicator = () => {
    const wifiIcon = () => {
        const wifi = network.wifi;
        if (!wifi?.enabled) return "󰤭";

        const strength = wifi.strength;
        if (strength > 75) return "󰤨";
        if (strength > 50) return "󰤥";
        if (strength > 25) return "󰤢";
        return "󰤟";
    };

    return Widget.Button({
        class_name: "network",
        child: Widget.Box({
            children: [
                Widget.Label({
                    class_name: "network-icon",
                    label: Utils.merge(
                        [
                            network.bind("primary"),
                            network.wifi?.bind("strength") ?? Variable(0).bind(),
                        ],
                        () => {
                            if (network.primary === "wired") return "󰈁";
                            return wifiIcon();
                        }
                    ),
                }),
                Widget.Label({
                    class_name: "network-name",
                    label: Utils.merge(
                        [
                            network.bind("primary"),
                            network.wifi?.bind("ssid") ?? Variable("").bind(),
                        ],
                        () => {
                            if (network.primary === "wired") return "Ethernet";
                            return network.wifi?.ssid || "Disconnected";
                        }
                    ),
                }),
            ],
        }),
    });
};

// ──────────────────────────────────────
// VOLUME WIDGET
// ──────────────────────────────────────
const Volume = () => {
    const iconMap = (vol, isMuted) => {
        if (isMuted) return "󰝟";
        if (vol > 66) return "󰕾";
        if (vol > 33) return "󰖀";
        if (vol > 0) return "󰕿";
        return "󰝟";
    };

    return Widget.Button({
        class_name: "volume",
        on_clicked: () => Utils.execAsync("pavucontrol"),
        on_scroll_up: () =>
            Utils.execAsync("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
        on_scroll_down: () =>
            Utils.execAsync("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
        child: Widget.Box({
            children: [
                Widget.Label({
                    class_name: "volume-icon",
                    label: Utils.merge(
                        [
                            audio.speaker.bind("volume"),
                            audio.speaker.bind("is_muted"),
                        ],
                        (vol, muted) => iconMap(Math.round(vol * 100), muted)
                    ),
                }),
                Widget.Label({
                    class_name: "volume-label",
                    label: audio.speaker
                        .bind("volume")
                        .as((v) => `${Math.round(v * 100)}`),
                }),
            ],
        }),
    });
};

// ──────────────────────────────────────
// BATTERY WIDGET
// ──────────────────────────────────────
const BatteryWidget = () => {
    const batteryIcon = (percent, charging) => {
        if (charging) return "󰂄";
        if (percent > 90) return "󰁹";
        if (percent > 70) return "󰂁";
        if (percent > 50) return "󰁾";
        if (percent > 30) return "󰁻";
        if (percent > 15) return "󰁺";
        return "󰂃";
    };

    return Widget.Box({
        class_name: Utils.merge(
            [battery.bind("percent"), battery.bind("charging")],
            (pct, chg) => {
                let cls = "battery";
                if (chg) cls += " charging";
                if (pct <= 15) cls += " critical";
                else if (pct <= 30) cls += " low";
                return cls;
            }
        ),
        visible: battery.bind("available"),
        children: [
            Widget.Label({
                class_name: "battery-icon",
                label: Utils.merge(
                    [battery.bind("percent"), battery.bind("charging")],
                    (pct, chg) => batteryIcon(pct, chg)
                ),
            }),
            Widget.Label({
                class_name: "battery-label",
                label: battery.bind("percent").as((p) => `${p}%`),
            }),
        ],
    });
};

// ──────────────────────────────────────
// SWAYNC TOGGLE
// ──────────────────────────────────────
const NotificationToggle = () =>
    Widget.Button({
        class_name: "notification-toggle",
        on_clicked: () => Utils.execAsync("swaync-client -t -sw"),
        child: Widget.Label({
            label: "󰂚",
        }),
    });

// ──────────────────────────────────────
// SYSTEM TRAY
// ──────────────────────────────────────
const SysTray = () =>
    Widget.Box({
        class_name: "systray",
        children: systemtray.bind("items").as((items) =>
            items.map((item) =>
                Widget.Button({
                    child: Widget.Icon({ icon: item.bind("icon") }),
                    on_primary_click: (_, event) => item.activate(event),
                    on_secondary_click: (_, event) => item.openMenu(event),
                    tooltip_markup: item.bind("tooltip_markup"),
                })
            )
        ),
    });

// ──────────────────────────────────────
// BAR ASSEMBLY
// ──────────────────────────────────────
const Left = () =>
    Widget.Box({
        class_name: "bar-left",
        hpack: "start",
        spacing: 8,
        children: [NetworkIndicator(), ActiveWindow()],
    });

const Center = () =>
    Widget.Box({
        class_name: "bar-center",
        hpack: "center",
        children: [Workspaces()],
    });

const Right = () =>
    Widget.Box({
        class_name: "bar-right",
        hpack: "end",
        spacing: 8,
        children: [
            SysTray(),
            Volume(),
            BatteryWidget(),
            Clock(),
            NotificationToggle(),
        ],
    });

const Bar = (monitor = 0) =>
    Widget.Window({
        name: `bar-${monitor}`,
        monitor,
        anchor: ["top", "left", "right"],
        exclusivity: "exclusive",
        class_name: "bar",
        child: Widget.CenterBox({
            class_name: "bar-inner",
            start_widget: Left(),
            center_widget: Center(),
            end_widget: Right(),
        }),
    });

// ──────────────────────────────────────
// APP ENTRY POINT
// ──────────────────────────────────────
App.config({
    style: `${App.configDir}/style.css`,
    windows: [Bar(0)],
});
