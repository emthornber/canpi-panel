use actix_web::{web, Error, HttpResponse, Result};
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use std::sync::Mutex;

use crate::errors::CanPiAppError;
// use crate::models::{EditFilterForm, FilterNameText};
use crate::state::AppState;
use crate::validation::*;

pub async fn status_diagram(
    app_state: web::Data<Mutex<AppState>>,
    tmpl: web::Data<tera::Tera>,
) -> Result<HttpResponse, Error> {
    let app_state = app_state.lock().unwrap();
    let index = &app_state.current_panel_index.clone().unwrap();
    let panel = app_state.panels.get(index).unwrap();
    let mut ctx = tera::Context::new();
    ctx.insert("panel_file", &panel.json_file);
    ctx.insert("panel_title", &panel.title);
    let s = tmpl
        .render("panel_index.html", &ctx)
        .map_err(|_| CanPiAppError::TeraError("Template error".to_string()))?;
    Ok(HttpResponse::Ok().content_type("text/html").body(s))
}

#[cfg(test)]
mod tests {}
