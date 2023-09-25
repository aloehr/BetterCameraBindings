BCB::BindingsManager g_bindingsManager;
BCB::BindingsManagerView g_bindingsManagerView(g_bindingsManager);

string g_mainWindowLabel = "";
string g_menuItemLabel = "";

[Setting hidden]
bool g_renderWindow = true;

[Setting hidden]
bool g_bindingsEnabled = true;

[Setting hidden]
string g_bindingsData = "";

void Main() {
    const string pluginName = Icons::Camera + " Better Camera Bindings" + (isDevMode() ? " DEV" : "");
    g_mainWindowLabel = pluginName + "###BCBmainWindow" + (isDevMode() ? "DEV" : "");
    g_menuItemLabel = pluginName + "###BCBmenuItem" + (isDevMode() ? "DEV" : "");

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
    g_bindingsManager.checkBindings();
}

bool isDevMode() {
    return Meta::ExecutingPlugin().Type == Meta::PluginType::Folder;
}
