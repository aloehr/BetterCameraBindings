namespace BCB {

bool renderColoredButton(
    const string &in label,
    const vec4 &in colorNormal,
    const vec4 &in colorHovered,
    const vec4 &in colorActive,
    const vec2 &in size = vec2()
) {
    UI::PushStyleColor(UI::Col::Button, colorNormal);
    UI::PushStyleColor(UI::Col::ButtonHovered, colorHovered);
    UI::PushStyleColor(UI::Col::ButtonActive, colorActive);

    if (UI::Button(label, size)) {
        UI::PopStyleColor(3);
        return true;
    } else {
        UI::PopStyleColor(3);
        return false;
    }
}

bool renderRedButton(const string &in label, const vec2 &in size = vec2()) {
    const vec4 colNormal(235.f/255.f, 75.f/255.f, 75.f/255.f, 1.f);
    const vec4 colHovered(245.f/255.f, 50.f/255.f, 50.f/255.f, 1.f);
    const vec4 colActive(255.f/255.f, 15.f/255.f, 15.f/255.f, 1.f);

    return renderColoredButton(label, colNormal, colHovered, colActive, size);
}

bool renderGreenButton(const string &in label, const vec2 &in size = vec2()) {
    const vec4 colNormal(90.f/255.f, 200.f/255.f, 90.f/255.f, 1.f);
    const vec4 colHovered(60.f/255.f, 210.f/255.f, 60.f/255.f, 1.f);
    const vec4 colActive(5.f/255.f, 215.f/255.f, 5.f/255.f, 1.f);

    return renderColoredButton(label, colNormal, colHovered, colActive, size);
}

bool renderGrayButton(const string &in label, const vec2 &in size = vec2()) {
    const vec4 colNormal(130.f/255.f, 130.f/255.f, 130.f/255.f, 1.f);
    const vec4 colHovered(90.f/255.f, 90.f/255.f, 90.f/255.f, 1.f);
    const vec4 colActive(70.f/255.f, 70.f/255.f, 70.f/255.f, 1.f);

    return renderColoredButton(label, colNormal, colHovered, colActive, size);
}

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
}

void renderComboBox(
    const string &in label,
    const string[] &in items,
    IdxWrapper &idx,
    const string &in preview = "",
    int flags = UI::ComboFlags::None
) {
    string currentlySelected = idx.valid ? tostring(items[idx.i]) : preview;
    if (UI::BeginCombo(label, currentlySelected, flags)) {

        for (uint i = 0; i < items.Length; ++i) {
            bool selected = idx.i == i;
            if (UI::Selectable(tostring(items[i]), selected)) {
                idx.set(i);
            }

            if (selected) {
                UI::SetItemDefaultFocus();
            }
        }
        UI::EndCombo();
    }
}

// for horizontal- / vertical alignment:
//      valid values are between 0.0 and 1.0
//      a value of 0 means that the text is left / top aligned
//      a value of 0.5 means the text is aligned in the middle
//      and a value of 1.0 means that the text is right / bottom aligned
// is buggy in content regions with scroll bars
void renderAlignedText(
    const string &in text,
    float horizontalAlignment = 0.5f,
    float verticalAlignment = 0.5f
) {

    // make sure alignment values are between 0 - 1
    horizontalAlignment = Math::Clamp(horizontalAlignment, 0.0f, 1.0f);
    verticalAlignment = Math::Clamp(verticalAlignment, 0.0f, 1.0f);

    vec2 space = UI::GetContentRegionAvail();
    vec2 textSize = Draw::MeasureString(text);

    // set item spacing to 0 for the dummy items so we don't have to consider it
    // in the offset calculation
    UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0.f, 0.f));

    vec2 offset = (space - textSize);

    offset.x *= horizontalAlignment;
    offset.y *= verticalAlignment;

    // vertical alignment for centered text
    if (offset.y > 0.f) {
        UI::Dummy(vec2(space.x, offset.y));
    }

    // horizontal alignment
    if (offset.x > 0.f) {
        UI::Dummy(vec2(offset.x, textSize.y));
        UI::SameLine();
    }

    UI::PopStyleVar(1);

    UI::Text(text);
}

} // namespace BCB
