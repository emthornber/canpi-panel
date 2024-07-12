use itertools::Itertools;
use log;
use std::fs::File;
use std::io::prelude::*;
use std::path::{Path, PathBuf};

use crate::errors::CanPiAppError;
use server::{PanelHash, PanelList};

fn create_html_file<P: AsRef<Path>>(format_file: P) -> std::io::Result<File> {
    let mut html_file = PathBuf::from(format_file.as_ref());
    html_file.set_extension("html");
    File::create(html_file)
}

pub fn build_top_menu_html<P: AsRef<Path>>(
    panel_hash: &PanelHash,
    format_file: P,
) -> Result<(), CanPiAppError> {
    let mut format_defn = String::new();
    let mut file = File::open(format_file.as_ref())?;
    file.read_to_string(&mut format_defn)?;
    let mut html_file = create_html_file(format_file)?;
    if panel_hash.is_empty() {
        html_file.write_all(b"<li><br>No displayable panels configured<br></li>")?;
    } else {
        let mut html_code = String::new();
        for k in panel_hash.keys().sorted() {
            let pd = panel_hash.get(k).unwrap();
            let line_title = format_defn.as_str().replace("|title|", pd.title.as_str());
            let line = line_title
                .as_str()
                .replace("|index|", k.to_string().as_str());
            html_code.push_str(line.as_str());
        }
        html_file.write_all(&html_code.into_bytes())?;
    }

    Ok(())
}

#[cfg(test)]
mod panel_tests {
    use super::*;
    use env_logger::Target;
    use log::{info, LevelFilter};

    fn init_logging() {
        let _ = env_logger::builder()
            .target(Target::Stdout)
            .filter_level(LevelFilter::max())
            .is_test(true)
            .try_init();
    }

    #[test]
    fn check_html_file_name() {
        let file_name_root = Path::new("templates");
        let mut format_file = file_name_root;
        let mut format_file = format_file.join("top_menu.format");
        let mut html_file = file_name_root;
        let mut html_file = html_file.join("top_menu.html");
        format_file.set_extension("html");
        assert_eq!(format_file, html_file);
    }

    #[test]
    fn build_html_test() {
        init_logging();
        let panel_list = PanelList::new(Path::new("panels"));
        // let panel_list = PanelList::new(Path::new("../../canpi-config/tests"));
        let file_name_root = Path::new("templates");
        let mut format_file = file_name_root;
        let mut format_file = format_file.join("top_menu.format");
        if let Some(ph) = panel_list.panels {
            if let Err(e) = build_top_menu_html(&ph, format_file) {
                assert!(false, "build failed");
            }
        } else {
            assert!(false, "No panel hash");
        }
    }
}
