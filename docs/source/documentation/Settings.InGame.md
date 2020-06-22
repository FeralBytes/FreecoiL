# Settings.InGame

InGame Settings are saved to disk and they are passed over the network.

## game_weapon_types

Defines the weapons that are allowed in the game. 

### Game Weapons

Am example weapon the P1S is defined below in code. It is important to note that all of the weapons are virtual and are not tied to the physical model of the weapon you are utilizing in game.

```
{"P1S": {"magazine_size": 10, "damage": 1, 
        "shot_modes": ["single"], "reload_speed": 3, "rate_of_fire": 0.3}, "P2B": {"magazine_size": 10, "damage": 1, 
        "shot_modes": ["burst"], "reload_speed": 3, "rate_of_fire": 0.3}, "P3A": {"magazine_size": 10, "damage": 1, 
        "shot_modes": ["auto"], "reload_speed": 3, "rate_of_fire": 0.3}}
```

The "P" stands for pistol. The "1" simply designates the approximate level of the gun, as it increases as the weapon gains features. The "S" stand for single shot per pull of the trigger weapon. A "B" stands for burst, specifically a 3 round burst or 3 shots per pull of the trigger. And an "A" stands for automatic or a single pull of the trigger can empty and entire magazine of the weapon if you hold the trigger long enough.

Note: rate_of_fire is not yet fully implemented.