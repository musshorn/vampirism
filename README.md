# Vampirism
Vampirism is a mod for Dota 2 based on the 'Vampirism Fire' map for Warcraft III. Human players gather resources and defend themselves agains powerful vampires who are seeking to convert all humans into vampires.

Please bear in mind that the mod is currently in **beta** and that there are likely bugs which may prevent you from completing a full game.

If you experience any bugs, feel free to submit an issue if it is not currently tracked, but please include as much detail and a reproduction of your bug in order to assure that it can be identified and fixed.

## Differences

There are many differences from the original map, players of the original map would be advised to familiarize themselves with them before jumping into a game.

- Workers

Workers behave somewhat differently in this mod. The reason for this is that having too many moving units uses a lot of bandwidth, this is most noticable at the start of the game,
when a few hundered tier 1 workers are active. To assure a good experience for the majority of players, workers can be "stacked", which means that one phyiscal worker can represent
any number of workers. By default, tier 1 workers are stacked four times, tier 2 workers are stacked twice, and each worker from then on is not stacked. The host may specify how much
worker stacking they wish to use, with 1 being no stacking and 4 being the default. (Giving stacking of 4, 2, 1, 1, 1). It is possible that no stacking may be possible on a LAN,
but this has not been tested.

- Slayers

Slayers are not a 'hero' by default, and as such will not be hotkeyed by default.

- Cancelling upgrades

Buildings do not have a cancel ability, however they may be cancelled during any upgrade by issuing a 'Stop' command to break the channeling upgrade. ('S' is the default hotkey for this).

## Credits

[BMD](https://github.com/bmddota) : Being the Based Modding Dude, [Barebones](https://github.com/bmddota/barebones), [PlayerSay](https://github.com/bmddota/PlayerSay) and answering so many questions on IRC.

[Myll](https://github.com/Myll) : The [BuildingHelper](https://github.com/Myll/Dota-2-Building-Helper) library.

[Pizzalol](https://github.com/Pizzalol), [Noya](https://github.com/MNoya), [kritth](https://github.com/kritth), [Rook](https://github.com/Rookdota) : And everyone else who worked on [SpellLibrary](https://github.com/Pizzalol/SpellLibrary).

[carligit](https://github.com/carligit) : For much of the original flash that buildUI is based on.

[zedor](https://github.com/zedor) : [CustomError](https://github.com/zedor/CustomError)

[snippet](https://github.com/snipplets) : Dodgy maths, git conflicts and shipping content.