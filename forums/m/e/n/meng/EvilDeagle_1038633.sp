/*

	Evil Deagle.

*/

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define NAME "Evil Deagle"
#define VERSION "1.3"

/* the admin flag required for the menu and all commands */
#define ADMFLAG ADMFLAG_RCON

new Handle:g_hAdminMenu;
new bool:g_bEnabled;
new Handle:g_hSpawnsADT;
new Handle:g_cvarEfxColor;
new Handle:g_cvarRecoilMul, Float:g_fRecoilMul;
new Handle:g_cvarDamage, String:g_sDamage[8];
new g_iPointHurt, g_iEDEntityIndex, g_iEDOwnerIndex, Float:g_fLastPosVec[3], bool:g_bIsRoundEnd;
new g_ihOwnerEntity, g_iiClip1, g_iiAmmo;
new g_iRingColor[4], g_iBeamSprite, g_iHaloSprite, g_iGlowSprite;
new String:g_sMapCfgPath[PLATFORM_MAX_PATH];

public Plugin:myinfo = 
{
	name = NAME,
	author = "meng",
	version = VERSION,
	description = "special deagle for CSS",
	url = "http://www.sourcemod.net"
};

public OnPluginStart()
{
	CreateConVar("sm_evildeagle_version", VERSION, NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvarEfxColor = CreateConVar("sm_evildeagle_efxcolor", "0", "The color of the evil deagle's location effects. [0 = red | 1 = gold]", _, true, 0.0, true, 1.0);
	g_cvarRecoilMul = CreateConVar("sm_evildeagle_recoil", "400", "Recoil effect adjustment. [range 100 - 700]", _, true, 100.0, true, 700.0);
	g_cvarDamage = CreateConVar("sm_evildeagle_damage", "300", "Damage adjustment. [range 100 - 700]", _, true, 100.0, true, 700.0);
	HookConVarChange(g_cvarRecoilMul, OnSettingChanged);
	HookConVarChange(g_cvarDamage, OnSettingChanged);

	g_hSpawnsADT = CreateArray(3);

	g_ihOwnerEntity = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	g_iiClip1 = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
	g_iiAmmo = FindSendPropInfo("CCSPlayer", "m_iAmmo");

	RegAdminCmd("sm_evildeagle", CommandEDControl, ADMFLAG);
	RegAdminCmd("sm_evildeagle_show", CommandShowPos, ADMFLAG);
	RegAdminCmd("sm_evildeagle_save", CommandSavePos, ADMFLAG);
	RegAdminCmd("sm_evildeagle_remove", CommandRemovePos, ADMFLAG);

	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
	HookEvent("weapon_fire", EventWeaponFire);
	HookEvent("player_hurt", EventPlayerHurt);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("round_end", EventRoundEnd, EventHookMode_PostNoCopy);

	decl String:configspath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, configspath, sizeof(configspath), "configs/evil-deagle");
	if (!DirExists(configspath))
	{
		CreateDirectory(configspath, 0x0265);
	}

	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnMapStart()
{
	g_iBeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_iHaloSprite = PrecacheModel("materials/sprites/halo01.vmt");

	decl String:map[64];
	GetCurrentMap(map, sizeof(map));
	BuildPath(Path_SM, g_sMapCfgPath, sizeof(g_sMapCfgPath), "configs/evil-deagle/%s.cfg", map);

	new Handle:hKV = CreateKeyValues("EDSP");
	if (FileToKeyValues(hKV, g_sMapCfgPath) && KvGotoFirstSubKey(hKV, false))
	{
		decl Float:fVec[3];
		do
		{
			KvGetVector(hKV, NULL_STRING, fVec);
			PushArrayArray(g_hSpawnsADT, fVec);
		} while (KvGotoNextKey(hKV, false));
	}

	CloseHandle(hKV);
}

public OnConfigsExecuted()
{
	if (GetConVarInt(g_cvarEfxColor) == 1)
	{
		g_iRingColor = {150, 125, 0, 255};
		g_iGlowSprite = PrecacheModel("sprites/yellowglow1.vmt");
	}
	else
	{
		g_iRingColor = {255, 25, 15, 255};
		g_iGlowSprite = PrecacheModel("sprites/redglow3.vmt");
	}

	g_fRecoilMul = -1.0*GetConVarFloat(g_cvarRecoilMul);
	GetConVarString(g_cvarDamage, g_sDamage, sizeof(g_sDamage));
}

public OnSettingChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_cvarRecoilMul)
	{
		g_fRecoilMul = (-1.0 * StringToFloat(newValue));
	}
	else if (convar == g_cvarDamage)
	{
		strcopy(g_sDamage, sizeof(g_sDamage), newValue);
	}
}

public OnMapEnd()
{
	ClearArray(g_hSpawnsADT);
}

public Action:CommandEDControl(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_evildeagle <0/1>");
		return Plugin_Handled;
	}

	decl String:sArg[8];
	GetCmdArgString(sArg, sizeof(sArg));
	new ibuffer = StringToInt(sArg);
	switch (ibuffer)
	{
		case 0:
		{
			g_bEnabled = false;
			ReplyToCommand(client, "\x04[Evil Deagle] \x03Plugin DISABLED");
		}
		case 1:
		{
			if (GetArraySize(g_hSpawnsADT) < 1)
			{
				g_bEnabled = false;
				ReplyToCommand(client, "\x04[Evil Deagle] \x03No saved spawn positions. Plugin DISABLED");
			}
			else
			{
				g_bEnabled = true;
				ReplyToCommand(client, "\x04[Evil Deagle] \x03Plugin ENABLED");
			}
		}
	}

	return Plugin_Handled;
}

public Action:CommandShowPos(client, args)
{
	new arraySize = GetArraySize(g_hSpawnsADT);
	if (arraySize < 1)
	{
		ReplyToCommand(client, "\x04[Evil Deagle] \x03No saved spawn positions.");
		return Plugin_Handled;
	}


	CreateTimer(1.0, TimerShowSpawns, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	ReplyToCommand(client, "\x04[Evil Deagle] \x03Showing spawns for 1 minute.");

	return Plugin_Handled;
}

public Action:TimerShowSpawns(Handle:timer, any:client)
{
	static timesRepeated;
	new arraySize = GetArraySize(g_hSpawnsADT);

	if ((timesRepeated++ > 60) || (arraySize < 1) || !IsClientInGame(client))
	{
		timesRepeated = 0;
		return Plugin_Stop;
	}

	decl Float:fVec[3];
	for (new i = 0; i < arraySize; i++)
	{
		GetArrayArray(g_hSpawnsADT, i, fVec);
		TE_SetupGlowSprite(fVec, g_iGlowSprite, 1.0, 0.7, 217);
		TE_SendToClient(client);
	}

	PrintHintText(client, "Total Saved Spawns: %i", arraySize);

	return Plugin_Continue;
}

public Action:CommandSavePos(client, args)
{
	new Handle:hKV = CreateKeyValues("EDSP");
	decl Float:fVec[3], String:sBuffer[32];
	GetClientAbsOrigin(client, fVec);
	fVec[2] += 16.0;
	Format(sBuffer, sizeof(sBuffer), "vec:%i%i", RoundToFloor(FloatAbs(fVec[0])), RoundToFloor(FloatAbs(fVec[1])));
	FileToKeyValues(hKV, g_sMapCfgPath);
	KvSetVector(hKV, sBuffer, fVec);
	KeyValuesToFile(hKV, g_sMapCfgPath);
	PushArrayArray(g_hSpawnsADT, fVec);
	ReplyToCommand(client, "\x04[Evil Deagle] \x03Spawn position saved! [total spawn positions: %d]", GetArraySize(g_hSpawnsADT));
	CloseHandle(hKV);

	return Plugin_Handled;
}

public Action:CommandRemovePos(client, args)
{
	decl Float:client_fVec[3], Float:spawn_fVec[3], String:sBuffer[32];
	GetClientAbsOrigin(client, client_fVec);
	client_fVec[2] += 16.0;
	new arraySize = GetArraySize(g_hSpawnsADT);
	if (arraySize > 0)
	{
		for (new i = 0; i < arraySize; i++)
		{
			GetArrayArray(g_hSpawnsADT, i, spawn_fVec);
			if (GetVectorDistance(client_fVec, spawn_fVec) < 48.0)
			{
				new Handle:hKV = CreateKeyValues("EDSP");
				FileToKeyValues(hKV, g_sMapCfgPath);
				Format(sBuffer, sizeof(sBuffer), "vec:%i%i", RoundToFloor(FloatAbs(spawn_fVec[0])), RoundToFloor(FloatAbs(spawn_fVec[1])));
				if (KvJumpToKey(hKV, sBuffer))
				{
					KvDeleteThis(hKV);
					RemoveFromArray(g_hSpawnsADT, i);
					KvRewind(hKV);
					KeyValuesToFile(hKV, g_sMapCfgPath);
					ReplyToCommand(client, "\x04[Evil Deagle] \x03Spawn position successfully removed!");
				}
				else
				{
					LogError("Error removing spawn position. Invalid KV key (%s).", sBuffer);
				}

				CloseHandle(hKV);

				return Plugin_Handled;
			}
		}
	}

	ReplyToCommand(client, "\x04[Evil Deagle] \x03No valid spawn position found.");

	return Plugin_Handled;
}

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
	{
		return;
	}

	if (GetArraySize(g_hSpawnsADT) < 1)
	{
		g_bEnabled = false;
		return;
	}

	g_bIsRoundEnd = false;
	g_iEDEntityIndex = -1;
	g_iEDOwnerIndex = -1;
	g_fLastPosVec[0] = 0.0;
	g_iPointHurt = CreateEntityByName("point_hurt");
	DispatchSpawn(g_iPointHurt);
	CreateTimer(1.0, TimerTrackED, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bIsRoundEnd = true;
}

SpawnNewED(spott)
{
	new entity = CreateEntityByName("weapon_deagle");
	DispatchSpawn(entity);
	decl Float:fVec[3];
	switch (spott)
	{
		case 0: /* array position */
		{
			new arraysize = GetArraySize(g_hSpawnsADT);
			if (arraysize < 1)
			{
				g_bEnabled = false;
				return;
			}
			GetArrayArray(g_hSpawnsADT, GetURandomIntRange(0, arraysize-1), fVec);
		}
		case 1: /* last owner position */
		{
			fVec = g_fLastPosVec;
		}
	}
	TeleportEntity(entity, fVec, NULL_VECTOR, NULL_VECTOR);
	SetEntData(entity, g_iiClip1, 1);
	g_iEDEntityIndex = entity;
}

public Action:TimerTrackED(Handle:timer)
{
	if (g_bIsRoundEnd)
	{
		return Plugin_Stop;
	}

	if (!IsValidEntity(g_iEDEntityIndex))
	{
		SpawnNewED(g_fLastPosVec[0] == 0.0 ? 0 : 1);
		return Plugin_Continue;
	}

	if ((g_iEDOwnerIndex = GetEntDataEnt2(g_iEDEntityIndex, g_ihOwnerEntity)) != -1)
	{
		if (GetEntData(g_iEDEntityIndex, g_iiClip1) > 1)
		{
			SetEntData(g_iEDEntityIndex, g_iiClip1, 1);
		}
		if (GetEntData(g_iEDOwnerIndex, g_iiAmmo + 4) > 1)
		{
			SetEntData(g_iEDOwnerIndex, g_iiAmmo + 4, 0);
		}

		return Plugin_Continue;
	}

	decl Float:fVec[3];
	GetEntPropVector(g_iEDEntityIndex, Prop_Data, "m_vecOrigin", fVec);
	TE_SetupGlowSprite(fVec, g_iGlowSprite, 1.0, 0.7, 217);
	TE_SendToAll();
	fVec[2] += 3;
	TE_SetupBeamRingPoint(fVec, 8.0, 36.0, g_iBeamSprite, g_iHaloSprite, 0, 10, 1.0, 7.0, 1.0, g_iRingColor, 7, 0);
	TE_SendToAll();

	return Plugin_Continue;
}

public EventWeaponFire(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (!g_bEnabled)
	{
		return;
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client == g_iEDOwnerIndex)
	{
		decl String:weapon[16];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		if (StrEqual(weapon, "deagle"))
		{
			SetEntData(client, g_iiAmmo + 4, 1);
			if (GetEntData(g_iEDEntityIndex, g_iiClip1) == 1)
			{
				CreateTimer(0.01, TimerRecoil, client);
			}
		}
	}
}

public Action:TimerRecoil(Handle:timer, any:client)
{
	static Float:fPlayerAng[3], Float:fPlayerVel[3], Float:fPush[3];
	GetClientEyeAngles(client, fPlayerAng);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fPlayerVel);
	fPlayerAng[0] *= -1.0;
	fPlayerAng[0] = DegToRad(fPlayerAng[0]);
	fPlayerAng[1] = DegToRad(fPlayerAng[1]);
	fPush[0] = g_fRecoilMul*Cosine(fPlayerAng[0])*Cosine(fPlayerAng[1])+fPlayerVel[0];
	fPush[1] = g_fRecoilMul*Cosine(fPlayerAng[0])*Sine(fPlayerAng[1])+fPlayerVel[1];
	fPush[2] = g_fRecoilMul*Sine(fPlayerAng[0])+fPlayerVel[2]; 
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fPush);
}

public EventPlayerHurt(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (!g_bEnabled)
	{
		return;
	}

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker == g_iEDOwnerIndex)
	{
		decl String:weapon[16];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		if (StrEqual(weapon, "deagle") && IsValidEntity(g_iPointHurt))
		{
			new victim = GetClientOfUserId(GetEventInt(event,"userid"));
			decl Float:attackerPos[3];
			GetClientAbsOrigin(attacker, attackerPos);
			TeleportEntity(g_iPointHurt, attackerPos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(victim, "targetname", "hurt");
			DispatchKeyValue(g_iPointHurt, "DamageTarget", "hurt");
			DispatchKeyValue(g_iPointHurt, "Damage", g_sDamage);
			DispatchKeyValue(g_iPointHurt, "DamageType", "0");
			AcceptEntityInput(g_iPointHurt, "Hurt", attacker);
			DispatchKeyValue(victim, "targetname", "nohurt");
		}
	}
}

public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (!g_bEnabled)
	{
		return;
	}

	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (client == g_iEDOwnerIndex)
	{
		GetClientAbsOrigin(client, g_fLastPosVec);
		g_fLastPosVec[2] += 16.0;
	}
}

/*
	get U random int. *added v1.3 *thx to psychonic
*/

stock GetURandomIntRange(min, max)
{
	return (GetURandomInt() % (max-min+1)) + min;
}  

/* 
	menu support *added v1.3 
*/

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		g_hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == g_hAdminMenu)
	{
		return;
	}

	g_hAdminMenu = topmenu;
	new TopMenuObject:serverCmds = FindTopMenuCategory(g_hAdminMenu, ADMINMENU_SERVERCOMMANDS);
	AddToTopMenu(g_hAdminMenu, "sm_evildeagle", TopMenuObject_Item, TopMenuHandler, serverCmds, "sm_evildeagle", ADMFLAG);
}

public TopMenuHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Evil Deagle");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		MainMenu(client);
	}
}

MainMenu(client)
{
	new Handle:menu = CreateMenu(MainMenuHandler);
	SetMenuTitle(menu, "Evil Deagle");
	AddMenuItem(menu, "0", "Enable Plugin");
	AddMenuItem(menu, "1", "Disable Plugin");
	AddMenuItem(menu, "2", "Show Spawns");
	AddMenuItem(menu, "3", "Save New Spawn");
	AddMenuItem(menu, "4", "Remove Spawn");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MainMenuHandler(Handle:menu, MenuAction:action, client, selection)
{
	if (action == MenuAction_Select)
	{
		decl String:sBuffer[7], iBuffer;
		GetMenuItem(menu, selection, sBuffer, sizeof(sBuffer));
		iBuffer = StringToInt(sBuffer);
		switch (iBuffer)
		{
			case 0:
			{
				FakeClientCommand(client, "say /evildeagle 1");
			}
			case 1:
			{
				FakeClientCommand(client, "say /evildeagle 0");
			}
			case 2:
			{
				FakeClientCommand(client, "say /evildeagle_show");
				MainMenu(client);
			}
			case 3:
			{
				FakeClientCommand(client, "say /evildeagle_save");
				MainMenu(client);
			}
			case 4:
			{
				FakeClientCommand(client, "say /evildeagle_remove");
				MainMenu(client);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}