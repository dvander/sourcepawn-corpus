#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2items>
#include <tf2_stocks>
#include <tf2>
#include <tf2attributes>

#define GIANTSCOUT_SND_LOOP			"mvm/giant_scout/giant_scout_loop.wav"
#define GIANTSOLDIER_SND_LOOP		"mvm/giant_soldier/giant_soldier_loop.wav"
#define GIANTPYRO_SND_LOOP			"mvm/giant_pyro/giant_pyro_loop.wav"
#define GIANTDEMOMAN_SND_LOOP		"mvm/giant_demoman/giant_demoman_loop.wav"
#define GIANTHEAVY_SND_LOOP			")mvm/giant_heavy/giant_heavy_loop.wav"

new String:weaponAttribs[256];
new Handle:hSDKEquipWearable = INVALID_HANDLE;
new bool:bInRespawn[MAXPLAYERS];

public Plugin:myinfo = 
{
	name = "[TF2] Red2Robot",
	author = "Bitl",
	description = "Change your team to robot!",
	version = "2.0",
	url = ""
}

public OnPluginStart()
{
	CheckGame();
	
	HookEvent("player_death", event_PlayerDeath);
	HookEvent("player_spawn", event_PlayerSpawn);
	
	RegAdminCmd("sm_bot", Command_Help, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_machine", Command_Robot_Me, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_mann", Command_Human_Me, ADMFLAG_RESERVATION);
	RegConsoleCmd("sm_gauntlet", Command_SteelGauntlet);
	RegConsoleCmd("sm_shortstop", Command_Shortstop);
	RegConsoleCmd("sm_gauntletpusher", Command_GauntletPusher);
	RegConsoleCmd("sm_deflector", Command_GiantDeflectorHeavy);
	RegConsoleCmd("sm_bowmanrapidfire", Command_BowSpammer);
	RegConsoleCmd("sm_giant", Command_Giant);
	RegConsoleCmd("sm_small", Command_Small);
	
}

public OnMapStart()
{
	if (IsMvM())
	{
		PrintToServer("[Red2Robot] MvM Detected. Red2Robot activated and ready for use!");
		new iEnt = -1;
		while( ( iEnt = FindEntityByClassname( iEnt, "func_respawnroom") ) != -1 )
			if( GetEntProp( iEnt, Prop_Send, "m_iTeamNum" ) == _:TFTeam_Blue )
			{
				SDKHook( iEnt, SDKHook_Touch, OnSpawnStartTouch );
				SDKHook( iEnt, SDKHook_EndTouch, OnSpawnEndTouch );
			}
	}
	else
	{
		SetFailState("[Red2Robot] Error #1: This plugin is only usable on MvM maps.");
	}
	PrecacheSound(GIANTSCOUT_SND_LOOP, true);
	PrecacheSound(GIANTSOLDIER_SND_LOOP, true);
	PrecacheSound(GIANTPYRO_SND_LOOP, true);
	PrecacheSound(GIANTDEMOMAN_SND_LOOP, true);
	PrecacheSound(GIANTHEAVY_SND_LOOP, true);
}

CheckGame()
{
	decl String:strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
	if (StrEqual(strModName, "tf")) return;
	SetFailState("[SM] This plugin is only for Team Fortress 2.");
}

public Action:Command_Robot_Me(client, args)
{
	if (args == 0)
	{
		if (GetClientTeam(client) == 2)
		{
			new entflags = GetEntityFlags(client);
			SetEntityFlags(client, entflags | FL_FAKECLIENT);
			ChangeClientTeam(client, _:TFTeam_Blue);
			StopSounds(client);
			SetEntityFlags(client, entflags);
			ReplyToCommand(client, "[Red2Robot] You are now in the Machine team!");
			ShowActivity2(client, "[Red2Robot] ", "%N changed his team to Machine!", client);
		}
		else
		{
			ReplyToCommand(client, "[Red2Robot] You are already in the Machine team!");
		}
	}
	else if (args == 1)
	{
		new String:arg1[128];
		GetCmdArg(1, arg1, 128);
		//Create strings
		decl String:buffer[64];
		decl String:target_name[MAX_NAME_LENGTH];
		decl target_list[MAXPLAYERS];
		decl target_count;
		decl bool:tn_is_ml;
		
		//Get target arg
		GetCmdArg(1, buffer, sizeof(buffer));
		
		//Process
		if ((target_count = ProcessTargetString(
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
		
		for (new i = 0; i < target_count; i ++)
		{
			if (GetClientTeam(target_list[i]) ==2)
			{
				new entflags = GetEntityFlags(target_list[i]);
				SetEntityFlags(target_list[i], entflags | FL_FAKECLIENT);
				ChangeClientTeam(target_list[i], _:TFTeam_Blue);
				SetEntityFlags(target_list[i], entflags);
				ReplyToCommand(target_list[i], "[Red2Robot] You are now in the Machine team!");
				ShowActivity2(target_list[i], "[Red2Robot] ", "%N changed his team to Machine!", target_list[i]);
			}
			else
			{
				ReplyToCommand(target_list[i], "[Red2Robot] You are already in the Machine team!");
			}
		}	
	}

	return Plugin_Handled;
}


public Action:Command_Human_Me(client, args)
{
	if (args == 0)
	{
		if (GetClientTeam(client) ==3)
		{
			new entflags = GetEntityFlags(client);
			SetEntityFlags(client, entflags | FL_FAKECLIENT);
			ChangeClientTeam(client, _:TFTeam_Red);
			SetEntityFlags(client, entflags);
			StopSounds(client);
			ReplyToCommand(client, "[Red2Robot] You are now in the Mann team!");
			ShowActivity2(client, "[Red2Robot] ", "%N changed his team to Mann!", client);
		}
		else
		{
			ReplyToCommand(client, "[Red2Robot] You are already in the Mann team!");
		}
	}
	else if (args == 1)
	{
		new String:arg1[128];
		GetCmdArg(1, arg1, 128);
		//Create strings
		decl String:buffer[64];
		decl String:target_name[MAX_NAME_LENGTH];
		decl target_list[MAXPLAYERS];
		decl target_count;
		decl bool:tn_is_ml;
		
		//Get target arg
		GetCmdArg(1, buffer, sizeof(buffer));
		
		//Process
		if ((target_count = ProcessTargetString(
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
		
		for (new i = 0; i < target_count; i ++)
		{
			if (GetClientTeam(target_list[i]) ==3)
			{
				new entflags = GetEntityFlags(target_list[i]);
				SetEntityFlags(target_list[i], entflags | FL_FAKECLIENT);
				ChangeClientTeam(target_list[i], _:TFTeam_Red);
				SetEntityFlags(target_list[i], entflags);
				ReplyToCommand(target_list[i], "[Red2Robot] You are now in the Mann team!");
				ShowActivity2(target_list[i], "[Red2Robot] ", "%N changed his team to Mann!", target_list[i]);
			}
			else
			{
				ReplyToCommand(target_list[i], "[Red2Robot] You are already in the Mann team!");
			}
		}
	}

	return Plugin_Handled;
}

public Action:Command_Shortstop(client, args)
{
	if (GetClientTeam(client) ==3)
	{
		TF2_SetPlayerClass(client, TFClass_Scout);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.4);
		UpdatePlayerHitbox(client, 1.4);
		TF2_RegeneratePlayer(client);
		TF2Attrib_RemoveAll(client);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 0);
		SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:false);
		TF2Attrib_SetByName(client, "head scale", 0.7);
		TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 525.0);
		TF2Attrib_SetByName(client, "move speed bonus", 1.25);
		Format(weaponAttribs, sizeof(weaponAttribs), "241 ; 1.5 ; 328 ; 1.0");
		SpawnWeapon( client, "tf_weapon_handgun_scout_primary", 220, 100, 5, weaponAttribs, false );
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
		SetEntityHealth(client, 650);
		StopSounds(client);
		SetModel(client);
		
		ReplyToCommand(client, "[Red2Robot] You are now Shortstop Scout!");
		ShowActivity2(client, "[Red2Robot] ", "%N is now Shortstop Scout!", client);
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to be Shortstop Scout.");
	}
}

public Action:Command_BowSpammer(client, args)
{
	if (GetClientTeam(client) ==3)
	{
		TF2_SetPlayerClass(client, TFClass_Sniper);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.5);
		UpdatePlayerHitbox(client, 1.5);
		TF2_RegeneratePlayer(client);
		TF2Attrib_RemoveAll(client);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 0);
		SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:false);
		TF2Attrib_SetByName(client, "head scale", 0.7);
		TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 1075.0);
		TF2Attrib_SetByName(client, "move speed bonus", 0.85);
		Format(weaponAttribs, sizeof(weaponAttribs), "6 ; 0.6");
		SpawnWeapon( client, "tf_weapon_compound_bow", 56, 100, 5, weaponAttribs, false );
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
		SetEntityHealth(client, 1200);
		StopSounds(client);
		SetModel(client);
		
		ReplyToCommand(client, "[Red2Robot] You are now Bowman Rapid Fire!");
		ShowActivity2(client, "[Red2Robot] ", "%N is now Bowman Rapid Fire!", client);
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to be Bowman Rapid Fire.");
	}
}

public Action:Command_SteelGauntlet(client, args)
{
	if (GetClientTeam(client) ==3)
	{
		TF2_SetPlayerClass(client, TFClass_Heavy);
		TF2_RegeneratePlayer(client);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.5);
		UpdatePlayerHitbox(client, 1.5);
		TF2Attrib_RemoveAll(client);
		TF2_RemoveWeaponSlot(client, 2);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 0);
		SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:false);
		TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 600.0);
		Format(weaponAttribs, sizeof(weaponAttribs), "205 ; 0.6 ; 206 ; 2.0 ; 177 ; 1.2");
		SpawnWeapon( client, "tf_weapon_fists", 331, 100, 5, weaponAttribs, false );
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
		SetEntityHealth(client, 900);
		StopSounds(client);
		SetModel(client);
		
		ReplyToCommand(client, "[Red2Robot] You are now Steel Gauntlet!");
		ShowActivity2(client, "[Red2Robot] ", "%N is now Steel Gauntlet!", client);
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to be Steel Gauntlet.");
	}
}

public Action:Command_GauntletPusher(client, args)
{
	if (GetClientTeam(client) ==3)
	{
		TF2_SetPlayerClass(client, TFClass_Heavy);
		TF2_RegeneratePlayer(client);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.5);
		UpdatePlayerHitbox(client, 1.5);
		TF2Attrib_RemoveAll(client);
		TF2_RemoveWeaponSlot(client, 2);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 0);
		SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:false);
		TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 600.0);
		Format(weaponAttribs, sizeof(weaponAttribs), "2 ; 1.5 ; 522 ; 1");
		SpawnWeapon( client, "tf_weapon_fists", 331, 100, 5, weaponAttribs, false );
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
		SetEntityHealth(client, 900);
		StopSounds(client);
		SetModel(client);
		
		ReplyToCommand(client, "[Red2Robot] You are now Steel Gauntlet Pusher!");
		ShowActivity2(client, "[Red2Robot] ", "%N is now Steel Gauntlet Pusher!", client);
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to be Steel Gauntlet Pusher.");
	}
}

public Action:Command_GiantDeflectorHeavy(client, args)
{
	if (GetClientTeam(client) ==3)
	{	
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
		UpdatePlayerHitbox(client, 1.75);
		TF2_SetPlayerClass(client, TFClass_Heavy);
		TF2_RegeneratePlayer(client);
		TF2Attrib_RemoveAll(client);
		TF2_RemoveWeaponSlot(client, 2);
		TF2_RemoveWeaponSlot(client, 1);
		TF2_RemoveWeaponSlot(client, 0);
		SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
		PrecacheSound(GIANTHEAVY_SND_LOOP);
		EmitSoundToAll(GIANTHEAVY_SND_LOOP, client, _, SNDLEVEL_DISHWASHER);
		TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);
		TF2Attrib_SetByName(client, "aiming movespeed increased", 1.5);
		TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
		TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.3);
		TF2Attrib_SetByName(client, "damage force reduction", 0.3);
		TF2Attrib_SetByName(client, "move speed bonus", 0.5);
		TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 4700.0);
		Format(weaponAttribs, sizeof(weaponAttribs), "2 ; 1.5 ; 323 ; 1");
		SpawnWeapon( client, "tf_weapon_minigun", 850, 100, 5, weaponAttribs, false );
		SetEntityHealth(client, 5000);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
		SetModelGiant(client);
		ReplyToCommand(client, "[Red2Robot] You are now Giant Deflector Heavy!");
		ShowActivity2(client, "[Red2Robot] ", "%N is now Giant Deflector Heavy!", client);
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to be Giant Deflector Heavy.");
	}
}

public Action:Command_Giant(client, args)
{
	if (GetClientTeam(client) ==3)
	{	
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.75);
		UpdatePlayerHitbox(client, 1.75);
		TF2_RegeneratePlayer(client);
		TF2Attrib_RemoveAll(client);
		SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:true);
		TF2Attrib_SetByName(client, "cannot be backstabbed", 1.0);
		TF2Attrib_SetByName(client, "aiming movespeed increased", 1.5);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
		
		if(TF2_GetPlayerClass(client) == TFClass_Scout)
		{
			PrecacheSound(GIANTSCOUT_SND_LOOP);
			EmitSoundToAll(GIANTSCOUT_SND_LOOP, client, _, SNDLEVEL_DISHWASHER);
			TF2Attrib_SetByName(client, "override footstep sound set", 5.0);
			TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.7);
			TF2Attrib_SetByName(client, "damage force reduction", 0.7);
			TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 1475.0);
			SetEntityHealth(client, 1600);
		}
		else if(TF2_GetPlayerClass(client) == TFClass_Soldier)
		{
			PrecacheSound(GIANTSOLDIER_SND_LOOP);
			EmitSoundToAll(GIANTSOLDIER_SND_LOOP, client, _, SNDLEVEL_DISHWASHER);
			TF2Attrib_SetByName(client, "override footstep sound set", 3.0);
			TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.4);
			TF2Attrib_SetByName(client, "damage force reduction", 0.4);
			TF2Attrib_SetByName(client, "move speed bonus", 0.5);
			TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 3600.0);
			SetEntityHealth(client, 3800);
		}
		else if(TF2_GetPlayerClass(client) == TFClass_Pyro)
		{
			PrecacheSound(GIANTPYRO_SND_LOOP);
			EmitSoundToAll(GIANTPYRO_SND_LOOP, client, _, SNDLEVEL_DISHWASHER);
			TF2Attrib_SetByName(client, "override footstep sound set", 6.0);
			TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.6);
			TF2Attrib_SetByName(client, "damage force reduction", 0.6);
			TF2Attrib_SetByName(client, "move speed bonus", 0.5);
			TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 2825.0);
			SetEntityHealth(client, 3000);
		}
		else if(TF2_GetPlayerClass(client) == TFClass_DemoMan)
		{
			PrecacheSound(GIANTDEMOMAN_SND_LOOP);
			EmitSoundToAll(GIANTDEMOMAN_SND_LOOP, client, _, SNDLEVEL_DISHWASHER);
			TF2Attrib_SetByName(client, "override footstep sound set", 4.0);
			TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
			TF2Attrib_SetByName(client, "damage force reduction", 0.5);
			TF2Attrib_SetByName(client, "move speed bonus", 0.5);
			TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 3125.0);
			SetEntityHealth(client, 3300);
		}
		else if(TF2_GetPlayerClass(client) == TFClass_Heavy)
		{
			PrecacheSound(GIANTHEAVY_SND_LOOP);
			EmitSoundToAll(GIANTHEAVY_SND_LOOP, client, _, SNDLEVEL_DISHWASHER);
			TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
			TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.3);
			TF2Attrib_SetByName(client, "damage force reduction", 0.3);
			TF2Attrib_SetByName(client, "move speed bonus", 0.5);
			TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 4700.0);
			SetEntityHealth(client, 5000);
		}
		else if(TF2_GetPlayerClass(client) == TFClass_Engineer)
		{
			PrecacheSound(GIANTDEMOMAN_SND_LOOP);
			EmitSoundToAll(GIANTDEMOMAN_SND_LOOP, client, _, SNDLEVEL_DISHWASHER);
			TF2Attrib_SetByName(client, "override footstep sound set", 3.0);
			TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.6);
			TF2Attrib_SetByName(client, "damage force reduction", 0.6);
			TF2Attrib_SetByName(client, "move speed bonus", 0.5);
			TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 3125.0);
			SetEntityHealth(client, 3250);
		}
		else if(TF2_GetPlayerClass(client) == TFClass_Medic)
		{
			PrecacheSound(GIANTSOLDIER_SND_LOOP);
			EmitSoundToAll(GIANTSOLDIER_SND_LOOP, client, _, SNDLEVEL_DISHWASHER);
			TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.6);
			TF2Attrib_SetByName(client, "damage force reduction", 0.6);
			TF2Attrib_SetByName(client, "move speed bonus", 0.5);
			TF2Attrib_SetByName(client, "heal rate bonus", 200.0);
			TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 4350.0);
			SetEntityHealth(client, 4500);
		}
		else if(TF2_GetPlayerClass(client) == TFClass_Sniper)
		{
			PrecacheSound(GIANTPYRO_SND_LOOP);
			EmitSoundToAll(GIANTPYRO_SND_LOOP, client, _, SNDLEVEL_DISHWASHER);
			TF2Attrib_SetByName(client, "override footstep sound set", 3.0);
			TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
			TF2Attrib_SetByName(client, "damage force reduction", 0.5);
			TF2Attrib_SetByName(client, "move speed bonus", 0.5);
			TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 3235.0);
			SetEntityHealth(client, 3360);
		}
		else if(TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			PrecacheSound(GIANTSCOUT_SND_LOOP);
			EmitSoundToAll(GIANTSCOUT_SND_LOOP, client, _, SNDLEVEL_DISHWASHER);
			TF2Attrib_SetByName(client, "override footstep sound set", 5.0);
			TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.6);
			TF2Attrib_SetByName(client, "damage force reduction", 0.6);
			TF2Attrib_SetByName(client, "move speed bonus", 0.5);
			TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 2342.0);
			SetEntityHealth(client, 2467);
		}
		
		SetModelGiant(client);
		ReplyToCommand(client, "[Red2Robot] You are now Giant!");
		ShowActivity2(client, "[Red2Robot] ", "%N is now giant!", client);
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to turn giant.");
	}
}

public Action:Command_Small(client, args)
{
	if (GetClientTeam(client) ==3)
	{	
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
		UpdatePlayerHitbox(client, 1.0);
		TF2_RegeneratePlayer(client);
		SetEntProp(client, Prop_Send, "m_bIsMiniBoss", _:false);
		SetEntProp(client, Prop_Data, "m_iMaxHealth", GetClassMaxHealth(client));
		SetEntProp(client, Prop_Send, "m_iHealth", GetClassMaxHealth(client), 1);
		TF2Attrib_RemoveAll(client);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
		StopSounds(client);
		SetModel(client);
		ReplyToCommand(client, "[Red2Robot] You are now Small!");
		ShowActivity2(client, "[Red2Robot] ", "%N is now small!", client);
	}
	else
	{
		ReplyToCommand(client, "[Red2Robot] You need to be in the BLU/Robots team in order to turn small.");
	}
}

public Action:OnSpawnStartTouch( iEntity, iOther )
{
	if( !IsMvM() || !IsValidClient(iOther) || GetEntProp( iEntity, Prop_Send, "m_iTeamNum" ) != _:TFTeam_Blue )
		return Plugin_Continue;

	TF2_AddCondition(iOther, TFCond_UberchargedHidden, -1.0);
	TF2_AddCondition(iOther, TFCond_UberchargeFading, -1.0);

	bInRespawn[iOther] = true;
	return Plugin_Continue;
}

public Action:OnSpawnEndTouch( iEntity, iOther )
{
	if( !IsMvM() || !IsValidClient(iOther) || GetEntProp( iEntity, Prop_Send, "m_iTeamNum" ) != _:TFTeam_Blue )
		return Plugin_Continue;

	TF2_RemoveCondition(iOther, TFCond_UberchargedHidden);
	TF2_RemoveCondition(iOther, TFCond_UberchargeFading);
	TF2_AddCondition(iOther, TFCond_UberchargedHidden, 1.0);
	TF2_AddCondition(iOther, TFCond_UberchargeFading, 1.0);
	
	bInRespawn[iOther] = false;
	return Plugin_Continue;
}

public OnEntityCreated( iEntity, const String:strClassname[] )
{
	if( StrEqual( strClassname, "func_respawnroom", false ) )
	{
		SDKHook( iEntity, SDKHook_StartTouch, OnSpawnStartTouch );
		SDKHook( iEntity, SDKHook_EndTouch, OnSpawnEndTouch );
	}
}


public OnClientDisconnect(client)
{
	RemoveModel(client);
}

public Action:Command_Help(client, args)
{
	ReplyToCommand(client, "[Red2Robot] !bot, !machine [target], !mann [target], !giant, !small");
}

public event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsMvM())
	{
		if (GetClientTeam(client) ==3)
		{
			StopSounds(client);
			TF2Attrib_RemoveAll(client);
		}
	}
}

public event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsMvM())
	{
		if (GetClientTeam(client) ==3)
		{
			SetModel(client);
			StopSounds(client);
			TF2Attrib_RemoveAll(client);
		}
		else
		{
			RemoveModel(client);
			StopSounds(client);
		}
	}
}

GetClassMaxHealth(client)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	new Health;
	switch(class)
	{
		case TFClass_Scout: Health = 125;
		case TFClass_Soldier: Health = 200;
		case TFClass_Pyro: Health = 175;
		case TFClass_DemoMan: Health = 175;
		case TFClass_Heavy: Health = 300;
		case TFClass_Engineer: Health = 125;
		case TFClass_Medic: Health = 150;
		case TFClass_Sniper: Health = 125;
		case TFClass_Spy: Health = 125;
	}
	return Health;
}

stock bool:SetModel(client)
{
	if (!IsValidClient(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	new String:Mdl[PLATFORM_MAX_PATH];
	switch (TF2_GetPlayerClass(client))
	{
		case TFClass_Scout: Format(Mdl, sizeof(Mdl), "scout");
		case TFClass_Soldier: Format(Mdl, sizeof(Mdl), "soldier");
		case TFClass_Pyro: Format(Mdl, sizeof(Mdl), "pyro");
		case TFClass_DemoMan: Format(Mdl, sizeof(Mdl), "demo");
		case TFClass_Heavy: Format(Mdl, sizeof(Mdl), "heavy");
		case TFClass_Medic: Format(Mdl, sizeof(Mdl), "medic");
		case TFClass_Sniper: Format(Mdl, sizeof(Mdl), "sniper");
		case TFClass_Spy: Format(Mdl, sizeof(Mdl), "spy");
		case TFClass_Engineer: Format(Mdl, sizeof(Mdl), "engineer");
	}
	if (!StrEqual(Mdl, ""))
	{
		Format(Mdl, sizeof(Mdl), "models/bots/%s/bot_%s.mdl", Mdl, Mdl);
		PrecacheModel(Mdl);
	}
	SetVariantString(Mdl);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	if (StrEqual(Mdl, "")) return false;
	return true;
}

stock SpawnWeapon(client,String:name[],index,level,qual,String:att[], bool:bWearable = false)
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION|PRESERVE_ATTRIBUTES);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2 = 0;
		for (new i = 0; i < count; i+=2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	if (hWeapon==INVALID_HANDLE)
		return -1;
	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	if( IsValidEdict( entity ) )
	{
		if( bWearable )
		{
			if( hSDKEquipWearable != INVALID_HANDLE )
				SDKCall( hSDKEquipWearable, client, entity );
		}
		else
			EquipPlayerWeapon( client, entity );
	}
	return entity;
}

stock StopSounds(entity)
{
	if(entity <= 0 || !IsValidEntity(entity))
		return;
	
	StopSnd(entity, _, GIANTSCOUT_SND_LOOP);
	StopSnd(entity, _, GIANTSOLDIER_SND_LOOP);
	StopSnd(entity, _, GIANTPYRO_SND_LOOP);
	StopSnd(entity, _, GIANTDEMOMAN_SND_LOOP);
	StopSnd(entity, _, GIANTHEAVY_SND_LOOP);
}

stock StopSnd(client, channel = SNDCHAN_AUTO, const String:sound[PLATFORM_MAX_PATH])
{
	if(!IsValidEntity(client))
		return;
	StopSound(client, channel, sound);
}

stock UpdatePlayerHitbox(const client, const Float:fScale)
{
	static const Float:vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, Float:vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };
   
	decl Float:vecScaledPlayerMin[3], Float:vecScaledPlayerMax[3];

	vecScaledPlayerMin = vecTF2PlayerMin;
	vecScaledPlayerMax = vecTF2PlayerMax;
   
	ScaleVector(vecScaledPlayerMin, fScale);
	ScaleVector(vecScaledPlayerMax, fScale);
   
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}

stock bool:SetModelGiant(client)
{
	if (!IsValidClient(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	new String:Mdl[PLATFORM_MAX_PATH];
	switch (TF2_GetPlayerClass(client))
	{
		case TFClass_Scout: Format(Mdl, sizeof(Mdl), "scout_boss");
		case TFClass_Soldier: Format(Mdl, sizeof(Mdl), "soldier_boss");
		case TFClass_Pyro: Format(Mdl, sizeof(Mdl), "pyro_boss");
		case TFClass_DemoMan: Format(Mdl, sizeof(Mdl), "demo_boss");
		case TFClass_Heavy: Format(Mdl, sizeof(Mdl), "heavy_boss");
		case TFClass_Medic: Format(Mdl, sizeof(Mdl), "medic");
		case TFClass_Sniper: Format(Mdl, sizeof(Mdl), "sniper");
		case TFClass_Spy: Format(Mdl, sizeof(Mdl), "spy");
		case TFClass_Engineer: Format(Mdl, sizeof(Mdl), "engineer");
	}
	if (!StrEqual(Mdl, ""))
	{
		Format(Mdl, sizeof(Mdl), "models/bots/%s/bot_%s.mdl", Mdl, Mdl);
		PrecacheModel(Mdl);
	}
	SetVariantString(Mdl);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	if (StrEqual(Mdl, "")) return false;
	return true;
}

stock bool:RemoveModel(client)
{
	if (!IsValidClient(client)) return false;
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	return true;
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}

stock void TF2_RemoveAllWearables(int client)
{
	int wearable = -1;
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}
	
	while ((wearable = FindEntityByClassname(wearable, "vgui_screen")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Data, "m_hOwnerEntity");
			if (client == player)
			{
				AcceptEntityInput(wearable, "Kill");
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_powerup_bottle")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			int player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}
}

stock bool:IsMvM(bool:forceRecalc = false)
{
    static bool:found = false;
    static bool:ismvm = false;
    if (forceRecalc)
    {
        found = false;
        ismvm = false;
    }
    if (!found)
    {
        new i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
        if (i > MaxClients && IsValidEntity(i)) ismvm = true;
        found = true;
    }
    return ismvm;
}
