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

#[cfg(test)]
mod test {

    use crate::unit::{Defense, Strength, Unit};

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
