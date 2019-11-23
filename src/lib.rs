#[macro_use]
extern crate gdnative as godot;
use hex2d;
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

/// The Game Board. Is a 2D grid of hexagonal Tiles.
#[derive(NativeClass)]
#[inherit(godot::Node)]
pub struct Board {
    tile_size: hex2d::Spacing,
    tiles: HashMap<(u32, u32), Tile>,
}

pub const TILE_SIZE: f32 = 10 as f32;

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
        use Tile::*;
        let mut board = Board::new(hex2d::Spacing::FlatTop(TILE_SIZE));
        board.tiles.insert((1, 1), Normal);
        board
    }
    // Godot's ready hook
    #[export]
    fn _ready(&self, _owner: godot::Node) {
        godot_print!("{:#?} tile size, {:?} map", self.tile_size, self.tiles);
    }
}

/// The Tiles of the game's Board.
#[derive(Debug)]
pub enum Tile {
    Normal,
    Road,
    City,
    Bridge,
    BridgeWithRoad,
    Forest,
    Cliff,
    Lake,
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
