BCB::BindingsManager g_bindManager;

const string g_pluginName = Icons::Camera + " Better Camera Bindings";

[Setting hidden]
bool g_renderWindow = true;

[Setting hidden]
string g_bindingsData = "";

[Setting hidden]
bool g_disableBinds = false;

void Main() {
    g_bindManager.loadData();
}

void RenderInterface() {
    if (!g_renderWindow) return;

    UI::SetNextWindowSize(475, 320, UI::Cond::Appearing);
    if (UI::Begin(g_pluginName, g_renderWindow)) {

        g_bindManager.render();

    }
    UI::End();
}

void RenderMenu() {
    if (UI::MenuItem(g_pluginName, "", g_renderWindow)) {
        g_renderWindow = !g_renderWindow;
    }
}

void Update(float dt) {
    if (g_disableBinds) return;

    g_bindManager.checkBindings();
}
