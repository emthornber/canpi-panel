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

    log::info!("canpi panel app listening on http://{}", sock_addr);

    axum::Server::bind(&sock_addr)
        .serve(app.into_make_service())
        .await
        .expect("unable to start canpi panel app");
}
