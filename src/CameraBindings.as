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

    private IdxWrapper comboBoxCameraTypeIdx;
    private IdxWrapper comboBoxBindModeIdx;
    private CameraBinding newBinding;
    private bool newBindingValidButton = false;

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

    void render() {
        this.initCreateNewBindingPopup();

        const vec2 startCursorPos = UI::GetCursorPos();

        UI::SetCursorPos(startCursorPos);

        if (UI::Button(Icons::Plus)) {
            UI::OpenPopup("createNewBindingPopup");
        }

        UI::SameLine();
        renderAlignedText("\\$555" + Meta::ExecutingPlugin().Version, 1.f, 0.f);

        UI::Separator();

        if (UI::BeginChild("bindings")) {
            this.renderBindings();
        }
        UI::EndChild();
    }

    void initCreateNewBindingPopup() {
        UI::PushStyleColor(UI::Col::Border, vec4(0.7f, 0.7f, 0.7f, 1.f));
        if (UI::BeginPopup("createNewBindingPopup")) {
            if (!this.newBindingValidButton) {
                UI::Dummy(vec2(0.f, 20.f));
                UI::AlignTextToFramePadding();
                UI::Text("press the Controller button you want to bind...");
                UI::SameLine();
                if (renderRedButton(Icons::Times)) {
                    UI::CloseCurrentPopup();
                }
                UI::Dummy(vec2(20.f, 20.f));
                this.checkNextButtonPress();
            } else {
                UI::Text("Buttonpress detected:");

                UI::Dummy(vec2(5.f, 5.f));

                UI::BeginGroup();
                UI::Text("\\$BBBController ID: \\$FFF" + tostring(this.newBinding.padId));
                UI::Text("\\$BBBController Name: \\$FFF" + this.newBinding.padName);
                UI::EndGroup();
                UI::BeginGroup();
                UI::Text("\\$BBBController Type: \\$FFF" + tostring(this.newBinding.padType));
                UI::Text("\\$BBBButton: \\$FFF" + tostring(this.newBinding.bindButton));
                UI::EndGroup();

                UI::Dummy(vec2(10.f, 10.f));

                CameraType[] camTypes = {
                    CameraType::CAM1,
                    CameraType::CAM2,
                    CameraType::CAM3,
                    CameraType::BACKWARDS
                };

                string[] camTypesStrings;

                for (uint i = 0; i < camTypes.Length; ++i) {
                    camTypesStrings.InsertLast(tostring(camTypes[i]));
                }

                UI::Text("Select camera:");

                UI::SameLine();
                UI::Text("\\$888" + Icons::QuestionCircle);
                if (UI::IsItemHovered()) {
                    UI::BeginTooltip();
                    UI::Text("BACKWARDS:");
                    UI::SameLine();
                    UI::PushTextWrapPos(UI::GetCursorPos().x + 400.f * UI::GetScale());
                    UI::TextWrapped("- bind mode doesn't matter for backwards camera"
                        + " because it has no alternative camera.\n"
                        + "- a mode where the backwards cam is only activated while "
                        + "holding the button is not yet implemented."
                    );
                    UI::PopTextWrapPos();
                    UI::EndTooltip();
                }

                renderComboBox("##CameraType", camTypesStrings, this.comboBoxCameraTypeIdx, "");

                UI::Text("Select Bind Mode:");

                UI::SameLine();
                UI::Text("\\$888" + Icons::QuestionCircle);
                if (UI::IsItemHovered()) {
                    UI::BeginTooltip();

                    UI::Text("DEFAULT:");

                    UI::SameLine();

                    UI::PushTextWrapPos(UI::GetCursorPos().x + 400.f * UI::GetScale());
                    UI::TextWrapped(
                        "Default trackmania camera behaviour, it alternates between "
                        + "normal and alternative camera mode."
                    );

                    UI::Text("DEFAULT_REVERSED:");
                    UI::SameLine();
                    UI::TextWrapped(
                        "Reversed default trackmania camera behaviour, when switching "
                        + "from a different camera it starts in alternative camera mode "
                        + "and then it alternates between alt mode and normal mode."
                    );

                    UI::Text("ONLY_NORMAL_CAM:");
                    UI::SameLine();
                    UI::TextWrapped(
                        "Switches from a different camera only into normal camera mode "
                        + " and does nothing if it already is in normal mode."
                    );

                    UI::Text("ONLY_ALT_CAM:");
                    UI::SameLine();
                    UI::TextWrapped(
                        "Switches from a different camera only into alternative "
                        + "camera mode and does nothing if it already is in alternative mode."
                    );

                    UI::PopTextWrapPos();
                    UI::EndTooltip();
                }

                BindMode[] bindModes = {
                    BindMode::DEFAULT,
                    BindMode::DEFAULT_REVERSED,
                    BindMode::ONLY_NORMAL_CAM,
                    BindMode::ONLY_ALT_CAM
                };

                string[] bindModesStrings;

                for (uint i = 0; i < bindModes.Length; ++i) {
                    bindModesStrings.InsertLast(tostring(bindModes[i]));
                }

                renderComboBox("##BindMode", bindModesStrings, this.comboBoxBindModeIdx, "");

                UI::Dummy(vec2(10.f, 10.f));

                bool readyToSaveBind = this.comboBoxBindModeIdx.valid && this.comboBoxCameraTypeIdx.valid;

                // workaround for UI::HoveredFlags::AllowWhenDisabled not working
                // put a group around the disabled part and check if that group is hovered
                UI::BeginGroup();
                UI::BeginDisabled(!readyToSaveBind);

                bool buttonReturn = false;

                if (!readyToSaveBind) {
                    buttonReturn = renderGrayButton(Icons::Check);

                } else {
                    buttonReturn = renderGreenButton(Icons::Check);
                }

                if (buttonReturn) {
                    newBinding.mode = bindModes[comboBoxBindModeIdx.i];
                    newBinding.camType = camTypes[comboBoxCameraTypeIdx.i];
                    this.addBinding(this.newBinding);
                    UI::CloseCurrentPopup();
                }
                UI::EndDisabled();
                UI::EndGroup();

                if (UI::IsItemHovered() && !readyToSaveBind) {
                    UI::BeginTooltip();
                    UI::Text("You have to select camera type and bind mode \nbefore you can save the binding.");
                    UI::EndTooltip();
                }

                UI::SameLine();

                if (renderRedButton(Icons::Times)) {
                    UI::CloseCurrentPopup();
                }

            }
            UI::EndPopup();
        } else {
            this.newBindingValidButton = false;
            this.comboBoxCameraTypeIdx.reset();
            this.comboBoxBindModeIdx.reset();
        }
        UI::PopStyleColor(1);
    }

    void renderBindings() {
        if (this.bindings.Length == 0) {
            const string text = "No Bindings";
            renderAlignedText(text);
        }

        for (uint i = 0; i < this.bindings.Length; ++i) {
            auto cur = this.bindings[i];

            UI::PushID(tostring(i));
            UI::PushStyleColor(UI::Col::TableBorderStrong, vec4(0.35f ,0.35f ,0.35f ,1.f));

            if (UI::BeginTable("bindingInfo", 1, UI::TableFlags::Borders)) {

                UI::PushStyleVar(UI::StyleVar::CellPadding, vec2(0.f, 5.f));
                UI::TableNextColumn();
                UI::PopStyleVar(1);

                UI::BeginGroup();
                UI::BeginGroup();
                UI::Text("\\$BBBController ID: \\$FFF" + tostring(cur.padId));
                UI::Text("\\$BBBController Type: \\$FFF" + tostring(cur.padType));
                UI::Text("\\$BBBController Name: \\$FFF" + cur.padName);
                UI::EndGroup();

                UI::SameLine();

                UI::BeginGroup();
                UI::Text("\\$BBBBind Mode: \\$FFF" + tostring(cur.mode));
                UI::Text("\\$BBBCamera Type: \\$FFF" + tostring(cur.camType));
                UI::Text("\\$BBBController Button: \\$FFF" + tostring(cur.bindButton));
                UI::EndGroup();
                UI::EndGroup();

                UI::SameLine();

                if (UI::BeginPopup("deleteBinding")) {
                    UI::AlignTextToFramePadding();
                    UI::Text("Delete this binding?");
                    UI::SameLine();

                    if (renderGreenButton(Icons::Check)) {
                        this.deleteBinding(i);
                        UI::CloseCurrentPopup();
                    }
                    UI::SameLine();
                    if (renderRedButton(Icons::Times)) {
                        UI::CloseCurrentPopup();
                    }
                    UI::EndPopup();
                }

                vec2 spacing = UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing);
                vec2 buttonSize(30.f * UI::GetScale(), 30.f * UI::GetScale());

                vec2 dummySize(vec2(UI::GetContentRegionAvail().x - buttonSize.x - spacing.x, buttonSize.y));
                UI::Dummy(dummySize);

                UI::SameLine();

                if (renderRedButton(Icons::Times, buttonSize)) {
                    UI::OpenPopup("deleteBinding");
                }

                UI::EndTable();
            }

            UI::PopStyleColor(1);
            UI::PopID();
        }
    }

    void checkNextButtonPress() {

        auto app = GetApp();

        auto ip = app.InputPort;

        for (uint i = 0; i < ip.Script_Pads.Length; ++i) {
            auto sp = ip.Script_Pads[i];

            if (sp.Type == CInputScriptPad::EPadType::Keyboard || sp.Type == CInputScriptPad::EPadType::Mouse)
                continue;

            for (uint j = 0; j < sp.ButtonEvents.Length; ++j) {
                this.newBinding.padId = sp.ControllerId;
                this.newBinding.padName = sp.ModelName;
                this.newBinding.padType = sp.Type;
                this.newBinding.bindButton = sp.ButtonEvents[j];
                this.newBindingValidButton = true;

                return;
            }
        }
    }

    void checkBindings() {
        if (this.bindings.Length == 0) return;

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
