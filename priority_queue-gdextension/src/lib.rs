use godot::prelude::*;
use std::cmp::Ordering;
use std::collections::BinaryHeap;

struct ExtensionHandle;

#[gdextension]
unsafe impl ExtensionLibrary for ExtensionHandle {}

#[derive(Debug)]
struct HeapItem {
    tile: Vector2i,
    priority: f32,
    cost_to_reach: f32,
    is_in_enemy_zoc: bool,
}
impl PartialEq for HeapItem {
    fn eq(&self, other: &Self) -> bool {
        self.tile == other.tile
    }
}
impl Eq for HeapItem {}
impl PartialOrd for HeapItem {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
impl Ord for HeapItem {
    fn cmp(&self, other: &Self) -> Ordering {
        self.priority.total_cmp(&other.priority)
    }
}

#[derive(GodotClass)]
#[class(base=RefCounted)]
struct PriorityQueueGDExt {
    heap: BinaryHeap<HeapItem>,
}

#[godot_api]
impl IRefCounted for PriorityQueueGDExt {
    fn init(_: Base<RefCounted>) -> Self {
        Self {
            heap: BinaryHeap::new(),
        }
    }
}

#[godot_api]
impl PriorityQueueGDExt {
    #[func]
    pub fn insert(&mut self, item: Dictionary) {
        let tile = item.get("tile").unwrap().to();
        let priority = item.get("priority").unwrap().to();
        let cost_to_reach = item.get("cost_to_reach").unwrap().to();
        let is_in_enemy_zoc = item.get("is_in_enemy_zoc").unwrap().to();
        self.heap.push(HeapItem {
            tile,
            priority,
            cost_to_reach,
            is_in_enemy_zoc,
        });
        // dbg!(&self.heap);
    }
    #[func]
    pub fn insert_as_multiple(
        &mut self,
        tile: Vector2i,
        priority: f32,
        cost_to_reach: f32,
        is_in_enemy_zoc: bool,
    ) {
        self.heap.push(HeapItem {
            tile,            //: tile.to(),
            priority,        //: priority.to(),
            cost_to_reach,   //: cost_to_reach.to(),
            is_in_enemy_zoc, //: is_in_enemy_zoc.to(),
        })
    }

    #[func]
    pub fn len(&self) -> u8 {
        self.heap.len() as u8
    }
    #[func]
    pub fn pop(&mut self) -> Dictionary {
        let item = self.heap.pop().unwrap();
        let mut result = Dictionary::new();
        result.set("tile", item.tile);
        result.set("priority", item.priority);
        result.set("cost_to_reach", item.cost_to_reach);
        result.set("is_in_enemy_zoc", item.is_in_enemy_zoc);
        result
    }
}
