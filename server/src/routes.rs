// use crate::handlers::diagram_handlers::*;
use crate::handlers::general_handlers::*;
use actix_web::web;
use lazy_static::lazy_static;
use std::collections::HashMap;

const LAYOUT: &str = "/layout";
const CONFIRM: &str = "/confirm";
const DISPLAY: &str = "/display";
const EDIT: &str = "/edit";
const PANEL: &str = "/panel";
const SAVE: &str = "/save";
const TITLE: &str = "/panel/{title}";
const DIAGRAM: &str = "/diagram";
const UPDATE: &str = "/update";

lazy_static! {
    pub static ref ROUTE_DATA: HashMap<&'static str, String> = {
        let mut map = HashMap::new();

        #[allow(clippy::useless_format)]
        map.insert("root", format!("{LAYOUT}"));
        map.insert("confirm", format!("{LAYOUT}{DIAGRAM}{CONFIRM}"));
        map.insert("display", format!("{LAYOUT}{DIAGRAM}{DISPLAY}"));
        map.insert("edit", format!("{LAYOUT}{DIAGRAM}{EDIT}"));
        map.insert("panel", format!("{LAYOUT}{PANEL}"));
        map.insert("save", format!("{LAYOUT}{DIAGRAM}{SAVE}"));
        map.insert("diagram", format!("{LAYOUT}{DIAGRAM}"));
        map.insert("update", format!("{LAYOUT}{DIAGRAM}{UPDATE}"));

        map
    };
}

pub fn general_routes(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope(ROUTE_DATA["root"].as_str())
            .service(web::resource("").route(web::get().to(status_handler)))
            .service(web::resource(TITLE).route(web::get().to(status_panel))),
    );
}

/* pub fn diagram_routes(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope(ROUTE_DATA["diagram"].as_str())
            .service(web::resource("").route(web::get().to(status_diagram)))
            .service(web::resource(DISPLAY).route(web::get().to(display_diagram)))
            .service(web::resource(EDIT).route(web::get().to(edit_diagram)))
            .service(web::resource(SAVE).route(web::get().to(save_diagram)))
            .service(web::resource(UPDATE).route(web::post().to(update_diagram))),
    );
} */
