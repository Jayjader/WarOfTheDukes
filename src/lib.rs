#[macro_use]
extern crate gdnative as godot;
use hex2d::{Coordinate, Spacing};
use std::collections::HashMap;

/// The "Unit" enum. Represents the 4 unit types of the game:
///  Infantry, Cavalry, Artillery, Duke
pub enum Unit {
    Duke,
    Infantry,
    Cavalry,
    Artillery,
}

/// The "Strength" trait. Represents the capability to participate offensively in combat.
pub trait Strength {
    fn attack(&self) -> u32;
}

impl Strength for Unit {
    fn attack(&self) -> u32 {
        use Unit::*;
        match self {
            Duke => 0,
            Infantry => 5,
            Cavalry => 2,
            Artillery => 3,
        }
    }
}

/// The "Defense" trait. Represents the capability to participate defensively in combat.
pub trait Defense {
    fn defend(&self) -> u32;
}

impl Defense for Unit {
    fn defend(&self) -> u32 {
        match self {
            Unit::Duke => 1,
            _ => self.attack(),
        }
    }
}

//impl godot::ToVariant for hex2d::Coordinate {
//    fn to_variant(&self) -> godot::Variant {
//        godot::Vector2::new(self.x as f32, self.y as f32)
//    }
//}

/// The Game Board. Is a 2D grid of hexagonal Tiles.
#[derive(NativeClass)]
#[inherit(godot::Node)]
struct Board {
    tile_size: Spacing,
    tiles: HashMap<Coordinate, TileType>,
}

const TILE_SIZE: f32 = 60 as f32;

const BOARD_TILES: &[(Coordinate, TileType)] = &[
    (Coordinate { x: 0, y: 0 }, TileType::City),
    (Coordinate { x: 0, y: 1 }, TileType::City),
    (Coordinate { x: 0, y: 2 }, TileType::City),
    (Coordinate { x: 0, y: 3 }, TileType::City),
    (Coordinate { x: 0, y: 4 }, TileType::Cliff),
    (Coordinate { x: 0, y: 5 }, TileType::Plains),
    (Coordinate { x: 0, y: 6 }, TileType::Forest),
    (Coordinate { x: 0, y: 7 }, TileType::Forest),
    (Coordinate { x: 0, y: 8 }, TileType::Forest),
    (Coordinate { x: 0, y: 9 }, TileType::Forest),
    (Coordinate { x: 0, y: 10 }, TileType::Forest),
    (Coordinate { x: 0, y: 11 }, TileType::Forest),
    (Coordinate { x: 0, y: 12 }, TileType::Forest),
    (Coordinate { x: 0, y: 13 }, TileType::Plains),
    (Coordinate { x: 0, y: 14 }, TileType::Plains),
    (Coordinate { x: 0, y: 15 }, TileType::Plains),
    (Coordinate { x: 0, y: 16 }, TileType::Forest),
    (Coordinate { x: 0, y: 17 }, TileType::Forest),
    (Coordinate { x: 0, y: 18 }, TileType::Forest),
];

#[methods]
impl Board {
    fn new(tile_size: hex2d::Spacing) -> Board {
        Board {
            tile_size,
            tiles: HashMap::new(),
        }
    }
    // Godot's init hook
    fn _init(_owner: godot::Node) -> Self {
        use TileType::*;
        let mut board = Board::new(hex2d::Spacing::FlatTop(TILE_SIZE));
        for (coord, tile) in BOARD_TILES.iter() {
            board.tiles.insert(*coord, *tile);
        }
        board
    }
    // Godot's ready hook
    #[export]
    fn _ready(&self, _owner: godot::Node) {}

    #[export]
    fn test_func(&self, _owner: godot::Node) {
        godot_print!("test_func");
    }

    #[export]
    fn get_tiles_xy(&self, _owner: godot::Node) -> Vec<(godot::Vector2, TileType)> {
        self.tiles
            .iter()
            .map(|(position, tile)| (position.to_pixel(self.tile_size), tile))
            .map(|((x, y), tile)| (godot::Vector2::new(x, y), *tile))
            .collect()
    }
}

/// The type of terrain making up the center of a tile. This can impact a unit's offensive or
/// defensive power during combat.
#[derive(Debug, Copy, Clone)]
enum TileType {
    Plains,
    Road,
    City,
    Forest,
    Cliff,
    Lake,
}

/// The type of terrain making up the border between 2 tiles. As well as the different types of
/// tile, there are a few extra special cases, such as bridges and rivers. This can impact a unit's
/// ability to move through the border in question, reflected by the cost in movement points to do
/// so.
#[derive(Debug, Copy, Clone)]
enum BorderType {
    Some(TileType),
    River,
    Bridge,
    BridgeWithRoad,
}

/// A tile on the game board
#[derive(Debug, Copy, Clone)]
struct Tile {
    center: TileType,
    yz: BorderType,
    xz: BorderType,
    xy: BorderType,
    zy: BorderType,
    zx: BorderType,
    yx: BorderType,
}

impl ToString for TileType {
    fn to_string(&self) -> String {
        use TileType::*;
        match &self {
            Plains => "Plains".to_string(),
            Road => "Road".to_string(),
            City => "City".to_string(),
            Forest => "Forest".to_string(),
            Cliff => "Cliff".to_string(),
            Lake => "Lake".to_string(),
        }
    }
}

impl ToString for BorderType {
    fn to_string(&self) -> String {
        use BorderType::*;
        use TileType::*;
        match &self {
            Some(tile_type) => tile_type.to_string(),
            River => "River".to_string(),
            Bridge => "Bridge".to_string(),
            BridgeWithRoad => "BridgeWithRoad".to_string(),
        }
    }
}

impl godot::ToVariant for TileType {
    fn to_variant(&self) -> godot::Variant {
        use godot::{GodotString, Variant};
        Variant::from_godot_string(&GodotString::from_str(self.to_string()))
    }
}

impl godot::ToVariant for BorderType {
    fn to_variant(&self) -> godot::Variant {
        use godot::{GodotString, Variant};
        Variant::from_godot_string(&GodotString::from_str(self.to_string()))
    }
}

impl godot::ToVariant for Tile {
    fn to_variant(&self) -> godot::Variant {
        use godot::{GodotString, Variant};
        Variant::from_godot_string(&GodotString::from_str(format!(
            "{}",
            self.center.to_string()
        )))
    }
}

#[cfg(test)]
mod test {
    use crate::{Defense, Strength, Unit};

    #[test]
    fn test_duke_attack_should_be_0() {
        assert_eq!(Unit::Duke.attack(), 0);
    }

    #[test]
    fn test_duke_defense_should_be_1() {
        assert_eq!(Unit::Duke.defend(), 1);
    }

    #[test]
    fn test_infantry_strength_should_be_5() {
        assert_eq!(Unit::Infantry.attack(), 5);
        assert_eq!(Unit::Infantry.defend(), 5);
    }

    #[test]
    fn test_cavalry_strength_should_be_2() {
        assert_eq!(Unit::Cavalry.attack(), 2);
        assert_eq!(Unit::Cavalry.defend(), 2);
    }

    #[test]
    fn test_artillery_strength_should_be_3() {
        assert_eq!(Unit::Artillery.attack(), 3);
        assert_eq!(Unit::Artillery.defend(), 3);
    }
}

/// The HelloWorld "class"
///#[derive(NativeClass)]
///#[inherit(godot::Node)]
///pub struct HelloWorld;
///
/// __One__ `impl` block can have the `#[methods]` attribute, which will generate
/// code to automatically bind any exported methods to Godot.
///#[methods]
///impl HelloWorld {
///    /// The "constructor" of the class.
///    fn _init(_owner: godot::Node) -> Self {
///        HelloWorld
///    }
///
///    // In order to make a method known to Godot, the #[export] attribute has to be used.
///    // In Godot script-classes do not actually inherit the parent class.
///    // Instead they are"attached" to the parent object, called the "owner".
///    // The owner is passed to every single exposed method.
///    #[export]
///    fn _ready(&self, _owner: godot::Node) {
///        // The `godot_print!` macro works like `println!` but prints to the Godot-editor
///        // output tab as well.
///        godot_print!("hello, world...");
///    }
///}

/// Function that registers all exposed classes to Godot
fn init(handle: godot::init::InitHandle) {
    handle.add_class::<Board>();
}

// macros that create the entry-points of the dynamic library.
godot_gdnative_init!();
godot_nativescript_init!(init);
godot_gdnative_terminate!();
