# README for FreecoiL

## [Download Links - Get the Game](https://gitlab.com/FeralBytes/FreecoiL/snippets/1781429)

## Please See [Our Current Milestone Here](https://gitlab.com/FeralBytes/FreecoiL/-/milestones/2).
[For the most up to date development information contact the lead developer on Discord.](https://discordapp.com/invite/tn4hThV).

### [Our Documentation](https://freecoil.readthedocs.io/en/latest/) is on ReadTheDocs.

### What is FreecoiL?   [![pipeline status](https://gitlab.com/FeralBytes/FreecoiL/badges/develop/pipeline.svg)](https://gitlab.com/FeralBytes/FreecoiL/-/commits/develop) [![Documentation Status](https://readthedocs.org/projects/freecoil/badge/?version=develop)](https://freecoil.readthedocs.io/en/develop/)
FreecoiL is a laser tag application for the RECOIL[2] system for Android[6]. The focus is to add more features to the game environment, offer more flexibility and customization to players, and increase replay-ability. 

## Features:

* No Network: Independent game play. Just like SIMPLECOIL[3].
* Partial Networking: Ability for players to drop out of the network but still play, then receive updates when back in range. 
  * Play does not stop just because you left the Wi-Fi coverage area. [5]
* Network Enabled: Support of Scoreboard and Achievements.
  * Support for development of enhanced game modes.
* Dedicated Host Flexibility: Server OS options: Android, Linux, & Windows.[7]
  * Host pushes settings to other players, but can enable some settings to be set by the players.
* Multiple Game Modes
  * Free For All: supporting up to 63 Players. [4]
  * Team Modes: supporting 2 teams or up to 31 teams with a maximum of 62 players and the teams must be equal in size. [4]
  <del>* Weapon Profiles: for handgun, shotgun, rifle, and machine gun. [8]</del>
  * Ammunition 1-253 rounds per reload.   
* More Features are planned.

### How to Get FreecoiL:

[Signup for further updates by providing your email here](https://docs.google.com/forms/d/e/1FAIpQLSd-ZglY7iiT7ToqPvR-o6Bv0AsBIz9rJWOAWz83Mygj_GL-Yw/viewform).
Once Ready you will be able to Download from GOOGLE PLAY STORE[1], coming soon! Expected Price $0.00. The project is now open source and we will accept donations to help pay for the PLAY STORE and iTunes submissions.

### How to Donate:

* Donate to [FeralBytes the Creators of FreecoiL here](https://www.paypal.me/FeralBytes).

## How to Get Involved

[Contact the Lead Developer on Discord.](https://discordapp.com/invite/tn4hThV).
```eval_rst
.. mermaid::

  graph TD;
      A(You)--First Time Involved-->B[<a href='https://gitlab.com/users/sign_in#register-pane'>Create Account on GitLab</a>];
      B-->C[<a href='https://gitlab.com/FeralBytes/FreecoiL/'>Clone & Branch FreecoiL<a/>];
      C-->D[<a href='https://gitlab.com/FeralBytes/FreecoiL/merge_requests/new'>Make Changes & Submit a Merge Request</a>];
      D-->E{I Review Your MR};
      E-->F[Looks Good!]
      E-->I[Needs Changes]
      F-->G[Your Changes are Merged]
      G-->H[Play the Game with Your Changes]
      I--Returns to You-->A
      A--After Changes-->D
```

### The Release Plan So Far: If we are able to speed up the timeline below, we will.

```eval_rst
.. note:: All dates are in ISO Standard Format: YYYY-MM-DD
```
* <del>Version 0.1.0 on 2018-10-23</del>
* <del>Version 0.2.0 on 2018-11-25</del>
* Version 0.3.0 In Development.

### Why FreecoiL?

FreecoiL was created because we wanted more features and flexibility than what was offered by the RECOIL[2] app. When we found SIMPLECOIL[3], it inspired us to begin coding our desired features. We wanted more than those offered by either RECOIL[2] or SIMPLECOIL[3].

## Frequently Asked Questions:

* Does this really work or are you creating a hoax? 
* * Actually our app already works, it has worked for months now, but we are improving and adding features. It communicates with the guns and already supports team and individual play.

### Notes:

1. GOOGLE PLAY and the Google Play logo are trademarks of Google LLC.
2. RECOIL are trademarks of SkyRocket LLC.
3. SIMPLECOIL is copyright of Dees-Troy.
4. This feature has not been tested completely, but the software and hardware can, in theory and as programmed, support the capability. If you test this feature to its maximum extent, please let us know if it worked as promised. If it did not, please inform us of limitations or bugs encountered.
5. Some game modes may require all players to stay on the network at all times. But it is our goal to not have this be the case. Currently, all of our game modes support network drop-out with little affect to game play. However, it is important to realize that, due to the way the guns work, if a player is killed outside the network, determining who killed him will not be updated until the killed player returns to the network.
6. Our work is portable to iOS / iPhone, but at this time we have not begun development for iOS. The GUI is already compatible with iOS though. The back-end needs to be written in swift or Objective-C.
7. OSX will likely be supported but has not been tested. The GUI is technically compatible with OSX already.
8. Weapon Profiles do not affect range, only the way in which the weapon fires and reloads. There may be a few ways to figure out range, but no time has been dedicated to this yet.
9. Dees-Troy's research was critical to enabling us to make our application. 
