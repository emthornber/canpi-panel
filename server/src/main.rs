use actix_files as fs;
use actix_web::{web, App, HttpServer};
use dotenv::dotenv;
use futures::{sink::SinkExt, stream::StreamExt};
use glob::glob;
use simple_logger::SimpleLogger;
use std::str::FromStr;
use std::{collections::HashMap, path::Path, process, sync::Mutex};
use tera::{from_value, to_value, Function, Tera, Value};
use time::macros::format_description;

mod errors;
mod panels;
mod state;
mod validation;

use panels::*;
use state::AppState;
use validation::*;

fn make_scope_for<'a>(scopes: &'static HashMap<&'a str, String>) -> impl Function + 'a {
    Box::new(
        move |args: &HashMap<String, Value>| -> tera::Result<Value> {
            match args.get("scope") {
                Some(val) => match from_value::<String>(val.clone()) {
                    Ok(v) => Ok(to_value(scopes.get(&*v).unwrap()).unwrap()),
                    Err(_) => Err("oops err".into()),
                },
                None => Err("oops none".into()),
            }
        },
    )
}

#[actix_web::main]
// async fn main() -> std::io::Result<()> {
async fn main() {
    dotenv().ok();
    SimpleLogger::new()
        .with_level(log::LevelFilter::Warn)
        .env()
        .with_timestamp_format(format_description!(
            "[year]-[month]-[day] [hour]:[minute]:[second]"
        ))
        .init()
        .unwrap();

    if let Ok(canpi_cfg) = CanpiConfig::new() {
        // Webpage formatting files
        let static_path = canpi_cfg.static_path.unwrap();

        // Create and load the configurations using the JSON schema files
        let panel_hash = canpi_cfg.panel_hash.unwrap();

        // Create the top menu HTML include file
        if let Some(tmpl_path) = canpi_cfg.template_path.clone() {
            let template_grandparent = Path::new(&tmpl_path)
                .parent()
                .and_then(Path::parent)
                .unwrap();
            let mut format_file = template_grandparent.to_path_buf();
            format_file.push("top_menu.format");
            if let Ok(()) = build_top_menu_html(&panel_hash, format_file.as_path()) {
                log::info!("Top menu created")
            } else {
                log::warn!("Failed to create top menu");
            }
        } else {
            log::warn!("Cannot find top menu format file");
        }
        // Start HTTP Server
        let host_port = canpi_cfg.host_port.unwrap();
        let shared_data = web::Data::new(Mutex::new(AppState {
            cangrid_uri: canpi_cfg.cangrid_uri,
            current_panel: None,
            panels: panel_hash,
        }));
        let mut tera = Tera::new(canpi_cfg.template_path.unwrap().as_str()).unwrap();
        /* tera.register_function("scope_for", make_scope_for(&ROUTE_DATA));
        let app = move || {
            App::new()
                .app_data(web::Data::new(tera.clone()))
                .app_data(shared_data.clone())
                .configure(topic_routes)
                .configure(general_routes)
                .service(fs::Files::new("/static", static_path.clone()).show_files_listing())
        }; */
        log::info!("canpi panel app listening on http://{}", host_port);
        // HttpServer::new(app).bind(&host_port)?.run().await
    } else {
        log::error!("EV contents failed validation - exiting ...");
        process::exit(1);
    }
}
