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

## Victory Condition Detection / Game Resolution
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
1. simplified game logic, as we only need to introspect the entire game state for victory conditions once.
2. prevents "cheese" strategies that could cheapen the feeling of victory or defeat; for example, a concerted push on an early turn could immediately give a minor victory to one faction, while their opponent could successfully contest the objective(s) in play in the following turns.
3. increases value of longer-turn strategy over all 15 turns?
4. increases chances of interesting turn-by-turn decisions for players emerging from gameplay?
