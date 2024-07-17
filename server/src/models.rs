use actix_web::web;
use serde::Deserialize;

#[derive(Deserialize, Debug, Clone)]
pub struct EditFilterForm {
    pub name: String,
    pub prompt: String,
    pub value: String,
}

impl From<web::Json<EditFilterForm>> for EditFilterForm {
    fn from(update_config: web::Json<EditFilterForm>) -> Self {
        EditFilterForm {
            name: update_config.name.clone(),
            prompt: update_config.prompt.clone(),
            value: update_config.value.clone(),
        }
    }
}

#[derive(Debug, Deserialize)]
pub struct FilterNameText {
    pub name: String,
}
