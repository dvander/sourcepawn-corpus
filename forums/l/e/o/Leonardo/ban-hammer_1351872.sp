/*

1.4.0:
	Fixed non-sourcebans' banning;
	Versions assembled together;
	Custom colors.inc no longer required;
	Ban-weapon is a fixed now;
	Added ability to add client name in annotations;
	Optimised code. Somewhere;

1.3.4:
	All versions:
		Preventing Kill command;
		Added victim freezing;
		Added cvar banhammer_freeze (default 0);
		Added victim's body removing (effects);
		Added instant ban when client trying to disconnect;
		Added cvar banhammer_noragequit (default 1);
	TF2 version:
		Preventing Explode command;

1.3.3:
	TF2 version: feight death fixed;

1.3.2:
	TF2 version: added annotations;
	Fixed SourceBans support;
	
1.3.1:
	CS:S and TF2 versions splitted;
	
1.3.0:
	Now all admins (players with BAN-flag) uses one list of victims;
	added effects (tf2/css) to faster searching victims;
	more commands...;
	
1.2.2:
	Added function OnClientDisconnected();
	now you can't use banhammer vs other admins with flag ADMFLAG_BAN;
	fixed buddha (he disabled buddha everytime so that conflict with other plugins);
	
1.2.1:
	Common phrases (required for ReplyToTargetError()) fixed;
	
1.2.0:
	Added argument to command (argument is a one or many targets, can be empty);
	added buddha ("ubercharge" for css );
	fixed buddha/ubercharging with any weapon;
	fixed media checks/paths;
	added render color changing for css;
	now you must set as weapon only default weapons (for example: if you want use "sledgehammer" you still must set "fireaxe"...)
	
1.1.1:
	Fixed effects, added sounds;
	
1.1.0:
	Added debug mode (no-ban-mode);
	added compatibility with CS:S;
	added effects, fixed death-log disabling;
	
1.0.1:
	Fixed text in chat;
	added custom log (Admin killed cheater with banhammer);
	
1.0.0:
	First release;

*/

#pragma semicolon 1

#include <sourcemod>
#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS
#include <sdktools>

#define PLUGIN_VERSION "1.3.4"
//#define DEBUG // uncomment to compile non-banning plugin with some debug replies

// ConVars
new Handle:g_Enabled = INVALID_HANDLE;
new Handle:g_BanTime = INVALID_HANDLE;
new Handle:g_Annotations = INVALID_HANDLE;
new Handle:g_FreezeVictims = INVALID_HANDLE;
new Handle:g_PreventRagequit = INVALID_HANDLE;
new Handle:g_TF2Classic = INVALID_HANDLE;
new Handle:g_HL2DMAdminRace = INVALID_HANDLE;
// about game types
new String:g_GameType[16];
new bool:g_tf2Library = false;
new bool:g_tf2sLibrary = false;
// about victim list
new g_Players[MAXPLAYERS+1] = 0; // 0 - disabled; 1 - regular ban-hammer; 2 - ban everyone
new g_VictimsArray[MAXPLAYERS+1] = 0;
new g_VictimsCount = 0;
// other
new Float:g_LastKeyCheckTime[MAXPLAYERS+1] = 0.0;
new String:g_Weapon[64];
new g_iEntGlowSprite;
new g_iEntExplosionSprite;

public Plugin:myinfo =
{
	name = "Ban-Hammer!",
	author = "Leonardo",
	description = "Admin can ban everyone by selected weapon",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("banhammer_verion", PLUGIN_VERSION, "", FCVAR_NOTIFY);
	g_Enabled = CreateConVar("banhammer_enable", "1", "Enable or disable plugin", 0, true, 0.0, true, 1.0);
	g_BanTime = CreateConVar("banhammer_bantime", "0", "Ban-time in minutes; 0=Permanent", 0, true, 0.0);
	g_FreezeVictims = CreateConVar("banhammer_freeze", "0", "Enable/disable freezing victims");
	g_PreventRagequit = CreateConVar("banhammer_noragequit", "1", "Enable/disable instant ban when victim trying to disconnect");
	
	GetGameFolderName(g_GameType, sizeof(g_GameType));
	if ( StrEqual(g_GameType, "tf", true) )
	{
		g_Annotations = CreateConVar("banhammer_annotations", "PWND!", "Text of annotations; leave empty to disable");
		g_TF2Classic = CreateConVar("banhammer_classic", "0", "Switch ban-weapon to Wrench if there no unlockable weapons", 0, true, 0.0, true, 1.0);
		
		HookConVarChange(g_TF2Classic, OnTF2ClassicCVarChange);
		
		g_Weapon = "fireaxe";
		
		g_tf2Library = LibraryExists("tf2");
		g_tf2sLibrary = LibraryExists("tf2_stocks");
	}
	else if ( StrEqual(g_GameType, "cstrike", true) )
	{
		g_Weapon = "knife";
	}
	else if ( StrEqual(g_GameType, "hl2mp", true) )
	{
		g_HL2DMAdminRace = CreateConVar("banhammer_adminteam", "rebels", "If rebels, then crowbars are a ban-weapons, otherside - stunstick", 0, true, 0.0, true, 1.0);
		
		HookConVarChange(g_HL2DMAdminRace, OnHL2AdminTeamCVarChange);
		
		g_Weapon = "crowbar"; // brutal admin-rebels, huh?
	}
	else
	{
		SetFailState("This plugin is for CS:S, HL2:DM and TF2 only and is not supported for \"%s\".", g_GameType);
	}
	
	RegAdminCmd("banhammer", CmdEnable, ADMFLAG_BAN, "Enable/disable ban-hammer");
	RegAdminCmd("bh_toggle", CmdEnable, ADMFLAG_BAN, "Enable/disable ban-hammer");
	RegAdminCmd("bh_toggleall", CmdEnableAll, ADMFLAG_BAN, "Enable/disable ban-all-hammer");
	RegAdminCmd("bh_victims", CmdManage, ADMFLAG_BAN, "Manage list of players-to-ban");
	RegConsoleCmd("kill", PreventSuicideCmd);
	RegConsoleCmd("explode", PreventSuicideCmd);
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	
	LoadTranslations("common.phrases.txt");
	
	for(new cell = 0; cell <= MAXPLAYERS; cell++)
	{
		g_VictimsArray[cell] = 0;
		g_Players[cell] = 0;
		g_LastKeyCheckTime[cell] = 0.0;
	}
	g_VictimsCount = 0;
}

public OnPluginEnd()
{
	if ( StrEqual(g_GameType, "tf", true) )
		UnhookConVarChange(g_TF2Classic, OnTF2ClassicCVarChange);
	else if ( StrEqual(g_GameType, "hl2mp", true) )
		UnhookConVarChange(g_HL2DMAdminRace, OnHL2AdminTeamCVarChange);
	UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public OnMapStart()
{
	if ( StrEqual(g_GameType, "tf", true) )
	{
		g_iEntExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
		PrecacheSound("weapons/c4/c4_explode1.wav", true);
		g_iEntGlowSprite = PrecacheModel("sprites/glow.vmt");
	}
	else
	{
		PrecacheSound("items/cart_explode.wav", true);
		PrecacheSound("vo/announcer_victory.wav", true);
		g_iEntGlowSprite = PrecacheModel("sprites/light_glow03.vmt");
	}
	
	for(new cell = 0; cell <= MAXPLAYERS; cell++)
	{
		g_VictimsArray[cell] = 0;
		g_Players[cell] = 0;
		g_LastKeyCheckTime[cell] = 0.0;
	}
	g_VictimsCount = 0;
}

public OnLibraryAdded(const String:sLibName[])
{
	if (StrEqual(sLibName, "tf2"))
		g_tf2Library = true;
	if (StrEqual(sLibName, "tf2_stocks"))
		g_tf2sLibrary = true;
}

public OnLibraryRemoved(const String:sLibName[])
{
	if (StrEqual(sLibName, "tf2"))
		g_tf2Library = false;
	if (StrEqual(sLibName, "tf2_stocks"))
		g_tf2sLibrary = false;
}

public OnGameFrame()
{
	if(GetConVarBool(g_Enabled))
		for (new iClient = 1; iClient <= MaxClients; iClient++)
			if( IsValidClient(iClient) && IsPlayerAlive(iClient) && GetClientTeam(iClient)>1 )
			{
				new String:sWeapon[64];
				GetClientWeapon(iClient, sWeapon, sizeof(sWeapon));
				if( g_Players[iClient]>0 && StrContains(sWeapon, g_Weapon, false) != -1 )
				{
					if( StrEqual(g_GameType, "tf", true) && g_tf2Library )
					{
						if( CheckElapsedTime(iClient,1.0) ) // prevent spamming
						{
							TF2_AddCondition(iClient, TFCond:TFCond_Ubercharged, 1.05);
							TF2_AddCondition(iClient, TFCond:TFCond_TeleportedGlow, 1.05);
							TF2_AddCondition(iClient, TFCond:TFCond_Kritzkrieged, 1.05);
							TF2_AddCondition(iClient, TFCond:TFCond_Overhealed, 1.05);
							SaveKeyTime(iClient);
						}
					}
					else
						SetEntityRenderColor(iClient, 255, 87, 0, 91);
					SetEntProp(iClient, Prop_Data, "m_takedamage", 1, 1);
				}
				else
				{
					decl bool:victimFound;
					victimFound = false;
					for(new cell = 0; cell <= MAXPLAYERS; cell++)
						if(g_VictimsArray[cell]!=0)
							if(g_VictimsArray[cell]==iClient)
							{
								victimFound = true;
								break;
							}
					if(victimFound)
					{
						decl Float:clientOrigin[3];
						GetClientAbsOrigin(iClient, clientOrigin);
						clientOrigin[2] += 50;
						TE_SetupGlowSprite(clientOrigin, g_iEntGlowSprite, 0.1, 0.5, 150);
						TE_SendToAll();
						if(GetConVarBool(g_FreezeVictims))
							SetEntityMoveType(iClient, MOVETYPE_NONE);
					}
				}
			}
}

public Action:PreventSuicideCmd(iClient, iArgs)
{
	for(new cell = 0; cell <= MAXPLAYERS; cell++)
		if(g_VictimsArray[cell] == iClient) // no suicide while player is a victim
			return Plugin_Handled;
	if(g_Players[iClient]>0) // no suicide while under banhammer effect
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action:CmdEnable(iClient, iArgs)
{
	if(GetConVarBool(g_Enabled) && IsValidClient(iClient) && iClient>0)
		if(g_Players[iClient]==0 && g_VictimsCount==0)
			ReplyToCommand(iClient, "BAN-Hammer: isn't allowed (victims not found).");
		else
			if( g_Players[iClient]>0 )
			{
				g_Players[iClient] = 0;
				SetEntProp(iClient, Prop_Data, "m_takedamage", 2, 1);
				if(!(StrEqual(g_GameType, "tf", true) && g_tf2Library))
					SetEntityRenderColor(iClient, 255, 255, 255, 255);
				ReplyToCommand(iClient, "BAN-Hammer: disabled for you.");
			}
			else
			{
				g_Players[iClient] = 1;
				ReplyToCommand(iClient, "BAN-Hammer: enabled for you.");
			}
	return Plugin_Handled;
}

public Action:CmdEnableAll(iClient, iArgs)
{
	if(GetConVarBool(g_Enabled) && IsValidClient(iClient) && iClient>0)
		if( g_Players[iClient]>0 )
		{
			g_Players[iClient] = 0;
			SetEntProp(iClient, Prop_Data, "m_takedamage", 2, 1);
			if(!(StrEqual(g_GameType, "tf", true) && g_tf2Library))
				SetEntityRenderColor(iClient, 255, 255, 255, 255);
			ReplyToCommand(iClient, "BAN-Hammer: disabled for you.");
		}
		else
		{
			g_Players[iClient] = 2;
			ReplyToCommand(iClient, "BAN-Hammer: enabled for you; you can ban anyone!");
		}
	return Plugin_Handled;
}

public Action:CmdManage(iClient, iArgs)
{
	new String:buffer[512];
	decl manageType;
	manageType = 0;
	
	if(iArgs>=1)
	{
		GetCmdArg(1, buffer, sizeof(buffer));
		if(StrEqual(buffer, "reset", false))
			manageType = 3;
		else if(!StrEqual(buffer, "list", false))
			manageType = 1;
	}
	
	if(iArgs==2)
	{
		GetCmdArg(2, buffer, sizeof(buffer));
		if(StrEqual(buffer, "remove", false))
			manageType = 2;
		else
			manageType = 1;
	}
	
	GetCmdArg(1, buffer, sizeof(buffer));
	if(manageType>0)
	{
		decl String:target_name[MAX_NAME_LENGTH];
		decl target_list[MAXPLAYERS];
		decl target_count;
		decl bool:tn_is_ml;
		decl bool:dpl_check;
		
		if(manageType==3) // removing all
		{
			for(new cell = 0; cell <= MAXPLAYERS; cell++)
			{
				g_VictimsArray[cell] = 0;
				if(IsValidClient(g_VictimsArray[cell]) && IsPlayerAlive(g_VictimsArray[cell]))
					SetEntityMoveType(g_VictimsArray[cell], MOVETYPE_WALK);
			}
			g_VictimsCount = 0;
			PrintToConsole(iClient, "BAN-Hammer: victims list cleaned");
#if defined DEBUG
			PrintToConsole(iClient, "BAN-Hammer: victims count: %d", g_VictimsCount);
#endif
			return Plugin_Handled;
		}
		
		if( (target_count = ProcessTargetString(buffer, iClient, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0 )
		{
			ReplyToTargetError(iClient, target_count);
			return Plugin_Handled;
		}
		
		if(manageType==2) // removing
		{
			decl tmpArray[MAXPLAYERS+1];
			decl tmpCount;
			decl victimsRemoved;
			victimsRemoved = 0;
			for(new count = 0; count <= target_count; count++)
				for(new cell = 0; cell <= MAXPLAYERS; cell++)
					if(g_VictimsArray[cell]!=0)
						if(g_VictimsArray[cell] == target_list[count])
						{
							g_VictimsArray[cell] = 0;
							victimsRemoved++;
							if(IsValidClient(target_list[count]) && IsPlayerAlive(target_list[count]))
								SetEntityMoveType(target_list[count], MOVETYPE_WALK);
						}
			tmpArray = g_VictimsArray;
			for(new cell = 0; cell <= MAXPLAYERS; cell++)
				if(tmpArray[cell]!=0)
					g_VictimsArray[tmpCount++] = tmpArray[cell];
			g_VictimsCount = tmpCount;
			PrintToConsole(iClient, "BAN-Hammer: %d victims removed", victimsRemoved);
#if defined DEBUG
			PrintToConsole(iClient, "BAN-Hammer: victims count: %d", g_VictimsCount);
#endif
		}
		else // adding
		{
			decl victimsAdded;
			victimsAdded = 0;
			for(new count = 0; count <= target_count; count++)
				if( IsValidClient(target_list[count]) && target_list[count]>0 /* do not try to ban console lol */ )
					if(target_list[count]!=iClient && !(GetUserFlagBits(target_list[count]) & ADMFLAG_BAN))
					{
						dpl_check = false;
						if(g_VictimsCount>0)
							for(new cell = 0; cell <= MAXPLAYERS; cell++)
								if(g_VictimsArray[cell]!=0)
									if(g_VictimsArray[cell] == target_list[count])
									{
										dpl_check = true;
										break;
									}
						if(!dpl_check)
							for(new cell = 0; cell <= MAXPLAYERS; cell++)
								if(g_VictimsArray[cell]==0)
								{
									g_VictimsArray[cell] = target_list[count];
									victimsAdded++;
									break;
								}
					}
			g_VictimsCount = 0;
			for(new cell = 0; cell <= MAXPLAYERS; cell++)
				if(g_VictimsArray[cell]!=0)
					g_VictimsCount++;
			PrintToConsole(iClient, "BAN-Hammer: %d victims added", victimsAdded);
#if defined DEBUG
			PrintToConsole(iClient, "BAN-Hammer: victims count: %d", g_VictimsCount);
#endif
		}
	}
	else // printing
#if !defined DEBUG
		if(g_VictimsCount>0)
		{
#endif
			for(new cell = 0; cell <= MAXPLAYERS; cell++)
			{
				if(g_VictimsArray[cell]>0)
				{
					new String:clientName[64];
					GetClientName(g_VictimsArray[cell], clientName, sizeof(clientName));
					PrintToConsole(iClient, "BAN-Hammer: victim #%d: %s (#%d)", cell, clientName, g_VictimsArray[cell]);
				}
			}
#if !defined DEBUG
		}
		else
			PrintToConsole(iClient, "BAN-Hammer: victims not found.");
#endif
		
	return Plugin_Handled;
}

public Action:Event_PlayerDeath(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	// checking settings:
	if (!GetConVarBool(g_Enabled)) return Plugin_Continue;

	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(iVictim))
		return Plugin_Continue;
	
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(!IsValidClient(iAttacker))
		return Plugin_Continue;
	
	if(iAttacker==iVictim) // IT'S SO STUPID
		return Plugin_Continue;
	
	new String:sAttackerAuth[32];
	GetClientAuthString(iAttacker, sAttackerAuth, sizeof(sAttackerAuth));
	if( !(GetUserFlagBits(iAttacker) & ADMFLAG_BAN) )
		return Plugin_Continue;
	
	if(g_Players[iAttacker]<=0)
		return Plugin_Continue;
	
	if( StrEqual(g_GameType, "tf", true) && g_tf2sLibrary )
		if( GetEventInt(hEvent, "death_flags") & TF_DEATHFLAG_DEADRINGER)
			return Plugin_Continue;
	
	// if everything is okay:
	if(g_Players[iAttacker]==1)
	{
		if( g_VictimsCount==0 ) return Plugin_Continue;
		
		new String:sWeapon[64];
		GetClientWeapon(iAttacker, sWeapon, sizeof(sWeapon));
		if( StrContains(sWeapon, g_Weapon, false) < 0 ) return Plugin_Continue;
		
		// checking target-list:
		decl bool:bVictimFound;
		bVictimFound = false;
		for(new i = 0; i <= MAXPLAYERS; i++)
			if(g_VictimsArray[i]>0)
				if(g_VictimsArray[i] == iVictim)
				{
					bVictimFound = true;
					g_VictimsArray[i] = 0;
					g_VictimsCount--;
					break;
				}
		
		if(!bVictimFound) return Plugin_Continue;
	}
	
	if( StrEqual(g_GameType, "tf", true) )
		SetEventString(hEvent, "weapon_logclassname", "banhammer");
	
	// effects, byatch!
	PrintToChatAll("\x01* \x03%N\x01 humiliated by \x04BAN-Hammer\x01!!!", iVictim);
	CreateTimer(0.01, Timer_TimeToRunEffects, iVictim, TIMER_FLAG_NO_MAPCHANGE);
	
	if( StrEqual(g_GameType, "tf", true) && g_Annotations!=INVALID_HANDLE )
	{
		new String:sAnnotationText[32];
		GetConVarString(g_Annotations,sAnnotationText,sizeof(sAnnotationText));
		if( strlen(sAnnotationText)>2 )
		{
			decl String:sVictimName[64];
			decl String:sAttackerName[64];
			GetClientName(iVictim, sVictimName, sizeof(sVictimName));
			if(iAttacker>0)
				GetClientName(iAttacker, sAttackerName, sizeof(sAttackerName));
			else
				sAttackerName = "CONSOLE";
			ReplaceString(sAnnotationText, sizeof(sAnnotationText), "{victim}", sVictimName);
			ReplaceString(sAnnotationText, sizeof(sAnnotationText), "{attacker}", sAttackerName);
			new Handle:hTmpEvent = CreateEvent("show_annotation");
			if (hTmpEvent != INVALID_HANDLE)
			{
				decl Float:pos[3];
				GetClientAbsOrigin(iVictim, pos);
				SetEventInt(hTmpEvent, "id", GetRandomInt(1,1000)*GetRandomInt(1,1000));
				SetEventFloat(hTmpEvent, "worldPosX", pos[0]);
				SetEventFloat(hTmpEvent, "worldPosY", pos[1]);
				SetEventFloat(hTmpEvent, "worldPosZ", pos[2]);
				SetEventInt(hTmpEvent, "visibilityBitfield", 16777215);
				SetEventString(hTmpEvent, "text", sAnnotationText);
				SetEventFloat(hTmpEvent, "lifetime", 3.2);
				FireEvent(hTmpEvent);
			}
		}
	}
	
	// banning...
	new Handle:hDataPack;
	CreateDataTimer(3.25, Timer_TimeToBan, hDataPack, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(hDataPack, iVictim);
	WritePackCell(hDataPack, iAttacker);
	
	// everyone banned? so, its time to disable banhammer
	if( g_Players[iAttacker]==1 && g_VictimsCount==0 )
		FakeClientCommand(iAttacker, "bh_toggle");
	
	return Plugin_Continue;
}

public OnClientDisconnect(iClient)
{
	for(new cell = 0; cell <= MAXPLAYERS; cell++)
		if(g_VictimsArray[cell] == iClient)
		{
			g_VictimsArray[cell] = 0;
			g_VictimsCount--;
			if(IsClientInGame(iClient) && GetConVarBool(g_PreventRagequit))
				BanVictim(iClient);
		}
	if(g_VictimsCount==0)
		for(new iAdmin = 0; iAdmin <= MAXPLAYERS; iAdmin++)
			if(g_Players[iAdmin]==1 && (GetUserFlagBits(iAdmin) & ADMFLAG_BAN))
				FakeClientCommand(iAdmin, "bh_toggle");
}

public Action:Timer_TimeToRunEffects(Handle:hTimer, any:iClient)
{
	decl Float:fOrigin[3];
	GetClientAbsOrigin(iClient, fOrigin);	
	if( StrEqual(g_GameType, "tf", true) && g_tf2Library )
	{
		EmitSoundToAll("items/cart_explode.wav", 0, SNDCHAN_WEAPON, 0, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, _, fOrigin, NULL_VECTOR, true, 0.0);
		ShowParticle(fOrigin, "cinefx_goldrush", 2.0);
	}
	else
	{
		EmitSoundToAll("weapons/c4/c4_explode1.wav", 0, SNDCHAN_WEAPON, 0, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, _, fOrigin, NULL_VECTOR, true, 0.0);
		TE_SetupExplosion(fOrigin, g_iEntExplosionSprite, 100.0, 1, 0, 0, 0);
		TE_SendToAll();
	}
	decl iBodyEnt;
	iBodyEnt = GetEntPropEnt(iClient, Prop_Send, "m_hRagdoll");
	if(IsValidEdict(iBodyEnt))
		RemoveEdict(iBodyEnt);
	return Plugin_Handled;
}

public Action:Timer_TimeToBan(Handle:hTimer, Handle:hDataPack)
{
	ResetPack(hDataPack);
	new iClient = ReadPackCell(hDataPack);
#if !defined DEBUG
	// if its not a debug mode, then this is for real :D
	new iAdmin = ReadPackCell(hDataPack);
	BanVictim(iClient, iAdmin);
#endif
	if( StrEqual(g_GameType, "tf", true) )
	{
		decl Float:fOrigin[3];
		GetClientAbsOrigin(iClient, fOrigin);
		EmitSoundToAll("vo/announcer_victory.wav", 0, SNDCHAN_AUTO, 0, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, _, fOrigin, NULL_VECTOR, true, 0.0);
	}
	return Plugin_Handled;
}

public OnTF2ClassicCVarChange(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
{
	if( StrEqual(g_GameType, "tf", true) )
	{
		if ( StringToInt(sNewValue)==0 )
			g_Weapon = "fireaxe";
		else if ( StringToInt(sNewValue)==1 )
			g_Weapon = "wrench";
	}
}

public OnHL2AdminTeamCVarChange(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
{
	if( StrEqual(g_GameType, "hl2mp", true) )
	{
		if ( StrContains(sNewValue, "rebel", false) >= 0 )
			g_Weapon = "stunstick";
		else if ( StrContains(sNewValue, "combine", false) >= 0 )
			g_Weapon = "crowbar";
	}
}

stock bool:BanVictim(iClient, iAdmin=0)
{
	if(!IsValidClient(iClient))
		return false;
	if(!IsValidClient(iAdmin))
		iAdmin = 0;
	if(FindConVar("sb_version")!=INVALID_HANDLE)
	{
		if(iAdmin==0)
		{
			ServerCommand("sm_ban #%d %d \"Humiliated by BAN-Hammer\"", GetClientUserId(iClient), GetConVarInt(g_BanTime));
			ServerExecute();
		}
		else
			FakeClientCommand(iAdmin, "sm_ban #%d %d \"Humiliated by BAN-Hammer\"", GetClientUserId(iClient), GetConVarInt(g_BanTime));
		return true;
	}
	else
	{
		decl String:sBanReason[64];
		decl iBanDuration;
		iBanDuration = GetConVarInt(g_BanTime);
		if(iBanDuration>0)
			Format(sBanReason, sizeof(sBanReason), "You're banned for %d minutes on this server.", iBanDuration);
		else
			sBanReason = "You're permanently banned on this server.";
		return BanClient(iClient, iBanDuration, BANFLAG_AUTO, "Humiliated by BAN-Hammer", sBanReason);
	}
}

public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
    new particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", particlename);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, DeleteParticles, particle);
    }
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
    if (IsValidEntity(particle))
    {
        new String:classname[64];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false))
            RemoveEdict(particle);
    }
}

stock bool:IsValidClient(iClient)
{
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    return IsClientInGame(iClient);
}

stock SaveKeyTime(any:iClient)
{
	if(iClient)
		g_LastKeyCheckTime[iClient] = GetGameTime();
}

stock bool:CheckElapsedTime(any:iClient, Float:time)
{
	if(iClient)
		if( IsClientInGame(iClient) )
			if( (GetGameTime() - g_LastKeyCheckTime[iClient]) >= time )
				return true;
	return false;
}