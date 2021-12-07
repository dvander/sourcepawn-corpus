/*/////////////////////////////////////////////////////////////////////////////////////////
		История версий ML Glow:
///////////////////////////////////////////////////////////////////////////////////////////
1.0 - 07/25/09 (3 views)
-Release
1.1 - 07/25/09 (14 views)
-Add D1 theme, activated cvar ml_glow 2
1.2 - 07/30/09 (12 views)
-Cvar is 0 it changes everything back to normal
-Optimization code
1.3 - 07/30/09 (15 views)
-[URL="http://forums.alliedmods.net/member.php?u=38335"]Dragonshadow[/URL] сhanges:
-Hooked glow cvar to glowhook so it isn't calling GetConvarInt every time the timer runs (optimization)
-Uses switches instead of constant if statements (optimization)
-Changed OnClientPutInServer to OnClientPostAdminCheck (they should be ingame at this point so nothing can screw up)
-If ml_glow = 0 when a client joins it doesn't start the timers on them.
-If client isn't connected and ingame the timers stop.
-If the convar is changed to default (0) it sets the cvars back to default and then kills the timer so it isn't running just running (optimization)
-When the cvar is changed to something other than 0 the timers will start again.
-Added min & max values for ml_glow
-Added version cvar "ml_version" for use as public cvar
-Added description
-Tweaked cvar description
1.4 - 07/31/09 (52 views)
-Deleted clones ClientCommand from second stage Glow (optimization)
-glowhook default is 1. I think a better way
1.5 - 08/01/09
-Added config with choice glows to your taste (thx Dragonshadow) 
-Changed cvar ml_glow to ml_glow_mode
-Custom colors are changing only when ml_glow_mode 3
-Colors are changing, even if the client is set to color blind (optional)
-Added new color choices: 
-Color of ability glow
-Color the PZs see the IT victim glow
-Color the Infected see Survivors when their health is high, medium and low
-Glow of items in "black and white" mode
-Controls the size of the halo shown around players and usable items 
-Brightness of player halos
-Forces glows on\off
-Is Survivor glow seen by infected based on noise? On/Off
-Time out of sight before a survivor friend shows up through a wall to a survivor. (cl_glow_los_delay)
-Time after cl_glow_los_delay before a survivor friend shows up fully through wall.
-Time after cl_glow_los_delay before a survivor friend goes away*/


	 
#pragma semicolon 1
#define PLUGIN_VERSION "1.5"
#undef REQUIRE_PLUGIN

new Handle:MLGlow=INVALID_HANDLE;
new Handle:IgnoringColorblindSet=INVALID_HANDLE;
new glowhook = 1;

new Handle: GlowItemFarRed1=INVALID_HANDLE;
new Handle: GlowItemFarGreen1=INVALID_HANDLE;
new Handle: GlowItemFarBlue1=INVALID_HANDLE;
new Handle: GlowItemFarRed2=INVALID_HANDLE;
new Handle: GlowItemFarGreen2=INVALID_HANDLE;
new Handle: GlowItemFarBlue2=INVALID_HANDLE;
	
new Handle: GlowGhostInfectedRed1=INVALID_HANDLE;
new Handle: GlowGhostInfectedGreen1=INVALID_HANDLE;
new Handle: GlowGhostInfectedBlue1=INVALID_HANDLE;
new Handle: GlowGhostInfectedRed2=INVALID_HANDLE;
new Handle: GlowGhostInfectedGreen2=INVALID_HANDLE;
new Handle: GlowGhostInfectedBlue2=INVALID_HANDLE;
	
new Handle: GlowItemRed1=INVALID_HANDLE;
new Handle: GlowItemGreen1=INVALID_HANDLE;
new Handle: GlowItemBlue1=INVALID_HANDLE;
new Handle: GlowItemRed2=INVALID_HANDLE;
new Handle: GlowItemGreen2=INVALID_HANDLE;
new Handle: GlowItemBlue2=INVALID_HANDLE;
	
new Handle: GlowSurvivorHurtRed1=INVALID_HANDLE;
new Handle: GlowSurvivorHurtGreen1=INVALID_HANDLE;
new Handle: GlowSurvivorHurtBlue1=INVALID_HANDLE;
new Handle: GlowSurvivorHurtRed2=INVALID_HANDLE;
new Handle: GlowSurvivorHurtGreen2=INVALID_HANDLE;
new Handle: GlowSurvivorHurtBlue2=INVALID_HANDLE;
	
new Handle: GlowSurvivorVomitRed1=INVALID_HANDLE;
new Handle: GlowSurvivorVomitGreen1=INVALID_HANDLE;
new Handle: GlowSurvivorVomitBlue1=INVALID_HANDLE;
new Handle: GlowSurvivorVomitRed2=INVALID_HANDLE;
new Handle: GlowSurvivorVomitGreen2=INVALID_HANDLE;
new Handle: GlowSurvivorVomitBlue2=INVALID_HANDLE;
		
new Handle: GlowInfectedRed1=INVALID_HANDLE;
new Handle: GlowInfectedGreen1=INVALID_HANDLE;
new Handle: GlowInfectedBlue1=INVALID_HANDLE;
new Handle: GlowInfectedRed2=INVALID_HANDLE;
new Handle: GlowInfectedGreen2=INVALID_HANDLE;
new Handle: GlowInfectedBlue2=INVALID_HANDLE;
	
new Handle: GlowSurvivorRed1=INVALID_HANDLE;
new Handle: GlowSurvivorGreen1=INVALID_HANDLE;
new Handle: GlowSurvivorBlue1=INVALID_HANDLE;
new Handle: GlowSurvivorRed2=INVALID_HANDLE;
new Handle: GlowSurvivorGreen2=INVALID_HANDLE;
new Handle: GlowSurvivorBlue2=INVALID_HANDLE;

				///IN VERSION 1.5///
				
new Handle: GlowAbilityBlue1=INVALID_HANDLE;
new Handle: GlowAbilityGreen1=INVALID_HANDLE;
new Handle: GlowAbilityRed1=INVALID_HANDLE;
new Handle: GlowAbilityBlue2=INVALID_HANDLE;
new Handle: GlowAbilityGreen2=INVALID_HANDLE;
new Handle: GlowAbilityRed2=INVALID_HANDLE;
				
new Handle: GlowInfectedVomitBlue1=INVALID_HANDLE;
new Handle: GlowInfectedVomitGreen1=INVALID_HANDLE;
new Handle: GlowInfectedVomitRed1=INVALID_HANDLE;
new Handle: GlowInfectedVomitBlue2=INVALID_HANDLE;
new Handle: GlowInfectedVomitGreen2=INVALID_HANDLE;
new Handle: GlowInfectedVomitRed2=INVALID_HANDLE;
				
new Handle: GlowSurvivorHealthHighBlue1=INVALID_HANDLE;
new Handle: GlowSurvivorHealthHighGreen1=INVALID_HANDLE;
new Handle: GlowSurvivorHealthHighRed1=INVALID_HANDLE;
new Handle: GlowSurvivorHealthHighBlue2=INVALID_HANDLE;
new Handle: GlowSurvivorHealthHighGreen2=INVALID_HANDLE;
new Handle: GlowSurvivorHealthHighRed2=INVALID_HANDLE;

new Handle: GlowSurvivorHealthMedBlue1=INVALID_HANDLE;
new Handle: GlowSurvivorHealthMedGreen1=INVALID_HANDLE;
new Handle: GlowSurvivorHealthMedRed1=INVALID_HANDLE;
new Handle: GlowSurvivorHealthMedBlue2=INVALID_HANDLE;
new Handle: GlowSurvivorHealthMedGreen2=INVALID_HANDLE;
new Handle: GlowSurvivorHealthMedRed2=INVALID_HANDLE;

new Handle: GlowSurvivorHealthLowBlue1=INVALID_HANDLE;
new Handle: GlowSurvivorHealthLowGreen1=INVALID_HANDLE;
new Handle: GlowSurvivorHealthLowRed1=INVALID_HANDLE;
new Handle: GlowSurvivorHealthLowBlue2=INVALID_HANDLE;
new Handle: GlowSurvivorHealthLowGreen2=INVALID_HANDLE;
new Handle: GlowSurvivorHealthLowRed2=INVALID_HANDLE;

new Handle: GlowThirdstrikeItemBlue1=INVALID_HANDLE;
new Handle: GlowThirdstrikeItemGreen1=INVALID_HANDLE;
new Handle: GlowThirdstrikeItemRed1=INVALID_HANDLE;
new Handle: GlowThirdstrikeItemBlue2=INVALID_HANDLE;
new Handle: GlowThirdstrikeItemGreen2=INVALID_HANDLE;
new Handle: GlowThirdstrikeItemRed2=INVALID_HANDLE;

/*new Handle: BlurScale=INVALID_HANDLE;
new Handle: Brightness=INVALID_HANDLE;
new Handle: Force=INVALID_HANDLE;
new Handle: LosDelay=INVALID_HANDLE;
new Handle: LosFadeInTime=INVALID_HANDLE;
new Handle: LosFadeOutTime=INVALID_HANDLE;
new Handle: Noise=INVALID_HANDLE;*/

	public Plugin:myinfo = 
	{
		name = "[L4D] Must Live Glow",
		author = "Pontifex",
		description = "Changes glow colors on items to that of the l4d community autoexec",
		version = PLUGIN_VERSION,
		url = "http://must-live.ru"
	}

	public OnPluginStart()
	{

		CreateConVar("ml_version", PLUGIN_VERSION, "[L4D] Must Live Glow Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
		MLGlow = CreateConVar("ml_glow_mode", "1", "Glow Mode (0 - default, 1 - Q1 glow, 2 - D1 glow, 3 - Custom config glow)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 3.0);
		IgnoringColorblindSet = CreateConVar("ml_glow_colorblindset_ignoring", "1", "Colors are changing, even if the client is set to color blind? (0 - No, 1 - Yes)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		
		//BlurScale = CreateConVar("ml_glow_blur_scale", "3", "Controls the size of the halo shown around players and usable items", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100000.0);
		//Brightness = CreateConVar("ml_glow_brightness", "1", "Brightness of player halos", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		//Force = CreateConVar("ml_glow_force", "255", "Forces glows on", FCVAR_PLUGIN|FCVAR_NOTIFY/*, true, 0.0, true, 1.0*/); //i dont know max vomit
		//LosDelay = CreateConVar("ml_glow_los_delay", "0.0", "Time out of sight before a survivor friend shows up through a wall to a survivor.", FCVAR_PLUGIN|FCVAR_NOTIFY/*, true, 0.0, true, 1.0*/); //max time is indefinitely?
		//LosFadeInTime = CreateConVar("ml_glow_los_fade_in_time", "0.5", "Time after cl_glow_los_delay before a survivor friend shows up fully through wall", FCVAR_PLUGIN|FCVAR_NOTIFY/*, true, 0.0, true, 1.0*/); //max time is indefinitely?
		//LosFadeOutTime = CreateConVar("ml_glow_los_fade_out_time", "0.5", "Time after cl_glow_los_delay before a survivor friend goes away", FCVAR_PLUGIN|FCVAR_NOTIFY/*, true, 0.0, true, 1.0*/); //max time is indefinitely?
		//Noise = CreateConVar("ml_glow_noise", "1", "Is Survivor glow seen by infected based on noise?", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		
		/////////////glow
		GlowItemFarRed1 = CreateConVar("ml_glow_item_far_r_one", "0.3", "Red color of items from a distance glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowItemFarGreen1 = CreateConVar("ml_glow_item_far_g_one", "0.4", "Green color of items from a distance glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowItemFarBlue1 = CreateConVar("ml_glow_item_far_b_one", "1.0", "Blue color of items from a distance glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowItemFarRed2 = CreateConVar("ml_glow_item_far_r_two", "0.3", "Red color of items from a distance glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowItemFarGreen2 = CreateConVar("ml_glow_item_far_g_two", "0.4", "Green color of items from a distance glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowItemFarBlue2 = CreateConVar("ml_glow_item_far_b_two", "1.0", "Blue color of items from a distance glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
		GlowGhostInfectedRed1 = CreateConVar("ml_glow_ghost_infected_r_one", "0.3", "Red color of infected ghost glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowGhostInfectedGreen1 = CreateConVar("ml_glow_ghost_infected_g_one", "0.4", "Green color of infected ghost glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowGhostInfectedBlue1 = CreateConVar("ml_glow_ghost_infected_b_one", "1.0", "Blue color of infected ghost glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowGhostInfectedRed2 = CreateConVar("ml_glow_ghost_infected_r_two", "0.3", "Red color of infected ghost glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowGhostInfectedGreen2 = CreateConVar("ml_glow_ghost_infected_g_two", "0.4", "Green color of infected ghost glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowGhostInfectedBlue2 = CreateConVar("ml_glow_ghost_infected_b_two", "1.0", "Blue color of infected ghost glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
		GlowItemRed1 = CreateConVar("ml_glow_item_r_one", "0.7", "Red color of items up close (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowItemGreen1 = CreateConVar("ml_glow_item_g_one", "0.7", "Green color of items up close glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowItemBlue1 = CreateConVar("ml_glow_item_b_one", "1.0", "Blue color of items up close glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowItemRed2 = CreateConVar("ml_glow_item_r_two", "0.7", "Red color of items up close glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowItemGreen2 = CreateConVar("ml_glow_item_g_two", "0.7", "Green color of items up close glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowItemBlue2 = CreateConVar("ml_glow_item_b_two", "1.0", "Blue color of items up close glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
		GlowSurvivorHurtRed1 = CreateConVar("ml_glow_survivor_hurt_r_one", "1.0", "Red color of survivor team mate glow when incapacitated (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorHurtGreen1 = CreateConVar("ml_glow_survivor_hurt_g_one", "0.4", "Green color of survivor team mate glow when incapacitated (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorHurtBlue1 = CreateConVar("ml_glow_survivor_hurt_b_one", "0.0", "Blue color of survivor team mate glow when incapacitated (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorHurtRed2 = CreateConVar("ml_glow_survivor_hurt_r_two", "1.0", "Red color of survivor team mate glow when incapacitated (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorHurtGreen2 = CreateConVar("ml_glow_survivor_hurt_g_two", "0.4", "Green color of survivor team mate glow when incapacitated (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorHurtBlue2 = CreateConVar("ml_glow_survivor_hurt_b_two", "0.0", "Blue color of survivor team mate glow when incapacitated (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
		GlowSurvivorVomitRed1 = CreateConVar("ml_glow_survivor_vomit_r_one", "1.0", "Red color the Survivors see the IT victim glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorVomitGreen1 = CreateConVar("ml_glow_survivor_vomit_g_one", "0.4", "Green color the Survivors see the IT victim glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorVomitBlue1 = CreateConVar("ml_glow_survivor_vomit_b_one", "0.0", "Blue color the Survivors see the IT victim glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorVomitRed2 = CreateConVar("ml_glow_survivor_vomit_r_two", "1.0", "Red color the Survivors see the IT victim glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorVomitGreen2 = CreateConVar("ml_glow_survivor_vomit_g_two", "0.4", "Green color the Survivors see the IT victim glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorVomitBlue2 = CreateConVar("ml_glow_survivor_vomit_b_two", "0.0", "Blue color the Survivors see the IT victim glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
			
		GlowInfectedRed1 = CreateConVar("ml_glow_infected_r_one", "0.3", "Red color of infected glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowInfectedGreen1 = CreateConVar("ml_glow_infected_g_one", "0.4", "Green color of infected glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowInfectedBlue1 = CreateConVar("ml_glow_infected_b_one", "1.0", "Blue color of infected glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowInfectedRed2 = CreateConVar("ml_glow_infected_r_two", "0.3", "Red color of infected glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowInfectedGreen2 = CreateConVar("ml_glow_infected_g_two", "0.4", "Green color of infected glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowInfectedBlue2 = CreateConVar("ml_glow_infected_b_two", "1.0", "Blue color of infected glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
		GlowSurvivorRed1 = CreateConVar("ml_glow_survivor_r_one", "0.3", "Red color of survivor team mate glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorGreen1 = CreateConVar("ml_glow_survivor_g_one", "0.4", "Green color of survivor team mate glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorBlue1 = CreateConVar("ml_glow_survivor_b_one", "1.0", "Blue color of survivor team mate glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorRed2 = CreateConVar("ml_glow_survivor_r_two", "0.3", "Red color of survivor team mate glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorGreen2 = CreateConVar("ml_glow_survivor_g_two", "0.4", "Green color of survivor team mate glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorBlue2 = CreateConVar("ml_glow_survivor_b_two", "1.0", "Blue color of survivor team mate glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		
						///IN VERSION 1.5///
		GlowAbilityRed1 = CreateConVar("ml_glow_ability_r_one", "1.0", "Red color of ability glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);			
		GlowAbilityGreen1 = CreateConVar("ml_glow_ability_g_one", "0.0", "Green color of ability glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowAbilityBlue1 = CreateConVar("ml_glow_ability_b_one", "0.0", "Blue color of ability glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowAbilityRed2 = CreateConVar("ml_glow_ability_r_two", "1.0", "Red color of ability glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);			
		GlowAbilityGreen2 = CreateConVar("ml_glow_ability_g_two", "0.0", "Green color of ability glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowAbilityBlue2 = CreateConVar("ml_glow_ability_b_two", "0.0", "Blue color of ability glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		
		GlowInfectedVomitRed1 = CreateConVar("ml_glow_infected_vomit_r_one", "0.79", "Red the PZs see the IT victim glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);	
		GlowInfectedVomitGreen1 = CreateConVar("ml_glow_infected_vomit_g_one", "0.07", "Green the PZs see the IT victim glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowInfectedVomitBlue1 = CreateConVar("ml_glow_infected_vomit_b_one", "0.72", "Blue the PZs see the IT victim glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowInfectedVomitRed2 = CreateConVar("ml_glow_infected_vomit_r_two", "0.79", "Red the PZs see the IT victim glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowInfectedVomitGreen2 = CreateConVar("ml_glow_infected_vomit_g_two", "0.07", "Green the PZs see the IT victim glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowInfectedVomitBlue2 = CreateConVar("ml_glow_infected_vomit_b_two", "0.72", "Blue the PZs see the IT victim glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);

		GlowSurvivorHealthHighRed1 = CreateConVar("ml_glow_survivor_health_high_r_one", "0.039", "Red color the Infected see Survivors when their health is high (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorHealthHighGreen1 = CreateConVar("ml_glow_survivor_health_high_g_one", "0.69", "Green color the Infected see Survivors when their health is high (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorHealthHighBlue1 = CreateConVar("ml_glow_survivor_health_high_b_one", "0.196", "Blue color the Infected see Survivors when their health is high (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorHealthHighRed2 = CreateConVar("ml_glow_survivor_health_high_r_two", "0.039", "Red color the Infected see Survivors when their health is high (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorHealthHighGreen2 = CreateConVar("ml_glow_survivor_health_high_g_two", "0.69", "Green color the Infected see Survivors when their health is high (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorHealthHighBlue2 = CreateConVar("ml_glow_survivor_health_high_b_two", "0.196", "Blue color the Infected see Survivors when their health is high (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);

		GlowSurvivorHealthMedRed1 = CreateConVar("ml_glow_survivor_health_med_r_one", "0.59", "Red color the Infected see Survivors when their health is medium (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorHealthMedGreen1 = CreateConVar("ml_glow_survivor_health_med_g_one", "0.4", "Green color the Infected see Survivors when their health is medium (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorHealthMedBlue1 = CreateConVar("ml_glow_survivor_health_med_b_one", "0.032", "Blue color the Infected see Survivors when their health is medium (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorHealthMedRed2 = CreateConVar("ml_glow_survivor_health_med_r_two", "0.59", "Red color the Infected see Survivors when their health is medium (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorHealthMedGreen2 = CreateConVar("ml_glow_survivor_health_med_g_two", "0.4", "Green color the Infected see Survivors when their health is medium (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorHealthMedBlue2 = CreateConVar("ml_glow_survivor_health_med_b_two", "0.032", "Blue color the Infected see Survivors when their health is medium (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		
		GlowSurvivorHealthLowRed1 = CreateConVar("ml_glow_survivor_health_low_r_one", "0.63", "Red color the Infected see Survivors when their health is low (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorHealthLowGreen1 = CreateConVar("ml_glow_survivor_health_low_g_one", "0.098", "Green color the Infected see Survivors when their health is low (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorHealthLowBlue1 = CreateConVar("ml_glow_survivor_health_low_b_one", "0.098", "Blue color the Infected see Survivors when their health is low (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorHealthLowRed2 = CreateConVar("ml_glow_survivor_health_low_r_two", "0.63", "Red color the Infected see Survivors when their health is low (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorHealthLowGreen2 = CreateConVar("ml_glow_survivor_health_low_g_two", "0.098", "Green color the Infected see Survivors when their health is low (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowSurvivorHealthLowBlue2 = CreateConVar("ml_glow_survivor_health_low_b_two", "0.098", "Blue color the Infected see Survivors when their health is low (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
		GlowThirdstrikeItemRed1 = CreateConVar("ml_glow_thirdstrike_item_r_one", "1.0", "Red color of survivor team mate glow (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowThirdstrikeItemGreen1 = CreateConVar("ml_glow_thirdstrike_item_g_one", "0.0", "Green color of items in black and white mode (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowThirdstrikeItemBlue1 = CreateConVar("ml_glow_thirdstrike_item_b_one", "0.0", "Blue color of items in black and white mode (First stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowThirdstrikeItemRed2 = CreateConVar("ml_glow_thirdstrike_item_r_two", "1.0", "Red color of survivor team mate glow (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowThirdstrikeItemGreen2 = CreateConVar("ml_glow_thirdstrike_item_g_two", "0.0", "Green color of items in black and white mode (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		GlowThirdstrikeItemBlue2 = CreateConVar("ml_glow_thirdstrike_item_b_two", "0.0", "Blue color of items in black and white mode (Second stage)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);	
				
		HookConVarChange(MLGlow, CvarChanged);
		
		AutoExecConfig(true, "mlglow_config");
		
		/*new flags1 = GetCommandFlags("cl_glow_blur_scale");
		SetCommandFlags("cl_glow_blur_scale", flags1 & ~FCVAR_CHEAT);
		new flags2 = GetCommandFlags("cl_glow_brightness");
		SetCommandFlags("cl_glow_brightness", flags2 & ~FCVAR_CHEAT);
		new flags3 = GetCommandFlags("cl_glow_force");
		SetCommandFlags("cl_glow_force", flags3 & ~FCVAR_CHEAT);
		new flags4 = GetCommandFlags("cl_glow_los_delay");
		SetCommandFlags("cl_glow_los_delay", flags4 & ~FCVAR_CHEAT);
		new flags5 = GetCommandFlags("cl_glow_los_fade_in_time");
		SetCommandFlags("cl_glow_los_fade_in_time", flags5 & ~FCVAR_CHEAT);
		new flags6 = GetCommandFlags("cl_glow_los_fade_out_time");
		SetCommandFlags("cl_glow_los_fade_out_time", flags6 & ~FCVAR_CHEAT);
		new flags7 = GetCommandFlags("cl_glow_noise");
		SetCommandFlags("cl_glow_noise", flags7 & ~FCVAR_CHEAT);*/
	}

	public OnClientPostAdminCheck(client)
	{
		if(glowhook != 0)
		{
			if(IsClientConnected(client))
			{
				TimerStart(client);
			}
		}
	}
	
	public OnConfigExecuted()
	{
		glowhook = GetConVarInt(MLGlow);
	}
	
	public CvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		glowhook = GetConVarInt(MLGlow);
		if (glowhook !=0)
		{
			for(new i=1; i<=MaxClients;i++)
			{
				TimerStart(i);
			}
		}
	}
	
	public Action:Glow1(Handle:timer, any:client)  
	{
		if(!IsClientConnected(client) && !IsClientInGame(client))
		{
			return Plugin_Stop;
		}
		
		switch (glowhook)
		{
			case 0: //default
			{
				//Glow of items from a distance
				ClientCommand(client, "cl_glow_item_far_b 1.0");
				ClientCommand(client, "cl_glow_item_far_g 0.4");
				ClientCommand(client, "cl_glow_item_far_r 0.3");
				
				//Color of infected ghost glow
				ClientCommand(client, "cl_glow_ghost_infected_b 1.0");
				ClientCommand(client, "cl_glow_ghost_infected_g 0.4");
				ClientCommand(client, "cl_glow_ghost_infected_r 0.3");
				
				//Glow of items up close
				ClientCommand(client, "cl_glow_item_b 1.0");
				ClientCommand(client, "cl_glow_item_g 0.7");
				ClientCommand(client, "cl_glow_item_r 0.7");
				
				//Color of survivor team mate glow when incapacitated
				ClientCommand(client, "cl_glow_survivor_hurt_b 0.0");
				ClientCommand(client, "cl_glow_survivor_hurt_g 0.4");
				ClientCommand(client, "cl_glow_survivor_hurt_r 1.0");
				
				//Color the Survivors see the IT victim glow
				ClientCommand(client, "cl_glow_survivor_vomit_b 0.0");
				ClientCommand(client, "cl_glow_survivor_vomit_g 0.4");
				ClientCommand(client, "cl_glow_survivor_vomit_r 1.0");
				
				//Color of infected glow
				ClientCommand(client, "cl_glow_infected_b 1.0");
				ClientCommand(client, "cl_glow_infected_g 0.4");
				ClientCommand(client, "cl_glow_infected_r 0.3");
				
				//Color of survivor team mate glow
				ClientCommand(client, "cl_glow_survivor_b 1.0");
				ClientCommand(client, "cl_glow_survivor_g 0.4");
				ClientCommand(client, "cl_glow_survivor_r 0.3");
				
				///IN VERSION 1.5///
							
				//Color of ability glow
				ClientCommand(client, "cl_glow_ability_b 0.0");
				ClientCommand(client, "cl_glow_ability_g 0.0");
				ClientCommand(client, "cl_glow_ability_r 1.0");
				//Color of ability glow for people with color blind
				ClientCommand(client, "cl_glow_ability_colorblind_b 1.0");
				ClientCommand(client, "cl_glow_ability_colorblind_g 1.0");
				ClientCommand(client, "cl_glow_ability_colorblind_r 0.3");
				
				//Color the PZs see the IT victim glow
				ClientCommand(client, "cl_glow_infected_vomit_b 0.72");
				ClientCommand(client, "cl_glow_infected_vomit_g 0.07");
				ClientCommand(client, "cl_glow_infected_vomit_r 0.79");
				
				//Color the Infected see Survivors when their health is high
				ClientCommand(client, "cl_glow_survivor_health_high_b 0.196");
				ClientCommand(client, "cl_glow_survivor_health_high_g 0.69");
				ClientCommand(client, "cl_glow_survivor_health_high_r 0.039");
				//Color the Infected see Survivors when their health is high for people with color blind
				ClientCommand(client, "cl_glow_survivor_health_high_colorblind_b 0.392");
				ClientCommand(client, "cl_glow_survivor_health_high_colorblind_g 0.694");
				ClientCommand(client, "cl_glow_survivor_health_high_colorblind_r 0.047");

				//Color the Infected see Survivors when their health is medium
				ClientCommand(client, "cl_glow_survivor_health_med_b 0.032");
				ClientCommand(client, "cl_glow_survivor_health_med_g 0.4");
				ClientCommand(client, "cl_glow_survivor_health_med_r 0.59");
				//Color the Infected see Survivors when their health is medium for people with color blind
				ClientCommand(client, "cl_glow_survivor_health_med_colorblind_b 0.098");
				ClientCommand(client, "cl_glow_survivor_health_med_colorblind_g 0.573");
				ClientCommand(client, "cl_glow_survivor_health_med_colorblind_r 0.694");

				//Color the Infected see Survivors when their health is low
				ClientCommand(client, "cl_glow_survivor_health_low_b 0.098");
				ClientCommand(client, "cl_glow_survivor_health_low_g 0.098");
				ClientCommand(client, "cl_glow_survivor_health_low_r 0.63");
				//Color the Infected see Survivors when their health is low for people with color blind
				ClientCommand(client, "cl_glow_survivor_health_low_colorblind_b 0.807");
				ClientCommand(client, "cl_glow_survivor_health_low_colorblind_g 0.807");
				ClientCommand(client, "cl_glow_survivor_health_low_colorblind_r 0.047");

				//Glow of items in "black and white" mode
				ClientCommand(client, "cl_glow_thirdstrike_item_b 0.0");
				ClientCommand(client, "cl_glow_thirdstrike_item_g 0.0");
				ClientCommand(client, "cl_glow_thirdstrike_item_r 1.0");
				//Glow of items in "black and white" mode for people with color blind
				ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_b 1.0");
				ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_g 1.0");
				ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_r 0.3");

				//cheats
				/*ClientCommand(client, "cl_glow_blur_scale 3"); //[max=100000] Controls the size of the halo shown around players and usable items  
				ClientCommand(client, "cl_glow_brightness 1"); //Brightness of player halos
				ClientCommand(client, "cl_glow_force 255"); //Forces glows on
				ClientCommand(client, "cl_glow_los_delay 0.0"); //Time out of sight before a survivor friend shows up through a wall to a survivor.
				ClientCommand(client, "cl_glow_los_fade_in_time 0.5"); //Time after cl_glow_los_delay before a survivor friend shows up fully through wall.
				ClientCommand(client, "cl_glow_los_fade_out_time 0.5"); //Time after cl_glow_los_delay before a survivor friend goes away
				ClientCommand(client, "cl_glow_noise 1"); //Is Survivor glow seen by infected based on noise?*/
				
				return Plugin_Stop;
			}
				
			case 1: //q1
			{
				ClientCommand(client, "cl_glow_item_far_r 0.5");
				ClientCommand(client, "cl_glow_item_far_g 1.0");
				ClientCommand(client, "cl_glow_item_far_b 0.0");
				
				ClientCommand(client, "cl_glow_ghost_infected_r 0.35");
				ClientCommand(client, "cl_glow_ghost_infected_g 0.35");
				ClientCommand(client, "cl_glow_ghost_infected_b 0.35");
				
				ClientCommand(client, "cl_glow_item_r 0.5");
				ClientCommand(client, "cl_glow_item_g 1.0");
				ClientCommand(client, "cl_glow_item_b 0.0");
				
				ClientCommand(client, "cl_glow_survivor_hurt_b 0.0");
				ClientCommand(client, "cl_glow_survivor_hurt_g 0.45");
				ClientCommand(client, "cl_glow_survivor_hurt_r 1.0");
				
				ClientCommand(client, "cl_glow_survivor_vomit_b 0.72");
				ClientCommand(client, "cl_glow_survivor_vomit_g 0.07");
				ClientCommand(client, "cl_glow_survivor_vomit_r 0.79");
				
				ClientCommand(client, "cl_glow_infected_b 1.0");
				ClientCommand(client, "cl_glow_infected_g 0.5");
				ClientCommand(client, "cl_glow_infected_r 0.0");
				
				ClientCommand(client, "cl_glow_survivor_b 1.0");
				ClientCommand(client, "cl_glow_survivor_g 0.5");
				ClientCommand(client, "cl_glow_survivor_r 0.5");
			}	
				
			case 2: //d1
			{
				ClientCommand(client, "cl_glow_item_far_r 0.0");
				ClientCommand(client, "cl_glow_item_far_b 1.0");
				ClientCommand(client, "cl_glow_item_far_g 0.6");
				
				ClientCommand(client, "cl_glow_ghost_infected_r 0.35");
				ClientCommand(client, "cl_glow_ghost_infected_g 0.35");
				ClientCommand(client, "cl_glow_ghost_infected_b 0.35");
				
				ClientCommand(client, "cl_glow_item_r 0.0");
				ClientCommand(client, "cl_glow_item_b 1.0");
				ClientCommand(client, "cl_glow_item_g 0.5");
				
				ClientCommand(client, "cl_glow_survivor_hurt_b 0.0");
				ClientCommand(client, "cl_glow_survivor_hurt_g 0.45");
				ClientCommand(client, "cl_glow_survivor_hurt_r 1.0");	
				
				ClientCommand(client, "cl_glow_survivor_vomit_b 0.72");
				ClientCommand(client, "cl_glow_survivor_vomit_g 0.07");
				ClientCommand(client, "cl_glow_survivor_vomit_r 0.79");
				
				ClientCommand(client, "cl_glow_infected_b 1.0");
				ClientCommand(client, "cl_glow_infected_g 0.5");
				ClientCommand(client, "cl_glow_infected_r 0.0");
				
				ClientCommand(client, "cl_glow_survivor_b 1.0");
				ClientCommand(client, "cl_glow_survivor_g 0.5");
				ClientCommand(client, "cl_glow_survivor_r 0.5");
			}
			
			case 3: //user
			{
				ClientCommand(client, "cl_glow_item_far_b %f",  GetConVarFloat(GlowItemFarBlue1));
				ClientCommand(client, "cl_glow_item_far_g %f",  GetConVarFloat(GlowItemFarGreen1));
				ClientCommand(client, "cl_glow_item_far_r %f",  GetConVarFloat(GlowItemFarRed1));
				
				ClientCommand(client, "cl_glow_ghost_infected_b %f",  GetConVarFloat(GlowGhostInfectedBlue1));
				ClientCommand(client, "cl_glow_ghost_infected_g %f",  GetConVarFloat(GlowGhostInfectedGreen1));
				ClientCommand(client, "cl_glow_ghost_infected_r %f",  GetConVarFloat(GlowGhostInfectedRed1));
				
				ClientCommand(client, "cl_glow_item_b %f",  GetConVarFloat(GlowItemBlue1));
				ClientCommand(client, "cl_glow_item_g %f",  GetConVarFloat(GlowItemGreen1));
				ClientCommand(client, "cl_glow_item_r %f",  GetConVarFloat(GlowItemRed1));
				
				ClientCommand(client, "cl_glow_survivor_hurt_b %f",  GetConVarFloat(GlowSurvivorHurtBlue1));		
				ClientCommand(client, "cl_glow_survivor_hurt_g %f",  GetConVarFloat(GlowSurvivorHurtGreen1));
				ClientCommand(client, "cl_glow_survivor_hurt_r %f",  GetConVarFloat(GlowSurvivorHurtRed1));
				
				ClientCommand(client, "cl_glow_survivor_vomit_b %f",  GetConVarFloat(GlowSurvivorVomitBlue1));	
				ClientCommand(client, "cl_glow_survivor_vomit_g %f",  GetConVarFloat(GlowSurvivorVomitGreen1));
				ClientCommand(client, "cl_glow_survivor_vomit_r %f",  GetConVarFloat(GlowSurvivorVomitRed1));
				
				ClientCommand(client, "cl_glow_infected_b %f",  GetConVarFloat(GlowInfectedBlue1));	
				ClientCommand(client, "cl_glow_infected_g %f",  GetConVarFloat(GlowInfectedGreen1));
				ClientCommand(client, "cl_glow_infected_r %f",  GetConVarFloat(GlowInfectedRed1));
				
				ClientCommand(client, "cl_glow_survivor_b %f",  GetConVarFloat(GlowSurvivorBlue1));	
				ClientCommand(client, "cl_glow_survivor_g %f",  GetConVarFloat(GlowSurvivorGreen1));
				ClientCommand(client, "cl_glow_survivor_r %f",  GetConVarFloat(GlowSurvivorRed1));
				
				///IN VERSION 1.5///
				
				ClientCommand(client, "cl_glow_ability_b %f",  GetConVarFloat(GlowAbilityBlue1));
				ClientCommand(client, "cl_glow_ability_g %f",  GetConVarFloat(GlowAbilityGreen1));
				ClientCommand(client, "cl_glow_ability_r %f",  GetConVarFloat(GlowAbilityRed1));
				if (GetConVarInt(IgnoringColorblindSet) == 1)
				{
					ClientCommand(client, "cl_glow_ability_colorblind_b %f",  GetConVarFloat(GlowAbilityBlue1));
					ClientCommand(client, "cl_glow_ability_colorblind_g %f",  GetConVarFloat(GlowAbilityGreen1));
					ClientCommand(client, "cl_glow_ability_colorblind_r %f",  GetConVarFloat(GlowAbilityRed1));
				}
				
				ClientCommand(client, "cl_glow_infected_vomit_b %f",  GetConVarFloat(GlowInfectedVomitBlue1));
				ClientCommand(client, "cl_glow_infected_vomit_g %f",  GetConVarFloat(GlowInfectedVomitGreen1));
				ClientCommand(client, "cl_glow_infected_vomit_r %f",  GetConVarFloat(GlowInfectedVomitRed1));
				
				ClientCommand(client, "cl_glow_survivor_health_high_b %f",  GetConVarFloat(GlowSurvivorHealthHighBlue1));
				ClientCommand(client, "cl_glow_survivor_health_high_g %f",  GetConVarFloat(GlowSurvivorHealthHighGreen1));
				ClientCommand(client, "cl_glow_survivor_health_high_r %f",  GetConVarFloat(GlowSurvivorHealthHighRed1));
				if (GetConVarInt(IgnoringColorblindSet) == 1)
				{
					ClientCommand(client, "cl_glow_survivor_health_high_colorblind_b %f",  GetConVarFloat(GlowSurvivorHealthHighBlue1));
					ClientCommand(client, "cl_glow_survivor_health_high_colorblind_g %f",  GetConVarFloat(GlowSurvivorHealthHighGreen1));
					ClientCommand(client, "cl_glow_survivor_health_high_colorblind_r %f",  GetConVarFloat(GlowSurvivorHealthHighRed1));
				}
				
				ClientCommand(client, "cl_glow_survivor_health_med_b %f",  GetConVarFloat(GlowSurvivorHealthMedBlue1));
				ClientCommand(client, "cl_glow_survivor_health_med_g %f",  GetConVarFloat(GlowSurvivorHealthMedGreen1));
				ClientCommand(client, "cl_glow_survivor_health_med_r %f",  GetConVarFloat(GlowSurvivorHealthMedRed1));
				if (GetConVarInt(IgnoringColorblindSet) == 1)
				{
					ClientCommand(client, "cl_glow_survivor_health_med_colorblind_b %f",  GetConVarFloat(GlowSurvivorHealthMedBlue1));
					ClientCommand(client, "cl_glow_survivor_health_med_colorblind_g %f",  GetConVarFloat(GlowSurvivorHealthMedGreen1));
					ClientCommand(client, "cl_glow_survivor_health_med_colorblind_r %f",  GetConVarFloat(GlowSurvivorHealthMedRed1));
				}
				
				ClientCommand(client, "cl_glow_survivor_health_low_b %f",  GetConVarFloat(GlowSurvivorHealthLowBlue1));
				ClientCommand(client, "cl_glow_survivor_health_low_g %f",  GetConVarFloat(GlowSurvivorHealthLowGreen1));
				ClientCommand(client, "cl_glow_survivor_health_low_r %f",  GetConVarFloat(GlowSurvivorHealthLowRed1));
				if (GetConVarInt(IgnoringColorblindSet) == 1)
				{
					ClientCommand(client, "cl_glow_survivor_health_low_colorblind_b %f",  GetConVarFloat(GlowSurvivorHealthLowBlue1));
					ClientCommand(client, "cl_glow_survivor_health_low_colorblind_g %f",  GetConVarFloat(GlowSurvivorHealthLowGreen1));
					ClientCommand(client, "cl_glow_survivor_health_low_colorblind_r %f",  GetConVarFloat(GlowSurvivorHealthLowRed1));
				}
				
				ClientCommand(client, "cl_glow_thirdstrike_item_b %f",  GetConVarFloat(GlowThirdstrikeItemBlue1));
				ClientCommand(client, "cl_glow_thirdstrike_item_g %f",  GetConVarFloat(GlowThirdstrikeItemGreen1));
				ClientCommand(client, "cl_glow_thirdstrike_item_r %f",  GetConVarFloat(GlowThirdstrikeItemRed1));
				if (GetConVarInt(IgnoringColorblindSet) == 1)
				{
					ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_b %f",  GetConVarFloat(GlowThirdstrikeItemBlue1));
					ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_g %f",  GetConVarFloat(GlowThirdstrikeItemGreen1));
					ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_r %f",  GetConVarFloat(GlowThirdstrikeItemRed1));
				}
				
				/*ClientCommand(client, "cl_glow_blur_scale %f",  GetConVarFloat(BlurScale));
				ClientCommand(client, "cl_glow_brightness %f",  GetConVarFloat(Brightness));
				ClientCommand(client, "cl_glow_force %f",  GetConVarFloat(Force));
				ClientCommand(client, "cl_glow_los_delay %f",  GetConVarFloat(LosDelay));
				ClientCommand(client, "cl_glow_los_fade_in_time %f",  GetConVarFloat(LosFadeInTime));
				ClientCommand(client, "cl_glow_los_fade_out_time %f",  GetConVarFloat(LosFadeOutTime));
				ClientCommand(client, "cl_glow_noise %f",  GetConVarFloat(Noise));*/
			}
		}
		return Plugin_Continue;
	}
	
	public Action:Glow2(Handle:timer, any:client)  
	{
		if(!IsClientConnected(client) && !IsClientInGame(client))
		{
			return Plugin_Stop;
		}
		
		switch (glowhook)
		{
			case 1: //q1
			{
				ClientCommand(client, "cl_glow_item_far_r 0.0");
				
				ClientCommand(client, "cl_glow_ghost_infected_r 0.7");
				ClientCommand(client, "cl_glow_ghost_infected_g 0.7");
				ClientCommand(client, "cl_glow_ghost_infected_b 0.7");
				
				ClientCommand(client, "cl_glow_item_r 0.0");
				ClientCommand(client, "cl_glow_item_g 0.0");
				
				ClientCommand(client, "cl_glow_survivor_hurt_g 0.0");
			}
			
			case 2: //d1
			{
				ClientCommand(client, "cl_glow_item_far_r 0.45");
				
				ClientCommand(client, "cl_glow_ghost_infected_r 0.7");
				ClientCommand(client, "cl_glow_ghost_infected_g 0.7");
				ClientCommand(client, "cl_glow_ghost_infected_b 0.7");
				
				ClientCommand(client, "cl_glow_item_g 1.0");
				ClientCommand(client, "cl_glow_item_r 1.0");
				
				ClientCommand(client, "cl_glow_survivor_hurt_g 0.0");
			}
			
			case 3: //user
			{
				ClientCommand(client, "cl_glow_item_far_b %f",  GetConVarFloat(GlowItemFarBlue2));
				ClientCommand(client, "cl_glow_item_far_g %f",  GetConVarFloat(GlowItemFarGreen2));
				ClientCommand(client, "cl_glow_item_far_r %f",  GetConVarFloat(GlowItemFarRed2));
				
				ClientCommand(client, "cl_glow_ghost_infected_b %f",  GetConVarFloat(GlowGhostInfectedBlue2));
				ClientCommand(client, "cl_glow_ghost_infected_g %f",  GetConVarFloat(GlowGhostInfectedGreen2));
				ClientCommand(client, "cl_glow_ghost_infected_r %f",  GetConVarFloat(GlowGhostInfectedRed2));
				
				ClientCommand(client, "cl_glow_item_b %f",  GetConVarFloat(GlowItemBlue2));
				ClientCommand(client, "cl_glow_item_g %f",  GetConVarFloat(GlowItemGreen2));
				ClientCommand(client, "cl_glow_item_r %f",  GetConVarFloat(GlowItemRed2));
				
				ClientCommand(client, "cl_glow_survivor_hurt_b %f",  GetConVarFloat(GlowSurvivorHurtBlue2));		
				ClientCommand(client, "cl_glow_survivor_hurt_g %f",  GetConVarFloat(GlowSurvivorHurtGreen2));
				ClientCommand(client, "cl_glow_survivor_hurt_r %f",  GetConVarFloat(GlowSurvivorHurtRed2));
				
				ClientCommand(client, "cl_glow_survivor_vomit_b %f",  GetConVarFloat(GlowSurvivorVomitBlue2));	
				ClientCommand(client, "cl_glow_survivor_vomit_g %f",  GetConVarFloat(GlowSurvivorVomitGreen2));
				ClientCommand(client, "cl_glow_survivor_vomit_r %f",  GetConVarFloat(GlowSurvivorVomitRed2));
				
				ClientCommand(client, "cl_glow_infected_b %f",  GetConVarFloat(GlowInfectedBlue2));	
				ClientCommand(client, "cl_glow_infected_g %f",  GetConVarFloat(GlowInfectedGreen2));
				ClientCommand(client, "cl_glow_infected_r %f",  GetConVarFloat(GlowInfectedRed2));
				
				ClientCommand(client, "cl_glow_survivor_b %f",  GetConVarFloat(GlowSurvivorBlue2));	
				ClientCommand(client, "cl_glow_survivor_g %f",  GetConVarFloat(GlowSurvivorGreen2));
				ClientCommand(client, "cl_glow_survivor_r %f",  GetConVarFloat(GlowSurvivorRed2));
				
				///IN VERSION 1.5///
				
				ClientCommand(client, "cl_glow_ability_b %f",  GetConVarFloat(GlowAbilityBlue2));
				ClientCommand(client, "cl_glow_ability_g %f",  GetConVarFloat(GlowAbilityGreen2));
				ClientCommand(client, "cl_glow_ability_r %f",  GetConVarFloat(GlowAbilityRed2));
				if (GetConVarInt(IgnoringColorblindSet) == 1)
				{
					ClientCommand(client, "cl_glow_ability_colorblind_b %f",  GetConVarFloat(GlowAbilityBlue2));
					ClientCommand(client, "cl_glow_ability_colorblind_g %f",  GetConVarFloat(GlowAbilityGreen2));
					ClientCommand(client, "cl_glow_ability_colorblind_r %f",  GetConVarFloat(GlowAbilityRed2));
				}
				
				ClientCommand(client, "cl_glow_infected_vomit_b %f",  GetConVarFloat(GlowInfectedVomitBlue2));
				ClientCommand(client, "cl_glow_infected_vomit_g %f",  GetConVarFloat(GlowInfectedVomitGreen2));
				ClientCommand(client, "cl_glow_infected_vomit_r %f",  GetConVarFloat(GlowInfectedVomitRed2));
				
				ClientCommand(client, "cl_glow_survivor_health_high_b %f",  GetConVarFloat(GlowSurvivorHealthHighBlue2));
				ClientCommand(client, "cl_glow_survivor_health_high_g %f",  GetConVarFloat(GlowSurvivorHealthHighGreen2));
				ClientCommand(client, "cl_glow_survivor_health_high_r %f",  GetConVarFloat(GlowSurvivorHealthHighRed2));
				if (GetConVarInt(IgnoringColorblindSet) == 1)
				{
					ClientCommand(client, "cl_glow_survivor_health_high_colorblind_b %f",  GetConVarFloat(GlowSurvivorHealthHighBlue2));
					ClientCommand(client, "cl_glow_survivor_health_high_colorblind_g %f",  GetConVarFloat(GlowSurvivorHealthHighGreen2));
					ClientCommand(client, "cl_glow_survivor_health_high_colorblind_r %f",  GetConVarFloat(GlowSurvivorHealthHighRed2));
				}
				
				ClientCommand(client, "cl_glow_survivor_health_med_b %f",  GetConVarFloat(GlowSurvivorHealthMedBlue2));
				ClientCommand(client, "cl_glow_survivor_health_med_g %f",  GetConVarFloat(GlowSurvivorHealthMedGreen2));
				ClientCommand(client, "cl_glow_survivor_health_med_r %f",  GetConVarFloat(GlowSurvivorHealthMedRed2));
				if (GetConVarInt(IgnoringColorblindSet) == 1)
				{
					ClientCommand(client, "cl_glow_survivor_health_med_colorblind_b %f",  GetConVarFloat(GlowSurvivorHealthMedBlue2));
					ClientCommand(client, "cl_glow_survivor_health_med_colorblind_g %f",  GetConVarFloat(GlowSurvivorHealthMedGreen2));
					ClientCommand(client, "cl_glow_survivor_health_med_colorblind_r %f",  GetConVarFloat(GlowSurvivorHealthMedRed2));
				}
				
				ClientCommand(client, "cl_glow_survivor_health_low_b %f",  GetConVarFloat(GlowSurvivorHealthLowBlue2));
				ClientCommand(client, "cl_glow_survivor_health_low_g %f",  GetConVarFloat(GlowSurvivorHealthLowGreen2));
				ClientCommand(client, "cl_glow_survivor_health_low_r %f",  GetConVarFloat(GlowSurvivorHealthLowRed2));
				if (GetConVarInt(IgnoringColorblindSet) == 1)
				{
					ClientCommand(client, "cl_glow_survivor_health_low_colorblind_b %f",  GetConVarFloat(GlowSurvivorHealthLowBlue2));
					ClientCommand(client, "cl_glow_survivor_health_low_colorblind_g %f",  GetConVarFloat(GlowSurvivorHealthLowGreen2));
					ClientCommand(client, "cl_glow_survivor_health_low_colorblind_r %f",  GetConVarFloat(GlowSurvivorHealthLowRed2));
				}
				
				ClientCommand(client, "cl_glow_thirdstrike_item_b %f",  GetConVarFloat(GlowThirdstrikeItemBlue2));
				ClientCommand(client, "cl_glow_thirdstrike_item_g %f",  GetConVarFloat(GlowThirdstrikeItemGreen2));
				ClientCommand(client, "cl_glow_thirdstrike_item_r %f",  GetConVarFloat(GlowThirdstrikeItemRed2));
				if (GetConVarInt(IgnoringColorblindSet) == 1)
				{
					ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_b %f",  GetConVarFloat(GlowThirdstrikeItemBlue2));
					ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_g %f",  GetConVarFloat(GlowThirdstrikeItemGreen2));
					ClientCommand(client, "cl_glow_thirdstrike_item_colorblind_r %f",  GetConVarFloat(GlowThirdstrikeItemRed2));
				}
			}
		}
		return Plugin_Continue;
	}
	
	public Action:TimerStart(client)
	{	
		CreateTimer(1.0, Glow1, client, TIMER_REPEAT);
		CreateTimer(2.0, Glow2, client, TIMER_REPEAT);
	}
	