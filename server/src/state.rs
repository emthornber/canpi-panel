use server::{PanelDefinition, PanelHash};

pub struct AppState {
    pub cangrid_uri: String,
    pub current_panel_index: Option<u8>,
    pub panels: PanelHash,
}
