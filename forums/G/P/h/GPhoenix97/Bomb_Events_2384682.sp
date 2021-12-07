#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>

#define PLUGIN_VERSION "1.5"

#define GAME_CSTRIKE 1
#define GAME_CSGO 2

#pragma semicolon 1

new Handle:gBombEvents = INVALID_HANDLE;
new Handle:gBombPlanted = INVALID_HANDLE;
new Handle:gBombDefused = INVALID_HANDLE;
new Handle:gBombBeginPlant = INVALID_HANDLE;
new Handle:gBombExploded = INVALID_HANDLE;
new Handle:gBombAbortPlant = INVALID_HANDLE;
new Handle:gBombPickUp = INVALID_HANDLE;
new Handle:gBombDropped = INVALID_HANDLE;
new Handle:gBombBeginDefuse = INVALID_HANDLE;
new Handle:gBombAbortDefuse = INVALID_HANDLE;

new Handle:gBombBeginPlantSoundPath = INVALID_HANDLE;
new Handle:gBombAbortPlantSoundPath = INVALID_HANDLE;
new Handle:gBombPlantedSoundPath = INVALID_HANDLE;
new Handle:gBombDefusedSoundPath = INVALID_HANDLE;
new Handle:gBombExplodedSoundPath = INVALID_HANDLE;
new Handle:gBombDroppedSoundPath = INVALID_HANDLE;
new Handle:gBombPickUpSoundPath = INVALID_HANDLE;
new Handle:gBombBeginDefuseSoundPath = INVALID_HANDLE;
new Handle:gBombAbortDefuseSoundPath = INVALID_HANDLE;

new Handle:gPrintType = INVALID_HANDLE;
new Handle:gBombSounds = INVALID_HANDLE;

new String:SoundPath[9][256];
new String:SoundPathCSGO[9][256];
new String:BombEvent[9][256];

new Game;

public Plugin:myinfo = 
{
	name 			= "Bomb Events",
	author			= "tuty, G-Phoenix",
	description	= "Bomb events. Show when a player planted ... defused the bomb.",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?t=96444"
};
public OnPluginStart()
{
	decl String:gameName[32];
	GetGameFolderName(gameName, sizeof(gameName));
	
	if (!strcmp(gameName, "cstrike", false))
		Game = GAME_CSTRIKE;
	else if (!strcmp(gameName, "csgo", false))
		Game = GAME_CSGO;
	else
		SetFailState("Unrecognized game mod. This plugin supports only CS:S and CS:GO.");
	
	LoadTranslations("Bomb_Events.phrases");
	gBombEvents = CreateConVar("be_enabled", "1", "Enable/disable plugin.\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CreateConVar("bombevents_version", PLUGIN_VERSION, "Bomb Events version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	if (GetConVarInt(gBombEvents) == 1)
	{
		HookEvent("bomb_beginplant", Event_BeginPlant);
		HookEvent("bomb_abortplant", Event_AbortPlant);
		HookEvent("bomb_planted", Event_BombPlanted);
		HookEvent("bomb_defused", Event_BombDefused);
		HookEvent("bomb_exploded", Event_BombExploded);
		HookEvent("bomb_dropped", Event_BombDropped);
		HookEvent("bomb_pickup", Event_BombPickup);
		HookEvent("bomb_begindefuse", Event_BombBeginDefuse);
		HookEvent("bomb_abortdefuse", Event_BombAbortDefuse);
	
		gBombBeginPlant = CreateConVar("be_beginplant", "1", "Show message when player started planting bomb.\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		gBombAbortPlant = CreateConVar("be_abortplant", "1", "Show message when player stopped planting bomb.\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		gBombPlanted = CreateConVar("be_planted", "1", "Show message when player planted bomb.\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		gBombDefused = CreateConVar("be_defused", "1", "Show message when player defused bomb.\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		gBombExploded = CreateConVar("be_exploded", "1", "Show message when bomb has exploded.\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		gBombDropped = CreateConVar("be_dropped", "1", "Show message when player dropped bomb.\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		gBombPickUp = CreateConVar("be_pickup", "1", "Show message when player picked up bomb.\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		gBombBeginDefuse = CreateConVar("be_begindefuse", "1", "Show message when player started defusing bomb.\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		gBombAbortDefuse = CreateConVar("be_abortdefuse", "1", "Show message when player stopped defusing bomb.\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);	
		
		gBombBeginPlantSoundPath = CreateConVar("be_beginplant_sound", "", "Path to sound file playing when player started planting bomb (cstrike/sound/).", FCVAR_PLUGIN);
		gBombAbortPlantSoundPath = CreateConVar("be_abortplant_sound", "", "Path to sound file playing when player stopped planting bomb (cstrike/sound/).", FCVAR_PLUGIN);
		gBombPlantedSoundPath = CreateConVar("be_planted_sound", "misc/c4powa.mp3", "Path to sound file playing when player planted bomb (cstrike/sound/).", FCVAR_PLUGIN);
		gBombDefusedSoundPath = CreateConVar("be_defused_sound", "misc/laugh.mp3", "Path to sound file playing when player defused bomb (cstrike/sound/).", FCVAR_PLUGIN);
		gBombExplodedSoundPath = CreateConVar("be_exploded_sound", "misc/witch.mp3", "Path to sound file playing when bomb has exploded (cstrike/sound/).", FCVAR_PLUGIN);
		gBombDroppedSoundPath = CreateConVar("be_dropped_sound", "", "Path to sound file playing when player dropped bomb (cstrike/sound/).", FCVAR_PLUGIN);
		gBombPickUpSoundPath = CreateConVar("be_pickup_sound", "", "Path to sound file playing when player picked up bomb (cstrike/sound/).", FCVAR_PLUGIN);
		gBombBeginDefuseSoundPath = CreateConVar("be_begindefuse_sound", "", "Path to sound file playing when player started defusing bomb (cstrike/sound/).", FCVAR_PLUGIN);
		gBombAbortDefuseSoundPath = CreateConVar("be_abortdefuse_sound", "", "Path to sound file playing when player stopped defusing bomb (cstrike/sound/).", FCVAR_PLUGIN);
		
		gPrintType = CreateConVar("be_printtype", "1", "Message position.\n1 = Hint\n2 = Chat\n3 = Center", FCVAR_PLUGIN, true, 1.0, true, 3.0); // 1 hint, 2 chat, 3 center
		gBombSounds = CreateConVar("be_sounds", "1", "Enable playing sounds.\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	}
	
	AutoExecConfig(true, "Bomb_Events");
}

public OnConfigsExecuted()
{
	if (Game == GAME_CSTRIKE)
	{
		GetConVarString(gBombBeginPlantSoundPath, SoundPath[0], sizeof(SoundPath[]));
		GetConVarString(gBombAbortPlantSoundPath, SoundPath[1], sizeof(SoundPath[]));
		GetConVarString(gBombPlantedSoundPath, SoundPath[2], sizeof(SoundPath[]));
		GetConVarString(gBombDefusedSoundPath, SoundPath[3], sizeof(SoundPath[]));
		GetConVarString(gBombExplodedSoundPath, SoundPath[4], sizeof(SoundPath[]));
		GetConVarString(gBombDroppedSoundPath, SoundPath[5], sizeof(SoundPath[]));
		GetConVarString(gBombPickUpSoundPath, SoundPath[6], sizeof(SoundPath[]));
		GetConVarString(gBombBeginDefuseSoundPath, SoundPath[7], sizeof(SoundPath[]));
		GetConVarString(gBombAbortDefuseSoundPath, SoundPath[8], sizeof(SoundPath[]));
		
		Format(BombEvent[0], sizeof(BombEvent[]), "sound/%s", SoundPath[0]);
		Format(BombEvent[1], sizeof(BombEvent[]), "sound/%s", SoundPath[1]);
		Format(BombEvent[2], sizeof(BombEvent[]), "sound/%s", SoundPath[2]);
		Format(BombEvent[3], sizeof(BombEvent[]), "sound/%s", SoundPath[3]);
		Format(BombEvent[4], sizeof(BombEvent[]), "sound/%s", SoundPath[4]);
		Format(BombEvent[5], sizeof(BombEvent[]), "sound/%s", SoundPath[5]);
		Format(BombEvent[6], sizeof(BombEvent[]), "sound/%s", SoundPath[6]);
		Format(BombEvent[7], sizeof(BombEvent[]), "sound/%s", SoundPath[7]);
		Format(BombEvent[8], sizeof(BombEvent[]), "sound/%s", SoundPath[8]);
	}
	if (Game == GAME_CSGO)
	{
		GetConVarString(gBombBeginPlantSoundPath, SoundPathCSGO[0], sizeof(SoundPathCSGO[]));
		GetConVarString(gBombAbortPlantSoundPath, SoundPathCSGO[1], sizeof(SoundPathCSGO[]));
		GetConVarString(gBombPlantedSoundPath, SoundPathCSGO[2], sizeof(SoundPathCSGO[]));
		GetConVarString(gBombDefusedSoundPath, SoundPathCSGO[3], sizeof(SoundPathCSGO[]));
		GetConVarString(gBombExplodedSoundPath, SoundPathCSGO[4], sizeof(SoundPathCSGO[]));
		GetConVarString(gBombDroppedSoundPath, SoundPathCSGO[5], sizeof(SoundPathCSGO[]));
		GetConVarString(gBombPickUpSoundPath, SoundPathCSGO[6], sizeof(SoundPathCSGO[]));
		GetConVarString(gBombBeginDefuseSoundPath, SoundPathCSGO[7], sizeof(SoundPathCSGO[]));
		GetConVarString(gBombAbortDefuseSoundPath, SoundPathCSGO[8], sizeof(SoundPathCSGO[]));
	
		Format(SoundPath[0], sizeof(SoundPath[]), "*%s", SoundPathCSGO[0]);
		Format(SoundPath[1], sizeof(SoundPath[]), "*%s", SoundPathCSGO[1]);
		Format(SoundPath[2], sizeof(SoundPath[]), "*%s", SoundPathCSGO[2]);
		Format(SoundPath[3], sizeof(SoundPath[]), "*%s", SoundPathCSGO[3]);
		Format(SoundPath[4], sizeof(SoundPath[]), "*%s", SoundPathCSGO[4]);
		Format(SoundPath[5], sizeof(SoundPath[]), "*%s", SoundPathCSGO[5]);
		Format(SoundPath[6], sizeof(SoundPath[]), "*%s", SoundPathCSGO[6]);
		Format(SoundPath[7], sizeof(SoundPath[]), "*%s", SoundPathCSGO[7]);
		Format(SoundPath[8], sizeof(SoundPath[]), "*%s", SoundPathCSGO[8]);
		
		Format(BombEvent[0], sizeof(BombEvent[]), "sound/%s", SoundPathCSGO[0]);
		Format(BombEvent[1], sizeof(BombEvent[]), "sound/%s", SoundPathCSGO[1]);
		Format(BombEvent[2], sizeof(BombEvent[]), "sound/%s", SoundPathCSGO[2]);
		Format(BombEvent[3], sizeof(BombEvent[]), "sound/%s", SoundPathCSGO[3]);
		Format(BombEvent[4], sizeof(BombEvent[]), "sound/%s", SoundPathCSGO[4]);
		Format(BombEvent[5], sizeof(BombEvent[]), "sound/%s", SoundPathCSGO[5]);
		Format(BombEvent[6], sizeof(BombEvent[]), "sound/%s", SoundPathCSGO[6]);
		Format(BombEvent[7], sizeof(BombEvent[]), "sound/%s", SoundPathCSGO[7]);
		Format(BombEvent[8], sizeof(BombEvent[]), "sound/%s", SoundPathCSGO[8]);
	}
	
	if (FileExists (BombEvent[0]) && (!StrEqual (SoundPath[0], "", false)))
	{
		AddFileToDownloadsTable(BombEvent[0]);
		if (Game == GAME_CSTRIKE)
			PrecacheSound(SoundPath[0], true);
		else if (Game == GAME_CSGO)
			FakePrecacheSound(SoundPath[0]);
	}
	if (FileExists (BombEvent[1]) && (!StrEqual (SoundPath[1], "", false)))
	{
		AddFileToDownloadsTable(BombEvent[1]);
		if (Game == GAME_CSTRIKE)
			PrecacheSound(SoundPath[1], true);
		else if (Game == GAME_CSGO)
			FakePrecacheSound(SoundPath[1]);
	}
	if (FileExists (BombEvent[2]) && (!StrEqual (SoundPath[2], "", false)))
	{
		AddFileToDownloadsTable(BombEvent[2]);
		if (Game == GAME_CSTRIKE)
			PrecacheSound(SoundPath[2], true);
		else if (Game == GAME_CSGO)
			FakePrecacheSound(SoundPath[2]);
	}
	if (FileExists (BombEvent[3]) && (!StrEqual (SoundPath[3], "", false)))
	{
		AddFileToDownloadsTable(BombEvent[3]);
		if (Game == GAME_CSTRIKE)
			PrecacheSound(SoundPath[3], true);
		else if (Game == GAME_CSGO)
			FakePrecacheSound(SoundPath[3]);
	}
	if (FileExists (BombEvent[4]) && (!StrEqual (SoundPath[4], "", false)))
	{
		AddFileToDownloadsTable(BombEvent[4]);
		if (Game == GAME_CSTRIKE)
			PrecacheSound(SoundPath[4], true);
		else if (Game == GAME_CSGO)
			FakePrecacheSound(SoundPath[4]);
	}
	if (FileExists (BombEvent[5]) && (!StrEqual (SoundPath[5], "", false)))
	{
		AddFileToDownloadsTable(BombEvent[5]);
		if (Game == GAME_CSTRIKE)
			PrecacheSound(SoundPath[5], true);
		else if (Game == GAME_CSGO)
			FakePrecacheSound(SoundPath[5]);
	}
	if (FileExists (BombEvent[6]) && (!StrEqual (SoundPath[6], "", false)))
	{
		AddFileToDownloadsTable(BombEvent[6]);
		if (Game == GAME_CSTRIKE)
			PrecacheSound(SoundPath[6], true);
		else if (Game == GAME_CSGO)
			FakePrecacheSound(SoundPath[6]);
	}
	if (FileExists (BombEvent[7]) && (!StrEqual (SoundPath[7], "", false)))
	{
		AddFileToDownloadsTable(BombEvent[7]);
		if (Game == GAME_CSTRIKE)
			PrecacheSound(SoundPath[7], true);
		else if (Game == GAME_CSGO)
			FakePrecacheSound(SoundPath[7]);
	}
	if (FileExists (BombEvent[8]) && (!StrEqual (SoundPath[8], "", false)))
	{
		AddFileToDownloadsTable(BombEvent[8]);
		if (Game == GAME_CSTRIKE)
			PrecacheSound(SoundPath[8], true);
		else if (Game == GAME_CSGO)
			FakePrecacheSound(SoundPath[8]);
	}
}	
public Action:Event_BeginPlant(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(gBombBeginPlant) == 1)
	{
		new id = GetClientOfUserId(GetEventInt(event, "userid"));
		
		decl String:Name[32];
		GetClientName(id, Name, sizeof(Name) - 1);
		
		switch(GetConVarInt(gPrintType))
		{
			case 1:	PrintHintTextToAll("%t", "Begin_Plant", Name);
			case 2:	PrintToChatAll("\x03%t", "Begin_Plant", Name);
			case 3:	PrintCenterTextAll("%t", "Begin_Plant", Name);
		}
	}
	if (GetConVarInt(gBombSounds) == 1 && (FileExists(BombEvent[0])))
	{
		EmitSoundToAll(SoundPath[0]);
	}
}
public Action:Event_AbortPlant(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(gBombAbortPlant) == 1)
	{
		new id = GetClientOfUserId(GetEventInt(event, "userid"));
		
		decl String:Name[32];
		GetClientName(id, Name, sizeof( Name ) - 1);
		
		switch(GetConVarInt(gPrintType))
		{
			case 1:	PrintHintTextToAll("%t", "Bomb_Abort", Name);
			case 2:	PrintToChatAll("\x03%t", "Bomb_Abort", Name);
			case 3:	PrintCenterTextAll("%t", "Bomb_Abort", Name);
		}
	}
	if (GetConVarInt(gBombSounds) == 1 && (FileExists(BombEvent[1])))
	{
		EmitSoundToAll(SoundPath[1]);
	}
}
public Action:Event_BombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(gBombPlanted) == 1)
	{
		new id = GetClientOfUserId(GetEventInt (event, "userid"));
		
		decl String:Name[32];
		GetClientName(id, Name, sizeof (Name) - 1);
		
		switch (GetConVarInt (gPrintType))
		{
			case 1:	PrintHintTextToAll("%t", "Bomb_Planted", Name);
			case 2:	PrintToChatAll("\x03%t", "Bomb_Planted", Name);
			case 3:	PrintCenterTextAll("%t", "Bomb_Planted", Name);
		}
	}
	if (GetConVarInt (gBombSounds) == 1 && (FileExists (BombEvent[2])))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				StopSound (i, SNDCHAN_STATIC, "radio/bombpl.wav");
			}
		}
		
		EmitSoundToAll (SoundPath[2]);
	}
}
public Action:Event_BombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( GetConVarInt(gBombDefused) == 1)
	{
		new id = GetClientOfUserId(GetEventInt(event, "userid"));
		
		decl String:Name[32];
		GetClientName(id, Name, sizeof( Name ) - 1);
		
		switch(GetConVarInt(gPrintType))
		{
			case 1:	PrintHintTextToAll("%t", "Bomb_Defused", Name);
			case 2:	PrintToChatAll("\x03%t", "Bomb_Defused", Name);
			case 3:	PrintCenterTextAll("%t", "Bomb_Defused", Name);
		}
	}
	if (GetConVarInt(gBombSounds) == 1 && (FileExists (BombEvent[3])))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				StopSound (i, SNDCHAN_STATIC, "radio/bombdef.wav");
			}
		}
		
		EmitSoundToAll(SoundPath[3]);
	}
}
public Action:Event_BombExploded(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( GetConVarInt(gBombExploded ) == 1)
	{
		switch(GetConVarInt(gPrintType ))
		{
			case 1:	PrintHintTextToAll("%t", "Bomb_Exploded");
			case 2:	PrintToChatAll("\x03%t", "Bomb_Exploded");
			case 3:	PrintCenterTextAll("%t", "Bomb_Exploded");
		}
	}
	if (GetConVarInt(gBombSounds) == 1 && (FileExists (BombEvent[4])))
	{
		EmitSoundToAll(SoundPath[4]);
	}
}
public Action:Event_BombDropped(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(gBombDropped) == 1)
	{
		new id = GetClientOfUserId(GetEventInt(event, "userid"));
		
		decl String:Name[32];
		GetClientName(id, Name, sizeof(Name) - 1);
		
		switch(GetConVarInt(gPrintType))
		{
			case 1:	PrintHintTextToAll("%t", "Bomb_Dropped", Name);
			case 2:	PrintToChatAll("\x03%t", "Bomb_Dropped", Name);
			case 3:	PrintCenterTextAll("%t", "Bomb_Dropped", Name);
		}
	}
	if (GetConVarInt(gBombSounds) == 1 && (FileExists (BombEvent[5])))
	{
		EmitSoundToAll(SoundPath[5]);
	}
}
public Action:Event_BombPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(gBombPickUp) == 1)
	{
		new id = GetClientOfUserId(GetEventInt(event, "userid"));
		
		decl String:Name[32];
		GetClientName(id, Name, sizeof(Name) - 1);
		
		switch(GetConVarInt(gPrintType))
		{
			case 1:	PrintHintTextToAll("%t", "Bomb_Pickup", Name);
			case 2:	PrintToChatAll("\x03%t", "Bomb_Pickup", Name);
			case 3:	PrintCenterTextAll("%t", "Bomb_Pickup", Name);
		}
	}
	if (GetConVarInt(gBombSounds) == 1 && (FileExists (BombEvent[6])))
	{
		EmitSoundToAll(SoundPath[6]);
	}
}
public Action:Event_BombBeginDefuse(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(gBombBeginDefuse) == 1)
	{
		new id = GetClientOfUserId(GetEventInt(event, "userid"));
		
		decl String:Name[32];
		GetClientName(id, Name, sizeof(Name) - 1);
		
		switch(GetConVarInt(gPrintType))
		{
			case 1:	PrintHintTextToAll("%t", "Bomb_Begin_Defuse", Name);
			case 2:	PrintToChatAll("\x03%t", "Bomb_Begin_Defuse", Name);
			case 3:	PrintCenterTextAll("%t", "Bomb_Begin_Defuse", Name);
		}
	}
	if (GetConVarInt(gBombSounds) == 1 && (FileExists (BombEvent[7])))
	{
		EmitSoundToAll(SoundPath[7]);
	}
}
public Action:Event_BombAbortDefuse(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(gBombAbortDefuse) == 1)
	{
		new id = GetClientOfUserId(GetEventInt(event, "userid"));
		
		decl String:Name[32];
		GetClientName(id, Name, sizeof(Name) - 1);
		
		switch(GetConVarInt(gPrintType))
		{
			case 1:	PrintHintTextToAll("%t", "Bomb_Abort_Defuse", Name);
			case 2:	PrintToChatAll("\x03%t", "Bomb_Abort_Defuse", Name);
			case 3:	PrintCenterTextAll("%t", "Bomb_Abort_Defuse", Name);
		}
	}
	if (GetConVarInt(gBombSounds) == 1 && (FileExists (BombEvent[8])))
	{
		EmitSoundToAll(SoundPath[8]);
	}
}

stock FakePrecacheSound(const String:szPath[])
{
	AddToStringTable(FindStringTable("soundprecache"), szPath);
}
