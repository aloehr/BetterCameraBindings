namespace BCB {

class BindingsManagerView {
    private BindingsManager@ bindingsManager = null;

    private IdxWrapper comboBoxCameraTypeIdx;
    private IdxWrapper comboBoxBindModeIdx;
    private CameraBinding newBinding;
    private bool newBindingValidButton = false;

    BindingsManagerView(BindingsManager@ bm) {
        @this.bindingsManager = bm;
    }

    void render() {
        if (this.bindingsManager is null || !this.bindingsManager.dataLoaded) {
            renderAlignedText("Loading...");
            return;
        }

        this.initCreateNewBindingPopup();

        if (UI::Button(Icons::Plus)) {
            UI::OpenPopup("createNewBindingPopup");
        }

        UI::SameLine();
        this.bindingsManager.bindingsEnabled = UI::Checkbox("enable Bindings", this.bindingsManager.bindingsEnabled);
        g_bindingsEnabled = this.bindingsManager.bindingsEnabled;

        UI::SameLine();
        renderAlignedText("\\$555" + Meta::ExecutingPlugin().Version, 1.f, 0.f);

        UI::Separator();

        if (UI::BeginChild("bindings")) {
            this.renderBindings();
        }
        UI::EndChild();
    }

    void initCreateNewBindingPopup() {
        if (this.bindingsManager is null) return;

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

                if (!readyToSaveBind) {
                    renderGrayButton(Icons::Check);
                } else {
                    if (renderGreenButton(Icons::Check)) {
                        newBinding.mode = bindModes[comboBoxBindModeIdx.i];
                        newBinding.camType = camTypes[comboBoxCameraTypeIdx.i];
                        this.bindingsManager.addBinding(this.newBinding);
                        UI::CloseCurrentPopup();
                    }
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
        if (this.bindingsManager is null) return;

        if (this.bindingsManager.bindings.Length == 0) {
            const string text = "No Bindings";
            renderAlignedText(text);
        }

        for (uint i = 0; i < this.bindingsManager.bindings.Length; ++i) {
            auto cur = this.bindingsManager.bindings[i];

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
                        this.bindingsManager.deleteBinding(i);
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
}

} // namespace BCB
