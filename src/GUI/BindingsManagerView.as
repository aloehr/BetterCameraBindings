namespace BCB {

class DetectButtonPopupPage : PopupPage {
    ButtonEventCallback @callback = ButtonEventCallback(this.buttonEventCallback);

    void render() override {
        UI::Dummy(vec2(0.f, 20.f * UI::GetScale()));
        UI::AlignTextToFramePadding();
        UI::Text("press the key/button you want to bind...");
        UI::SameLine();
        if (renderRedButton(Icons::Times)) {
            this.parent.close();
        }
        UI::Dummy(vec2(0.f, 20.f * UI::GetScale()));

        g_bep.subscribeToBroadcast(this.callback);
    }

    void buttonEventCallback(const ButtonEvent @event) {
        @this.parent.data["event"] = event;
        g_bep.unsubscribeFromBroadcast(this.callback);
        this.parent.nextPage();
    }
}

class ConfigureButtonBindingPopupPage : PopupPage {
    BindingsManager @bindingsManager;
    IdxWrapper cameraTypeIdx;
    IdxWrapper triggerModeIdx;
    IdxWrapper cameraModeIdx;

    ConfigureButtonBindingPopupPage(BindingsManager @bm) {
        @this.bindingsManager = bm;
    }

    void render() override {
        if (!this.parent.data.Exists("event")) {
            this.parent.close();
        }

        const ButtonEvent @event = cast<const ButtonEvent@>(this.parent.data["event"]);
        auto @deviceInfo = g_bep.getDeviceInfo(event.deviceID);

        if (deviceInfo is null) {
            this.parent.close();
        }

        UI::BeginGroup();
        UI::Text("\\$EE0Device:");
        UI::Text(event.type == ButtonEventType::KEYBOARD ? "\\$EE0Key:" : "\\$EE0Button:");
        UI::EndGroup();

        UI::SameLine();

        UI::BeginGroup();
        UI::Text(deviceInfo.label);
        if (event.type == ButtonEventType::KEYBOARD) {
            auto @kbEvent = cast<const KeyboardButtonEvent@>(event);
            UI::Text("\\$0F0" + tostring(kbEvent.getButton()));
        } else {
            auto @controllerEvent = cast<const ControllerButtonEvent@>(event);
            UI::Text("\\$0F0" + tostring(controllerEvent.getButton()));
        }
        UI::EndGroup();

        UI::Dummy(vec2(10.f, 10.f));


        // camera type combo box
        UI::Text("Select Camera:");

        CameraType[] cameraTypes = {
            CameraType::CAM1,
            CameraType::CAM2,
            CameraType::CAM3,
            CameraType::BACKWARDS
        };

        string[] cameraTypesStrings;
        for (uint i = 0; i < cameraTypes.Length; ++i) {
            cameraTypesStrings.InsertLast(tostring(cameraTypes[i]));
        }

        renderComboBox("##CameraType", cameraTypesStrings, this.cameraTypeIdx, "");


        // trigger mode combo box
        UI::Text("Select Trigger Mode:");

        TriggerMode[] triggerModes = {
            TriggerMode::ON_PRESS,
            TriggerMode::ON_RELEASE,
            TriggerMode::ON_HOLD
        };

        string[] triggerModesStrings;
        for (uint i = 0; i < triggerModes.Length; ++i) {
            triggerModesStrings.InsertLast(tostring(triggerModes[i]));
        }

        UI::SameLine();
        UI::Text("\\$888" + Icons::QuestionCircle);
        if (UI::IsItemHovered()) {
            UI::SetNextWindowContentSize(400);
            UI::BeginTooltip();
            UI::Markdown(
                "**ON_PRESS**"
                "<br>Triggers the camera change when the button is pressed."
                "<br><br>**ON_RELEASE**"
                "<br>Triggers the camera change when the button is released."
                "<br><br>**ON_HOLD**"
                "<br>Changes to the given camera while holding the button. It "
                "switches back to the camera it was in before the button was "
                "held when the button is released. (Only use ON_HOLD if you do "
                "all camera switches while driving with this plugin.)"
            );
            UI::EndTooltip();
        }

        renderComboBox("##TriggerMode", triggerModesStrings, this.triggerModeIdx, "");


        // camera mode combo box
        UI::Text("Select Camera Mode:");

        UI::SameLine();
        UI::Text("\\$888" + Icons::QuestionCircle);
        if (UI::IsItemHovered()) {
            UI::SetNextWindowContentSize(400);
            UI::BeginTooltip();
            UI::Markdown(
                "**DEFAULT**"
                "<br>Default trackmania camera behaviour, it alternates between "
                "normal and alternative camera mode."
                "<br><br>**DEFAULT_REVERSED**"
                "<br>Reversed default trackmania camera behaviour, when switching "
                "from a different camera it starts in alternative camera mode "
                "and then it alternates between alt mode and normal mode."
                "<br><br>**ONLY_NORMAL_CAM**"
                "<br>Switches from a different camera only into normal camera mode "
                " and does nothing if it already is in normal mode."
                "<br><br>**ONLY_ALT_CAM**"
                "<br>Switches from a different camera only into alternative "
                "camera mode and does nothing if it already is in alternative mode."
            );
            UI::EndTooltip();
        }

        CameraMode[] cameraModes = {
            CameraMode::DEFAULT,
            CameraMode::DEFAULT_REVERSED,
            CameraMode::ONLY_NORMAL_CAM,
            CameraMode::ONLY_ALT_CAM
        };

        string[] cameraModesStrings;
        for (uint i = 0; i < cameraModes.Length; ++i) {
            cameraModesStrings.InsertLast(tostring(cameraModes[i]));
        }

        bool isTriggerModeHOLD =
            this.triggerModeIdx.valid &&
            triggerModes[this.triggerModeIdx] == TriggerMode::ON_HOLD;

        bool isBackwardsCam =
            this.cameraTypeIdx.valid &&
            cameraTypes[this.cameraTypeIdx] == CameraType::BACKWARDS;

        if (isBackwardsCam) {
            this.cameraModeIdx.set(2);
        }
        if (isTriggerModeHOLD && this.cameraModeIdx < 2) {
            this.cameraModeIdx.reset();
        }

        UI::BeginDisabled(isBackwardsCam);
        renderComboBox("##CameraMode", cameraModesStrings, this.cameraModeIdx, "", (isTriggerModeHOLD ? 2 : 0));
        UI::EndDisabled();

        UI::Dummy(vec2(10.f, 10.f));


        // confirm/discard buttons
        bool readyToSaveBind = this.cameraTypeIdx.valid && this.triggerModeIdx.valid && this.cameraModeIdx.valid;

        // workaround for UI::HoveredFlags::AllowWhenDisabled not working
        // put a group around the disabled part and check if that group is hovered
        UI::BeginGroup();
        UI::BeginDisabled(!readyToSaveBind);
        if (!readyToSaveBind) {
            renderGrayButton(Icons::Check);
        } else {
            if (renderGreenButton(Icons::Check)) {
                this.bindingsManager.addBinding(
                    deviceInfo.id,
                    deviceInfo.type,
                    deviceInfo.name,
                    event.buttonID,
                    cameraTypes[cameraTypeIdx],
                    cameraModes[cameraModeIdx],
                    triggerModes[triggerModeIdx]
                );
                this.parent.close();
            }
        }
        UI::EndDisabled();
        UI::EndGroup();

        if (UI::IsItemHovered() && !readyToSaveBind) {
            UI::BeginTooltip();
            UI::Text("You have to select camera , trigger mode and\ncamera mode before you can save the binding.");
            UI::EndTooltip();
        }

        UI::SameLine();

        if (renderRedButton(Icons::Times)) {
            this.parent.close();
        }
    }

    void reset() override {
        this.cameraTypeIdx.reset();
        this.triggerModeIdx.reset();
        this.cameraModeIdx.reset();
    }
}

class BindingsManagerView {
    private BindingsManager@ bindingsManager = null;
    private PagedPopup newBindingPopup("Creating new Binding");

    BindingsManagerView(BindingsManager@ bm) {
        @this.bindingsManager = bm;

        this.newBindingPopup.addPage(DetectButtonPopupPage());
        this.newBindingPopup.addPage(ConfigureButtonBindingPopupPage(bm));
    }

    void render() {
        if (this.bindingsManager is null) {
            renderAlignedText("\\$A00Error: bindingsManager is null");
            return;
        } else if (!this.bindingsManager.dataLoaded) {
            renderAlignedText("Loading...");
            return;
        }

        UI::PushStyleColor(UI::Col::Border, vec4(0.7f, 0.7f, 0.7f, 1.f));
        if (!this.newBindingPopup.render()) {
            this.newBindingPopup.resetToFirstPage();
        }
        UI::PopStyleColor();

        if (UI::Button(Icons::Plus)) {
            this.newBindingPopup.open();
        }

        UI::SameLine();
        this.bindingsManager.bindingsEnabled = UI::Checkbox(
            "enable Bindings",
            this.bindingsManager.bindingsEnabled
        );
        g_bindingsEnabled = this.bindingsManager.bindingsEnabled;

        UI::SameLine();
        renderAlignedText("\\$555" + Meta::ExecutingPlugin().Version, 1.f, 0.f);

        UI::Separator();

        if (UI::BeginChild("bindings")) {
            this.renderBindings();
        }
        UI::EndChild();
    }

    void renderBindings() {
        if (this.bindingsManager.deviceBindings.IsEmpty()) {
            renderAlignedText("No Bindings");
        }

        auto keys = this.bindingsManager.deviceBindings.GetKeys();

        for (uint i = 0; i < keys.Length; ++i) {
            auto dB = cast<DeviceBinding@>(this.bindingsManager.deviceBindings[keys[i]]);

            // shoult not happen
            if (dB.buttonBindings.Length == 0) continue;

            UI::PushID(tostring(i));

            if (UI::CollapsingHeader(dB.info.label)) {
                int flags = UI::TableFlags::SizingStretchSame | UI::TableFlags::NoClip | UI::TableFlags::PadOuterX;
                if (UI::BeginTable("buttonBindings", 5, flags)) {

                    for (uint j = 0; j < dB.buttonBindings.Length; ++j) {
                        UI::PushID(tostring(j));

                        auto curBB = dB.buttonBindings[j];

                        UI::TableNextColumn();
                        UI::AlignTextToFramePadding();
                        if (dB.info.type == CInputScriptPad::EPadType::Keyboard) {
                            renderAlignedText(tostring(VirtualKey(curBB.button)), 0.5f, 0.f);
                        } else {
                            renderAlignedText(tostring(CInputScriptPad::EButton(curBB.button)), 0.5f, 0.f);
                        }

                        UI::TableNextColumn();
                        UI::Text(tostring(curBB.camera));

                        UI::TableNextColumn();
                        UI::Text(tostring(curBB.trigger));

                        UI::TableNextColumn();
                        UI::Text(tostring(curBB.mode));

                        UI::TableNextColumn();

                        if (UI::BeginPopup("deleteButtonBinding")) {
                            UI::AlignTextToFramePadding();
                            UI::Text("Delete this binding?");
                            UI::SameLine();

                            if (renderGreenButton(Icons::Check)) {
                                this.bindingsManager.deleteBinding(dB.info.id, j);
                                UI::CloseCurrentPopup();
                            }
                            UI::SameLine();
                            if (renderRedButton(Icons::Times)) {
                                UI::CloseCurrentPopup();
                            }
                            UI::EndPopup();
                        }

                        string buttonLabel = Icons::Times;

                        float framePaddingX = UI::GetStyleVarVec2(UI::StyleVar::FramePadding).x;
                        float textSizeX = Draw::MeasureString(buttonLabel).x;
                        float buttonSizeX = framePaddingX * 2.f + textSizeX;

                        if (UI::GetContentRegionAvail().x - buttonSizeX > 0.f) {
                            UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0.f, 0.f));
                            UI::Dummy(vec2(UI::GetContentRegionAvail().x - buttonSizeX, 0.f));
                            UI::SameLine();
                            UI::PopStyleVar(1);
                        }

                        if (renderRedButton(buttonLabel)) {
                            UI::OpenPopup("deleteButtonBinding");
                        }

                        UI::PopID();
                    }
                    UI::EndTable();
                }
            }

            UI::PopID();
        }
    }
}

} // namespace BCB
