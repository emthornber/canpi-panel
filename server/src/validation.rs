use crate::errors::CanPiAppError;
use std::path::Path;

use canpi_config::PanelList;

#[macro_export]
macro_rules! pkg_name {
    () => {
        env!("CARGO_BIN_NAME")
    };
}

const CFGFILE: &str = "/canpi-panel.cfg";
const STATIC: &str = "/static";
const TEMPLATE: &str = "/templates/**/*";

/// Structure that holds configuration items expanded from EVs and static text
pub struct CanpiConfig {
    pub cangrid_port: Option<String>,
    pub config_path: Option<String>,
    pub host_port: Option<String>,
    pub panel_defn: Option<PanelList>,
    pub panel_path: Option<String>,
    pub static_path: Option<String>,
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
            let mut cfg = CanpiConfig {
                cangrid_port: None,
                config_path: None,
                host_port: None,
                panel_defn: None,
                panel_path: None,
                static_path: None,
                template_path: None,
            };

            let cfile = cpp_home.clone() + "/" + STATIC + CFGFILE;
            if Path::new(&cfile).is_file() {
                cfg.config_path = Some(cfile.clone());
                let mut pkg = Pkg::new();
                match pkg.load_panels(cfile) {
                    Ok(()) => cfg.pkg_defn = Some(pkg),
                    Err(e) => {
                        return Err(CanPiAppError::NotFound(format!(
                            "Cannot load package configurations '{e}'"
                        )))
                    }
                }
            } else {
                return Err(CanPiAppError::NotFound(format!(
                    "Configuration file '{cfile}' not found"
                )));
            }

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
            let grandparent = Path::new(&tdir).parent().unwrap().parent().unwrap();
            if grandparent.is_dir() {
                cfg.template_path = Some(tdir);
            }

            Ok(cfg)
        } else {
            Err(CanPiAppError::NotFound(
                "EV CPPANEL_HOME not defined".to_string(),
            ))
        }
    }
}
