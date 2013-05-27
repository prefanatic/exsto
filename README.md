## Exsto

Exsto is an administration framework Garry's Mod, with prime focus on a modular design.

There are two branches, choose wisely.  This branch (master) aims to be the most stable branch.  No new features are added, just fixed.  Developmental is the new feature branch.

As of writing (4/22), developmental is most likely the most stable.  Master has become 4 months out of date.

----

### Setup

Install the addon in ````/addons```` as usual. Next, open the server console and type ````exsto rank [yourname] srv_owner```` to become a server owner.

### Essential Commands

* 'ExQuickToggle' - Opens the menu in a toggle based format.
* '+ExQuick' - Opens the menu in a hold based format.
* 'exsto commands OR !commands' - Lists all the other stuff you'll probably use at some point.

### Things to keep in mind

The point is to keep Exsto modular.  Because of this, you might accidently screw with the ranks/settings in such a way where things "seem" to break.  They actually don't, you just need to re-fix what you broke.  The most common "I can't access the menu!" mistake is when people remove their menu page access in the rank editor.  It's pretty obvious which of these flags are menu related; hover over them, they tell you.

### I don't want feature 'x'

Then remove it.  You have a plugin list, settings page, right-click delete functionality in Windows; you can pretty much remove everything but the administration plugin if you want.  Exsto ships with a generic set of plugins I personally thought should come default.  These can easily be removed in game or out of the game.

### MySQL

You DO NOT NEED MySQL in order to use Exsto.  It is completely optional.  I had so many people three years ago thinking it was required.  If you want to use MySQL for external access, server data sharing, or other reasons, install the mysqloo module.  Otherwise, you should have no reason to use it - its optional.  Exsto has support for it, doesn't mean you should use it.

### Feature 'x' isn't working / I want feature 'x'

Github issues page please.  Let me know here, not through steam or email.  A big problem with Exsto 2010 was that I never received bug reports, other than people on steam saying 'This isn't working!'.  So please, if you want something fixed, make an issue for it.  I'd like to fix it as well.

### Donations

Me and Revanne are poor (or at least I am).  We both work on Exsto in our spare time, day and night, through hell and high water.  We both are University students, so it would be nice to get some cash to help pay for it.  If you have a little spark in your heart, feel free to donate to:
dumbplanet424@gmail.com

And you'll get our personal thanks :)
