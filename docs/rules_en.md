# War of the Dukes
### Story

For the past three hundred years, the Dukes of Orfburg and Wulfenburg have been engaged
in a border conflict over the town of Kaiserburg and the territory found
between the two branches of the river. Thirty years ago, after a lengthy
battle, the Duke of Wulfenburg retook Kaiserburg, but was unable to render
himself master of the "Two Rivers Territory".

After thirty years of armed peace, the Duke of Orfburg has declared war on his
old enemy. His goal: retake Kaiserburg, of course. It is this "War of the
Dukes" that you will reenact. This initiation game, kept voluntarily simple, is
designed to familiarise beginners with the basic principles of war games, as
well as give a decently realistic example of the "Napoleon" theme.

## Game Rules

### The game

For 2 players.  
Game materials:
 - a geographic map with hexagonal tiles,
 - pawns (to be cut out),
 - a combat result table and a terrain effect table printed directly on the map,
 - a dice will also need to be procured.

There are a total of 31 pawns per side (plus 1 turn counter), thusly: 1 Duke;
10 infantry units; 10 cavalry units; 10 artillery units.

These pawns have one of the following symbols (conforming to NATO's code):

[X] for infantry; [/] for cavalry; [·] for artillery;

and a crown for the Duke. They also display:
 - the beginning of their country's name: "ORF" (for Orfburg) and WULF (for
   Wulfentburg),
 - on the left, a number representing the offensive and defensive power,
 - on the right, a number representing the mobility potential (movement
   points),
 - solely for artillery, in the upper left, the number 2 is a reminder of the
   canons' 2 tile range

#### Game Objective

Decisively conquer territory or annihilate the Duke or the enemy forces. As we
shall see, a particular feature of the War of the Dukes is that the players'
situations are not symmetrical: they do not exactly share the same winning conditions.

#### Setting up the Pawns

Each player places one of their units on each city or fortress tile they own.
Next, they take turns placing their remaining units on tiles they possess until
all have been placed.  
The player owning Orfburg always plays first.

#### Game Length

The game lasts up to 15 turns, which are kept track of by moving the turn
tracker pawn forwards 1 square at the end of each turn.  
Each turn is further divided into 2 phases, each corresponding to the different
actions of 1 of the 2 players. Once both adversaries have played, the current
turn is over, and the next turn begins.

#### The Dukes

The 2 pawns representing the Dukes only have defensive power: they cannot
attack directly. However, their presence "inspires" their troupes within 2
tiles, doubling their offensive or defensive potential.  
The Dukes are affected by combat results just like any other pawn. In
particular, a Duke can be eliminated during the course of a battle. In that
case, the game immediately ends and the player they belong to loses, even if
the other victory conditions are not satisfied.


#### Fortresses

Fortresses may not contain more than one unit (eventually plus 1 Duke, who
doesn't count as a unit). Without a garrison, they are defenseless and may be
occupied by pawns from either side. Artillery units may fire from within a
fortress.

#### Victory Conditions

The two belligerents do not have the same conditions for victory.

#### Marginal Victory

The Duchy of Orfburg wins by seizing the city of Kaiserburg, all while
maintaining control of the territory between the two rivers. The Duchy of
Wulfenburg wins by preventing at least 1 of those 2 conditions.

##### Total Victory

Total victory is given to the country that conquers the opposing capital or
eliminates the enemy Duke.

#### Movement

During their active phase, each player may move as many units as they desire
to, within the limits of each unit's movement points. Here is the number of
points needed to move one tile, depending on the nature of the terrain:

terrain        | movement points per tile
---------------|-------------------------
roads          | 0.5
cities         | 0.5
normal         | 1
bridges        | 1 (0.5 if a road crosses the bridge)
woods          | 2
cliffs (brown) | 2
rivers         | Impassable other than via bridges
lakes          | Impassable


Note: if a unit wishing to traverse a road during their movement is not already
on that road, it must first spend the necessary movement points to reach the
road by crossing the terrain that separates it from the road.

#### Movement Restrictions

A unit may never occupy the same tile as another unit, allied or enemy.
However, units may move through other allied units with no penalty.  
Special case: the Duke, which may be placed on another allied unit.

#### Zone of Control

Each unit exerts a particular influence on the 6 tiles adjacent to it: theses
tiles constitute its "Zone of Control". These Zones of Control have the
following properties:

 - a unit may enter an enemy Zone of Control for no additional movement cost,
   but may not move within in; the unit must thus end its movement upon
   entering the Zone,
 - a unit may also thus only enter a new ZoC after exiting any ZoC it might currently be in,
 - ZoC do not extend over rivers, but they do cross bridges,
 - units are forbidden from retreating into an enemy ZoC.

Example:

![](./example_0.png)

Unit C, being in unit A's Zone of Control, may not cross through the tile
labelled `X1` to reach the one labelled `X2`. Instead, it must first exit and
then go around `X1` to finally enter `X2`. It thus spends a total of 4 movement
points to get to `X2` (and not 2!).


#### Combat

To do battle, the attacking unit must be in range of the defending unit:
adjacent tiles for infantry and cavalry, 1 tile further for artillery. Multiple
friendly units can attack the same enemy target, as long as they are each
individually in range.  
Once combat has been declared, sum up the attackers' offensive power, as well
as the defenders' defensive power (which is doubled in cities and tripled in
fortresses). The attacking player rolls a die, and applies any eventual
modifier due to the terrain. This result is compared to the ratio of the
attacker's power vs the defender's power, which can go from 1/5 (or "1 to 5")
to 6/1 (or "6 to 1"), on the combat result table.  
These results are noted as a pair of letters, whose meaning is the following:

AE (Attacker Eliminated): the attacking units are removed from play
AR (Attacker Retreats): the attacking units must move back 1 tile
DE (Defender Eliminated): the defending units are removed from play
DR (Defender Retreats): the defending units must move back 1 tile
EX (EXchange): the defending units are removed from play, as well as attacking
units with a total strength at least equal to the defenders'.

A unit that can not retreat (because a river, lake, or ZoC is behind it) is
removed from play, unless it is surrounded by friendly units: in this case it
pushes one of these out of the way and takes its place.  
Additionally, these 3 rules are to be taken into account during combat:

 - a given unit may not be attacked more than once (1 time) during a single phase,
 - a given unit (or group of units) may only attack a single enemy unit during the same phase,
 - multiple allied units may band together to attack an adversary unit, but
   this action only counts as a single combat, with a sole die role.

Combat results take effect immediately, before the next phase begins.

##### Special case: Artillery

An artillery unit may do battle either from a distance of 2 tiles (a
bombardment) or from an adjacent tile (close combat). During a bombardment, it
is not affected by the retreat or exchange results. During close combat,
however, it behaves like any other unit.
