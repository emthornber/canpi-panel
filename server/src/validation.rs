use crate::errors::CanPiAppError;
use ini::Ini;
use std::path::Path;

use server::{PanelHash, PanelList};

#[macro_export]
macro_rules! pkg_name {
    () => {
        env!("CARGO_BIN_NAME")
    };
}

const CANGRID_URI: &str = "localhost:5550";
const CFGFILE: &str = "canpi-panel.cfg";
const PANEL_PATH: &str = "panels";
const STATIC: &str = "static";
const TEMPLATE: &str = "templates/**/*";

/// Structure that holds configuration items expanded from EVs and static text
#[derive(Debug)]
pub struct CanpiConfig {
    /// Host and port that provides a CBus channel
    pub cangrid_uri: String,
    /// Host and port of the web service
    pub host_port: Option<String>,
    /// List of valid panel definitions
    pub panel_hash: PanelHash,
    /// Directory containing panel definitions
    pub panel_path: String,
    /// Definition files
    pub static_path: Option<String>,
    /// HTML templates
    pub template_path: Option<String>,
}

impl CanpiConfig {
    /// Creates a new instance of the structure
    ///
    /// The contents of the EV CPPANEL_HOME is used with the const text above to create path strings
    /// for items.
    ///
    /// If CPPANEL_HOME is not defined or does not point to a valid directory then an error result is
    /// returned.
    ///
    /// If the EV HOST_PORT is not defined then the entry in the struct is set to None.  No further
    /// validation is done if the EV does exist.
    ///
    pub fn new() -> Result<CanpiConfig, CanPiAppError> {
        let h = std::env::var("CPPANEL_HOME");
        if let Ok(home) = h {
            let cpp_home = home;
            if !Path::new(&cpp_home).is_dir() {
                return Err(CanPiAppError::NotFound(
                    "EV CPPANEL_HOME not a directory".to_string(),
                ));
            }
            // Set default panel direcctory
            let pfile = cpp_home.clone() + "/" + PANEL_PATH;
            let mut cfg = CanpiConfig {
                cangrid_uri: CANGRID_URI.to_string(),
                host_port: None,
                panel_hash: PanelHash::new(),
                panel_path: pfile.to_string(),
                static_path: None,
                template_path: None,
            };

            let cfile = cpp_home.clone() + "/" + STATIC + "/" + CFGFILE;
            let config_path = Path::new(&cfile);
            if config_path.is_file() {
                if let Ok(ini) = Ini::load_from_file(config_path) {
                    let properties = ini.general_section();
                    if let Some(uri) = properties.get("cangrid_uri") {
                        cfg.cangrid_uri = uri.to_string();
                    } else {
                        log::info!("Default canpi grid uri used - {}", cfg.cangrid_uri);
                    }
                    if let Some(mut path) = properties.get("panel_path") {
                        let pp = cpp_home.clone() + "/" + path;
                        if Path::new(&path).is_relative() {
                            path = pp.as_str();
                        }
                        cfg.panel_path = path.to_string();
                    } else {
                        log::info!("Default panel directory used - {}", cfg.panel_path);
                    }
                }
            } else {
                log::info!("Configuration file '{cfile}' not found");
                log::info!("canpi grid uri = {}", cfg.cangrid_uri);
                log::info!("panel directory = {}", cfg.panel_path);
            }

            let panel_list = PanelList::new(cfg.panel_path.clone());
            cfg.panel_hash = panel_list.panels;

            if let Ok(port) = std::env::var("HOST_PORT") {
                cfg.host_port = Some(port);
            } else {
                return Err(CanPiAppError::NotFound(
                    "EV HOST_PORT not valid".to_string(),
                ));
            }
            let sdir = cpp_home.clone() + "/" + STATIC;
            if Path::new(&sdir).is_dir() {
                cfg.static_path = Some(sdir);
            }
            let tdir = cpp_home.clone() + "/" + TEMPLATE;
            let grandparent = Path::new(&tdir).parent().and_then(Path::parent).unwrap();
            if grandparent.is_dir() {
                cfg.template_path = Some(tdir);
            }
            log::info!("{:#?}", cfg);
            Ok(cfg)
        } else {
            Err(CanPiAppError::NotFound(
                "EV CPPANEL_HOME not defined".to_string(),
            ))
        }
    }
}
