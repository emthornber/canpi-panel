use actix_web::{web, Error, HttpResponse, Result};
use std::sync::Mutex;

use crate::errors::CanPiAppError;
use crate::state::AppState;

use super::diagram_handlers::status_diagram;

pub async fn status_handler(
    app_state: web::Data<Mutex<AppState>>,
    tmpl: web::Data<tera::Tera>,
) -> Result<HttpResponse, Error> {
    let app_state = app_state.lock().unwrap();
    let mut ctx = tera::Context::new();
    ctx.insert("panels", &app_state.panels);
    let s = tmpl
        .render("index.html", &ctx)
        .map_err(|_| CanPiAppError::TeraError("Template error".to_string()))?;
    Ok(HttpResponse::Ok().content_type("text/html").body(s))
}

pub async fn status_panel(
    app_state: web::Data<Mutex<AppState>>,
    tmpl: web::Data<tera::Tera>,
    path: web::Path<String>,
) -> Result<HttpResponse, Error> {
    let index = path.into_inner().parse::<u8>().unwrap();
    {
        let mut app_state = app_state.lock().unwrap();
        // Assume failure and reset current panel
        app_state.current_panel_index = None;
        // Check that the panel is valid
        if app_state.panels.contains_key(&index) {
            app_state.current_panel_index = Some(index);
        }
        // The mutex guard gets dropped here as app_state goes out of scope
    }
    // Render the panel index web page
    status_diagram(app_state, tmpl).await
}
