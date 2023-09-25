namespace BCB {

enum BindMode {
    DEFAULT,
    DEFAULT_REVERSED,
    ONLY_NORMAL_CAM,
    ONLY_ALT_CAM
}

class CameraBinding {
    int padId;
    BindMode mode;
    string padName;
    CInputScriptPad::EPadType padType;
    CInputScriptPad::EButton bindButton;
    CameraType camType;

    CameraBinding() {}

    CameraBinding(
        int id,
        BindMode mode,
        const string &in name,
        CInputScriptPad::EPadType type,
        CInputScriptPad::EButton bindButton,
        CameraType ct
    ) {
        this.padId = id;
        this.mode = mode;
        this.padName = name;
        this.padType = type;
        this.bindButton = bindButton;
        this.camType = ct;
    }
}

class BindingsManager {
    CameraBinding@[] bindings;
    Camera cam;
    bool dataLoaded = false;
    bool bindingsEnabled = true;

    BindingsManager() {}

    void addBinding(CameraBinding &in camBind) {
        this.bindings.InsertLast(camBind);
        this.saveData();
    }

    void deleteBinding(uint idx) {
        this.bindings.RemoveAt(idx);
        this.saveData();
    }

    void loadData() {
        auto tokens = g_bindingsData.Split(";");

        if (tokens.Length % 6 != 0) {
            g_bindingsData = "";
            this.dataLoaded = true;
            return;
        }

        uint i = 0;
        while (i < tokens.Length) {
            CameraBinding cur;

            cur.padId      = Text::ParseInt(tokens[i++]);
            cur.mode       = BindMode(Text::ParseInt(tokens[i++]));
            cur.padName    = tokens[i++];
            cur.padType    = CInputScriptPad::EPadType(Text::ParseInt(tokens[i++]));
            cur.bindButton = CInputScriptPad::EButton(Text::ParseInt(tokens[i++]));
            cur.camType    = CameraType(Text::ParseInt(tokens[i++]));

            this.bindings.InsertLast(cur);
        }

        this.dataLoaded = true;
    }

    void saveData() {
        g_bindingsData = "";

        for (uint i = 0; i < this.bindings.Length; ++i) {

            auto cur = this.bindings[i];

            g_bindingsData += tostring(cur.padId) + ";";
            g_bindingsData += tostring(int(cur.mode)) + ";";
            g_bindingsData += cur.padName + ";";
            g_bindingsData += tostring(int(cur.padType)) + ";";
            g_bindingsData += tostring(int(cur.bindButton)) + ";";
            g_bindingsData += tostring(int(cur.camType));

            if (i < this.bindings.Length - 1) {
                g_bindingsData += ";";
            }
        }
    }

    void checkBindings() {
        if (this.bindings.Length == 0 || !this.bindingsEnabled) return;

        auto app = GetApp();
        if (app.CurrentPlayground is null) return;

        auto ip = app.InputPort;

        for (uint i = 0; i < ip.Script_Pads.Length; ++i) {
            auto sp = ip.Script_Pads[i];

            if (sp.Type == CInputScriptPad::EPadType::Keyboard || sp.Type == CInputScriptPad::EPadType::Mouse)
                continue;

            for (uint j = 0; j < this.bindings.Length; ++j) {
                auto binding = this.bindings[j];

                if (sp.Type != binding.padType || sp.ControllerId != binding.padId)
                    continue;

                for (uint k = 0; k < sp.ButtonEvents.Length; ++k) {
                    if (binding.bindButton == sp.ButtonEvents[k]) {

                        if (binding.mode == BindMode::ONLY_NORMAL_CAM) {
                            cam.CurAltMode = CameraAltMode::OFF;
                            cam.CurCam = binding.camType;
                        } else if (binding.mode == BindMode::ONLY_ALT_CAM) {
                            cam.CurAltMode = CameraAltMode::ON;
                            cam.CurCam = binding.camType;
                        } else if (binding.mode == BindMode::DEFAULT) {
                            if (cam.CurCam != binding.camType) {
                                cam.CurAltMode = CameraAltMode::OFF;
                                cam.CurCam = binding.camType;
                            } else {
                                if (cam.CurAltMode == CameraAltMode::OFF) {
                                    cam.CurAltMode = CameraAltMode::ON;
                                } else {
                                    cam.CurAltMode = CameraAltMode::OFF;
                                }
                            }
                        } else if (binding.mode == BindMode::DEFAULT_REVERSED) {
                            if (cam.CurCam != binding.camType) {
                                cam.CurAltMode = CameraAltMode::ON;
                                cam.CurCam = binding.camType;
                            } else {
                                if (cam.CurAltMode == CameraAltMode::OFF) {
                                    cam.CurAltMode = CameraAltMode::ON;
                                } else {
                                    cam.CurAltMode = CameraAltMode::OFF;
                                }
                            }
                        }

                        break;
                    }
                }
            }
        }
    }
}

} // Namespace BCB
