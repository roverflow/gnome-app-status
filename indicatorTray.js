import Clutter from 'gi://Clutter';
import GObject from 'gi://GObject';
import St from 'gi://St';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';

const TRAY_PANEL_ID = 'appstatus-tray';

export const IndicatorTray = GObject.registerClass(
class AppStatusIndicatorTray extends PanelMenu.Button {
    _init() {
        super._init(0.5, 'App Status Tray', true);

        this._icons = new Map();

        this._box = new St.BoxLayout({
            style_class: 'appstatus-tray-box',
            x_align: Clutter.ActorAlign.START,
        });
        this.add_child(this._box);

        this.add_style_class_name('appstatus-tray');

        this._updateVisibility();
    }

    addToPanel() {
        const existingIcon = Main.panel.statusArea[TRAY_PANEL_ID];
        if (existingIcon) {
            if (existingIcon !== this)
                existingIcon.destroy();
            Main.panel.statusArea[TRAY_PANEL_ID] = null;
        }

        Main.panel.addToStatusArea(TRAY_PANEL_ID, this, 0, 'right');
    }

    addIcon(icon) {
        if (this._icons.has(icon.uniqueId))
            return;

        this._icons.set(icon.uniqueId, icon);

        const insertIndex = this._getSortedInsertIndex(icon);
        this._box.insert_child_at_index(icon, insertIndex);

        if (icon.menu)
            Main.panel.menuManager.addMenu(icon.menu);

        icon.connect('destroy', () => this._onIconDestroyed(icon));

        icon.opacity = 0;
        icon.ease({
            opacity: 255,
            duration: 150,
            mode: Clutter.AnimationMode.EASE_OUT_QUAD,
        });

        this._updateVisibility();
    }

    removeIcon(icon) {
        if (!this._icons.has(icon.uniqueId))
            return;

        if (icon.menu)
            Main.panel.menuManager.removeMenu(icon.menu);

        this._icons.delete(icon.uniqueId);

        if (icon.get_parent() === this._box)
            this._box.remove_child(icon);

        this._updateVisibility();
    }

    getIcons() {
        return Array.from(this._icons.values());
    }

    getIconsByType(iconType) {
        return this.getIcons().filter(i => i instanceof iconType);
    }

    _onIconDestroyed(icon) {
        if (icon.menu) {
            try {
                Main.panel.menuManager.removeMenu(icon.menu);
            } catch (_e) {
                // Menu may already be removed
            }
        }
        this._icons.delete(icon.uniqueId);
        this._updateVisibility();
    }

    _getSortedInsertIndex(icon) {
        const children = this._box.get_children();
        const id = icon.uniqueId;

        for (let i = 0; i < children.length; i++) {
            if (children[i].uniqueId > id)
                return i;
        }

        return children.length;
    }

    _updateVisibility() {
        this.visible = this._icons.size > 0;
    }

    _onDestroy() {
        this._icons.clear();

        if (super._onDestroy)
            super._onDestroy();
    }
});
