namespace BCB {

class IdxWrapper {
    bool valid = false;
    uint i = 0;

    void reset() {
        this.valid = false;
        this.i = 0;
    }

    void set(uint i) {
        this.i = i;
        this.valid = true;
    }

    uint opImplConv() const {
        return this.i;
    }
}

} // namespace BCB
