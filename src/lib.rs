#[macro_use]
extern crate gdnative as godot;
extern crate serde;
#[macro_use]
extern crate serde_scan;

use std::collections::HashMap;
use std::convert::TryFrom;
use std::fs;

use hex2d::{Coordinate, Direction, Spacing};
use serde::Deserialize;
use serde_scan::from_str;

mod unit;

/// The Game Board. Is a 2D grid of hexagonal Tiles.
#[derive(NativeClass)]
#[inherit(godot::Node)]
struct Board {
    tile_size: Spacing,
    tiles: HashMap<Coordinate, TileType>,
}

const TILE_SIZE: f32 = 60 as f32;

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
        let mut board = Board::new(hex2d::Spacing::FlatTop(TILE_SIZE));
        board
    }
    // Godot's ready hook
    #[export]
    fn _ready(&self, _owner: godot::Node) {
        let contents = fs::read_to_string("board.config").expect("file read error :(");
    }

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
#[derive(Debug, Copy, Clone, Deserialize)]
enum TileType {
    Plains,
    City,
    Forest,
    Cliff,
    Lake,
}

impl TryFrom<&str> for TileType {
    type Error = &'static str;

    fn try_from(value: &str) -> Result<Self, Self::Error> {
        use TileType::*;
        match value {
            "Plains" => Ok(Plains),
            "City" => Ok(City),
            "Forest" => Ok(Forest),
            "Cliff" => Ok(Cliff),
            "Lake" => Ok(Lake),
            _ => Err("Unknown TileType"),
        }
    }
}

impl ToString for TileType {
    fn to_string(&self) -> String {
        use TileType::*;
        match &self {
            Plains => "Plains".to_string(),
            City => "City".to_string(),
            Forest => "Forest".to_string(),
            Cliff => "Cliff".to_string(),
            Lake => "Lake".to_string(),
        }
    }
}

impl godot::ToVariant for TileType {
    fn to_variant(&self) -> godot::Variant {
        use godot::{GodotString, Variant};
        Variant::from_godot_string(&GodotString::from_str(self.to_string()))
    }
}

/// The type of terrain making up the border between 2 tiles. As well as the different types of
/// tile, there are a few extra special cases, such as bridges and rivers. This can impact a unit's
/// ability to move through the border in question, reflected by the cost in movement points to do
/// so.
#[derive(Debug, Copy, Clone, Deserialize)]
enum BorderType {
    River,
    Road,
    Bridge,
    BridgeWithRoad,
}

impl TryFrom<&str> for BorderType {
    type Error = &'static str;

    fn try_from(value: &str) -> Result<Self, Self::Error> {
        use BorderType::*;
        match value {
            "river" => Ok(River),
            "road" => Ok(Road),
            "bridge" => Ok(Bridge),
            "bridge_with_road" => Ok(BridgeWithRoad),
            _ => Err("Unknown BorderType"),
        }
    }
}

impl ToString for BorderType {
    fn to_string(&self) -> String {
        use BorderType::*;
        match self {
            River => "River".to_string(),
            Road => "Road".to_string(),
            Bridge => "Bridge".to_string(),
            BridgeWithRoad => "BridgeWithRoad".to_string(),
        }
    }
}

impl godot::ToVariant for BorderType {
    fn to_variant(&self) -> godot::Variant {
        use godot::{GodotString, Variant};
        Variant::from_godot_string(&GodotString::from_str(self.to_string()))
    }
}

/// A tile on the game board
#[derive(Debug, Copy, Clone, Deserialize)]
struct Tile {
    center: TileType,
    yz: Option<BorderType>,
    xz: Option<BorderType>,
    xy: Option<BorderType>,
    zy: Option<BorderType>,
    zx: Option<BorderType>,
    yx: Option<BorderType>,
}

impl Tile {
    fn new(center: TileType) -> Tile {
        Tile {
            center,
            yz: None,
            xz: None,
            xy: None,
            zy: None,
            zx: None,
            yx: None,
        }
    }
    fn bridge(self, d: hex2d::Direction) -> Tile {
        use hex2d::Direction::*;
        use BorderType::Bridge;
        match d {
            YZ => Tile {
                yz: Some(Bridge),
                ..self
            },
            XZ => Tile {
                xz: Some(Bridge),
                ..self
            },
            XY => Tile {
                xy: Some(Bridge),
                ..self
            },
            ZY => Tile {
                zy: Some(Bridge),
                ..self
            },
            ZX => Tile {
                zx: Some(Bridge),
                ..self
            },
            YX => Tile {
                yx: Some(Bridge),
                ..self
            },
        }
    }
    fn road(self, d: hex2d::Direction) -> Tile {
        use hex2d::Direction::*;
        use BorderType::Road;
        match d {
            YZ => Tile {
                yz: Some(Road),
                ..self
            },
            XZ => Tile {
                xz: Some(Road),
                ..self
            },
            XY => Tile {
                xy: Some(Road),
                ..self
            },
            ZY => Tile {
                zy: Some(Road),
                ..self
            },
            ZX => Tile {
                zx: Some(Road),
                ..self
            },
            YX => Tile {
                yx: Some(Road),
                ..self
            },
        }
    }
    fn river(self, d: hex2d::Direction) -> Tile {
        use hex2d::Direction::*;
        use BorderType::River;
        match d {
            YZ => Tile {
                yz: Some(River),
                ..self
            },
            XZ => Tile {
                xz: Some(River),
                ..self
            },
            XY => Tile {
                xy: Some(River),
                ..self
            },
            ZY => Tile {
                zy: Some(River),
                ..self
            },
            ZX => Tile {
                zx: Some(River),
                ..self
            },
            YX => Tile {
                yx: Some(River),
                ..self
            },
        }
    }
    fn bridge_with_road(self, d: hex2d::Direction) -> Tile {
        use hex2d::Direction::*;
        use BorderType::BridgeWithRoad;
        match d {
            YZ => Tile {
                yz: Some(BridgeWithRoad),
                ..self
            },
            XZ => Tile {
                xz: Some(BridgeWithRoad),
                ..self
            },
            XY => Tile {
                xy: Some(BridgeWithRoad),
                ..self
            },
            ZY => Tile {
                zy: Some(BridgeWithRoad),
                ..self
            },
            ZX => Tile {
                zx: Some(BridgeWithRoad),
                ..self
            },
            YX => Tile {
                yx: Some(BridgeWithRoad),
                ..self
            },
        }
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
mod test {}

/// Function that registers all exposed classes to Godot
fn init(handle: godot::init::InitHandle) {
    handle.add_class::<Board>();
}

// macros that create the entry-points of the dynamic library.
godot_gdnative_init!();
godot_nativescript_init!(init);
godot_gdnative_terminate!();
