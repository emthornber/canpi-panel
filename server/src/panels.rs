use jsonschema::JSONSchema;
use schemars::schema::RootSchema;
use schemars::{schema_for, JsonSchema};
use serde::Deserialize;
use serde_json::Value;

use std::{
    collections::HashMap, fs::File, io::BufReader, path::Path, path::PathBuf, string::String,
};

fn create_json_schema(root_schema: RootSchema) -> JSONSchema {
    let schema_string = serde_json::to_string(&root_schema).unwrap();
    let json_value: Value =
        serde_json::from_slice(schema_string.as_bytes()).expect("convert schema to json");
    JSONSchema::options()
        .compile(&json_value)
        .expect("a valid schema")
}
///
/// Signalling Panel Definitions
///

/// Enumerations
///
/// Direction of track marking on a Tile
#[derive(Clone, Deserialize, Debug, JsonSchema, PartialEq)]
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
pub enum TurnOutDirection {
    North,
    East,
    South,
    West,
}

#[derive(Clone, Deserialize, Debug, JsonSchema, PartialEq)]
pub enum TurnOutHand {
    Left,
    Right,
    Wye,
}

/// Structures
///
/// CbusStates that indicate how the turnout is lying
#[derive(Clone, Deserialize, Debug, JsonSchema)]
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
pub struct CbusState {
    /// Item name
    name: String,
    /// Event number - either long or short format
    event: String,
    /// Current state of the event
    state: State,
}

/// Dimensions of the panel
#[derive(Clone, Deserialize, Debug, JsonSchema)]
pub struct Panel {
    /// Width of panel in tiles
    width: u16,
    /// Height of panel in tiles
    height: u16,
    /// size (in pixels) of a square tile
    tilesize: u16,
    /// RGB colour definition of panel background
    colour: u32,
    /// Margin in pixels
    margins: u16,
    //// Border in pixels
    border: u16,
    /// Diagram title
    title: String,
}

/// Position of tile within panel
#[derive(Clone, Deserialize, Debug, JsonSchema)]
pub struct Tile {
    /// (1 <= x_coord <= panel.width)
    x_coord: u16,
    /// (1 <= y_coord <= panel.height)
    y_coord: u16,
}

// How the track is shown on a tile
#[derive(Clone, Deserialize, Debug, JsonSchema)]
pub struct Track {
    /// Where the track is on the panel
    tile: Tile,
    /// Which image to use
    direction: Direction,
    /// Text to be displayed on panel
    label: String,
    /// CbusState that provides state of track circuit
    tcstate: String,
    /// CbusState that provides state of train detector
    spot: String,
}

/// Turnout (switch, point) details
#[derive(Clone, Deserialize, Debug, JsonSchema)]
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
pub struct Control {
    /// Position of switch on panel
    tile: Tile,
    /// Display name
    name: String,
    switch: SwitchType,
    /// Name of CBusState that acutates turnout
    action: String,
    /// How the turnout currently lies
    tostate: TurnoutState,
}

/// Specification of the signalling diagram
#[derive(Clone, Deserialize, Debug, JsonSchema)]
pub struct Layout {
    /// List of controls for turnouts, signals, ...
    controls: Vec<Control>,
    /// Overall panel details
    panel: Panel,
    /// Track layout
    track: Vec<Track>,
    /// Turnout definitions
    turnouts: Vec<Turnout>,
}

/// Definition of a Signalling Panel
#[derive(Clone, Deserialize, Debug, JsonSchema)]
pub struct Diagram {
    /// The state of the CBus producers and consumers
    cbusstates: Vec<CbusState>,
    /// The realisation of the signalling diagram
    layout: Layout,
}

pub struct PanelDetail {
    title: String,
    json_file: PathBuf,
}

/// Type alias defining the signalling diagram JSON files
pub type PanelHash = HashMap<u8, PanelDetail>;

/// The definition of available signalling diagrams
pub struct PanelList {
    schema: JSONSchema,
    pub panels: PanelHash,
}

impl PanelList {
    /// Create a new instance of the structure
    ///
    /// The type definition of Diagram is used to create
    /// a compiled JSON schema that will be used to validate
    /// the panel definition being referenced by PanelHash.
    pub fn new<P: AsRef<Path>>(panel_path: P) -> PanelList {
        let schema = Self::create_struct_schema();
        let panels = PanelHash::new();
        PanelList { schema, panels }
    }

    fn create_struct_schema() -> JSONSchema {
        let schema = schema_for!(Diagram);
        create_json_schema(schema)
    }
}
