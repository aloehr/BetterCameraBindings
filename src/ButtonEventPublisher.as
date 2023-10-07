namespace BCB {

enum ButtonEventType {
    KEYBOARD,
    CONTROLLER
}

enum ButtonAction {
    PRESSED,
    RELEASED
}

abstract class ButtonEvent {
    ButtonEventType type;
    int deviceID;
    ButtonAction action;
    int buttonID;

    ButtonEvent(ButtonEventType type, int deviceID, ButtonAction action, int buttonID) {
        this.type = type;
        this.deviceID = deviceID;
        this.action = action;
        this.buttonID = buttonID;
    }
}

class ControllerButtonEvent : ButtonEvent {
    ControllerButtonEvent(int deviceID, ButtonAction action, int buttonID) {
        super(ButtonEventType::CONTROLLER, deviceID, action, buttonID);
    }

    CInputScriptPad::EButton getButton() const {
        return CInputScriptPad::EButton(this.buttonID);
    }
}

class KeyboardButtonEvent : ButtonEvent {
    KeyboardButtonEvent(int deviceID, ButtonAction action, int buttonID) {
        super(ButtonEventType::KEYBOARD, deviceID, action, buttonID);
    }

    VirtualKey getButton() const {
        return VirtualKey(this.buttonID);
    }
}

class DeviceInfo {
    int id;
    CInputScriptPad::EPadType type;
    string name;
    string label;

    DeviceInfo(int id, CInputScriptPad::EPadType type, const string &in name) {
        this.id = id;
        this.type = type;
        this.name = name;

        if (this.type == CInputScriptPad::EPadType::Keyboard) {
            this.label = Icons::KeyboardO;
        } else {
            this.label = Icons::Gamepad;
        }

        this.label += " " + this.name + "   \\$888#" + tostring(this.id) + " Type: " + tostring(this.type) + "";
    }
}

// callback defintion
funcdef void ButtonEventCallback(const ButtonEvent @event);

class DeviceState {
    int id;
    uint idleDurationOnUpdate = uint(-1);
    array<bool> buttonDownStates(int(CInputScriptPad::EButton::None) + 1, false);

    DeviceState(int deviceID) {
        this.id = deviceID;
    }
}

class ButtonEventPublisher {
    private dictionary subscribers;
    private array<ButtonEventCallback@> broadcastSubs;
    private array<bool> keyboardState(int(VirtualKey::OemClear) + 1, false);
    private dictionary deviceStates;

    // returns true if callback was added and false if callback already exists for that device
    //     a callback can only be subscribed to broadcast OR to
    //     devices, not both, to prevent duplicate event triggers
    bool subscribeToDevice(int deviceID, ButtonEventCallback @callback) {
        if (this.broadcastSubs.FindByRef(callback) >= 0) return false;

        const string deviceIDString = tostring(deviceID);

        if (!this.subscribers.Exists(deviceIDString)) {
            ButtonEventCallback@[] tmp = { callback };
            @this.subscribers[deviceIDString] = tmp;
            return true;
        }

        auto deviceCallBacks = cast<ButtonEventCallback@[]@>(this.subscribers[deviceIDString]);

        if (deviceCallBacks.FindByRef(callback) < 0) {
            deviceCallBacks.InsertLast(callback);
            return true;
        }

        return false;
    }

    // returns true if callback was added and false if callback already exists for broadcasting
    //     a callback can only be subscribed to broadcast OR to
    //     devices, not both, to prevent duplicate event triggers
    bool subscribeToBroadcast(ButtonEventCallback @callback) {
        if (this.broadcastSubs.FindByRef(callback) >= 0) return false;

        auto keys = this.subscribers.GetKeys();
        for (uint i = 0; i < keys.Length; ++i) {
            auto deviceCallBacks = cast<ButtonEventCallback@[]@>(this.subscribers[keys[i]]);
            if (deviceCallBacks !is null && deviceCallBacks.FindByRef(callback) >= 0) {
                return false;
            }
        }

        this.broadcastSubs.InsertLast(callback);

        return true;
    }

    // returns true if unsubscribed successfull and false if the callback was never registered for this device
    bool unsubscribeFromDevice(int deviceID, ButtonEventCallback @callback) {
        const string deviceIDString = tostring(deviceID);


        if (!this.subscribers.Exists(deviceIDString)) return false;

        auto deviceCallBacks = cast<ButtonEventCallback@[]@>(this.subscribers[deviceIDString]);

        int idx = deviceCallBacks.FindByRef(callback);
        if (idx < 0) return false;
        deviceCallBacks.RemoveAt(idx);
        if (deviceCallBacks.Length == 0) {
            this.subscribers.Delete(deviceIDString);
        }

        return true;
    }

    // returns true if unsubscribed successfull and false if the callback was never registered for broadcasting
    bool unsubscribeFromBroadcast(ButtonEventCallback @callback) {
        int idx = this.broadcastSubs.FindByRef(callback);
        if (idx < 0) return false;
        this.broadcastSubs.RemoveAt(idx);

        return true;
    }

    DeviceInfo@ getDeviceInfo(int deviceID) {
        auto ip = GetApp().InputPort;

        for (uint i = 0; i < ip.Script_Pads.Length; ++i) {
            CInputScriptPad @sp = ip.Script_Pads[i];

            if (sp.ControllerId == deviceID) {
                return DeviceInfo(sp.ControllerId, sp.Type, sp.ModelName);
            }
        }

        return null;
    }

    void updateHook() {
        auto ip = GetApp().InputPort;

        for (uint i = 0; i < ip.Script_Pads.Length; ++i) {
            CInputScriptPad @sp = ip.Script_Pads[i];

            if (sp.Type == CInputScriptPad::EPadType::Keyboard || sp.Type == CInputScriptPad::EPadType::Mouse)
                continue;

            const string deviceIDString = tostring(sp.ControllerId);

            DeviceState @state = null;

            if (!this.deviceStates.Exists(deviceIDString)) {
                @state = DeviceState(sp.ControllerId);
                @this.deviceStates[deviceIDString] = state;
            } else {
                @state = cast<DeviceState@>(this.deviceStates[deviceIDString]);
            }


            // L2
            float value = sp.L2;
            // L2 on PS controller ranges from [-1, 1] (at least on the ps4 controller I tested)
            if (sp.Type == CInputScriptPad::EPadType::PlayStation) {
                value = (value + 1.f) * 0.5f;
            }
            checkAnalogButtonState(CInputScriptPad::EButton::L2, value, state);


            // R2
            value = sp.R2;
            // R2 on PS controller ranges from [-1, 1] (at least on the ps4 controller I tested)
            if (sp.Type == CInputScriptPad::EPadType::PlayStation) {
                value = (value + 1.f) * 0.5f;
            }
            checkAnalogButtonState(CInputScriptPad::EButton::R2, value, state);


            // Left Stick
            value = Math::Clamp(sp.LeftStickX, -1.f, 0.f) * -1.f;
            checkAnalogButtonState(CInputScriptPad::EButton::LeftStick_Left, value, state);
            value = Math::Clamp(sp.LeftStickX, 0.f, 1.f);
            checkAnalogButtonState(CInputScriptPad::EButton::LeftStick_Right, value, state);
            value = Math::Clamp(sp.LeftStickY, -1.f, 0.f) * -1.f;
            checkAnalogButtonState(CInputScriptPad::EButton::LeftStick_Down, value, state);
            value = Math::Clamp(sp.LeftStickY, 0.f, 1.f);
            checkAnalogButtonState(CInputScriptPad::EButton::LeftStick_Up, value, state);


            // Right Stick
            value = Math::Clamp(sp.RightStickX, -1.f, 0.f) * -1.f;
            checkAnalogButtonState(CInputScriptPad::EButton::RightStick_Left, value, state);
            value = Math::Clamp(sp.RightStickX, 0.f, 1.f);
            checkAnalogButtonState(CInputScriptPad::EButton::RightStick_Right, value, state);
            value = Math::Clamp(sp.RightStickY, -1.f, 0.f) * -1.f;
            checkAnalogButtonState(CInputScriptPad::EButton::RightStick_Down, value, state);
            value = Math::Clamp(sp.RightStickY, 0.f, 1.f);
            checkAnalogButtonState(CInputScriptPad::EButton::RightStick_Up, value, state);



            // idle duration for analog input only goes to zero when the analog input is ~0.8 or greater.
            // that means we always have to check analog inputs because currently we trigger press on >= 0.5
            // and release on <= 0.3
            if (state.idleDurationOnUpdate < sp.IdleDuration) continue;


            // controller buttons
            checkButtonState(CInputScriptPad::EButton::Left, sp.Left, state);
            checkButtonState(CInputScriptPad::EButton::Right, sp.Right, state);
            checkButtonState(CInputScriptPad::EButton::Up, sp.Up, state);
            checkButtonState(CInputScriptPad::EButton::Down, sp.Down, state);
            checkButtonState(CInputScriptPad::EButton::A, sp.A, state);
            checkButtonState(CInputScriptPad::EButton::B, sp.B, state);
            checkButtonState(CInputScriptPad::EButton::X, sp.X, state);
            checkButtonState(CInputScriptPad::EButton::Y, sp.Y, state);
            checkButtonState(CInputScriptPad::EButton::L1, sp.L1, state);
            checkButtonState(CInputScriptPad::EButton::R1, sp.R1, state);
            checkButtonState(CInputScriptPad::EButton::LeftStick, sp.LeftStickBut, state);
            checkButtonState(CInputScriptPad::EButton::RightStick, sp.RightStickBut, state);
            checkButtonState(CInputScriptPad::EButton::Menu, sp.Menu, state);
            checkButtonState(CInputScriptPad::EButton::View, sp.View, state);


            // get the idle duration
            state.idleDurationOnUpdate = sp.IdleDuration;
        }
    }

    void onKeyPressHook(bool down, VirtualKey key) {
        if (down) {
            if (this.keyboardState[key]) {
                return;
            } else {
                this.keyboardState[key] = true;
            }
        } else {
            this.keyboardState[key] = false;
        }

        this.sendEvent(KeyboardButtonEvent(1, down ? ButtonAction::PRESSED : ButtonAction::RELEASED, int(key)));
    }

    private void checkButtonState(
        const CInputScriptPad::EButton button,
        const uint pressedDuration,
        DeviceState @state
    ) {
        if (state.buttonDownStates[button]) {
            if (pressedDuration == 0) {
                sendEvent(ControllerButtonEvent(state.id, ButtonAction::RELEASED, int(button)));
                state.buttonDownStates[button] = false;
            }
        } else {
            if (pressedDuration > 0) {
                sendEvent(ControllerButtonEvent(state.id, ButtonAction::PRESSED, int(button)));
                state.buttonDownStates[button] = true;
            }
        }
    }

    // expects value to range from [0, 1]
    private void checkAnalogButtonState(
        const CInputScriptPad::EButton button,
        const float value,
        DeviceState @state
    ) {
        if (state.buttonDownStates[button]) {
            if (value <= 0.3f) {
                sendEvent(ControllerButtonEvent(state.id, ButtonAction::RELEASED, int(button)));
                state.buttonDownStates[button] = false;
            }
        } else {
            if (value >= 0.5f) {
                sendEvent(ControllerButtonEvent(state.id, ButtonAction::PRESSED, int(button)));
                state.buttonDownStates[button] = true;
            }
        }
    }

    private void sendEvent(const ButtonEvent @event) {
        for (uint i = 0; i < this.broadcastSubs.Length; ++i) {
            this.broadcastSubs[i](event);
        }

        const string deviceIDString = tostring(event.deviceID);

        if (this.subscribers.Exists(deviceIDString)) {
            auto deviceCallBacks = cast<ButtonEventCallback@[]@>(this.subscribers[deviceIDString]);
            for (uint i = 0; i < deviceCallBacks.Length; ++i) {
                deviceCallBacks[i](event);
            }
        }
    }
}

} // namespace BCB
