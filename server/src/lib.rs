use glob::glob;
use jsonschema::JSONSchema;
use schemars::schema::RootSchema;
use schemars::{schema_for, JsonSchema};
use serde::Deserialize;
use serde_json::Value;

use std::{
    collections::HashMap,
    fs::File,
    io::BufReader,
    path::{Path, PathBuf},
    string::String,
};

use log::error;

fn create_json_schema(root_schema: RootSchema) -> JSONSchema {
    let schema_string = serde_json::to_string(&root_schema).unwrap();
    let json_value: Value =
        serde_json::from_slice(schema_string.as_bytes()).expect("convert schema to json");
    JSONSchema::options()
        .compile(&json_value)
        .expect("A valid schema")
}
///
/// Signalling Panel Definitions
///
/// The enum and struct definitions are detailed so that JSON diagram definition
/// can be parsed successfully.
/// The only attribute used is diagram.layout.panel.title hence the supression
/// of dead code warnings.

/// Enumerations
///
/// Direction of track marking on a Tile
#[derive(Clone, Deserialize, Debug, JsonSchema, PartialEq)]
#[allow(dead_code)]
pub enum Direction {
    EW,
    NE,
    NS,
    NW,
    SE,
    SW,
}

/// State of CBus event
#[derive(Clone, Deserialize, Debug, JsonSchema, PartialEq)]
#[allow(dead_code)]
pub enum State {
    UNKN,
    ZERO,
    ONE,
}

/// Type of control switch
#[derive(Clone, Deserialize, Debug, JsonSchema, PartialEq)]
pub enum SwitchType {
    Toggle,
    PushButton,
}

#[derive(Clone, Deserialize, Debug, JsonSchema, PartialEq)]
#[allow(dead_code)]
pub enum TurnOutDirection {
    North,
    East,
    South,
    West,
}

#[derive(Clone, Deserialize, Debug, JsonSchema, PartialEq)]
#[allow(dead_code)]
pub enum TurnOutHand {
    Left,
    Right,
    Wye,
}

/// Structures

/// CbusStates that indicate how the turnout is lying
#[derive(Clone, Deserialize, Debug, JsonSchema)]
#[allow(dead_code)]
pub struct TurnoutState {
    /// Treat these as a double-bit
    /// 0-0 In-transit
    /// 1-0 Normal
    /// 0-1 Reverse
    /// 1-1 ERROR
    normal: String,
    reverse: String,
}

/// Definition of the state of a CBus event
#[derive(Clone, Deserialize, Debug, JsonSchema)]
#[allow(dead_code)]
pub struct CbusState {
    /// Item name
    name: String,
    /// Event number - either long or short format
    event: Option<String>,
    /// Current state of the event
    state: State,
}

/// Dimensions of the panel
#[derive(Clone, Deserialize, Debug, JsonSchema)]
#[allow(dead_code)]
pub struct Panel {
    /// Width of panel in tiles
    width: u16,
    /// Height of panel in tiles
    height: u16,
    /// size (in pixels) of a square tile
    tilesize: u16,
    /// RGB colour definition of panel background as a HEX string
    colour: String,
    /// Margin in pixels
    margins: u16,
    //// Border in pixels
    border: u16,
    /// Diagram title
    title: String,
}

/// Position of tile within panel
#[derive(Clone, Deserialize, Debug, JsonSchema)]
#[allow(dead_code)]
pub struct Tile {
    /// (1 <= x_coord <= panel.width)
    x_coord: u16,
    /// (1 <= y_coord <= panel.height)
    y_coord: u16,
}

// How the track is shown on a tile
#[derive(Clone, Deserialize, Debug, JsonSchema)]
#[allow(dead_code)]
pub struct Track {
    /// Where the track is on the panel
    tile: Tile,
    /// Which image to use
    direction: Direction,
    /// Text to be displayed on panel
    label: Option<String>,
    /// CbusState that provides state of track circuit
    tcstate: Option<String>,
    /// CbusState that provides state of train detector
    spot: Option<String>,
}

/// Turnout (switch, point) details
#[derive(Clone, Deserialize, Debug, JsonSchema)]
#[allow(dead_code)]
pub struct Turnout {
    /// Where on panel
    tile: Tile,
    /// Text to be displayed on panel
    name: String,
    /// Left, Right of Wye
    hand: TurnOutHand,
    /// Direction turnout is laid
    orientation: TurnOutDirection,
    /// CbusStates that define the turnout state
    tostate: TurnoutState,
}

/// Definition of a control switch
#[derive(Clone, Deserialize, Debug, JsonSchema)]
#[allow(dead_code)]
pub struct Control {
    /// Position of switch on panel
    tile: Tile,
    /// Display name
    name: String,
    switch: SwitchType,
    /// Name of CBusState that actuates turnout
    action: String,
    /// How the turnout currently lies
    tostate: TurnoutState,
}

/// Specification of the signalling diagram
#[derive(Clone, Deserialize, Debug, JsonSchema)]
#[allow(dead_code)]
pub struct Layout {
    /// Overall panel details
    panel: Panel,
    /// List of controls for turnouts, signals, ...
    controls: Vec<Control>,
    /// Track layout
    track: Vec<Track>,
    /// Turnout definitions
    turnouts: Vec<Turnout>,
}

/// Definition of a Signalling Panel
#[derive(Clone, Deserialize, Debug, JsonSchema)]
#[allow(dead_code)]
pub struct Diagram {
    /// The state of the CBus producers and consumers
    cbusstates: Vec<CbusState>,
    /// The realisation of the signalling diagram
    layout: Layout,
}

impl Diagram {
    /// Create a JSON schema from Diagram structure
    pub fn create_json_schema() -> String {
        let schema = schema_for!(Diagram);
        serde_json::to_string_pretty(&schema).unwrap()
    }
}

#[derive(Clone, Deserialize, Debug, JsonSchema)]
#[allow(dead_code)]
pub struct PanelDefinition {
    pub title: String,
    pub json_file: PathBuf,
}

/// Type alias defining the signalling diagram JSON files
pub type PanelHash = HashMap<u8, PanelDefinition>;

/// The definition of available control panels
#[allow(dead_code)]
pub struct PanelList {
    schema: JSONSchema,
    pub panels: Option<PanelHash>,
}

impl PanelList {
    /// Create a new instance of the structure
    ///
    /// The type definition of Diagram is used to create
    /// a compiled JSON schema that will be used to validate
    /// the panel definition being referenced by PanelHash.
    pub fn new<P: AsRef<Path>>(panel_dir: P) -> PanelList {
        let schema = Self::create_diagram_schema();
        let panels = Self::load_panels(panel_dir, &schema);
        PanelList { schema, panels }
    }

    /// Create a compiled JSON schema from Diagram definition
    fn create_diagram_schema() -> JSONSchema {
        let schema = schema_for!(Diagram);
        create_json_schema(schema)
    }

    /// Load the panel definitions from `${panel_dir}/*.json`, extract 'title'
    /// from JSON definitions, and store in PanelHash.
    fn load_panels<P: AsRef<Path>>(panel_dir: P, schema: &JSONSchema) -> Option<PanelHash> {
        // Read list of JSON files
        let pf = Self::find_panel_definitions(panel_dir);
        match pf {
            Ok(panel_files) => {
                let mut index = 1;
                let mut panels = PanelHash::new();
                // Walk through file list
                for panel in panel_files {
                    if let Ok(panel_defn) = Self::read_defn_file(panel, schema) {
                        // JSON file validated successfully so add to PanelHash
                        if let Some(_) = panels.insert(index, panel_defn) {
                            index += 1;
                        }
                    }
                    // ignore failures
                }
                if panels.len() > 0 {
                    Some(panels)
                } else {
                    None
                }
            }
            Err(e) => {
                // Log error text
                error!("{}", e);
                None
            }
        }
    }

    /// Return list of all JSON files in 'panels' directory
    fn find_panel_definitions<P: AsRef<Path>>(panel_dir: P) -> Result<Vec<PathBuf>, &'static str> {
        let mut panel_vec: Vec<PathBuf> = Vec::new();
        let mut panel_json = panel_dir.as_ref().to_path_buf();
        panel_json.push("*.json");
        if let Some(glob_str) = panel_json.to_str() {
            for entry in glob(glob_str).unwrap().filter_map(Result::ok) {
                panel_vec.push(entry);
            }
        }
        Ok(panel_vec)
    }

    /// Read the contents of a file as JSON and, if valid against the schema,
    /// return an instance of 'PanelDefinition'
    fn read_defn_file(
        json_file: PathBuf,
        schema: &JSONSchema,
    ) -> Result<PanelDefinition, &'static str> {
        // Open the file in read-only mode with buffer
        let f = File::open(json_file.as_path());
        match f {
            Ok(file) => {
                let reader = BufReader::new(file);
                if let Ok(json_value) = serde_json::from_reader(reader) {
                    if schema.is_valid(&json_value) {
                        // Read the JSON contents of the file as an instance of 'Diagram'.
                        if let Ok(diagram) = serde_json::from_value::<Diagram>(json_value) {
                            let title = diagram.layout.panel.title;
                            let panel_entry = PanelDefinition { title, json_file };
                            Ok(panel_entry)
                        } else {
                            error!("conversion to struct failed for {}", json_file.display());
                            Err("(failed to convert JSON to struct)")
                        }
                    } else {
                        // JSON not valid against schema - log detailed error report
                        let result = schema.validate(&json_value);
                        if let Err(errors) = result {
                            error!("schema errors");
                            for error in errors {
                                error!("{}", error);
                            }
                        }
                        error!("{} failed validation", json_file.display());
                        Err("failed to validate JSON")
                    }
                } else {
                    error!("reading file {} as json failed", json_file.display());
                    Err("(non-utf8 path)")
                }
            }
            Err(_) => {
                error!("io error from file {}", json_file.display());
                Err("io error")
            }
        }
    }
}

#[cfg(test)]
mod test_panel_list {
    use super::*;
    use env_logger::Target;
    use log::{info, LevelFilter};
    use std::fs;
    use std::io::Write;

    fn init_logging() {
        let _ = env_logger::builder()
            .target(Target::Stdout)
            .filter_level(LevelFilter::max())
            .is_test(true)
            .try_init();
    }

    fn setup_file<P: AsRef<Path>>(test_file: P, data: &str) {
        let mut f = File::create(test_file).expect("file creation failed");
        f.write_all(data.as_bytes()).expect("file write failed");
    }

    fn teardown_file<P: AsRef<Path>>(test_file: P) {
        fs::remove_file(test_file).expect("file deletion failed");
    }

    #[test]
    #[ignore = "verbose output"]
    fn view_diagram_schema() {
        // Initialise Logger
        init_logging();

        let dia_schema = schema_for!(Diagram);
        info!("{}", serde_json::to_string_pretty(&dia_schema).unwrap());
    }

    #[test]
    fn find_panel_definitions_zero() {
        let panel_dir = "src/";
        let pf = PanelList::find_panel_definitions(&panel_dir).unwrap();
        assert_eq!(pf.len(), 0);
    }

    #[test]
    fn find_panel_definitions_more_than_zero() {
        let json_file = "scratch/panel.json";
        setup_file(json_file, "{}");
        let panel_dir = "scratch/";
        let pf = PanelList::find_panel_definitions(&panel_dir).unwrap();
        teardown_file(json_file);
        assert!(pf.len() > 0);
    }

    #[test]
    #[should_panic]
    fn read_defn_file_missing() {
        let schema = PanelList::create_diagram_schema();
        let json_file = PathBuf::from("tests/nonexistent_file.json");
        let _ = PanelList::read_defn_file(json_file, &schema).unwrap();
    }

    #[test]
    #[should_panic]
    fn read_defn_file_not_valid() {
        let schema = PanelList::create_diagram_schema();
        let json_file = PathBuf::from("tests/good-example-config-defn.json");
        let _ = PanelList::read_defn_file(json_file, &schema).unwrap();
    }

    #[test]
    fn read_defn_file_validates() {
        let schema = PanelList::create_diagram_schema();
        let json_file = PathBuf::from("tests/test_diagram.json");
        let pd = PanelList::read_defn_file(json_file, &schema).unwrap();
        assert_eq!(pd.title, "Test Diagram");
    }

    #[test]
    fn load_panels_no_json() {
        let schema = PanelList::create_diagram_schema();
        let panel_dir = "src/";
        let panel_hash = PanelList::load_panels(panel_dir, &schema);
        match panel_hash {
            Some(_) => assert!(false),
            None => assert!(true),
        }
    }

    #[test]
    fn load_panels_invalid_json() {
        let schema = PanelList::create_diagram_schema();
        let panel_dir = "scratch/";
        let panel_hash = PanelList::load_panels(panel_dir, &schema);
        match panel_hash {
            Some(_) => assert!(false),
            None => assert!(true),
        }
    }

    #[test]
    fn load_panels_one_valid_json() {
        let schema = PanelList::create_diagram_schema();
        let panel_dir = "tests/";
        let panel_hash = PanelList::load_panels(panel_dir, &schema);
        match panel_hash {
            Some(ph) => assert_eq!(ph.len(), 1),
            None => assert!(false),
        }
    }
}
