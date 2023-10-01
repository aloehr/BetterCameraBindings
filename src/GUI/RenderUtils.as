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

    bool ret = UI::Button(label, size);
    UI::PopStyleColor(3);

    return ret;
}

const vec4 colGrayNormal(0.5098f, 0.5098f, 0.5098f, 1.f);
const vec4 colGrayHovered(0.3529f, 0.3529f, 0.3529f, 1.f);
const vec4 colGrayActive(0.2745f, 0.2745f, 0.2745f, 1.f);

const vec4 colRedNormal(0.9126f, 0.3059f, 0.3059f, 1.f);
const vec4 colRedHovered(0.9608f, 0.1961f, 0.1961f, 1.f);
const vec4 colRedActive(1.f, 0.0588f, 0.0588f, 1.f);

const vec4 colGreenNormal(0.3529f, 0.7843f, 0.3529f, 1.f);
const vec4 colGreenHovered(0.2353f, 0.8235f, 0.2353f, 1.f);
const vec4 colGreenActive(0.0196f, 0.8431f, 0.0196f, 1.f);

bool renderRedButton(const string &in label, const vec2 &in size = vec2()) {
    return renderColoredButton(label, colRedNormal, colRedHovered, colRedActive, size);
}

bool renderGreenButton(const string &in label, const vec2 &in size = vec2()) {
    return renderColoredButton(label, colGreenNormal, colGreenHovered, colGreenActive, size);
}

bool renderGrayButton(const string &in label, const vec2 &in size = vec2()) {
    return renderColoredButton(label, colGrayNormal, colGrayHovered, colGrayActive, size);
}

void renderComboBox(
    const string &in label,
    const string[] &in items,
    IdxWrapper &idx,
    const string &in preview = "",
    uint startIdx = 0,
    int flags = UI::ComboFlags::None
) {
    string currentlySelected = idx.valid ? items[idx] : preview;
    if (UI::BeginCombo(label, currentlySelected, flags)) {

        for (uint i = startIdx; i < items.Length; ++i) {
            bool selected = idx == i;
            if (UI::Selectable(items[i], selected)) {
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
// is buggy in content regions that can be scrolled down
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

    offset *= vec2(horizontalAlignment, verticalAlignment);

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
