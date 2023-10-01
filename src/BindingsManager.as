namespace BCB {

enum CameraMode {
    DEFAULT,
    DEFAULT_REVERSED,
    ONLY_NORMAL_CAM,
    ONLY_ALT_CAM
}

enum TriggerMode {
    ON_PRESS,
    ON_RELEASE,
    ON_HOLD
}

class ButtonBinding {
    int button;
    CameraMode mode;
    CameraType camera;
    TriggerMode trigger;

    ButtonBinding(int button, CameraMode mode, CameraType camera, TriggerMode trigger) {
        this.button = button;
        this.mode = mode;
        this.camera = camera;
        this.trigger = trigger;
    }
}

class DeviceBinding {
    DeviceInfo @info;
    ButtonBinding@[] buttonBindings;

    DeviceBinding(int id, CInputScriptPad::EPadType type, const string &in name) {
        @this.info = DeviceInfo(id, type, name);
    }
}

class BindingsManager {
    dictionary deviceBindings;
    ButtonEventCallback @callback = ButtonEventCallback(this.buttonEventCallback);
    Camera cam;
    bool bindingsEnabled = true;
    bool dataLoaded = false;

    // state for Hold mode
    bool holdActive = false;
    int holdButton;
    CameraType cameraAfterHold;
    CameraAltMode altModeAfterHold;

    void addBinding(
        int deviceID,
        CInputScriptPad::EPadType deviceType,
        const string &in deviceName,
        int button,
        CameraType camera,
        CameraMode mode,
        TriggerMode trigger,
        bool save = true
    ) {
        const string deviceIDString = tostring(deviceID);
        auto deviceBinding = cast<DeviceBinding@>(this.deviceBindings[deviceIDString]);

        if (deviceBinding is null) {
            @deviceBinding = DeviceBinding(deviceID, deviceType, deviceName);
            @this.deviceBindings[deviceIDString] = deviceBinding;
            g_bep.subscribeToDevice(deviceID, this.callback);
        }

        deviceBinding.buttonBindings.InsertLast(ButtonBinding(button, mode, camera, trigger));

        if (save) this.saveData();
    }

    void deleteBinding(int deviceID, uint buttonBindingIdx) {
        const string deviceIDString = tostring(deviceID);
        auto deviceBinding = cast<DeviceBinding@>(this.deviceBindings[deviceIDString]);

        if (deviceBinding is null) return;

        deviceBinding.buttonBindings.RemoveAt(buttonBindingIdx);

        if (deviceBinding.buttonBindings.Length == 0) {
            this.deviceBindings.Delete(deviceIDString);
            g_bep.unsubscribeFromDevice(deviceID, this.callback);
        }

        this.saveData();
    }

    void loadData() {

        const auto @tokens = g_bindingsData.Split(";");

        if (tokens.Length == 0) {
            this.dataLoaded = true;
            return;
        } else if (tokens[0].SubStr(0, 1) != "v") {
            this.loadUnversionedData(tokens);
            this.saveData();
        } else if (tokens[0] == "v1"){
            this.loadV1Data(tokens);
        } else {
            g_bindingsData = "";
            this.dataLoaded = true;
            return;
        }
    }

    // example: "v1;100;2;XInput Pad;3;8;18;0;100;0;XInput Pad;3;9;20;0;100;2;XInput Pad;3;23;21;2"
    void loadV1Data(const string[] @tokens) {
        if ((tokens.Length - 1) % 7 != 0) {
            g_bindingsData = "";
            this.dataLoaded = true;
            return;
        }

        uint i = 1;
        while (i < tokens.Length) {
            int deviceID = Text::ParseInt(tokens[i++]);
            CameraMode mode = CameraMode(Text::ParseInt(tokens[i++]));
            string deviceName = tokens[i++];
            CInputScriptPad::EPadType deviceType = CInputScriptPad::EPadType(Text::ParseInt(tokens[i++]));
            int button = Text::ParseInt(tokens[i++]);
            CameraType camera = CameraType(Text::ParseInt(tokens[i++]));
            TriggerMode trigger = TriggerMode(Text::ParseInt(tokens[i++]));

            this.addBinding(deviceID, deviceType, deviceName, button, camera, mode, trigger, false);
        }

        this.dataLoaded = true;
    }

    // example: "100;2;XInput Pad;3;8;18;100;0;XInput Pad;3;9;20;100;2;XInput Pad;3;23;21"
    void loadUnversionedData(const string[] @tokens) {
        if (tokens.Length % 6 != 0) {
            g_bindingsData = "";
            this.dataLoaded = true;
            return;
        }

        uint i = 0;
        while (i < tokens.Length) {
            int deviceID = Text::ParseInt(tokens[i++]);
            CameraMode mode = CameraMode(Text::ParseInt(tokens[i++]));
            string deviceName = tokens[i++];
            CInputScriptPad::EPadType deviceType = CInputScriptPad::EPadType(Text::ParseInt(tokens[i++]));
            int button = Text::ParseInt(tokens[i++]);
            CameraType camera = CameraType(Text::ParseInt(tokens[i++]));
            TriggerMode trigger = TriggerMode::ON_PRESS;

            this.addBinding(deviceID, deviceType, deviceName, button, camera, mode, trigger, false);
        }

        this.dataLoaded = true;
    }

    void saveData() {
        if (this.deviceBindings.IsEmpty()) {
            g_bindingsData = "";
            return;
        }

        g_bindingsData = "v1;";

        auto keys = this.deviceBindings.GetKeys();

        for (uint i = 0; i < keys.Length; ++i) {
            auto deviceBinding = cast<DeviceBinding@>(this.deviceBindings[keys[i]]);

            for (uint j = 0; j < deviceBinding.buttonBindings.Length; ++j) {
                auto curBB = deviceBinding.buttonBindings[j];

                g_bindingsData += tostring(deviceBinding.info.id) + ";";
                g_bindingsData += tostring(int(curBB.mode)) + ";";
                g_bindingsData += deviceBinding.info.name + ";";
                g_bindingsData += tostring(int(deviceBinding.info.type)) + ";";
                g_bindingsData += tostring(int(curBB.button)) + ";";
                g_bindingsData += tostring(int(curBB.camera)) + ";";
                g_bindingsData += tostring(int(curBB.trigger));

                if (i != keys.Length - 1 || j != deviceBinding.buttonBindings.Length - 1) {
                    g_bindingsData += ";";
                }
            }
        }
    }

    void buttonEventCallback(const ButtonEvent @event) {
        if (!this.bindingsEnabled || this.deviceBindings.IsEmpty() || GetApp().CurrentPlayground is null) {
            // reset hold button if still was active
            this.holdActive = false;
            return;
        }

        string deviceIDString = tostring(event.deviceID);
        if (!this.deviceBindings.Exists(deviceIDString)) return;
        auto deviceBinding = cast<DeviceBinding@>(this.deviceBindings[deviceIDString]);

        for (uint i = 0; i < deviceBinding.buttonBindings.Length; ++i) {
            auto bB = deviceBinding.buttonBindings[i];

            if (bB.button != event.buttonID) continue;

            if (bB.trigger == TriggerMode::ON_HOLD) {
                if (this.holdActive && this.holdButton == bB.button && event.action == ButtonAction::RELEASED) {
                    this.cam.setCameraState(this.altModeAfterHold, this.cameraAfterHold);
                    this.holdActive = false;
                } else if (!holdActive && event.action == ButtonAction::PRESSED) {
                    this.cam.getCameraState(this.altModeAfterHold, this.cameraAfterHold);

                    this.holdActive = true;
                    this.holdButton = bB.button;

                    if (bB.mode == CameraMode::ONLY_NORMAL_CAM || bB.mode == CameraMode::DEFAULT) {
                        this.cam.setCameraState(CameraAltMode::OFF, bB.camera);
                    } else {
                        this.cam.setCameraState(CameraAltMode::ON, bB.camera);
                    }
                }
            } else if (bB.trigger == TriggerMode::ON_PRESS && event.action == ButtonAction::PRESSED) {
                this.cameraBehaviourForOnPressOnRelease(bB);
            } else if (bB.trigger == TriggerMode::ON_RELEASE && event.action == ButtonAction::RELEASED) {
                this.cameraBehaviourForOnPressOnRelease(bB);
            }
        }
    }

    void cameraBehaviourForOnPressOnRelease(const ButtonBinding @bB) {
        CameraAltMode curAltMode;
        CameraType curCamera;

        this.cam.getCameraState(curAltMode, curCamera);

        if (bB.mode == CameraMode::ONLY_NORMAL_CAM) {
            this.changeCameraOrAfterHoldCamera(CameraAltMode::OFF, bB.camera);
        } else if (bB.mode == CameraMode::ONLY_ALT_CAM) {
            this.changeCameraOrAfterHoldCamera(CameraAltMode::ON, bB.camera);
        } else {
            CameraAltMode defaultAltMode =
                bB.mode == CameraMode::DEFAULT ? CameraAltMode::OFF : CameraAltMode::ON;
            CameraAltMode otherAltMode =
                bB.mode == CameraMode::DEFAULT ? CameraAltMode::ON : CameraAltMode::OFF;

            if (this.holdActive) {
                if (this.cameraAfterHold != bB.camera) {
                    this.changeCameraOrAfterHoldCamera(defaultAltMode, bB.camera);
                } else {
                    if (this.altModeAfterHold == defaultAltMode) {
                        this.changeCameraOrAfterHoldCamera(otherAltMode, bB.camera);
                    } else {
                        this.changeCameraOrAfterHoldCamera(defaultAltMode, bB.camera);
                    }
                }
            } else {
                if (curCamera != bB.camera) {
                    this.changeCameraOrAfterHoldCamera(defaultAltMode, bB.camera);
                } else {
                    if (curAltMode == defaultAltMode) {
                        this.changeCameraOrAfterHoldCamera(otherAltMode, bB.camera);
                    } else {
                        this.changeCameraOrAfterHoldCamera(defaultAltMode, bB.camera);
                    }
                }
            }
        }
    }

    void changeCameraOrAfterHoldCamera(const CameraAltMode &in altMode, const CameraType &in camera) {
        if (this.holdActive) {
            this.altModeAfterHold = altMode;
            this.cameraAfterHold = camera;
        } else {
            this.cam.setCameraState(altMode, camera);
        }
    }
}

} // namespace BCB
