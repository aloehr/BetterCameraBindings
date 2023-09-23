namespace BCB {

enum CameraAltMode {
    ON  = 0x0,
    OFF = 0x1
}

enum CameraType {
    CAM1 = 0x12,
    CAM2 = 0x13,
    CAM3 = 0x14,
    BACKWARDS = 0x15
}

class Camera {
    private CameraAltMode curAltMode = CameraAltMode::OFF;
    private CameraType curCam = CameraType::CAM1;

    CameraAltMode CurAltMode {
        get {
            this.updateCameraState();
            return this.curAltMode;
        }

        set {
            this.updateCameraState();

            if (this.curAltMode == value) {
                return;
            }

            auto gt = getGameTerminal();

            if (gt is null) {
                return;
            }

            Dev::SetOffset(gt, 0x30, uint16(value));
        }
    }

    CameraType CurCam {
        get {
            this.updateCameraState();
            return this.curCam;
        }

        set {
            this.updateCameraState();

            if (this.curCam == value) {
                return;
            }

            auto gt = getGameTerminal();

            if (gt is null) {
                return;
            }

            auto setCamNod = Dev::GetOffsetNod(gt, 0x50);
            Dev::SetOffset(setCamNod, 0x4, uint(value));
        }
    }


    Camera() {}

    void updateCameraState() {
        auto gt = getGameTerminal();

        if (gt is null) {
            return;
        }

        this.curAltMode = CameraAltMode(Dev::GetOffsetUint16(gt, 0x30));
        this.curCam = CameraType(Dev::GetOffsetUint32(gt, 0x34));
    }

    private CGameTerminal@ getGameTerminal() {
        auto app = GetApp();

        if (app.CurrentPlayground is null || app.CurrentPlayground.GameTerminals.Length == 0) {
            return null;
        }

        return app.CurrentPlayground.GameTerminals[0];
    }
}

} // namespace BetterCamBinds
