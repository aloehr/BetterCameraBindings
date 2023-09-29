BCB::BindingsManager g_bindingsManager;
BCB::BindingsManagerView g_bindingsManagerView(g_bindingsManager);

BCB::ButtonEventPublisher g_bep;

string g_mainWindowLabel = "";
string g_menuItemLabel = "";

[Setting hidden]
bool g_renderWindow = true;

[Setting hidden]
bool g_bindingsEnabled = true;

[Setting hidden]
string g_bindingsData = "";

void cb(const BCB::ButtonEvent @e) {
    if (e.type == BCB::ButtonEventType::KEYBOARD) {
        const BCB::KeyboardButtonEvent @kbe = cast<const BCB::KeyboardButtonEvent@>(e);

        print(tostring(e.type) + " " + tostring(kbe.getButton()) + " " + tostring(kbe.action));
    } else if (e.type == BCB::ButtonEventType::CONTROLLER) {
        const BCB::ControllerButtonEvent @pad = cast<const BCB::ControllerButtonEvent@>(e);

        print(tostring(e.type) + " " + tostring(pad.getButton()) + " " + tostring(pad.action));
    }
}

void cb2(const BCB::ButtonEvent @e) {
    if (e.type == BCB::ButtonEventType::KEYBOARD) {
        const BCB::KeyboardButtonEvent @kbe = cast<const BCB::KeyboardButtonEvent@>(e);

        print(tostring(e.type) + " " + tostring(kbe.getButton()) + " " + tostring(kbe.action));
    } else if (e.type == BCB::ButtonEventType::CONTROLLER) {
        const BCB::ControllerButtonEvent @pad = cast<const BCB::ControllerButtonEvent@>(e);

        print(tostring(e.type) + " " + tostring(pad.getButton()) + " " + tostring(pad.action));
    }
}

void Main() {
    const string pluginName = Icons::Camera + " Better Camera Bindings" + (isDevMode() ? " DEV" : "");
    g_mainWindowLabel = pluginName + "###BCBmainWindow" + (isDevMode() ? "DEV" : "");
    g_menuItemLabel = pluginName + "###BCBmenuItem" + (isDevMode() ? "DEV" : "");

    g_bindingsData = "v1;100;2;XInput Pad;3;8;18;0;100;0;XInput Pad;3;9;20;0;100;2;XInput Pad;3;23;21;2";

    g_bindingsManager.loadData();
    g_bindingsManager.bindingsEnabled = g_bindingsEnabled;
}

void RenderInterface() {
    if (!g_renderWindow) return;

    UI::SetNextWindowSize(475, 320, UI::Cond::Appearing);
    if (UI::Begin(g_mainWindowLabel, g_renderWindow)) {

        g_bindingsManagerView.render();

    }
    UI::End();
}

void RenderMenu() {
    if (UI::MenuItem(g_menuItemLabel, "", g_renderWindow)) {
        g_renderWindow = !g_renderWindow;
    }
}

void Update(float dt) {
    g_bep.updateHook();
}

void OnKeyPress(bool down, VirtualKey key) {
    g_bep.onKeyPressHook(down, key);
}

bool isDevMode() {
    return Meta::ExecutingPlugin().Type == Meta::PluginType::Folder;
}
