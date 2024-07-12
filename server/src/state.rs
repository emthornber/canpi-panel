use server::{PanelDefinition, PanelHash};

pub struct AppState {
    pub cangrid_uri: String,
    pub current_panel: Option<PanelDefinition>,
    pub panels: PanelHash,
}
