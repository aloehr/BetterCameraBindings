namespace BCB {

// only supports toFind to be of length 1
int findFirstOf(const string &in str, const string &in toFind) {
    if (toFind.Length > 1) return -1;

    for (int i = 0; i < str.Length; ++i) {
        if (str.SubStr(i, 1) == toFind) return i;
    }

    return -1;
}

} // namespace BCB
