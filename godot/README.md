# Game Design choices taken regarding the source document/rules

The original rules had an additional constraint for their wording given the nature of the source document; all of the rules (apperently) needed to fit on a magazine "centerpiece" (i.e. a pair of consecutive pages that the magazine can be laid open to display both of them simultaneously). In any case, the wording is sometimes vague, and this project's author has not been able to find any clarifications in either the rest of the magazine or following issues.

Thus, additional decisions regarding game play and rules specifics were made. They are recorded as follows.

## Phase and Turn Succession (Move/Move/Fight/Fight vs Move/Fight/Move/Fight)
### Problem statement
The document is unclear on whether players take turns:
1. moving their units *and* declaring and resolving combats, or
2. moving their units, *and then* declaring and resolving combats.

More concretely: after the Orfburg player has finished their movement phase, does play proceed to the Orfburg player's combat phase, or does play proceed to the Wulfenberg player's movement phase (the Orfburg player always going first)?
### Choice made: Move/Fight/Move/Fight
The Orfburg player, once declaring their Movement Phase finished, directly proceeds to their Combat Phase. After they similarly declare that Combat Phase to be finished, play proceeds to the Wulfenberg player's Movement Phase.

## Victory Condition Detection / Game Resolution (Early Win?)
### Problem statement
The document is unclear on *when* to inspect the game state to declare the overall game result:
1. as soon as it "could be" determined,
2. after each full turn,
3. somewhere in-between the 2 preceding,
4. only after the max amount (15) of turns has passed (unless a duke just died, of course)

More concretely: the Orfburg player currently has units on every tile of the "city minor objective" (Kaiserburg). No player has units on the other minor objective (the "between rivers" parcel of Orfburg territory). The player proceeds to move a unit into the "between rivers" territory. Does the game end immediately as a Orfburg minor victory, does it end as such after the Wulfenberg player has played their 2 phases, or does the Orfburg only need to be controlling the minor territories at the end of turn 15?
### Choice made: Play as long as possible
Play continues until the end of turn 15, upon which the victory conditions are evaluated and minor/major victory attributed to a faction. The only exception is the death of a Duke, which immediately ends the game in a major victory for the opposing faction.

This presents several benefits:
- simplified game logic, as we only need to introspect the entire game state for victory conditions once.
- prevents "cheese" strategies that could cheapen the feeling of victory or defeat; for example, a concerted push on an early turn could immediately give a minor victory to one faction, while their opponent could successfully contest the objective(s) in play in the following turns.
- increases value of longer-turn strategy over all 15 turns?
- increases chances of interesting turn-by-turn decisions for players emerging from gameplay?


## Combat Specifics
### Defenders (Can Stacked Dukes Be Targeted?)
#### Problem statement
The document is unclear on how to handle combat when the defender is 1 of 2 units stacked on the same tile. Given that this is only possible when 1 of the 2 is a Duke, and that a duke's death is immediate game over and defeat for its player, it is important to be clear about this.
#### Choice Made: Only lone Dukes can be targeted
A Duke can only be chosen as defender for a combat when it is the sole occupant of its tile on the board. Furthermore, when the unit stacked with a Duke is forced to retreat, the Duke retreats with them.

This gives us extra simplicity of choice for the attacking/current turn's player, encourages players to use their Dukes more aggressively in "urban combat", and can be justified by the duke "remaining in the center of its tile" during combat, as it does not attack; an opponent must eliminate their "guard" first, and they also provide enough cover while retreating for the Duke to keep pace.


### Retreat
#### Directions Allowed (What Is Backwards?)
##### Problem statement
The document is unclear on whether moving "backwards" means in the context of a retreat:
1. remaining in the existing attacker/defender axis, effectively moving "straight" backwards,
2. moving to any tile that increases the attacker/defender distance by 1, effectively moving either "straight" backwards or "diagonally".

More concretely, consider an adjacent attacker/defender pair (respectively `A` and `C` in the following figure:

![A small portion of a hexagonal grid. On it are 2 units, named "A" and "C", which are adjacent to each other. A is directly "above" C. Each of the 6 tiles directly adjacent to A are tinted pink.](./docs/example_0.png)

To retreat, the attacker could either choose from any of the top three pink tiles, or be forced to choose the tile above it.
##### Choice made: Backwards is Straight
The retreating player can choose from any adjacent tile that allows it to legally retreat. In practice this will be from amongst at most the 3 tiles "opposite" from its opponent(s).

#### Pushing Allies (Chain vs Single)
##### Problem statement
The document is unclear on how many allied units can be "pushed" out of the way for a retreating unit. Two obvious choices:
1. only 1 unit can move out of the way,
2. an unlimited amount of units can move out of the way (if the last in the "retreat chain" has at least 1 empty tile to move into beforehand).

More concretely: a unit is adjacent to an enemy unit, and is surrounded on the other neighbouring tiles by allied units. Some of these allied units are *also* effectively surrounded by allied units (effectively in the sense that at least one neighbouring, otherwise accessible tile is currently occupied by an allied unit). The first unit in question attacks the enemy unit, on its own, which resolves to an `AttackersRetreat` result. Can another allied unit move out of the way of one of the allied units adjacent to the first, or does a *different* adjacent unit [that *can* move to a different tile] need to move out of the way?

The logic for the 2 could be combined to further generalize to an arbitrary limit - finite or not. However, it does not appear obvious to this project's author that such a design decision would intrinsicly make the game more fun than choosing either of the previous choices.
##### Choice made: Single
Only 1 "additional" unit can "participate" in a retreat for a given combat.

Rationale: simplicity in game logic and gameplay. This also makes "lines" of units "deeper" than 2 more risky, rewards flanking more, and makes massed combat more deadly in general, as melee combattants are much more likely to be unable to to retreat from a lost combat.

#### Post-Retreat Pursuit (Who Can?)
##### Problem statement
The document states that "in the case of a combat resulting in the defender retreating, the attacking unit can pursue them and occupy the newly vacated tile." It does not clarify how to proceed when a combat has multiple attackers, nor does it imply that Artillery bombarding from a distance cannot pursue - or only "pursue" over a distance of 1 tile.

#### Choice made: Only Melee
When the defender retreats, the attacking player may choose up to 1 Cavalry or Infantry unit among the attackers to pursue it.

This neatly resolves the problem, and best preserves the medieval-europe-wargame "flavor" of the game:
 - to attack in real life, the cavalry and infantry of the time needed to get within close physical proximity. they would thus be almost in the defender's position. a "pursuit" would realistically take place over a much smaller distance than what an entire tile's breadth represents.
 - a retreating unit's allies would need to make way and/or be careful of them. they would thus be hard-pressed to exercise their zone of control, potentially even blocked from doing so by their retreating ally. the pursuing unit would realistically have an easier time advancing to the same position than otherwise.
 - attacking artillery would remain stationary. thus even against the equivalent of an "adjacent" unit, they would not be close enough to pursue their retreating opponents "in the moment".
 - pursuit over/across rivers makes no sense.
 - the game's rules only allow stacking units on the same tile in specific cases; the most relevant being that 1 of the 2 stacked units will always be a Duke. Several attackers occupying the same vacated tile is thus guaranteed to be forbidden in most multiple-attacker combats. In the remaining cases where it _would_ be allowed (a Duke is already stacked with one of the attackers), we can justify maintaining the ban as a non-fighter Duke, as the game's rules and stats imply, would not realistically pursue a retreating enemy "in the heat of the moment" on the battlefield.

### Exchange
#### Loss Allocation (Random vs Player Choice)
##### Problem statement
The document is unclear on whether loss allocation amongst the attackers of an exchange is up to any player's choice. The choices are:
- the attacking player allocates them
- the defending player allocates them
- the losses amongst the attackers are allocated at random (amongst melee attackers, of course)
##### Choice made: Attacking Player Allocates
The attacker selects attacking units until their combined offensive strength equals that of the [killed] defender's defensive strength.

#### Which Strength (Effective vs Base)
##### Problem statement
The document is unclear on whether loss allocation during an exchange is based off of the base attack strength of each attacker, or their effective strength given the current position of all units on the board.

More concretely: are terrain- and duke-aura-based strength multipliers applied when referencing "how much" attacker strength needs to be allocated as a loss for an Exchange combat result?
##### Choice made: Effective
Total attack strength includes duke aura effects, and defender's defensive strength is affected by terrain and duke aura multipliers. This increases the risk towards attackers when attacking "garisonned" units (and reduces risk for those defenders), and increases the impact of duke's auras.
