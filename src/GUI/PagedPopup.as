namespace BCB {

abstract class PopupPage {
    PagedPopup@ parent = null;

    void render() {}

    void reset() {}
}

class PagedPopup {
    string title;
    uint currentPageIdx = 0;
    PopupPage@[] pages;
    bool popupOpen = false;
    bool renderPageCount;

    // if you want to share data between pages, put it in here
    dictionary data;

    PagedPopup(const string &in title = "", bool renderPageCount = true) {
        this.title = title;
        this.renderPageCount = renderPageCount;
    }

    void addPage(PopupPage@ page) {
        @page.parent = this;
        pages.InsertLast(page);
    }

    // render has to be called before open
    // it it returns true the popup is currently being rendered/ is open
    bool render() {
        this.popupOpen = UI::BeginPopup(this.title);

        if (this.popupOpen) {
            if (this.title.Length > 0) {
                UI::Text(title);
                UI::Separator();
            }

            if (this.currentPageIdx < this.pages.Length) {
                pages[this.currentPageIdx].render();
            }

            if (this.renderPageCount) {
                UI::Separator();
                UI::Text("\\$999" + tostring(this.currentPageIdx + 1) + "/" + tostring(this.pages.Length));
            }
            UI::EndPopup();
        }

        return this.popupOpen;
    }

    // open has to be called in the same ID Stack as render() was called
    void open() {
        UI::OpenPopup(this.title);
    }

    void close() {
        if (this.popupOpen) UI::CloseCurrentPopup();
    }

    void nextPage() {
        if (this.currentPageIdx + 1 < this.pages.Length) {
            this.currentPageIdx++;
        }
    }

    void previousPage() {
        if (this.currentPageIdx > 0) {
            this.currentPageIdx--;
        }
    }

    void resetToFirstPage() {
        while (this.currentPageIdx > 0) {
            this.pages[this.currentPageIdx].reset();
            this.previousPage();
        }
    }
}

} // namespace BCB
