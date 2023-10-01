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

// finds first char in str that matches any char in toFind
int findFirstOf(const string &in str, const string &in toFind) {
    for (int i = 0; i < str.Length; ++i) {
        const string currentChar = str.SubStr(i, 1);

        for (int j = 0; j < toFind.Length; ++j) {
            if (currentChar == toFind.SubStr(j, 1)) return i;
        }
    }

    return -1;
}

} // namespace BCB
