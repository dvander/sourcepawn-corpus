/* Chicken.sp

Description: Chicken Plugin Duh!!

Versions: 0.5

Changelog:

0.1 - Initial Release
0.2 - removed console errors that repeat and cause server lag and require server reboot.
0.3 - Repaired if player has knife out when turnd into chicken, player don't get 200hp
    - Added let chicken keep and plant bomb
0.4 - Repard if player leaves game while a chicken errors loop in console and server needs reboot. 
    - Added let Chicken keep and use a he-grennade 

- sm_chicken <player/@ALL/@CT/@T> <1|0>

0.5 - reworked the plugin with updated code with help from Peace-Maker and DarthNinja (example from his cash.sp)
    - renamed plugin from sm_chicken to Chicken
    - special thanks to pred, dalto, techknow, peace-maker, and darthninja for their contributions, whether or 
	  not they know it

0.6 - fixed the bug where player's guns were turned to knives dropped after they became chickens which caused 
      knives to litter the map.
    - Added back #pragma semicolon 1
	- Changed the messages sent to players to be more aesthetic
*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "0.6"
#define MAX_FILE_LEN 256


// Plugin definitions
public Plugin:myinfo = 
{
	name = "Chicken",
	author = "TnTSCS, TechKnow, Peace-Maker",
	description = "Turns Players Into Chickens",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=156898"
};


new Handle:g_hChickenList[MAXPLAYERS + 1];
new Handle:g_Cvarctchicken = INVALID_HANDLE;
new Handle:g_Cvartchicken = INVALID_HANDLE;
new Handle:g_CvarSoundName = INVALID_HANDLE;
new String:g_soundName[MAX_FILE_LEN];
new String:g_ctchicken[MAX_FILE_LEN];
new String:g_tchicken[MAX_FILE_LEN];
new bool:chicken = false;
new onoff;
new iMyWeapons;
new health = 200;


public OnPluginStart()
{
	CreateConVar("sm_chicken_version", PLUGIN_VERSION, "Chicken Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_CvarSoundName = CreateConVar("sm_chicken_sound", "smchicken/chicken.wav", "Chicken Death Sound to Play");

	g_Cvarctchicken = CreateConVar("sm_ctchicken_model", "models/player/chicken/ct/chicken-ct.mdl", "The CT Chicken Model");

	g_Cvartchicken = CreateConVar("sm_tchicken_model", "models/player/chicken/t/chicken-t.mdl", "The T Chicken Model");

	RegAdminCmd("sm_chicken", Command_SetChicken, ADMFLAG_SLAY);
	iMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");
	
	// Needed for FindTarget
	LoadTranslations("common.phrases");
	
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
}

public OnMapStart()
{
	decl String:buffer[MAX_FILE_LEN];
	
	GetConVarString(g_CvarSoundName, g_soundName, sizeof(g_soundName));
	
	if (strcmp(g_soundName, ""))
	{
		PrecacheSound(g_soundName, true);
		Format(buffer, MAX_FILE_LEN, "sound/%s", g_soundName);
		AddFileToDownloadsTable(buffer);
	}
	
	GetConVarString(g_Cvarctchicken, g_ctchicken, sizeof(g_ctchicken));
	
	if (strcmp(g_ctchicken, ""))
	{
		PrecacheModel(g_ctchicken, true);
		Format(buffer, MAX_FILE_LEN, "%s", g_ctchicken);
		AddFileToDownloadsTable(buffer);
	}
	
	GetConVarString(g_Cvartchicken, g_tchicken, sizeof(g_tchicken));
	
	if (strcmp(g_tchicken, ""))
	{
		PrecacheModel(g_tchicken, true);
		Format(buffer, MAX_FILE_LEN, "%s", g_tchicken);
		AddFileToDownloadsTable(buffer);
	}

	//open precache file and add everything to download table
	new String:file[256];
	BuildPath(Path_SM, file, 255, "configs/chicken.ini");
	new Handle:fileh = OpenFile(file, "r");
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{
		new len = strlen(buffer);
		if (buffer[len-1] == '\n')
			buffer[--len] = '\0';
   		
		if (FileExists(buffer))
		{
			AddFileToDownloadsTable(buffer);
		}
		
		if (IsEndOfFile(fileh))
			break;
	}
	
	PrecacheSound(g_soundName, true);
	PrecacheModel(g_ctchicken, true);
	PrecacheModel(g_tchicken, true);
}

public Action:Command_SetChicken(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "\x04[\x03SM Chicken\x04]\x01 Usage: sm_chicken <target> <1/0>");
		return Plugin_Handled;
	}
	
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;	

	GetCmdArg(1, buffer, sizeof(buffer));

	if ((target_count = ProcessTargetString (
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	decl String:sb[10];

	GetCmdArg(2, sb, sizeof(sb));
	onoff = StringToInt(sb);
	chicken = (onoff==1?true:false);

	for (new i = 0; i < target_count; i ++)
	{
		if(target_list[i] == -1)
			return Plugin_Handled;
		ExecChicken(target_list[i]);
	}
	
	return Plugin_Handled;
}

public ExecChicken(client)
{     
	if (chicken == true)
	{
		DoChicken(client);
	}
	else if (chicken == false)
	{
		// Admin Turnoff Chicken /// REMOVE MODEL/////
		if (g_hChickenList[client] != INVALID_HANDLE)
		{
			CloseHandle(g_hChickenList[client]);
			g_hChickenList[client] = INVALID_HANDLE;
			PrintToChat(client,"\x04[\x03SM Chicken\x04]\x01 Your no longer a Chicken!!"); 
			if (GetClientTeam(client) == 3)
			{
				// Make player a random ct model 
				set_random_model(client,3);
			}
			else if (GetClientTeam(client) == 2)
			{
				// Make player random t model
				set_random_model(client,2);
			}
		}
	}
}

public DoChicken(client)
{
	if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return;
	}
	
	PrintToChat(client,"\x04[\x03SM Chicken\x04]\x01 You have been turned into a Chicken by an admin.  Have a clucking good time!");
	
	if (GetClientTeam(client) == 3)
	{
		// Make player a blue chicken 
		SetEntityModel(client, g_ctchicken);
	}
	else if (GetClientTeam(client) == 2)
	{
		// Make player a red chicken
		SetEntityModel(client, g_tchicken);
	}
	
	SetEntProp(client, Prop_Send, "m_iHealth", health, 1);
	
	PrintToChat(client,"\x04Your health has been set to %i",health);
	
	// search through the players inventory for the weapon
	new weaponEntity;
	decl String:weapon[50];
	for(new i = 0; i < 32; i++)
	{
		weaponEntity = GetEntDataEnt2(client, iMyWeapons + i * 4);
		if (weaponEntity && weaponEntity != -1)
		{
			GetEdictClassname(weaponEntity, weapon, sizeof(weapon));
			if (!IsKnife(weapon))
			{
				RemovePlayerItem(client, weaponEntity);
				RemoveEdict(weaponEntity);
				//GivePlayerItem(client, "weapon_knife");
				EquipAvailableWeapon(client);
				g_hChickenList[client] = CreateTimer(0.1, removeweapons, client, TIMER_REPEAT);
			}
		}
	}
}

public Action:EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	// get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// check to see if he was a Chicken
	if (g_hChickenList[client] != INVALID_HANDLE)
	{
		if (strcmp(g_soundName, ""))
	    {
			new Float:vec[3];
			GetClientEyePosition(client, vec);
			EmitAmbientSound(g_soundName, vec, client, SNDLEVEL_RAIDSIREN);
	    }
	}
	
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	if (g_hChickenList[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hChickenList[client]);
		g_hChickenList[client] = INVALID_HANDLE;
	}
}

public Action:EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	PrecacheSound(g_soundName, true);
	PrecacheModel(g_ctchicken, true);
	PrecacheModel(g_tchicken, true);
	// get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// check to see if an outstanding Chicken from last round//REMOVE MODEL TOO!!////
	if (g_hChickenList[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hChickenList[client]);
		g_hChickenList[client] = INVALID_HANDLE;
		if (GetClientTeam(client) == 3)
		{
			// Make player a random ct model 
			set_random_model(client,3);
		}
		else if (GetClientTeam(client) == 2)
		{
			// Make player random t model
			set_random_model(client,2);
		}
	}

	return Plugin_Continue;
}

public EquipAvailableWeapon(client)
{
	// Find a new weapon to equip
	new pos = 0;
	new weaponEntity = -1;
	do {
		weaponEntity = GetPlayerWeaponSlot(client, pos);
		pos++;
	} while(weaponEntity == -1 && pos < 5);
	if (weaponEntity != -1)
	{
		decl String:sClassName[64];
		GetEdictClassname(weaponEntity, sClassName, sizeof(sClassName));
		FakeClientCommand(client, "use %s", sClassName);
	}
}

public IsKnife(String:weapon[])
{
	// Counter Strike Knife
	if (StrEqual(weapon, "weapon_knife") || StrEqual(weapon, "weapon_c4")|| StrEqual(weapon, "weapon_hegrenade"))
		return 1;

	return 0;
}
// 418
public Action:removeweapons(Handle:timer, any:client)
{ 
    if (g_hChickenList[client] != INVALID_HANDLE)
	{           
        // Make sure Chickens still only have a knife &
		// search through the players inventory for the weapon
		new weaponEntity;
		decl String:weapon[50];
		for(new i = 0; i < 32; i++)
		{
			weaponEntity = GetEntDataEnt2(client, iMyWeapons + i * 4);
			if (weaponEntity && weaponEntity != -1)
			{
				GetEdictClassname(weaponEntity, weapon, sizeof(weapon));
				if (!IsKnife(weapon))
				{
					RemovePlayerItem(client, weaponEntity);
					RemoveEdict(weaponEntity);
					PrintToChat(client,"\x04[\x03SM Chicken\x04]\x01 Chickens can't carry guns!!");
					EquipAvailableWeapon(client);
				}
			}
		}
	}
}

static const String:ctmodels[4][] = {"models/player/ct_urban.mdl","models/player/ct_gsg9.mdl","models/player/ct_sas.mdl","models/player/ct_gign.mdl"};
static const String:tmodels[4][] = {"models/player/t_phoenix.mdl","models/player/t_leet.mdl","models/player/t_arctic.mdl","models/player/t_guerilla.mdl"};

stock set_random_model(client,team)
{
	new random=GetRandomInt(0, 3);
	
	if (team==2) //t!
	{
		SetEntityModel(client, tmodels[random]);
	}
	else if (team==3) //ct	
	{
		SetEntityModel(client, ctmodels[random]);
	}
}