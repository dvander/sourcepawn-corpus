
//This is based loosely off of the now unsupported plugin hp_left(http://forums.alliedmods.net/showthread.php?t=57735) by TSCDan. 
//Being written for CS:S severely limited it on our TF2 server and since I was looking for something closer to my Natural Selection plugin (http://www.nsmod.org/forums/index.php?showtopic=9663)
//I used hp_left as a starting point to get me into TF2 and SM development, however the only thing that still remains the original code is the distance check.

/*
* Change log:
* 	0.1 - cleaned up unused code... recoded functions. fixed TF2 specific events, output looks better.
* 	0.2 - fixed distance (stupid error)
* 	0.3 - fix colors / fixed customkill check. Spelling errors on weapons (lol).
* 	0.4 - Killer already dead check to fix weird outputs
* 	0.5	- ability to disable output
* 
* Todo:
* 		Assist info
* 		More accurate distance check
* 		Distance for non melee weapons
*/

#include <sourcemod>
#define VERSION "0.5"

//enable or disable including distance in the output
#define DISTANCE	0

//ignore
#define WPNSMAX	26
new const String:wpnsName[WPNSMAX][32] = 
									{	
										"scattergun", "bat", "pistol_scout", "tf_projectile_rocket", "shotgun_soldier", "shovel", 
										"flamethrower", "fireaxe", "shotgun_pyro", "tf_projectile_pipe", "tf_projectile_pipe_remote", "bottle", 
										"minigun", "fists", "shotgun_hwg", "obj_sentrygun", "wrench", "pistol", 
										"shotgun_primary", "bonesaw", "syringegun_medic",	"club", "smg", "sniperrifle", 
										"revolver",	"knife"
									}
									
new const String:wpnsPretty[WPNSMAX][32] = 
									{	
										"a Scatter Gun", "a Bat", "a Pistol", "a Rocket", "a Shotgun", "a Shovel",
										 "a Flamethrower", "a Fire Axe", "a Shotgun", "a Pipe Bomb", "a Remote Pipe Bomb", "a Bottle",
										"a Minigun", "Fists", "a Shotgun", "a Sentry Gun", "a Wrench", "a Pistol",
										 "a Shotgun", "a Bone Saw", "a Syringe Gun", "a Machete", "an SMG", "a Sniper Rifle",
										"a Revolver", "a Knife"
									}

//new bool:showOutput[33];
new showOutput[MAXPLAYERS + 1];

new String:g_fileset[128];
new Handle:g_CvarDefaultSetting = INVALID_HANDLE;
new Handle:hKVSettings = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "TF2: Killer's Info",
	author = "Nut",
	description = "Shows who killed you, with what, how far, and how much hp left.",
	version = VERSION,
	url = "http://www.lolsup.com/tf2/"
}

public OnPluginStart()
{
	CreateConVar("sm_ki_version", VERSION, "TF2: Killer's Info", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_ki_toggle", cmd_ToggleOutput, "Toggles then info about your killler.");

	g_CvarDefaultSetting = CreateConVar("ki_default_set", "1", "The default setting for new players");
	
	HookEvent("player_death", event_player_death);
	HookEvent("teamplay_round_start", event_round_start);

	hKVSettings=CreateKeyValues("Playerschoice");
  	BuildPath(Path_SM, g_fileset, 128, "data/tf2killersinfo.txt");
	if(!FileToKeyValues(hKVSettings, g_fileset))
	{
    	       KeyValuesToFile(hKVSettings, g_fileset);
        }
}

public OnClientPutInServer(client)
{
	//showOutput[client] = true;
	CapturePlayer(client);
}

public CapturePlayer(client)
{
	new String:steamId[20];
	if(client)
	{
		if(!IsFakeClient(client))
		{
			// Get the users saved setting or create them if they don't exist
			GetClientAuthString(client, steamId, sizeof(steamId));
			KvRewind(hKVSettings);
			if(KvJumpToKey(hKVSettings, steamId)) {
			        showOutput[client] = KvGetNum(hKVSettings, "show info", 1);
			} else {
				KvRewind(hKVSettings);
				KvJumpToKey(hKVSettings, steamId, true);
				KvSetNum(hKVSettings, "show info", GetConVarInt(g_CvarDefaultSetting));
				showOutput[client] = GetConVarInt(g_CvarDefaultSetting);
			}
			KvRewind(hKVSettings);
		}
	}
}

public event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Save user settings to a file
	KvRewind(hKVSettings);
	KeyValuesToFile(hKVSettings, g_fileset);
}

public Action:cmd_ToggleOutput(client, args)
{
	new String:steamId[20];
	GetClientAuthString(client, steamId, sizeof(steamId));
	
	if (showOutput[client])
	{
		KvRewind(hKVSettings);
		KvJumpToKey(hKVSettings, steamId);
		KvSetNum(hKVSettings, "show info", 0);
		showOutput[client] = false;
		PrintToConsole(client, "[SM] Killer's info output is now disabled.");
		
	} else {
		KvRewind(hKVSettings);
		KvJumpToKey(hKVSettings, steamId);
		KvSetNum(hKVSettings, "show info", 1);
		showOutput[client] = true;
		PrintToConsole(client, "[SM] Killer's info output is now enabled.");
	}
	return Plugin_Handled;
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (showOutput[victim])
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new customkill = GetEventInt(event, "customkill");
		new dominated = GetEventInt(event, "dominated");
		
		//skip worldspawn and suicides
		if (!attacker || attacker == victim)
		{
			return Plugin_Continue;
		}
			
		decl String:strAttacker[32];
		decl String:weapon[32];
		
		GetClientName(attacker,strAttacker,32);
		GetEventString(event, "weapon", weapon, 32);
		ReplaceString(weapon, 32, "WEAPON_", "");
		
		decl String:killType[12];
		
		if (dominated)
		{
			strcopy(killType,10,"DOMINATED");
		} else if (customkill)
		{
			if(strcmp(weapon,"sniperrifle", false) == 0)
			{
				strcopy(killType,10,"headshot");
			} else if (strcmp(weapon,"knife", false) == 0)
			{
				strcopy(killType,12,"backstabbed");
			} else {
				strcopy(killType,10,"killed");
			}
				
		} else {
			strcopy(killType,10,"killed");
		}
		
		new wpnId = getPrettyWpnName(weapon);
		if (wpnId != -1) {
			strcopy(weapon,32,wpnsPretty[wpnId]);
		}

		if (!IsPlayerAlive(attacker))
		{
			PrintToChat(victim,"\x04%s\x01 died before killing you.", strAttacker);
		} else {
			#if DISTANCE
			new Float:victimLoc[3], Float:attackerLoc[3], distance;
			GetClientAbsOrigin(victim,victimLoc);
			GetClientAbsOrigin(attacker,attackerLoc);
			distance = RoundToNearest(FloatDiv(calcDistance(victimLoc[0],attackerLoc[0], victimLoc[1],attackerLoc[1], victimLoc[2],attackerLoc[2]),12.0));
			PrintToChat(victim,"\x04%s\x01 \x05%s\x01 you with \x04%s\x01 @ \x04%ift\x01. \x04%ihp\x01 left.", strAttacker, killType, weapon, distance, GetClientHealth(attacker));
			#else
			PrintToChat(victim,"\x04%s\x01 \x05%s\x01 you with \x04%s\x01. \x04%ihp\x01 left.", strAttacker, killType, weapon, GetClientHealth(attacker));
			#endif
		}
	}
	return Plugin_Continue;
}

getPrettyWpnName(String:wpn[32])
{
	for (new i = 0; i < WPNSMAX; i++)
	{
		if (strncmp(wpn, wpnsName[i], strlen(wpn)) == 0)
		{
			return i;
		}
	}
	return -1;
}

#if DISTANCE
Float:calcDistance(Float:x1,Float:x2,Float:y1,Float:y2,Float:z1,Float:z2){ 
	new Float:dx = x1-x2;
	new Float:dy = y1-y2;
	new Float:dz = z1-z2; 
	return(SquareRoot(dx*dx + dy*dy + dz*dz));
}
#endif