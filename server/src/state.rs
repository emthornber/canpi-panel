use std::collections::HashMap;

/// Definitions of Panels
pub struct Panel {
    pub json_path: String,
}

/// Type alias based on HasMap for a set of Panels
pub type PanelHash = HashMap<String, Panel>;

pub struct AppState {
    pub cangrid_uri: String,
    pub current_panel: Option<Panel>,
    pub panels: PanelHash,
}
