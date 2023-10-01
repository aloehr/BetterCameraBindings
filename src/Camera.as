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

    void updateCameraState() {
        auto gt = getGameTerminal();

        if (gt is null) {
            return;
        }

        this.curAltMode = CameraAltMode(Dev::GetOffsetUint16(gt, 0x30));
        this.curCam = CameraType(Dev::GetOffsetUint32(gt, 0x34));
    }


    void setCameraState(const CameraAltMode &in altMode, const CameraType &in camera) {
        this.updateCameraState();

        auto gt = getGameTerminal();

        if (gt is null) {
            return;
        }

        // set alt mode
        if (this.curAltMode != altMode) {
            Dev::SetOffset(gt, 0x30, uint16(altMode));
        }

        // set camera
        if (this.curCam != camera) {
            auto setCamNod = Dev::GetOffsetNod(gt, 0x50);
            Dev::SetOffset(setCamNod, 0x4, uint(camera));
        }
    }

    void getCameraState(CameraAltMode &out altMode, CameraType &out camera) {
        this.updateCameraState();

        altMode = this.curAltMode;
        camera = this.curCam;
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
