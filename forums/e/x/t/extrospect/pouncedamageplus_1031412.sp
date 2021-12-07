///////////////////////////////////////////////////////////
/////////////////////////////////   ///////////////////////
////////''''////////////////////   ////////'''/////''''////
///////  /////        ////        ////////   ///////  /////
//////  /////   ///   //   ///   ////           ///  //////
/////  /////        ////        ////////   ///////  ///////
////,,,,///   /////////////////////////,,,/////,,,,////////
//////////   //////////////////////////////////////////////
///////////////////////////////////////////////////////////
/* 
*
* L4D2 (+ L4D1) pouncedamage+ [pd+]
* `````````````````````````````````
*
* 	This plugin allows a server admin to:
*		
*		+ Uncap hunter pounce damage upto any value they require (including fully uncapped), pounce damage
*		  will scale as normal upto the inbuilt cap (i.e. a 25dmg pounce before adding the plugin will
*		  STILL be a 25 dmg pounce afterwards) but pounce damage will continue to increase (using the same 
*		  default scaling) beyond the inbuilt cap, upto the limit decided by pdplus_maxdmg.  (Default 100)
*
*		+ Adjust damage scaling so that pounce damage NO LONGER scales at the default amount, allowing
*		  the distance required to acheieve a given pounce damage to be increased (by reducing the damage scaling 
*		  value) or decreased (by increasing the damage scaling value).  The damage scaling factor (pdplus_scale) 
*		  acts as a multiplier to the damage inflicted by a pounce, so turning it up (> 1) increases the damage for 
*		  a given pounce while turning it down (0 < x < 1) decreases the damage dealt. (Default 1.0 = default scaling)
*
*		+ Enable pounce damage 'carry-over' on incap; essentially, if a survivor is incapped by pounce damage
*		  but did not have sufficient health before being incapped to experience all of the pounce damage acheived 
*		  by the hunter, then any 'lost' damage will be applied once the survivor is downed. i.e. a 45 dmg pounce on 
*		  a survivor with only 10 hp would normally lose 35 hp of hard-earned damage, with pdplus_incap_dmg set to 1
*		  however, this extra damage will be taken from the survivors 300 incapped-hp, leaving them downed with 265 hp.
*		  (Default 1 = carry-over enabled)
*
*		+ If incap pounce damage carry-over IS enabled, then you can also scale the dmg that is applied POST-incap using 
*		  the pdplus_incap_scale cvar.  Any damage dealt to an incapped survivor due to the damage carry-over system 
*		  will be multiplied by this value before it is applied.  i.e. if pdplus_incap_scale was set to 3 in the above 
*		  example, then the 35 hp of 'carry-over' damage would be multiplied by 3 to give 105 hp of dmg to be carried 
*		  over into the survivor's incapped hp (leaving them incapped with 195 hp). (Default 1.0 = no rescaling of incap dmg)
*
*		+ There is also an inbuilt notifications system to inform players of what the plugin is doing, this also includes
*		  several cvars to customise which notifications are displayed and how they are displayed: pdplus_notify to enable
*		  or disable notifications (0) & select notification style (1 - chat msg, over default cap dmg only; 2 - chat msg, all 
*		  damage pounces over pdplus_notify_min; 3 - hintbox, over default cap dmg only; 4 - hintbox, all damage pounces over 
*		  pdplus_notify_min); pdplus_notify_all to toggle between notifications being sent to all players (1) or just to the 
*		  pounce damage attacker & victim (0); pdplus_welcome to enable (1)/disable (0) a chat message explaining the effects
*		  of pdplus to connecting players; pdplus_incapnotify to toggle notifications when a player receives incap carry-over 
*		  damage (0 - off; 1 - on).
*
*
*	The plugin also includes a hunter pounce stats system which collects info on players' total # of pounces, total # of
*	damage pounces, total pounce damage dealt, total # of incap-dmg causing pounces, total incap damage dealt and also each player's
*	highest damage pounce score on the server to date (their pounce damage p.b.).
*
*	Users may check their stats and the top <n> highest dmg pounces on the server using chat or console commands 
*	(!pdpstats [sm_pdpstats / pdplus_mystats] & !pdptop <n> [sm_pdptop <n>] respectively).
*
*/


#include <sourcemod>
#define MAX_PLAYERS 32

#define PLUGIN_VERSION "0.9.0x"

//globals
new Handle:hSupportedModes = INVALID_HANDLE;
new Handle:hCurrentGamemode = INVALID_HANDLE;

new Handle:hMaxPounceRange = INVALID_HANDLE;
new maxPounceDistance;
new Handle:hMinPounceRange = INVALID_HANDLE;
new minPounceDistance;
new Handle:hMaxPounceDamage = INVALID_HANDLE;


//hunter position store
new Float:infectedPosition[32][3];
//support up to 32 slots on a server

//cvars + timers
new Handle:hCapDamage = INVALID_HANDLE;
new Handle:hPdpScale = INVALID_HANDLE;
new Handle:hIncapDmg = INVALID_HANDLE;
new Handle:hIncapScale = INVALID_HANDLE;
new Handle:hApplyIncapDmgTimers[MAX_PLAYERS+1];

new gLateDmg[MAX_PLAYERS+1];


new Handle:hNotifyStyle = INVALID_HANDLE;
new Handle:hNotifyMin = INVALID_HANDLE;
new Handle:hNotifyAll = INVALID_HANDLE;
new Handle:hScaleNotify = INVALID_HANDLE;
new Handle:hIncapNotify = INVALID_HANDLE;
new Handle:hIncapHintTimers[MAX_PLAYERS+1];
new Handle:hWelcomeText = INVALID_HANDLE;
new Handle:hPdpWelcomeTimers[MAX_PLAYERS+1];


new Handle:hStatsEnabled = INVALID_HANDLE;


//stats cvars + timers
new Handle:hStatsMinVisits = INVALID_HANDLE;
new Handle:hStatsSchmuckTimeout = INVALID_HANDLE;
new Handle:hStatsRegularTimeout = INVALID_HANDLE;
new Handle:hStatsAdminTimeout = INVALID_HANDLE;
new Handle:hStatsAdminFlags = INVALID_HANDLE;
new Handle:hStatsWelcomeMsgDefault = INVALID_HANDLE;
new Handle:hStatsWelcomeTimers[MAX_PLAYERS+1];
new Handle:hStatsCmdInfoTimers[MAX_PLAYERS+1];
new Handle:hStatsTopMenuTimers[MAX_PLAYERS+1];

new gPdpTopMenuActive[MAX_PLAYERS+1];
new gTopPos[MAX_PLAYERS+1];



public Plugin:myinfo = 
{
	name = "pouncedamage+",
	author = "extrospect",
	description = "Uncap and modify hunter pounce damage in L4D2 and L4D [now with pounce stats]",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1003371"
}



public OnPluginStart()
{
	decl String:gameMod[32];
	GetGameFolderName(gameMod, sizeof(gameMod));
	//If the game is L4D1 then get the max range cvar's value else use the fixed L4D2 value
	maxPounceDistance = 0;
	if(StrEqual(gameMod, "left4dead", false))
	{
		hMaxPounceRange = FindConVar("z_pounce_damage_range_max");
		maxPounceDistance = GetConVarInt(hMaxPounceRange);
	}
	else
	{
		maxPounceDistance = 1024;
	}
	
	//If the game is L4D1 then get the min range cvar's value else use the fixed L4D2 value
	minPounceDistance = 0;
	if(StrEqual(gameMod, "left4dead", false))
	{
		hMinPounceRange = FindConVar("z_pounce_damage_range_min");
		minPounceDistance = GetConVarInt(hMinPounceRange);
	}
	else
	{
		minPounceDistance = 300;
	}

	hMaxPounceDamage = FindConVar("z_hunter_max_pounce_bonus_damage");
	new defMaxDamage = GetConVarInt(hMaxPounceDamage);
	
	hSupportedModes = CreateConVar("pdplus_gamemodes","versus,scavenge","A comma-separated list of the gamemodes for which pd+ will be enabled. Available game modes:\n    [L4D1+2] - \"coop\", \"versus\" & \"survival\"\n    [L4D2 only] - \"realism\", \"scavenge\", \"teamversus\" & \"teamscavenge\" ",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	hCurrentGamemode = FindConVar("mp_gamemode");
	
	hCapDamage = CreateConVar("pdplus_maxdmg","100","The extended pounce damage cap the plugin will enforce - only values over (z_max_pounce_bonus_damage + 1) will have an effect",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	new newMaxDamage = GetConVarInt(hCapDamage);
	if (newMaxDamage < (defMaxDamage + 1))
	{
		newMaxDamage = defMaxDamage + 1;
		SetConVarInt(hCapDamage, newMaxDamage);
	}
	
	hPdpScale = CreateConVar("pdplus_scale","1.0","Pounce damage scaling factor - pounce damage will be multiplied by this; so a value of 4 results in the same pounce doing 4 times the dmg",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	hIncapDmg = CreateConVar("pdplus_incap_dmg","1","When enabled, any extra pounce damage that would be lost when a survivor is incapped will be applied to the survivor's hp once they're downed",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	hIncapScale = CreateConVar("pdplus_incap_scale","1.0","Allows any pounce damage carried-over into a survivor's incapped health to be multiplied by this value to compensate for the 300hp incapped survivors have",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	hNotifyStyle = CreateConVar("pdplus_notify","3","How clients will be notified of pd+ events:\n\n  0 - No announcements\n  1 - Chat msg for pounces with dmg above what the game can show\n  2 - Chat msg for pounces over pdplus_notify_min\n  3 - Same as 1 but a hintbox\n  4 - Same as 2 but a hintbox",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY,true,0.0,true,4.0);
	hNotifyMin = CreateConVar("pdplus_notify_min","1","The minimum pounce damage required to trigger a pd+ notification when pdplus_notify is set to either 2 or 4",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	hNotifyAll = CreateConVar("pdplus_notify_all","1","If set to 0 notifications will only be shown to a pounce's victim and attacker; if set to 1 then pd+ notifications will be broadcast to all players.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY,true,0.0,true,1.0);
	hScaleNotify = CreateConVar("pdplus_scalenotify","1","Whether or not clients will be notified when custom damage scaling is enabled (recommended, to avoid confusion)",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY,true,0.0,true,1.0);
	hIncapNotify = CreateConVar("pdplus_incapnotify","1","Whether or not clients will be notified when a pounce causes sufficient damage to carry-over into a survivor's incapped hp",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY,true,0.0,true,1.0);
	hWelcomeText = CreateConVar("pdplus_welcome","1","If set to 1 then connecting clients will be shown a chat message explaining the features of this plugin shortly after joining the server, setting to 0 disables this message",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY,true,0.0,true,1.0);
	
	
	hStatsEnabled = CreateConVar("pdpstats_enabled","1","Setting this to 1 enables pd+ stats tracking on the server; likewise, setting it to 0 disables pd+ stats.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY,true,0.0,true,1.0);
	
	
	AutoExecConfig(true,"pouncedamageplus");
	
	
	new statsEnabled = GetConVarInt(hStatsEnabled);
	if(statsEnabled == 1)
	{
		PdpStatsInitialize();
	}
	
	
	AutoExecConfig(true,"pouncedamageplus");
	
	
	statsEnabled = GetConVarInt(hStatsEnabled);
	if(statsEnabled == 1)
	{
		PdpStatsCleanKeyfile();
	}
	
	
	HookEvent("lunge_pounce",Event_PlayerPounced);
	HookEvent("ability_use",Event_AbilityUse);
}



public Event_AbilityUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	//ability_use returns ability = ability_lunge(hunter), ability_toungue(smoker), ability_vomit(boomer)
	//ability_charge(charger and ability_spit(spitter) (weirdly nothing for jockey though ;/)
	
	new user = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//Save the location of the player who just pounced as hunter
	GetClientAbsOrigin(user,infectedPosition[user]);	
}



public Event_PlayerPounced(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Obtain supported gamemodes and the current gamemode
	new String:supportedModes[256] = "";
	GetConVarString(hSupportedModes,supportedModes,sizeof(supportedModes));
	
	new String:currentMode[32] = "";
	GetConVarString(hCurrentGamemode,currentMode,sizeof(currentMode));
	
	//Prefix and suffix both strings with 2 "," to make searching for scavenge and versus
	//(without getting false hits from teamscavenge and teamversus) easier
	new String:supModesStr[256] = "";
	Format(supModesStr,sizeof(supModesStr),",%s,",supportedModes);
	
	new String:curModeStr[32] = "";
	Format(curModeStr,sizeof(curModeStr),",%s,",currentMode);

	//if the current gamemode isn't on the lists of supported modes then just stop right here
	if(StrContains(supModesStr,curModeStr) == -1)
	{
		return false;
	}
	else
	{
		new Float:pouncePosition[3];
		new attackerId = GetEventInt(event, "userid");
		new victimId = GetEventInt(event, "victim");
		new attackerClient = GetClientOfUserId(attackerId);
		new victimClient = GetClientOfUserId(victimId);
		
		decl String:attackerName[MAX_NAME_LENGTH];
		decl String:victimName[MAX_NAME_LENGTH];
		decl String:pounceChat[256];
		decl String:pounceHint[256];
			
		//decl String:debugHealth[256];

		//Check whether stats is enabled + add one to the attackers pounce count if it is
		new statsEnabled = GetConVarInt(hStatsEnabled);
		if(statsEnabled != 0 && !IsFakeClient(attackerClient))
		PdpStatsAddPounce(attackerClient);
		
		
		//distance supplied isn't the actual 2d vector distance needed for damage calculation. See more about it at
		//http://forums.alliedmods.net/showthread.php?t=93207
		
		//get hunter-related pounce cvars
		new max = maxPounceDistance;
		new min = minPounceDistance;
		new oldCap = GetConVarInt(hMaxPounceDamage);
		oldCap++;
		
		//Get current position while pounced
		GetClientAbsOrigin(attackerClient,pouncePosition);
		
		//Calculate 2d distance between previous position and pounce position
		new distance = RoundToNearest(GetVectorDistance(infectedPosition[attackerClient], pouncePosition));
		
		//If the jump is below the min to cause pounce damage, then stop running the plugin
		if(distance < minPounceDistance)
		return true;
		
		//Get damage using hunter damage formula, done using floats for accuracy then rounded to an int (intDmg)
		new Float:dmg = (((distance - float(min)) / float(max - min)) * float(oldCap)) + 1;
		new intDmg = RoundToFloor(dmg);
		
		//Check if calculated damage is higher than default cap, and apply damage or add health to the 
		//victim as needed to acheive that total amount of damage obtained according to the plugin
			
		//First, recheck pdp_maxdmg incase its been changed since plugin load 
		//& set to default cap damage + 1 if not set/set lower than default
		new newMaxDamage = GetConVarInt(hCapDamage);
		new defMaxDamage = GetConVarInt(hMaxPounceDamage);
		
		if (newMaxDamage < (defMaxDamage + 1))
		{
			newMaxDamage = (defMaxDamage + 1);
			SetConVarInt(hCapDamage, newMaxDamage)
		}
		
		new newCap = GetConVarInt(hCapDamage);
		
		
		//This section checks pdp_scale and adjusts intDmg (into scaledDmg) appropriately using multiplication.
		//So setting pdp_scale to 5 produces 5 times greater damage for a given size pounce, likewise, setting 
		//it to 0.2 would reduce received pounce damage by a factor of 5 at a given distance
		
		new Float:fDmgScale = GetConVarFloat(hPdpScale);
		new Float:fScaledDmg = dmg * fDmgScale;
		new scaledDmg = RoundToFloor(fScaledDmg);
		
		
		//This section handles applying the corrective health changes depending on pounce scale and damage
		
		//First, store the scaled damage into cappedDmg and make sure it is not exceeding the pdp_maxdmg cap
		new cappedDmg = scaledDmg;
		if(scaledDmg > newCap)
		cappedDmg = newCap;
		
		//If stats is enabled then add damage pounce stats to users section if there is some pounce damage to add
		if(statsEnabled != 0 && !IsFakeClient(attackerClient) && cappedDmg > 0)
		PdpStatsAddDmgPounce(attackerClient,cappedDmg);
		
		//Create the extraDmg int, to make sure its blank on each run
		new extraDmg = 0;
		
		//If the dmg dealt by the game got capped then the extra dmg we need to add to the survivor is the calculated 
		//value (cappedDmg) minus the in-game cap, else we need to correct using the pre-scaling+capping intDmg value (the 
		//pounce dmg applied ingame) instead.
		if(intDmg > oldCap)
		extraDmg = cappedDmg - oldCap;
		else 
		extraDmg = cappedDmg - intDmg;
		
		
		//If the capped & scaled pounce damage will put the survivor below zero hp (incap), then store the 
		//excess (in lateDmg) for use by a timer function used to apply the extra damage after a delay
		//and, if pdplus_incap_notify != 0, set incapText to inform players of the extra damage
		new dmgIncaps = GetConVarInt(hIncapDmg);
		new realHealth = GetClientHealth(victimClient);
		
		//work out the victim's new hp
		new newRealHealth = realHealth - extraDmg;
		
		new totalHealth = realHealth;
		
		new tempHealth = GetTempHealth(victimClient);
		if(tempHealth > 0)
		{
			totalHealth = realHealth + tempHealth;
			
			new tempAdjust = 0 - newRealHealth;
			
			if(tempAdjust > 0)
			{
				new newTempHealth = tempHealth - tempAdjust;
				
				if(newTempHealth < 0)
				newTempHealth = 0;
				
				SetTempHealth(victimClient,newTempHealth);
				
				newRealHealth = 0;
			}
		}
		
		
		
		new Float:fIncapScale = GetConVarFloat(hIncapScale);
		new Float:fLateDmg = 0.0;
		
		new String:incapText[256] = "";
		new String:incapHint[256] = "";
		
		GetClientName(attackerClient,attackerName,sizeof(attackerName));
		GetClientName(victimClient,victimName,sizeof(victimName));
		
		new lateDmg = 0;
		new incapNotify = GetConVarInt(hIncapNotify);
		
		//check if the damage done puts the survivor below 0 hp (incapped) and if incap carry-over is enabled then multiply the 
		//incap carry-over by the incap-scale value and check the total dmg dealt doesn't exceed the maxdmg cap, cap it if it does
		if((totalHealth - cappedDmg) < 0 && dmgIncaps != 0)
		{
			fLateDmg = ((cappedDmg - totalHealth) * fIncapScale);
			lateDmg = RoundToFloor(fLateDmg);
			if((totalHealth + lateDmg) > newCap)
			lateDmg = newCap - totalHealth;
			
			if(incapNotify != 0)
			{
				Format(incapText,sizeof(incapText),"\n\x01[pd+] \x03%i \x04hp of excess dmg applied to \x03%s's\x04 incapped health.",lateDmg,victimName);
				Format(incapHint,sizeof(incapHint),"[pd+] %i hp of post-incap dmg done to %s",lateDmg,victimName);
			}
			
			//If stats is enabled then add damage pounce stats to users section
			if(statsEnabled != 0 && !IsFakeClient(attackerClient))
			PdpStatsAddIncapPounce(attackerClient,lateDmg);
			
			//Set a 0.15 sec timer to trigger additional damage once the survivor is downed 
			//(checks again later to verify incap damage is enabled)
			
			gLateDmg[victimClient] = lateDmg;
					
			hApplyIncapDmgTimers[victimClient] = CreateTimer(0.15, ApplyIncappedDmg, victimClient);
		}
		

		SetEntityHealth(victimClient, newRealHealth);
		
		
		//If the dmg scale isn't 1.0 then create a small message to tack onto the notifications
		new scaleNotify = GetConVarInt(hScaleNotify);
		new String:scaleText[256] = "";
		new String:scaleHint[256] = "";
		if(scaleNotify != 0 && fDmgScale != 1.0)
		{
			if(fDmgScale < 1.0)
			{
				Format(scaleText,sizeof(scaleText),"\n\x04(pd+ damage multiplier: \x03%.2f\x04)\n ",fDmgScale);
				Format(scaleHint,sizeof(scaleHint),"\n{pd+ damage multiplier: %.2f)",fDmgScale);
			}
			else
			{
				Format(scaleText,sizeof(scaleText),"\n\x04(pd+ damage multiplier: \x03%.1f\x04)\n ",fDmgScale);
				Format(scaleHint,sizeof(scaleHint),"\n{pd+ damage multiplier: %.1f)",fDmgScale);
			}
		}
		
		
		//Check what style of notifications to use
		new notifyType = GetConVarInt(hNotifyStyle);
		new notifyAll = GetConVarInt(hNotifyAll);
		new notifyMin = GetConVarInt(hNotifyMin);
		
		//NOTIFY STYLE 1: If the damage dealt is over the default cap then display a chat notification
		//NOTIFY STYLE 2: Show a chat notification for ALL pounce damage-incurring pounces
		//NOTIFY STYLE 3: Show a hint text message if the damage dealt is over the default cap
		//NOTIFY STYLE 4: Show a hint text message for all damage pounces
		if(notifyType > 0)
		{		
			if((notifyType == 1 && cappedDmg > oldCap) || (notifyType == 2 && cappedDmg >= notifyMin))
			{
				Format(pounceChat,sizeof(pounceChat),"\x01[pd+] \x03%s\x04 pounced \x03%s\x04 for \x03%i\x04 hp! %s %s",attackerName,victimName,cappedDmg,scaleText,incapText);
				
				if(notifyAll == 0)
				{
					PrintToChat(victimClient, pounceChat);
					PrintToChat(attackerClient, pounceChat);
				}
				else
				{
					PrintToChatAll(pounceChat);
				}
			}
			if((notifyType == 3 && cappedDmg > oldCap) || (notifyType == 4 && cappedDmg >= notifyMin))
			{
				if(StrEqual(scaleHint,"") && StrEqual(incapHint,""))
				{
					Format(pounceHint,sizeof(pounceHint),"[pd+] %s pounced %s for %i hp!",attackerName,victimName,cappedDmg);
				}				
				else if(StrEqual(scaleHint,"") && !StrEqual(incapHint,""))
				{
					Format(pounceHint,sizeof(pounceHint),"[pd+] %s pounced %s for %i hp!%s",attackerName,victimName,cappedDmg,incapHint);
				}
				else if(StrEqual(incapHint,"") && !StrEqual(scaleHint,""))
				{
					Format(pounceHint,sizeof(pounceHint),"[pd+] %s pounced %s for %i hp!%s",attackerName,victimName,cappedDmg,scaleHint);
				}
				else
				{
					Format(pounceHint,sizeof(pounceHint),"[pd+] %s pounced %s for %i hp!%s",attackerName,victimName,cappedDmg,scaleHint);
					
					new Handle:incapHintPack;
					
					hIncapHintTimers[attackerClient] = CreateDataTimer(6.8, ShowLatePounceHint, incapHintPack);
					
					WritePackCell(incapHintPack,attackerClient);
					WritePackCell(incapHintPack,victimClient);
					WritePackString(incapHintPack,incapHint);
				}
				
				if(notifyAll == 0)
				{
					PrintHintText(victimClient, pounceHint);
					PrintHintText(attackerClient, pounceHint);
				}
				else
				{
					PrintHintTextToAll(pounceHint);
				}
			}
		}
		return true;
	}
}



public Action:ApplyIncappedDmg(Handle:timer, any:client)
{
	new dmgIncapped = GetConVarInt(hIncapDmg);

	new lateDmg = gLateDmg[client];
		
	if(dmgIncapped != 0 && hApplyIncapDmgTimers[client] != INVALID_HANDLE)
	{
		new oldHealth = GetClientHealth(client);
		new newHealth = oldHealth - lateDmg;
		
		if(newHealth < 0)
		newHealth = 0;
	
		if(IsClientConnected(client) && IsClientInGame(client))
		SetEntityHealth(client, newHealth);
	}
	
	gLateDmg[client] = 0;
	
	hApplyIncapDmgTimers[client] = INVALID_HANDLE;

	return Plugin_Continue;
}



public Action:ShowLatePounceHint(Handle:timer, Handle:hintPack)
{
	new notifyAll = GetConVarInt(hNotifyAll);
	
	ResetPack(hintPack);
	
	new attClient = ReadPackCell(hintPack);
	new vicClient = ReadPackCell(hintPack);
	new String:lateHint[256] = "";
	
	ReadPackString(hintPack,lateHint,sizeof(lateHint));
	
	if(notifyAll == 0)
	{
		PrintHintText(vicClient, lateHint);
		PrintHintText(attClient, lateHint);
	}
	else
	{
		PrintHintTextToAll(lateHint);
	}
	
	hIncapHintTimers[attClient] = INVALID_HANDLE;
	
	return Plugin_Handled;
}



//Used to set temp health, modified from code by TheDanner.
public SetTempHealth(client, hp)
{
	if(IsClientConnected(client) && IsClientInGame(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	
		new Float:fHp = 0.0 + hp;
		
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHp);
		
		return true;
	}
	else
	{
		return false;
	}
}

//Used to get temp health, modified from code by TheDanner.
public GetTempHealth(client)
{
	if(IsClientConnected(client) && IsClientInGame(client))
	{
		new Float:fullTemp = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
		
		new Float:tempStarted = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
		
		new Float:decayRate = GetConVarFloat(FindConVar("pain_pills_decay_rate"));
		
		new Float:tempDuration = (tempStarted - GetGameTime()) * -1;
		
		new Float:fTempHp = fullTemp - (tempDuration * decayRate);
		
		new tempHp = RoundToFloor(fTempHp);
		
		if(tempHp < 0)
		tempHp = 0;
		
		return tempHp;
	}
	else
	{
		return 0;
	}
}



public Action:PdpWelcomeMsg(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	
	new client = ReadPackCell(pack);
	
	new newDmgCap = GetConVarInt(hCapDamage);
	new oldDmgCap = GetConVarInt(hMaxPounceDamage);
	oldDmgCap++;
	new incapOn = GetConVarInt(hIncapDmg);
	new Float:incapScl = GetConVarFloat(hIncapScale);
	new Float:dmgScale = GetConVarFloat(hPdpScale);
	
	
	PrintToChat(client,"\x01[pd+] \x04This server uses \x01pouncedamage+ %s \n\x03          Hunter pounce damage modification\n ",PLUGIN_VERSION)
	
	if(newDmgCap > oldDmgCap)
	{
		PrintToChat(client,"\x04Default damage cap: \x01%i \x04| \x01[pd+] \x04damage cap: \x01%i",oldDmgCap,newDmgCap)
	}
	
	
	
	if(dmgScale != 1.0)
	{
		if (dmgScale < 1.0)
		{
			PrintToChat(client,"\x04Non-default damage scaling \x03enabled\x04. (pd+ dmg multiplier: \x01%.2f\x04)",dmgScale)
		}
		else
		{
			PrintToChat(client,"\x04Non-default damage scaling \x03enabled\x04. (pd+ dmg multiplier: \x01%.1f\x04)",dmgScale)
		}
	}
	
	
	if(incapOn != 0)
	{
		if(incapScl < 1.0)
		{
			PrintToChat(client,"\x04Scaled incap carry-over dmg \x03enabled\x04. If a pounce incaps a survivor, any dmg beyond their original hp will be dealt after the incap.  This extra dmg will be multiplied by \x01%.2f\x04.",incapScl)
		}
		else if(incapScl > 1.0)
		{
			PrintToChat(client,"\x04Scaled incap carry-over dmg \x03enabled\x04. If a pounce incaps a survivor, any dmg beyond their original hp will be dealt after the incap.  This extra dmg will be multiplied by \x01%.1f\x04.",incapScl)
		}
		else
		{
			PrintToChat(client,"\x04Incap carry-over dmg \x03enabled\x04. If a pounce incaps a survivor, any dmg beyond their original hp will be dealt after the incap")
		}
	}
	
	
	hPdpWelcomeTimers[client] = INVALID_HANDLE;
}



public PdpSignWelcReg(client)
{
	new Handle:pdpwkv = CreateKeyValues("PDP Welcome Register");
	FileToKeyValues(pdpwkv, "pdpwelcomereg.txt");
	
	new String:clientAuth[32] = "";
	GetClientAuthString(client,clientAuth,sizeof(clientAuth));
	
	//For servers without steamid's, set the clientAuth to their name
	new String:clientAuthName[32] = "";
	Format(clientAuthName,sizeof(clientAuthName),"%N",client);
	if(StrEqual(clientAuth,"STEAM_1:0:0"))
	clientAuth = clientAuthName;

	
	if(KvJumpToKey(pdpwkv,clientAuth,true))
	{
		new String:dateStr[32] = "";
		FormatTime(dateStr,sizeof(dateStr),"%j-%Y");
		
		KvSetString(pdpwkv,"date",dateStr);
	}
	else
	{
		return false;
	}
	
	KvRewind(pdpwkv);
	KeyValuesToFile(pdpwkv, "pdpwelcomereg.txt");
	
	CloseHandle(pdpwkv);
	
	return true;
}

public bool:PdpSignedWelcReg(client)
{
	new Handle:pdpwkv = CreateKeyValues("PDP Welcome Register");
	FileToKeyValues(pdpwkv, "pdpwelcomereg.txt");
	
	new String:clientAuth[32] = "";
	GetClientAuthString(client,clientAuth,sizeof(clientAuth));
	
	//For servers without steamid's, set the clientAuth to their name
	new String:clientAuthName[32] = "";
	Format(clientAuthName,sizeof(clientAuthName),"%N",client);
	if(StrEqual(clientAuth,"STEAM_1:0:0"))
	clientAuth = clientAuthName;

	
	if(KvJumpToKey(pdpwkv,clientAuth))
	{
		CloseHandle(pdpwkv);
		return true;
	}
	else
	{
		CloseHandle(pdpwkv);
		return false;
	}
}



public Action:PdpStopPlugin()
{
	return Plugin_Handled;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////   ///////////////////////////////////////////////////////////////////////////////////
////////////////////////////   ///////'''//////////        ////          //////    ////          ////        //////
//////////        ////        ///////   /////////   //////////////  /////////   /  ///////  ///////   /////////////  
/////////   ///   //   ///   ///           //////        ////////  /////////  ///  //////  ////////        ////////
////////        ////        ///////   ////////////////   ///////  ////////         /////  //////////////   ////////
///////   ////////////////////////,,,//////////        ////////  ///////  ///////  ////  ////////        //////////
//////   //////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// *This section handles ALL stats-specific events + actions* //



public bool:PdpStatsInitialize()
{
	//Check if stats is enabled before proceeding
	new statsEnabled = GetConVarInt(hStatsEnabled);
	if(statsEnabled == 0)
	{
		return false;
	}
	
	//Setup all the stats convars & con cmds using handles defined globally at the start of the plugin & hook necessary game events
	hStatsMinVisits = CreateConVar("pdpstats_min_visits","3","The minimum number of visits a player needs for their stats to remain for <pdpstats_regular_timeout> days, rather than <pdpstats_guest_timeout> days after their last connect.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	hStatsSchmuckTimeout = CreateConVar("pdpstats_guest_timeout","5","The number of days a 'guest' player's stats will stay on the server from their last connect, after which they will be deleted. (0 = Never)",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	hStatsRegularTimeout = CreateConVar("pdpstats_reg_timeout","30","The number of days a player with more than <pdpstats_min_visits> connects' stats will remain after they last connected, before being deleted. (0 = Never)",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	hStatsAdminTimeout = CreateConVar("pdpstats_admin_timeout","0","The number of days an admin's stats will remain on the server after their last connect, after which they will be deleted. (0 = Never)",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	hStatsAdminFlags = CreateConVar("pdpstats_min_admin","a","Minimum admin level required for stats to be stored for <pdpstats_admin_timeout> before deletion.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	hStatsWelcomeMsgDefault = CreateConVar("pdpstats_welcome_msg_default","0","Default welcome message behaviour for clients(can be customised by the client later):\n    0 - No welcome messages\n    1 - Private welcome messages\n    2 - Public welcome messages",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	
	RegConsoleCmd("sm_pdpstats",PdpShowStatsMenu,"Displays your pd+ stats menu.");
	RegConsoleCmd("pdplus_statsme",PdpShowStatsMenu,"Displays your pd+ stats menu.");
	RegConsoleCmd("sm_pdptop",PdpShowTopMenu,"Shows the top <n> personal best pounce damage scores on the server (usage - sm_pdptop <n>).");
	RegConsoleCmd("sm_pdpwelcome",PdpWelcomeMsgToggle,"Controls how pd+ displays your welcome/stats message on connect:\n    0 - No message\n    1 - Private message (to only you)\n    2 - Public message (to all players)")
	RegConsoleCmd("sm_pdptopdelay",PdpTopDelayToggle,"Change (using sm_pdptopdelay <n>) or toggle (sm_pdptopdelay) the delay between receiving pages of the top pounces menu")

	RegServerCmd("pdpstats_clean_statsfile",PdpStatsCleanKeyfile_Cmd,"Use this to manually trigger the stats file to delete all visitors' stats that have expired.");
	RegServerCmd("pdpstats_deleteall",PdpStatsClearAll_Cmd,"Use this to clear all saved stats from the server and start fresh.");
	
	
	//Hooking of potential future stats events
	//HookEvent("hunter_punched",Event_HunterPunted);
	//HookEvent("hunter_headshot",Event_HunterSkeeted);
	
	
	//Hook the round end event for when the server empties & clean up the stats file everytime it fires
	HookEvent("round_freeze_end",Event_ServerEmptied);
	HookEvent("server_spawn",Event_ServerEmptied);
	
	//Obtain key values from the stats file, if the stats file isn't present then make a blank one.
	new Handle:pdpkv = CreateKeyValues("pdpEmpty");
	FileToKeyValues(pdpkv, "pdpstats.txt");
	new String:rootSecName[64] = "";
	KvGetSectionName(pdpkv,rootSecName,sizeof(rootSecName));
	if(!StrEqual(rootSecName,"pd+ Stats",false))
	{
		KvSetSectionName(pdpkv, "pd+ Stats");
		KvRewind(pdpkv);
		KeyValuesToFile(pdpkv, "pdpstats.txt");
	}
	
	CloseHandle(pdpkv);
	return true;
}


//Collect stats from ALL pounces (+1 to pounce count)
public bool:PdpStatsAddPounce(client)
{
	new String:clientAuth[32] = "";
	GetClientAuthString(client,clientAuth,sizeof(clientAuth));
	
	//For servers without steamid's, set the clientAuth to their name
	new String:clientAuthName[32] = "";
	Format(clientAuthName,sizeof(clientAuthName),"%N",client);
	if(StrEqual(clientAuth,"STEAM_1:0:0"))
	clientAuth = clientAuthName;
	
	new Handle:pdpkv = CreateKeyValues("pdpEmpty");
	FileToKeyValues(pdpkv, "pdpstats.txt");
	
	if(KvJumpToKey(pdpkv,clientAuth))
	{
		KvJumpToKey(pdpkv,clientAuth);
		new pouncecount = KvGetNum(pdpkv,"total pounces",0);
		pouncecount++;
		KvSetNum(pdpkv,"total pounces",pouncecount);
	}
	
	KvRewind(pdpkv);
	KeyValuesToFile(pdpkv, "pdpstats.txt");
	
	CloseHandle(pdpkv)
	
	return true;
}

//Collect stats from only DAMAGE pounces (+1 to dp count | +dmg to dmg total | check to see if dmg > than highest, replace if true)
public bool:PdpStatsAddDmgPounce(client, pouncedmg)
{
	new String:clientAuth[32] = "";
	GetClientAuthString(client,clientAuth,sizeof(clientAuth));
	
	//For servers without steamid's, set the clientAuth to their name
	new String:clientAuthName[32] = "";
	Format(clientAuthName,sizeof(clientAuthName),"%N",client);
	if(StrEqual(clientAuth,"STEAM_1:0:0"))
	clientAuth = clientAuthName;
	
	new Handle:pdpkv = CreateKeyValues("pdpEmpty");
	FileToKeyValues(pdpkv, "pdpstats.txt");
	
	if(KvJumpToKey(pdpkv,clientAuth))
	{
		KvJumpToKey(pdpkv,clientAuth);
		
		new dpcount = KvGetNum(pdpkv,"total dmg pounces",0);
		dpcount++;
		KvSetNum(pdpkv,"total dmg pounces",dpcount);
		
		new dpamount = KvGetNum(pdpkv,"total pounce dmg",0);
		dpamount = dpamount + pouncedmg;
		KvSetNum(pdpkv,"total pounce dmg",dpamount);
		
		new bestdp = KvGetNum(pdpkv,"highest dmg pounce",0);
		if(pouncedmg > bestdp)
		KvSetNum(pdpkv,"highest dmg pounce",pouncedmg);
	}
	
	KvRewind(pdpkv);
	KeyValuesToFile(pdpkv, "pdpstats.txt");
	
	CloseHandle(pdpkv)
	
	return true;
}

//Collect stats from only INCAP pounces (+1 to incap count | +dmg to incap dmg)
public bool:PdpStatsAddIncapPounce(client, incapdmg)
{
	new String:clientAuth[32] = "";
	GetClientAuthString(client,clientAuth,sizeof(clientAuth));
	
	//For servers without steamid's, set the clientAuth to their name
	new String:clientAuthName[32] = "";
	Format(clientAuthName,sizeof(clientAuthName),"%N",client);
	if(StrEqual(clientAuth,"STEAM_1:0:0"))
	clientAuth = clientAuthName;
	
	new Handle:pdpkv = CreateKeyValues("pdpEmpty");
	FileToKeyValues(pdpkv, "pdpstats.txt");
	
	if(KvJumpToKey(pdpkv,clientAuth))
	{
		KvJumpToKey(pdpkv,clientAuth);
		
		new incapcount = KvGetNum(pdpkv,"total incap pounces",0);
		incapcount++;
		KvSetNum(pdpkv,"total incap pounces",incapcount);
		
		new incapamount = KvGetNum(pdpkv,"total incap dmg",0);
		incapamount = incapamount + incapdmg;
		KvSetNum(pdpkv,"total incap dmg",incapamount);
	}
	
	KvRewind(pdpkv);
	KeyValuesToFile(pdpkv, "pdpstats.txt");
	
	CloseHandle(pdpkv)
	
	return true;
}



public Action:PdpStatsCleanKeyfile_Cmd(args)
{
	PdpStatsCleanKeyfile();
	
	PrintToServer("All expired pd+ stats data has been removed.");
	
	return Plugin_Continue;
}



//Check how many days ago each client connected against user controlled variables
//(connects til regular, days til non-regs deleted, days til regs deleted & days til admins deleted)
public PdpStatsCleanKeyfile()
{
	//Check if stats is enabled before proceeding
	new statsEnabled = GetConVarInt(hStatsEnabled);
	if(statsEnabled == 0)
	{
		return false;
	}
	
	new Handle:pdpkv = CreateKeyValues("pdpEmpty");
	FileToKeyValues(pdpkv, "pdpstats.txt");
	
	new String:curDayStr[8] = "";
	FormatTime(curDayStr,sizeof(curDayStr),"%j");
	new curDay = StringToInt(curDayStr);
	new String:curYearStr[8] = "";
	FormatTime(curYearStr,sizeof(curYearStr),"%Y");
	new curYear = StringToInt(curYearStr);
	
	new minVisits = GetConVarInt(hStatsMinVisits);
	new schmuckTimeout = GetConVarInt(hStatsSchmuckTimeout);
	new regularTimeout = GetConVarInt(hStatsRegularTimeout);
	new adminTimeout = GetConVarInt(hStatsAdminTimeout);
	
	
	//Count the # of stats sections iteratively
	KvGotoFirstSubKey(pdpkv);

	new statsEntries = 1;

	while(KvGotoNextKey(pdpkv))
	{
		statsEntries++;
	}
	
	KvRewind(pdpkv);
	KvGotoFirstSubKey(pdpkv);
	
	new statsChecked = 0;
	
	//Now check each successive section til we match the count from above, deleting those which have expired
	while(statsChecked < statsEntries)
	{
		statsChecked++;
		
		new String:lastConnStr[128] = "";
		KvGetString(pdpkv,"last connect",lastConnStr,sizeof(lastConnStr),"failed");
		
		if(!StrEqual(lastConnStr,"failed",false))
		{
			new String:lastDayStr[6], String:lastYearStr[8];
	
			lastDayStr[0] = lastConnStr[3];
			lastDayStr[1] = lastConnStr[4];
			lastDayStr[2] = lastConnStr[5];
			new lastDay = StringToInt(lastDayStr);
	
			lastYearStr[0] = lastConnStr[7];
			lastYearStr[1] = lastConnStr[8];
			lastYearStr[2] = lastConnStr[9];
			lastYearStr[3] = lastConnStr[10];
			new lastYear = StringToInt(lastYearStr);
			
			curDay = curDay + ((curYear - lastYear) * 365);
			
			new daysSinceVisit = curDay - lastDay;
			
			new isAdmin = KvGetNum(pdpkv,"is admin");
			new totalConns = KvGetNum(pdpkv,"connections");
			
			if(isAdmin == 1)
			{
				if(daysSinceVisit > adminTimeout && adminTimeout != 0)
				{
					KvDeleteThis(pdpkv);
				}
				else
				{
					KvGotoNextKey(pdpkv);
				}
			}
			else if(totalConns >= minVisits)
			{
				if(daysSinceVisit > regularTimeout && regularTimeout != 0)
				{
					KvDeleteThis(pdpkv);
				}
				else
				{
					KvGotoNextKey(pdpkv);
				}
			}
			else
			{
				if(daysSinceVisit > schmuckTimeout && schmuckTimeout != 0)
				{
					KvDeleteThis(pdpkv);
				}
				else
				{
					KvGotoNextKey(pdpkv);
				}
			}
		}
		else
		{
			KvDeleteThis(pdpkv)
		}
	}	
	
	KvRewind(pdpkv);
	KeyValuesToFile(pdpkv, "pdpstats.txt");
	CloseHandle(pdpkv)
	return true;
}



public Action:PdpStatsClearAll_Cmd(args)
{
	PdpStatsClearAll();
	
	PrintToServer("pd+ stats file cleared, all stats data has been removed.");
	
	return Plugin_Continue;
}


//Just write over the old file with a blank one to delete all
public PdpStatsClearAll()
{
	new Handle:pdpkv = CreateKeyValues("pd+ Stats");
	KeyValuesToFile(pdpkv, "pdpstats.txt");
	CloseHandle(pdpkv)
	return true;
}



//WHEN A CLIENT CONNECTS:	- Check if they have got a stats section already
//							- If not then make one, obtaining the obtainable values & setting the others to defaults (mainly zero)
//							- If the client IS a returning client then check their last connect & update their connections count &
//							  last connect data if its been more than X hours since last connecting (stops dc/rc's being counted)
//							- Check if the client wants a welcome msg and trigger the welcome msg function with a timer if required
//							- Lastly, update the 'name' & 'is admin' values for all clients just to be sure the info is current
public OnClientPostAdminCheck(client)
{
	//Obtain supported gamemodes and the current gamemode
	new String:supportedModes[256] = "";
	GetConVarString(hSupportedModes,supportedModes,sizeof(supportedModes));
	
	new String:currentMode[32] = "";
	GetConVarString(hCurrentGamemode,currentMode,sizeof(currentMode));
	
	//Prefix and suffix both strings with 2 "," to make searching for scavenge and versus
	//(without getting false hits from teamscavenge and teamversus) easier
	new String:supModesStr[256] = "";
	Format(supModesStr,sizeof(supModesStr),",%s,",supportedModes);
	
	new String:curModeStr[32] = "";
	Format(curModeStr,sizeof(curModeStr),",%s,",currentMode);

	new statsEnabled = GetConVarInt(hStatsEnabled);
	
	new pdpWelcMsg = GetConVarInt(hWelcomeText);
	
	//Check if stats is enabled & that our client is both still connected and not a bot & also 
	//if the current gamemode is supported before proceeding
	if(IsFakeClient(client) || !IsClientConnected(client) || (StrContains(supModesStr,curModeStr) == -1))
	{
		//Do nothing if the connecting player is a bot, has left already or we're not playing a pd+ supported gamemode right now
	}
	else if(statsEnabled == 0)
	{
		if(pdpWelcMsg != 0)
		{
			if(!PdpSignedWelcReg(client))
			{
				PdpSignWelcReg(client);
				
				if(PdpSignedWelcReg(client))
				{
					new Handle:pdpWelcPack;
					hPdpWelcomeTimers[client] = CreateDataTimer(45.0,PdpWelcomeMsg,pdpWelcPack);
					WritePackCell(pdpWelcPack,client);
				}
			}
			PdpSignWelcReg(client);
		}
	}
	else
	{
		if(pdpWelcMsg != 0)
		{
			if(!PdpSignedWelcReg(client))
			{
				PdpSignWelcReg(client);
				
				if(PdpSignedWelcReg(client))
				{
					new Handle:pdpWelcPack;
					hPdpWelcomeTimers[client] = CreateDataTimer(45.0,PdpWelcomeMsg,pdpWelcPack);
					WritePackCell(pdpWelcPack,client);
				}
			}
			PdpSignWelcReg(client);
		}
	
	
		new String:clientAuth[32] = "";
		GetClientAuthString(client,clientAuth,sizeof(clientAuth));
	
		//For servers without steamid's, set the clientAuth to their name
		new String:clientAuthName[32] = "";
		Format(clientAuthName,sizeof(clientAuthName),"%N",client);
		if(StrEqual(clientAuth,"STEAM_1:0:0"))
		clientAuth = clientAuthName;

		new Handle:pdpkv = CreateKeyValues("pdpEmpty");
		FileToKeyValues(pdpkv, "pdpstats.txt");
		KvRewind(pdpkv);
			
		if(!KvJumpToKey(pdpkv,clientAuth,false))
		{
			KvJumpToKey(pdpkv,clientAuth,true);
			
			new String:clientName[32] = "nonamefool";
			GetClientName(client,clientName,sizeof(clientName));
			KvSetString(pdpkv,"name",clientName);
			
			KvSetNum(pdpkv,"connections",1);
			
			new String:minAdminLvl[128] = "";
			GetConVarString(hStatsAdminFlags,minAdminLvl,sizeof(minAdminLvl));
			if(GetUserFlagBits(client) >= ReadFlagString(minAdminLvl))
			{
				KvSetNum(pdpkv,"is admin",1);
			}
			else
			{
				KvSetNum(pdpkv,"is admin",0);
			}
			
			new String:clientLastConn[128] = "";
			FormatTime(clientLastConn,sizeof(clientLastConn),"%H-%j-%Y-%a %b %d, %Y at %I:%M %p");
			KvSetString(pdpkv,"last connect",clientLastConn);
			
			new statsWelcDef = GetConVarInt(hStatsWelcomeMsgDefault);
			KvSetNum(pdpkv,"welcome msgs",statsWelcDef);
			
			KvSetNum(pdpkv,"total pounces",0);
			KvSetNum(pdpkv,"total dmg pounces",0);
			KvSetNum(pdpkv,"total pounce dmg",0);
			KvSetNum(pdpkv,"total incap pounces",0);
			KvSetNum(pdpkv,"total incap dmg",0);
			KvSetNum(pdpkv,"highest dmg pounce",0);

			new Handle:cmdInfoPack;
			hStatsCmdInfoTimers[client] = CreateDataTimer(20.0, PdpStatsCmdInfoMsg, cmdInfoPack);
			WritePackCell(cmdInfoPack, client);
		}
		else
		{
			KvRewind(pdpkv);
			KvJumpToKey(pdpkv,clientAuth);
		
			new String:lastConnStr[128] = "";
			KvGetString(pdpkv,"last connect",lastConnStr,sizeof(lastConnStr),"00-000-0000-Never");
			
			new timeTilNewVisit = 2;
			
			new String:lastHourStr[2], String:lastDayStr[3];
			
			lastHourStr[0] = lastConnStr[0];
			lastHourStr[1] = lastConnStr[1];
			new lastHour = StringToInt(lastHourStr);
			
			lastDayStr[0] = lastConnStr[3];
			lastDayStr[1] = lastConnStr[4];
			lastDayStr[2] = lastConnStr[5];
			new lastDay = StringToInt(lastDayStr);
			
			new String:curHourStr[6], String:curDayStr[8];
			
			FormatTime(curHourStr,sizeof(curHourStr),"%H");
			new curHour = StringToInt(curHourStr);
			
			FormatTime(curDayStr,sizeof(curDayStr),"%j");
			new curDay = StringToInt(curDayStr);
			
			if(curDay < lastDay)
			curDay = curDay + 365;
			new hourDays = curDay - lastDay;
			
			new hourDiff = ((curHour - lastHour) + (hourDays * 24));
			
			if(hourDiff > timeTilNewVisit)
			{
			
				//Check if the client wants a welcome msg, if they do, trigger a timer and send the appropriate data to the callback
				new statsWelcDef = GetConVarInt(hStatsWelcomeMsgDefault);
				
				new welcomeStyle = KvGetNum(pdpkv,"welcome msgs",statsWelcDef);
				new Handle:welcomePack;
				
				if(welcomeStyle == 1)
				{
					hStatsWelcomeTimers[client] = CreateDataTimer(12.0, PdpStatsWelcomeMsg, welcomePack);
					WritePackCell(welcomePack, client);
					WritePackString(welcomePack,"User");
				}
				else if(welcomeStyle == 2)
				{
					hStatsWelcomeTimers[client] = CreateDataTimer(12.0, PdpStatsWelcomeMsg, welcomePack);
					WritePackCell(welcomePack, client);
					WritePackString(welcomePack,"All");
				}
				else
				{
					new connCount = KvGetNum(pdpkv,"connections",1);
					connCount++;
					KvSetNum(pdpkv,"connections",connCount);
					
					new String:clientLastConn[128] = "";
					FormatTime(clientLastConn,sizeof(clientLastConn),"%H-%j-%Y-%a %b %d, %Y at %I:%M %p");
					KvSetString(pdpkv,"last connect",clientLastConn);
					
					//Show the client the client cmd info text if they've not been here 3+ times yet
					if(connCount < 4)
					{
						new Handle:cmdInfoPack;
						hStatsCmdInfoTimers[client] = CreateDataTimer(20.0, PdpStatsCmdInfoMsg, cmdInfoPack);
						WritePackCell(cmdInfoPack, client);
					}
				}
			}			
		}
		
		//Reset everyone's name and admin flags regardless
		KvRewind(pdpkv);
		KvJumpToKey(pdpkv,clientAuth);
		
		new String:clientName[32] = "nonamefool";
		GetClientName(client,clientName,sizeof(clientName));
		KvSetString(pdpkv,"name",clientName);
		
		new String:minAdminLvl[128] = "";
		GetConVarString(hStatsAdminFlags,minAdminLvl,sizeof(minAdminLvl));
		if(GetUserFlagBits(client) >= ReadFlagString(minAdminLvl))
		{
			KvSetNum(pdpkv,"is admin",1);
		}
		else
		{
			KvSetNum(pdpkv,"is admin",0);
		}
		
		KvRewind(pdpkv);
		KeyValuesToFile(pdpkv, "pdpstats.txt");
		
		CloseHandle(pdpkv)
	}
}



//Timer kills for OnClientDisconnect
public OnClientDisconnect(client)
{
	//If the client was set to receive incap dmg then kill the timer for it if they leave before it is dealt
	if (hApplyIncapDmgTimers[client] != INVALID_HANDLE)
	{
		KillTimer(hApplyIncapDmgTimers[client]);
		hApplyIncapDmgTimers[client] = INVALID_HANDLE;
	}
	
	//If the client was set to receive an extra incap dmg hintbox then kill the timer for it if they leave before it is sent
	if (hIncapHintTimers[client] != INVALID_HANDLE)
	{
		KillTimer(hIncapHintTimers[client]);
		hIncapHintTimers[client] = INVALID_HANDLE;
	}
	
	//If the client had a welcome msg on its way then kill the timer for it if they leave before it arrives
	if (hPdpWelcomeTimers[client] != INVALID_HANDLE)
	{
		KillTimer(hPdpWelcomeTimers[client]);
		hPdpWelcomeTimers[client] = INVALID_HANDLE;
	}
	
	//If the client had a stats welcome msg on its way then kill the timer for it if they leave before it arrives
	if (hStatsWelcomeTimers[client] != INVALID_HANDLE)
	{
		KillTimer(hStatsWelcomeTimers[client]);
		hStatsWelcomeTimers[client] = INVALID_HANDLE;
	}
	
	//If the client had an info msg on its way then kill the timer for it if they leave before it arrives
	if (hStatsCmdInfoTimers[client] != INVALID_HANDLE)
	{
		KillTimer(hStatsCmdInfoTimers[client]);
		hStatsCmdInfoTimers[client] = INVALID_HANDLE;
	}
	
	//If the client had a page of a top menu on its way then kill the timer for it if they leave before it arrives
	if (hStatsTopMenuTimers[client] != INVALID_HANDLE)
	{
		KillTimer(hStatsTopMenuTimers[client]);
		hStatsTopMenuTimers[client] = INVALID_HANDLE;
		
		gPdpTopMenuActive[client] = 0;
	}
}



public Action:PdpShowStatsMenu(client, args)
{
	//Check if stats is enabled before proceeding
	new statsEnabled = GetConVarInt(hStatsEnabled);
	if(statsEnabled == 0)
	{
		return Plugin_Handled;
	}
	
	if (!IsClientConnected(client) && !IsClientInGame(client))
	return Plugin_Handled;

	
	
	//obtain all the necessary infos from the user's keyfile section
	//and print each piece to chat as a formatted msg
	new String:clientAuth[32] = "";
	GetClientAuthString(client,clientAuth,sizeof(clientAuth));
	
	//For servers without steamid's, set the clientAuth to their name
	new String:clientAuthName[32] = "";
	Format(clientAuthName,sizeof(clientAuthName),"%N",client);
	if(StrEqual(clientAuth,"STEAM_1:0:0"))
	clientAuth = clientAuthName;

	
	new Handle:pdpkv = CreateKeyValues("pdpEmpty");
	FileToKeyValues(pdpkv, "pdpstats.txt");
	KvJumpToKey(pdpkv,clientAuth,true)

	
	new String:clientName[32] = "";
	KvGetString(pdpkv,"name",clientName,sizeof(clientName),"Nameless");
	PrintToChat(client,"\x01[pd+] \x05Hunter Pounce Stats for \x03%s\x01",clientName);
	
	
	new highestDmg = KvGetNum(pdpkv,"highest dmg pounce",0);
	PrintToChat(client,"\x04Highest Damage Pounce:          \x01%i",highestDmg);

	
	new totalPounces = KvGetNum(pdpkv,"total pounces",0);
	PrintToChat(client,"\x04Total Pounces Landed:           \x01%i",totalPounces);
	
	
	new totalDPs = KvGetNum(pdpkv,"total dmg pounces",0);
	PrintToChat(client,"\x04Total Damage Pounces Landed:    \x01%i",totalDPs);
	
	
	new totalDmg = KvGetNum(pdpkv,"total pounce dmg",0);
	PrintToChat(client,"\x04Total Pounce Damage Dealt:      \x01%i",totalDmg);

	
	new totalIncaps = KvGetNum(pdpkv,"total incap pounces",0);
	PrintToChat(client,"\x04Total Incaps by Pounce Dmg:     \x01%i",totalIncaps);
	
	
	//Only obtain incap dmg info for clients if incap dmg is actually enabled
	new incapDmgOn = GetConVarInt(hIncapDmg);
	if(incapDmgOn != 0)
	{
		new incapDmg = KvGetNum(pdpkv,"total incap dmg",0);
		PrintToChat(client,"\x04Total Incap Carryover Dmg Done: \x01%i",incapDmg);
	}
	
	CloseHandle(pdpkv);
	
	return Plugin_Continue;
}



//Contract drawing of the entries after 5 out to a subfunction which initiates a timer after entering each successive 
//5 stats with 2 blank rows above them [this ensures it fills the 7 row chat box while it can stay onscreen thru 2 more 
//lines of text] loop this subfunction on a ~7 second timer to send them as many stats as they ask for, one panel at a
//time, with a ~7 sec pause for them to read in between.

public Action:PdpShowTopMenu(client, args)
{
	//Check if stats is enabled before proceeding
	new statsEnabled = GetConVarInt(hStatsEnabled);
	if(statsEnabled == 0)
	{
		return Plugin_Handled;
	}
	
	if (!IsClientConnected(client) && !IsClientInGame(client))
	return Plugin_Handled;
	
	if(gPdpTopMenuActive[client] == 1)
	{
		PrintToChat(client,"/x01[pd+] \x04You currently have an active top pounce menu, please wait until it has completed before requesting another.");
		return Plugin_Handled;
	}
	
	//First we need to count all the entries in the statsfile to work out a size 
	//for the array which will be used for storing and sorting the values
	new Handle:pdpkv = CreateKeyValues("pdpEmpty");
	FileToKeyValues(pdpkv, "pdpstats.txt");
	
	KvGotoFirstSubKey(pdpkv);
	
	new statsEntries = 1;

	while(KvGotoNextKey(pdpkv))
	{
		statsEntries++;
	}
	
	//Then make an array of the correct size with 2 'columns' and store
	//the section id (symbol) in column 0 and the highest dmg pounce in column 1
	//for each user's stats section from the stats file
	new pounceArr[statsEntries][2];
	new arrPos = 0;
	
	KvRewind(pdpkv);
	KvGotoFirstSubKey(pdpkv);
	
	KvGetSectionSymbol(pdpkv,pounceArr[arrPos][0]);
	
	pounceArr[arrPos][1] = KvGetNum(pdpkv,"highest dmg pounce",0);
	
	while(KvGotoNextKey(pdpkv))
	{
		arrPos++;
		
		//KvGotoNextKey(pdpkv);
		
		KvGetSectionSymbol(pdpkv,pounceArr[arrPos][0]);
		
		pounceArr[arrPos][1] = KvGetNum(pdpkv,"highest dmg pounce",0);
	}
	
	//We now need to pass this array through a sorting function using SortCustom2D
	//to arrange the section ids in descending order of highest pounce
	
	SortCustom2D(pounceArr,statsEntries,TopDPsSortFunc);
	
	//Then check thats there IS over <n> entries (n being the top <n> number entered
	//by the client), if not, then list all and explain to the client that there's only
	//x stats entries available
	new String:topNoStr[4] = "";
	GetCmdArg(1,topNoStr,sizeof(topNoStr));
	
	//Default to top 10 if they don't input a value for <n>
	if(StrEqual(topNoStr,""))
	topNoStr = "10";
	new topNo = StringToInt(topNoStr);
	
	new String:tooFewStats[128] = "";
	
	//Give the user a message at the bottom of the list if there aren't as many stats as they asked for
	if(topNo > statsEntries)
	{
		tooFewStats = "\x01No more stats entries available.";
		topNo = statsEntries;
	}
	
	//Print to chat what will serve as a menu title
	PrintToChat(client,"\x01[pd+] \x05Pouncedamage Personal Bests \x01[Top %i]\n ",topNo);
	
	//Setup the data pack ready to be sent to the paginating timer function
	new Handle:topPack;
	
	//Check what delay the client wants to use and then setup a repeating timer using that delay
	//if no delay specified in keyvalues then give default and send an info msg
	new String:clientAuth[32] = "";
	GetClientAuthString(client,clientAuth,sizeof(clientAuth));
	
	//For servers without steamid's, set the clientAuth to their name
	new String:clientAuthName[32] = "";
	Format(clientAuthName,sizeof(clientAuthName),"%N",client);
	if(StrEqual(clientAuth,"STEAM_1:0:0"))
	clientAuth = clientAuthName;

	
	KvRewind(pdpkv);
	KvJumpToKey(pdpkv,clientAuth);
	
	new Float:fTopDelay = KvGetFloat(pdpkv,"top menu delay",98723.4561);
	
	//if no top delay key value found then assume default of 10 & tag the pack
	//@ position 4 to let the timer function know to tack a message about 
	//!pdptopdelay onto the end of the list of stats.
	new topDlyMsg = 0;
	if(fTopDelay == 98723.4561)
	{
		topDlyMsg = 1;
		KvSetFloat(pdpkv,"top menu delay",10.0);
		
		KvRewind(pdpkv);
		KeyValuesToFile(pdpkv, "pdpstats.txt");
		
		fTopDelay = 10.0;
	}
	
	//Create the datapack & timer to draw each successive 5 entries, repeating with the delay obtained earlier
	hStatsTopMenuTimers[client] = CreateDataTimer(fTopDelay,PdpStatsBuildTopBy5,topPack,TIMER_REPEAT);
	
	
	WritePackCell(topPack,client);
	WritePackCell(topPack,topNo);
	
	if(!StrEqual(tooFewStats,""))
	WritePackCell(topPack,1);
	else
	WritePackCell(topPack,0);
	
	if(topDlyMsg == 1)
	{
		WritePackCell(topPack,1);
	}
	else
	{
		WritePackCell(topPack,0);
	}
	
	//setup any vars we will need during the iterative top <n> menu building process & send the keyvalues bk to root
	new arrPos2 = 0;
	new keyId = 0;

	
	
	//build the menu by collecting name & high pounce values from the keyfile, using the section
	//symbols retrieved (in order) from the pounceArr array, and printing them to chat as consecutive
	//formatted messages, do this until the # of stats requested [or the max available] are listed.
	while(arrPos2 < topNo)
	{
		keyId = pounceArr[arrPos2][0];
		
		WritePackCell(topPack,keyId);
		arrPos2++;
	}
	
	gTopPos[client] = 0;
	
	//Draw the first 5 entries
	PdpStatsDrawTop5(topPack);
	
	CloseHandle(pdpkv);
	
	return Plugin_Handled;
}


//Custom sort function to sort the integers stored in the 2nd 'column' (pos [][1]) of a 2D array 
public TopDPsSortFunc(elem1[], elem2[], array[][], Handle:data)
{
	if(elem1[1] < elem2[1])
	return 1;
	else if(elem1[1] > elem2[1])
	return -1;
	else
	return 0;
}



public Action:PdpStatsDrawTop5(Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new topNo = ReadPackCell(pack);
	new tooFew = ReadPackCell(pack);
	new delayMsg = ReadPackCell(pack);
	
	gPdpTopMenuActive[client] = 1;
	
	new Handle:pdpkv = CreateKeyValues("pdpEmpty");
	FileToKeyValues(pdpkv, "pdpstats.txt");
		
	new packPos = 0;
	new keyId;
		
	new i = 0;
	new String:playerName[64] = "";
	new bestDP = 0;	
	
	while(i < 5 && packPos <= topNo)
	{
		i++;
		packPos++;
		
		keyId = ReadPackCell(pack);
		
		KvRewind(pdpkv);
		KvJumpToKeySymbol(pdpkv,keyId);
		
		KvGetString(pdpkv,"name",playerName,sizeof(playerName),"unnamed");
		
		bestDP = KvGetNum(pdpkv,"highest dmg pounce",0);
		
		PrintToChat(client,"\x04%i) \x03%s \x04- \x01%i dmg",packPos,playerName,bestDP);
	}
	
	gTopPos[client] = packPos;
	
	CloseHandle(pdpkv);
	
	if(gTopPos[client] >= topNo)
	{
		if(tooFew == 1)
		PrintToChat(client,"\x01No more stats entries available.");
		if(delayMsg == 1)
		PrintToChat(client,"\x04Type \x03!pdptopdelay <n>\x04 in chat to change the delay between pages");
		gTopPos[client] = 0;
		
		gPdpTopMenuActive[client] = 0;
		
		hStatsTopMenuTimers[client] = INVALID_HANDLE;
		
		return Plugin_Stop;		
	}
	else
	{
		return Plugin_Continue;
	}
}




public Action:PdpStatsBuildTopBy5(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new topNo = ReadPackCell(pack);
	new tooFew = ReadPackCell(pack);
	new delayMsg = ReadPackCell(pack);

	new Handle:pdpkv = CreateKeyValues("pdpEmpty");
	FileToKeyValues(pdpkv, "pdpstats.txt");
	
	//Obtain the client's current position in their top 10 menu, as stored in gTopPos [1st name is pos 1]
	new startPos = gTopPos[client];
	
	new packPos = 0;
	new keyId;
	
	//Obtain the cell values into keyId until we reach the first one we're after
	while(packPos<startPos)
	{
		packPos++;
		keyId = ReadPackCell(pack);
	}
	
	new i = 0;
	new String:playerName[64] = "";
	new bestDP = 0;
	
	//Add two blank lines at the top to fill the 7-line chat box [if it's not the first page of the list]
	if(gTopPos[client] > 1)
	{
		PrintToChat(client,"  ");
		PrintToChat(client,"  ");
	}
		
	while(i < 5 && packPos < topNo)
	{
		i++;
		packPos++;
		
		keyId = ReadPackCell(pack);
		
		KvRewind(pdpkv);
		KvJumpToKeySymbol(pdpkv,keyId);
		
		KvGetString(pdpkv,"name",playerName,sizeof(playerName),"unnamed");
		
		bestDP = KvGetNum(pdpkv,"highest dmg pounce",0);
		
		PrintToChat(client,"\x04%i) \x03%s \x04- \x01%i dmg",packPos,playerName,bestDP);
	}
	
	gTopPos[client] = packPos;
	
	CloseHandle(pdpkv);
	
	if(gTopPos[client] >= topNo)
	{
		if(tooFew == 1)
		PrintToChat(client,"\x01No more stats entries available.");
		if(delayMsg == 1)
		PrintToChat(client,"\x04Type \x03!pdptopdelay <n>\x04 in chat to change the delay between pages");
		
		
		//Add in some extra blank rows to fill the chatbox if the list is gonna end 
		//this time and there's not gonna be enough entries to fill up the chatbox
		new extraRows = 5 - i;
		
		if(tooFew == 1)
		extraRows = extraRows - 1;
		if(delayMsg == 1)
		extraRows = extraRows - 2;
		
		if(extraRows < 0)
		extraRows = 0;
		
		new i2 = 0;
		
		while(i2 < extraRows)
		{
			i2++;
			PrintToChat(client,"  ");
		}
		
		
		gTopPos[client] = 0;
		
		gPdpTopMenuActive[client] = 0;
		
		hStatsTopMenuTimers[client] = INVALID_HANDLE;
		
		return Plugin_Stop;		
	}
	else
	{
		return Plugin_Continue;
	}
}


public Action:PdpTopDelayToggle(client, args)
{
	new String:clientAuth[32] = "";
	GetClientAuthString(client,clientAuth,sizeof(clientAuth));
	
	//For servers without steamid's, set the clientAuth to their name
	new String:clientAuthName[32] = "";
	Format(clientAuthName,sizeof(clientAuthName),"%N",client);
	if(StrEqual(clientAuth,"STEAM_1:0:0"))
	clientAuth = clientAuthName;

	new Handle:pdpkv = CreateKeyValues("pdpEmpty");
	FileToKeyValues(pdpkv, "pdpstats.txt");
	if(KvJumpToKey(pdpkv,clientAuth))
	{
		KvJumpToKey(pdpkv,clientAuth);
		
		new String:argStr[8] = "";
		GetCmdArg(1,argStr,sizeof(argStr));
		
		new Float:delaySet;
		
		//If they give a number to set it to then do that, if not then increment current value by 1
		if(!StrEqual(argStr,""))
		{
			if(StrEqual(argStr,"<n>"))
			{
				PrintToChat(client,"\x04You are an idiot, \x01<n> \x04means 'put a number here', i.e. \x03!pdptopdelay 10\x04. Try again...");
				return Plugin_Handled;
			}
			else
			delaySet = StringToFloat(argStr);
		}
		else
		{
			new Float:oldDelay = KvGetFloat(pdpkv,"top menu delay",98723.4561);
			
			if(oldDelay <= 1.0)
			delaySet = 2.5;
			else if(oldDelay <= 2.5)
			delaySet = 5.0;
			else if(oldDelay <= 5.0)
			delaySet = 7.5;
			else if(oldDelay <= 7.5)
			delaySet = 10.0;
			else if(oldDelay <= 10.0)
			delaySet = 12.5;
			else if(oldDelay <= 12.5)
			delaySet = 15.0;
			else if(oldDelay <= 15.0)
			delaySet = 20.0;
			else if(oldDelay > 15.0)
			delaySet = 1.0;
		}
		
		KvSetFloat(pdpkv,"top menu delay",delaySet);
		
		new Float:delayDPCheck = RoundToFloor(delaySet) + 0.0;
		
		//Give the client some feedback via chat so they know whats going on
		if(delayDPCheck == delaySet)
		{
			PrintToChat(client,"\x01[pd+] \x04Top pounce menu page delay set to: \x03%.0f \x04secs.",delaySet);
		}
		else
		{
			PrintToChat(client,"\x01[pd+] \x04Top pounce menu page delay set to: \x03%.1f \x04secs.",delaySet);
		}
		
		KvRewind(pdpkv);
		KeyValuesToFile(pdpkv,"pdpstats.txt");
	}
	CloseHandle(pdpkv)
	return Plugin_Handled;
}



public Action:PdpStatsWelcomeMsg(Handle:timer, Handle:pack)
{
	//Check if stats is enabled before proceeding
	new statsEnabled = GetConVarInt(hStatsEnabled);
	if(statsEnabled == 0)
	{
		return Plugin_Handled;
	}
	
	new client;
	new String:recipient[16] = "";
	
	ResetPack(pack);
	client = ReadPackCell(pack);
	ReadPackString(pack,recipient,sizeof(recipient));
	
	//obtain the necessary infos (name, last connect, # dmg pounces & total pounce dmg) from the user's keyfile section
	new String:clientAuth[32] = "";
	GetClientAuthString(client,clientAuth,sizeof(clientAuth));
	
	//For servers without steamid's, set the clientAuth to their name
	new String:clientAuthName[32] = "";
	Format(clientAuthName,sizeof(clientAuthName),"%N",client);
	if(StrEqual(clientAuth,"STEAM_1:0:0"))
	clientAuth = clientAuthName;

	
	new Handle:pdpkv = CreateKeyValues("pdpEmpty");
	FileToKeyValues(pdpkv, "pdpstats.txt");
	KvJumpToKey(pdpkv,clientAuth,true)
	
	new String:clientName[32] = "";
	KvGetString(pdpkv,"name",clientName,sizeof(clientName),"Nameless");
	
	new String:lastConnFull[128] = "";
	KvGetString(pdpkv,"last connect",lastConnFull,sizeof(lastConnFull),"X-X-X-Never");
	
	decl String:lastConnArr[5][64];
	ExplodeString(lastConnFull,"-",lastConnArr,sizeof(lastConnArr),sizeof(lastConnArr[]));
	new String:lastConnText[64] = "";
	Format(lastConnText,sizeof(lastConnText),"%s",lastConnArr[3]);
	
	new dpCount = KvGetNum(pdpkv,"total dmg pounces",0);
	
	new totalDmg = KvGetNum(pdpkv,"total pounce dmg",0);
	
	//Format the welcome message, its the same for private & public broadcast
	new String:welcomeMsg[256] = "";
	Format(welcomeMsg,sizeof(welcomeMsg),"\x01[pd+] \x05Welcome back \x03%s\x05! Last connected:\n            \x01%s.\x04\nTotal dmg pounces: \x01%i  \x05||\x04  Total pounce dmg done: \x01%i \n  ",clientName,lastConnText,dpCount,totalDmg);
	
	//send formatted msg to user only
	if(StrEqual(recipient,"User",false))
	{
		PrintToChat(client,welcomeMsg);
	}
	//send formatted msg to all
	else if(StrEqual(recipient,"All",false))
	{
		PrintToChatAll(welcomeMsg);
	}
		
	new connCount = KvGetNum(pdpkv,"connections",0);
	connCount++;
	KvSetNum(pdpkv,"connections",connCount);
	
	new String:clientLastConn[128] = "";
	FormatTime(clientLastConn,sizeof(clientLastConn),"%H-%j-%Y-%a %b %d, %Y at %I:%M %p");
	KvSetString(pdpkv,"last connect",clientLastConn);
	
	
	//Check if they've been connected more than 3 times, if not then send them the client cmd info text 12s after this welcome msg
	if(connCount < 4)
	{
		new Handle:cmdInfoPack;
		hStatsCmdInfoTimers[client] = CreateDataTimer(12.0, PdpStatsCmdInfoMsg, cmdInfoPack);
		WritePackCell(cmdInfoPack, client);
	}
	
	KvRewind(pdpkv);
	KeyValuesToFile(pdpkv, "pdpstats.txt");
	
	hStatsWelcomeTimers[client] = INVALID_HANDLE;
	CloseHandle(pdpkv)
	return Plugin_Handled;
}


public Action:PdpWelcomeMsgToggle(client, args)
{
	new String:clientAuth[32] = "";
	GetClientAuthString(client,clientAuth,sizeof(clientAuth));
	
	//For servers without steamid's, set the clientAuth to their name
	new String:clientAuthName[32] = "";
	Format(clientAuthName,sizeof(clientAuthName),"%N",client);
	if(StrEqual(clientAuth,"STEAM_1:0:0"))
	clientAuth = clientAuthName;

	new Handle:pdpkv = CreateKeyValues("pdpEmpty");
	FileToKeyValues(pdpkv, "pdpstats.txt");
	if(KvJumpToKey(pdpkv,clientAuth))
	{
		KvJumpToKey(pdpkv,clientAuth);
		
		new String:argStr[8] = "";
		GetCmdArg(1,argStr,sizeof(argStr));
		
		new welcSet;
		
		//If they give a number to set it to then do that, if not then increment current value by 1
		if(!StrEqual(argStr,""))
		{
			welcSet = StringToInt(argStr);
		}
		else
		{
			new oldWelc = KvGetNum(pdpkv,"welcome msgs",1);
			
			oldWelc++;
			if(oldWelc > 2) oldWelc = 0;
			
			welcSet = oldWelc;
		}
		
		KvSetNum(pdpkv,"welcome msgs",welcSet);
		
		//Give the client some feedback via chat so they know whats going on
		if(welcSet == 0)
		{
			PrintToChat(client,"\x01[pd+] \x04Welcome messages disabled.");
		}
		else if(welcSet == 1)
		{
			PrintToChat(client,"\x01[pd+] \x04Welcome messages set to private.");
		}
		else if(welcSet == 2)
		{
			PrintToChat(client,"\x01[pd+] \x04Welcome messages set to public.");
		}
		else
		{
			PrintToChat(client,"\x03[pd+] \x04Invalid value for welcome msg setting entered.\n  Acceptable values are: 0 - Disabled, 1 - Public or 2 - Private");
			new welcDef = GetConVarInt(hStatsWelcomeMsgDefault);
			KvSetNum(pdpkv,"welcome msgs",welcDef);
		}
		
		KvRewind(pdpkv);
		KeyValuesToFile(pdpkv,"pdpstats.txt");
	}
	CloseHandle(pdpkv)
	return Plugin_Handled;
}


public Action:PdpStatsCmdInfoMsg(Handle:timer, Handle:pack)
{
	new client;	
	ResetPack(pack);
	client = ReadPackCell(pack);
	
	PrintToChat(client,"\x01[pd+] \x04This server runs \x01pouncedamage+ %s \x04 w/ stats ON. \nType \x03!pdpstats \x04in chat to see your stats.",PLUGIN_VERSION);
	PrintToChat(client,"\x04Type \x03!pdptop <n> \x04to see the top <n> best damage pounces \nType \x03!pdpwelcome \x04to toggle pd+ welcome messages.");
}


public Event_ServerEmptied(Handle:event, const String:name[], bool:dontBroadcast)
{
	PdpStatsCleanKeyfile();
}



/*

public Event_HunterPunted(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Check if stats is enabled before proceeding
	new statsEnabled = GetConVarInt(hStatsEnabled);
	if(statsEnabled == 0)
	{
		return Plugin_Handled;
	}

	new bool:gotDenied = GetEventBool(event, "islunging");
	if(gotDenied == true)
	{
		new hunterId = GetEventInt(event, "hunterid");
		new String:hunterSteamId[32] = "";
		GetClientAuthString(hunterId,hunterSteamId,sizeof(hunterSteamId));
		new punterId = GetEventInt(event, "userid");
		new String:punterSteamId[32] = "";
		GetClientAuthString(punterId,punterSteamId,sizeof(punterSteamId));
		new String:deniedDebug[256] = "";
		Format(deniedDebug,sizeof(deniedDebug),"\x03[pd+ debug]\x02 %s\x04 got PUNTED by \x02%s!",hunterSteamId,punterSteamId);
		PrintToChatAll(deniedDebug);
	}
	else
	{
		new hunterId = GetEventInt(event, "hunterid");
		new String:hunterSteamId[32] = "";
		GetClientAuthString(hunterId,hunterSteamId,sizeof(hunterSteamId));
		new punterId = GetEventInt(event, "userid");
		new String:punterSteamId[32] = "";
		GetClientAuthString(punterId,punterSteamId,sizeof(punterSteamId));
		new String:deniedDebug[256] = "";
		Format(deniedDebug,sizeof(deniedDebug),"\x03[pd+ debug]\x02 %s\x04 got PUNTED by \x02%s! islunging failed",hunterSteamId,punterSteamId);
		PrintToChatAll(deniedDebug);
	}
}

public Event_HunterSkeeted(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Check if stats is enabled before proceeding
	new statsEnabled = GetConVarInt(hStatsEnabled);
	if(statsEnabled == 0)
	{
		return Plugin_Handled;
	}

	new bool:gotDenied = GetEventBool(event, "islunging");
	if(gotDenied == true)
	{
		new hunterId = GetEventInt(event, "hunterid");
		new String:hunterSteamId[32] = "";
		GetClientAuthString(hunterId,hunterSteamId,sizeof(hunterSteamId));
		new punterId = GetEventInt(event, "userid");
		new String:punterSteamId[32] = "";
		GetClientAuthString(punterId,punterSteamId,sizeof(punterSteamId));
		new String:deniedDebug[256] = "";
		Format(deniedDebug,sizeof(deniedDebug),"\x03[pd+ debug]\x02 %s\x04 got SKEETED by \x02%s!",hunterSteamId,punterSteamId);
		PrintToChatAll(deniedDebug);
	}
	else
	{
		new hunterId = GetEventInt(event, "hunterid");
		new String:hunterSteamId[32] = "";
		GetClientAuthString(hunterId,hunterSteamId,sizeof(hunterSteamId));
		new punterId = GetEventInt(event, "userid");
		new String:punterSteamId[32] = "";
		GetClientAuthString(punterId,punterSteamId,sizeof(punterSteamId));
		new String:deniedDebug[256] = "";
		Format(deniedDebug,sizeof(deniedDebug),"\x03[pd+ debug]\x02 %s\x04 got SKEETED by \x02%s! islunging failed",hunterSteamId,punterSteamId);
		PrintToChatAll(deniedDebug);
	}
}

*/