# WARNING: THE PROJECT IS DISCONTINUED AND IS CURRENTLY BEING REVAMPED

The main reason for this is that I have gained more knowledge about Spine, and will use Spine in the next project. Meanwhile, official level schema has been discovered, and the new Arknights Clone will be supporting this format (and only this format). In addition, the new program will be targeting PC instead of mobile devices.

**The below documentation has been outdated.**

---

# Arknights Clone

![](https://github.com/Gennadiyev/Arknights-Remake/workflows/LOVE/badge.svg)

This program is a 2D Arknights emulator, in hope for simulating gameplay and creating customized levels, also used as a primary framework for reinforcement learning.

You need [LOVE2D](https://love2d.org/) to run this project, or you need to wait for a beta release. 

# Arknights Clone Documentation - Designing Levels

Before the visual level editor comes out, levels may only be edited in JSON format.

## Constants

### Map: Block ID

| Block ID | Name | Operators Available | Implemented |
| :-: | :-: | :---------: | :-: |
| 0 | Placeholder (Empty) | None | :accept: |
| 1 | Path | **Ground** | :accept: |
| 2 | Platform | **Elevated** | :accept: |
| 3 | Restricted Path | None | |
| 4 | Restricted Platform | None | |
| 5 | Ground (grass) | **Ground** | |
| 6 | Platform  (grass) | **Elevated** | |
| 10 | Enemy Base | None | :accept: |
| 11 | Base | None | :accept: |
| 20 | Uniform Platform | **Both** | :accept: |
| 30 | Originium Ground | **Ground** | |
| 31 | Air-assist Platform | **Elevated** | |

## Map Program Syntax

### Wait

Pause the program flow for a certain time or until the field is cleared.

- `wait [duration]`

  Pause the program flow and wait for a certain time.
  
  | Parameter  | Type     | Description |
  | ---------- | -------- | ----------- |
  | `duration` | `number` | The length of the pause, in seconds            |
  
- `wait clear`
  
  Pause the program flow until there is no enemy on the field.

### Summon

Summon an enemy and defines its actions.

The general syntax is as follows:

`summon [enemy_type] [enemy_level] from [from_row] [from_column] <program>`

Summon a specific enemy from the specified position.

  | Parameter     | Type     | Description                                        |
  | ------------- | -------- | -------------------------------------------------- |
  | `enemy_type`  | `string` | The type of the enemy (see `/enemies/index.json`)  |
  | `enemy_level` | `number` | The level of the enemy (see `/enemies/index.json`) |
  | `from_row`    | `number` | Defines which row the enemy should spawn             |
  | `from_column` | `number` | Defines which column the enemy should spawn          |
  | `program`     | -        | Defines the behavior of the specific enemy         |

For the `program`, we can specify the actions of the enemy, enabling level desingers to pause the enemy, let the enemy move, and even let the enemy suicide.

#### Program: Wait

Unlike the `wait` command in main program, here the `wait` for mobs **does not support `wait clear`**. This means that only absolute time delays are supported.

- `wait [duration]`
  
  Pauses the move of the enemy. Note that blocked enemies will still attack during the pause.
  
  | Parameter  | Type     | Description |
  | ---------- | -------- | ----------- |
  | `duration` | `number` | The length of the pause, in seconds            |

### Program: Move

- `to [row] [column]`

  Moves the enemy to the designated position. ~~The enemy will use $\text{A}^*$ algorithm to find the path towards (not yet implemented)~~ ==Currently the enemy will move straight towards the target anchor point (known bug: ignores unwalkable paths.==
  
  | Parameter | Type     | Description                                            |
  | --------- | -------- | ------------------------------------------------------ |
  | `row`     | `number` | Defines the row where the enemy should move towards    |
  | `column`  | `number` | Defines the column where the enemy should move towards |

### Program: Invade

- `invade`

  Immediately invades the player's base.

### Program: Suicide

- `suicide`

  Immediately kills the enemy.

### Examples

```!
summon originium_slug 1 from 3 1 wait 2 to 3 4 to 5 4 to 5 7 to 3 7 to 3 10 invade
```

### Storyboard

Not yet implemented, please wait.

## Effect Syntax

Effect is a buff given to the operator(s) before and during a battle. These two methods share the same syntax.

