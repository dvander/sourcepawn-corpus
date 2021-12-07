#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_NAME "Rush Restrict"
#define PLUGIN_AUTHOR "Avo"
#define PLUGIN_DESCRIPTION "Enable some restrictions during rush"
#define PLUGIN_VERSION "1.1.2"

#define RESTRICT_MOLOTOV 					0
#define RESTRICT_INCGRENADE				1
#define RESTRICT_HEGRENADE				2
#define RESTRICT_FLASHBANG				3
#define RESTRICT_SMOKEGRENADE			4
#define RESTRICT_DECOY						5
#define RESTRICT_GRENADES_NUMBER	6

new Handle:g_hCVarEnabled = INVALID_HANDLE;
new Handle:g_hCVarTOnBombPlanted = INVALID_HANDLE;
new Handle:g_hCVarCTOnBombPlanted = INVALID_HANDLE;
new Handle:g_hCVarTOnBombGrounded = INVALID_HANDLE;
new Handle:g_hCVarCTOnBombGrounded = INVALID_HANDLE;
new Handle:g_hCVarTOnBombCarried = INVALID_HANDLE;
new Handle:g_hCVarCTOnBombCarried = INVALID_HANDLE;
new Handle:g_ahCVarGrenades[RESTRICT_GRENADES_NUMBER] = {INVALID_HANDLE, INVALID_HANDLE, INVALID_HANDLE, INVALID_HANDLE, INVALID_HANDLE, INVALID_HANDLE};
new Handle:g_hCVarScope = INVALID_HANDLE;
new Handle:g_hCVarDropBomb = INVALID_HANDLE;
new Handle:g_hCVarInformOnConnectDelay = INVALID_HANDLE;
new Handle:g_hCVarInformGrenades = INVALID_HANDLE;
new Handle:g_hCVarInformScope = INVALID_HANDLE;
new Handle:g_hCVarInformDropBomb = INVALID_HANDLE;
new Handle:g_hCVarInformRepetition = INVALID_HANDLE;

new bool:g_bCVarEnabled = true;
new bool:g_bCVarTOnBombPlanted = false;
new bool:g_bCVarCTOnBombPlanted = false;
new bool:g_bCVarTOnBombGrounded = false;
new bool:g_bCVarCTOnBombGrounded = false;
new bool:g_bCVarTOnBombCarried = false;
new bool:g_bCVarCTOnBombCarried = false;
new bool:g_abCVarGrenades[RESTRICT_GRENADES_NUMBER] = {false, false, false, false, false, false};
new bool:g_bCVarScope = false;
new bool:g_bCVarDropBomb = false;
new Float:g_fCVarInformOnConnectDelay = 0.0;
new bool:g_bCVarInformGrenades = false;
new bool:g_bCVarInformScope = false;
new bool:g_bCVarInformDropBomb = false;

enum InformRepetition
{
	InformRepetition_PerMap,
	InformRepetition_PerRound,
	InformRepetition_Always
}

new InformRepetition:g_eCVarInformRepetition = InformRepetition:InformRepetition_PerMap;

enum BombStatus
{
	BombStatus_None,
	BombStatus_Carried,
	BombStatus_Planted,
	BombStatus_Grounded
}

new BombStatus:g_eBombStatus = BombStatus:BombStatus_None;

new Handle:g_hCVarWarmupRoundActive = INVALID_HANDLE;
new bool:g_bCVarWarmupRoundActive = false;

new bool:g_bRestrictT = false;
new bool:g_bRestrictCT = false;

new bool:g_bRestrictGrenades = false;

new bool:g_abInformedGrenades[MAXPLAYERS+1];
new bool:g_abInformedScope[MAXPLAYERS+1];
new bool:g_abInformedDropBomb[MAXPLAYERS+1];
new bool:g_bInformedGrenadesOccured = false;
new bool:g_bInformedScopeOccured = false;
new bool:g_bInformedDropBombOccured = false;

new g_pFovOffset;
new g_pZoomOffset;

new String:g_aszGrenadesTextList[][] = {"Molotov", "IncGrenade", "HeGrenade", "Flashbang", "SmokeGrenade", "Decoy"};
new String:g_aszGrenadesNameList[][] = {"weapon_molotov", "weapon_incgrenade", "weapon_hegrenade", "weapon_flashbang", "weapon_smokegrenade", "weapon_decoy"};
new String:g_szGrenadesText[256] = "";
new String:g_szFullText[256] = "";
new g_iGrenadesTextSize = 256;
new g_iFullTextSize = 256;

new g_iWeaponC4;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://www.teamvec.fr/"
}

public OnPluginStart()
{
	g_hCVarEnabled = CreateConVar( "rushrestrict_enabled", "1", "Enable Rush Restrict" );
	CreateConVar("rushrestrict_version", PLUGIN_VERSION, "Rush Restrict version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	if( GetConVarInt( g_hCVarEnabled ) != 0 )
	{
		HookEvent( "round_start", EventRoundStart );
		HookEvent( "bomb_planted", Event_BombPlanted );
		HookEvent( "bomb_defused", Event_BombDefused );
		HookEvent( "bomb_exploded", Event_BombExploded );
		HookEvent( "bomb_dropped", Event_BombDropped );
		HookEvent( "bomb_pickup", Event_BombPickup );
			
		g_hCVarTOnBombPlanted = CreateConVar("rushrestrict_T_onbombplanted", "0", "Enable restrictions for T when bomb is planted", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		g_hCVarCTOnBombPlanted = CreateConVar("rushrestrict_CT_onbombplanted", "0", "Enable restrictions for CT when bomb is planted", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		g_hCVarTOnBombGrounded = CreateConVar("rushrestrict_T_onbombgrounded", "0", "Enable restrictions for T when bomb is grounded", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		g_hCVarCTOnBombGrounded = CreateConVar("rushrestrict_CT_onbombgrounded", "0", "Enable restrictions for CT when bomb is grounded", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		g_hCVarTOnBombCarried = CreateConVar("rushrestrict_T_onbombcarried", "1", "Enable restrictions for T when bomb is carried", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		g_hCVarCTOnBombCarried = CreateConVar("rushrestrict_CT_onbombcarried", "1", "Enable restrictions for CT when bomb is carried", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		g_ahCVarGrenades[RESTRICT_MOLOTOV] = CreateConVar("rushrestrict_molotov", "1", "Restrict molotov use", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		g_ahCVarGrenades[RESTRICT_INCGRENADE] = CreateConVar("rushrestrict_incgrenade", "1", "Restrict incendiary use", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		g_ahCVarGrenades[RESTRICT_HEGRENADE] = CreateConVar("rushrestrict_hegrenade", "0", "Restrict HE grenade use", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		g_ahCVarGrenades[RESTRICT_FLASHBANG] = CreateConVar("rushrestrict_flashbang", "0", "Restrict flash use", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		g_ahCVarGrenades[RESTRICT_SMOKEGRENADE] = CreateConVar("rushrestrict_smokegrenade", "0", "Restrict smoke use", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		g_ahCVarGrenades[RESTRICT_DECOY] = CreateConVar("rushrestrict_decoy", "0", "Restrict decoy use", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		g_hCVarScope = CreateConVar("rushrestrict_scope", "1", "Restrict scope use", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		g_hCVarDropBomb = CreateConVar("rushrestrict_dropbomb", "1", "Restrict drop bomb", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		g_hCVarInformOnConnectDelay = CreateConVar("rushrestrict_inform_onconnectdelay", "15.0", "Inform each player on connection after this delay. [-1 = Disabled, 0+ = Delay after connection]", FCVAR_PLUGIN, true, -1.0);
		g_hCVarInformGrenades = CreateConVar("rushrestrict_inform_grenades", "1", "Inform player when they try to use grenade (if restricted)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		g_hCVarInformScope = CreateConVar("rushrestrict_inform_scope", "1", "Inform player when they try to scope (if restricted)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		g_hCVarInformDropBomb = CreateConVar("rushrestrict_inform_dropbomb", "1", "Inform player when they try to drop bomb (if restricted)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
		g_hCVarInformRepetition = CreateConVar("rushrestrict_inform_repetition", "1", "Repetition of each information. [0 = First time per map, 1 = First time per round]", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
		AutoExecConfig(true, "rushrestrict");

		g_hCVarWarmupRoundActive = FindConVar("sm_warmupround_active");
		
		g_pFovOffset = FindSendPropOffs("CBasePlayer", "m_iFOV");
		g_pZoomOffset = FindSendPropOffs("CBasePlayer", "m_iDefaultFOV");
		
		if (g_hCVarWarmupRoundActive != INVALID_HANDLE)
		{
			HookConVarChange(g_hCVarWarmupRoundActive, OnConVarChange);
		}
		
		if (g_eCVarInformRepetition != InformRepetition:InformRepetition_Always)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				g_abInformedGrenades[i] = false;
				g_abInformedScope[i] = false;
				g_abInformedDropBomb[i] = false;
			}
		}

		LoadTranslations("common.phrases");
		LoadTranslations("rushrestrict.phrases");
	
		PrintToServer("SourceMod Rush Restrict %s has been loaded successfully.", PLUGIN_VERSION);
		
		GetConVars();
	}
}
    
public OnConVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
  GetConVars();
}

public OnConfigsExecuted()
{
  GetConVars();
}

GetConVars()
{
	if (g_hCVarWarmupRoundActive != INVALID_HANDLE)
		g_bCVarWarmupRoundActive = GetConVarBool(g_hCVarWarmupRoundActive);
	g_bCVarEnabled = GetConVarBool(g_hCVarEnabled);
	g_bCVarTOnBombPlanted = GetConVarBool(g_hCVarTOnBombPlanted);
	g_bCVarCTOnBombPlanted = GetConVarBool(g_hCVarCTOnBombPlanted);
	g_bCVarTOnBombGrounded = GetConVarBool(g_hCVarTOnBombGrounded);
	g_bCVarCTOnBombGrounded = GetConVarBool(g_hCVarCTOnBombGrounded);
	g_bCVarTOnBombCarried = GetConVarBool(g_hCVarTOnBombCarried);
	g_bCVarCTOnBombCarried = GetConVarBool(g_hCVarCTOnBombCarried);
	g_bRestrictGrenades = false;
	for (new i = 0 ; i < RESTRICT_GRENADES_NUMBER ; i++)
	{
		g_abCVarGrenades[i] = GetConVarBool(g_ahCVarGrenades[i]);
		g_bRestrictGrenades |= g_abCVarGrenades[i];
	}
	g_bCVarScope = GetConVarBool(g_hCVarScope);
	g_bCVarDropBomb = GetConVarBool(g_hCVarDropBomb);
	g_fCVarInformOnConnectDelay = GetConVarFloat(g_hCVarInformOnConnectDelay);
	g_bCVarInformGrenades = GetConVarBool(g_hCVarInformGrenades);
	g_bCVarInformScope = GetConVarBool(g_hCVarInformScope);
	g_bCVarInformDropBomb = GetConVarBool(g_hCVarInformDropBomb);
	switch (GetConVarInt(g_hCVarInformRepetition))
	{
		case 0:
		{
			g_eCVarInformRepetition = InformRepetition:InformRepetition_PerMap;
		}
		case 1:
		{
			g_eCVarInformRepetition = InformRepetition:InformRepetition_PerRound;
		}
		case 2:
		{
			g_eCVarInformRepetition = InformRepetition:InformRepetition_Always;
		}
	} 
	
	new bool:bFirst = true;
	if (g_bRestrictGrenades)
	{
		for (new i = 0 ; i < RESTRICT_GRENADES_NUMBER ; i++)
		{
			if (g_abCVarGrenades[i])
			{
				if (bFirst)
				{
					Format(g_szGrenadesText, g_iGrenadesTextSize-1, "%t", g_aszGrenadesTextList[i]);
					bFirst = false;
				}
				else
				{
					Format(g_szGrenadesText, g_iGrenadesTextSize-1, "%s, %t", g_szGrenadesText, g_aszGrenadesTextList[i]);
				}
			}
		}
		strcopy(g_szFullText, g_iFullTextSize-1, g_szGrenadesText);
	}
	if (g_bCVarScope)
	{
		if (bFirst)
		{
			Format(g_szFullText, g_iFullTextSize-1, "%t", "Scope");
			bFirst = false;
		}
		else
		{
			Format(g_szFullText, g_iFullTextSize-1, "%s, %t", g_szFullText, "Scope");
		}
	}
	if (g_bCVarDropBomb)
	{
		if (bFirst)
		{
			Format(g_szFullText, g_iFullTextSize-1, "%t", "DropBomb");
			bFirst = false;
		}
		else
		{
			Format(g_szFullText, g_iFullTextSize-1, "%s, %t", g_szFullText, "DropBomb");
		}
	}
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	if (!g_bCVarEnabled)
		return true;	
	
	if (g_eCVarInformRepetition != InformRepetition:InformRepetition_Always)
	{
		g_abInformedGrenades[client] = false;
		g_abInformedScope[client] = false;
		g_abInformedDropBomb[client] = false;
	}
	
	if (g_fCVarInformOnConnectDelay >= 0)
		CreateTimer(g_fCVarInformOnConnectDelay, TimerAdvertise, client);
	
	return true;
}

public Action:TimerAdvertise(Handle:timer, any:client)
{
		if (IsClientInGame(client))
			PrintToChat(client, "\x01\x0B\x04[RushRestrict]\x01 %t %s", "Rush restrictions enabled:", g_szFullText);
		else if (IsClientConnected(client))
			CreateTimer(5.0 + g_fCVarInformOnConnectDelay, TimerAdvertise, client);
}

public Action:EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_eCVarInformRepetition == InformRepetition:InformRepetition_PerRound)
	{
		if (g_bCVarInformGrenades && g_bInformedGrenadesOccured)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				g_abInformedGrenades[i] = false;
			}
			g_bInformedGrenadesOccured = false;
		}
		if (g_bCVarInformScope && g_bInformedScopeOccured)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				g_abInformedScope[i] = false;
			}
			g_bInformedScopeOccured = false;
		}
		if (g_bCVarInformDropBomb && g_bInformedDropBombOccured)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				g_abInformedDropBomb[i] = false;
			}
			g_bInformedDropBombOccured = false;
		}
	}
}

public Action:Event_BombPlanted( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( !g_bCVarWarmupRoundActive )
	{
		ChangeBombeStatus(BombStatus:BombStatus_Planted);
	}
}

public Action:Event_BombDefused( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( !g_bCVarWarmupRoundActive )
	{
		ChangeBombeStatus(BombStatus:BombStatus_None);
	}
}

public Action:Event_BombExploded( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( !g_bCVarWarmupRoundActive )
	{
		ChangeBombeStatus(BombStatus:BombStatus_None);
	}
}

public Action:Event_BombDropped( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( !g_bCVarWarmupRoundActive )
	{
		ChangeBombeStatus(BombStatus:BombStatus_Grounded);
	}
}

public Action:Event_BombPickup( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( !g_bCVarWarmupRoundActive )
	{
		ChangeBombeStatus(BombStatus:BombStatus_Carried);
	}
}

ChangeBombeStatus(BombStatus:status)
{
	g_eBombStatus = status;
	
	switch (g_eBombStatus)
	{
		case (BombStatus:BombStatus_None):
		{
			g_bRestrictT = false;
			g_bRestrictCT = false;
		}
		case (BombStatus:BombStatus_Planted):
		{
			g_bRestrictT = g_bCVarTOnBombPlanted;
			g_bRestrictCT = g_bCVarCTOnBombPlanted;
		}
		case (BombStatus:BombStatus_Grounded):
		{
			g_bRestrictT = g_bCVarTOnBombGrounded;
			g_bRestrictCT = g_bCVarCTOnBombGrounded;
		}
		case (BombStatus:BombStatus_Carried):
		{
			g_bRestrictT = g_bCVarTOnBombCarried;
			g_bRestrictCT = g_bCVarCTOnBombCarried;
		}
	}
	
	if (g_bCVarScope)
	{
		new iMaxClients = GetMaxClients();
		decl String:sWeapon[64];
		new iWeapon;
		for (new i = 1; i <= iMaxClients; i ++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
			{
				GetClientWeapon(i, sWeapon, 64);
				if(	IsScopableWeapon(sWeapon) )
				{
					SetEntData(i, g_pFovOffset, 90, 4, true);
					SetEntData(i, g_pZoomOffset, 90, 4, true);
					iWeapon = GetPlayerWeaponSlot(i, 0);
					if (IsValidEdict(iWeapon)) 
					{
						RemovePlayerItem(i, iWeapon);
						RemoveEdict(iWeapon);
						GivePlayerItem(i, sWeapon);
					}
				}
			}
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (g_bCVarEnabled && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (buttons & IN_ATTACK) 
		{
			if (g_bRestrictGrenades)
			{
				new iTeam = GetClientTeam(client);
				if ( (iTeam == CS_TEAM_T && g_bRestrictT) || (iTeam == CS_TEAM_CT && g_bRestrictCT) )
				{
					new bRestrict = false;
					decl String:sWeapon[64];
					GetClientWeapon(client, sWeapon, 64);
					for (new i = 0 ; i < RESTRICT_GRENADES_NUMBER ; i++)
					{
						if(StrEqual(sWeapon, g_aszGrenadesNameList[i]))
						{
							bRestrict = g_abCVarGrenades[i];
							break;
						}
					}
					if (bRestrict)
					{
						buttons &= ~IN_ATTACK;
						if (g_bCVarInformGrenades && (g_eCVarInformRepetition == InformRepetition:InformRepetition_Always || !g_abInformedGrenades[client]))
						{
							PrintToChat(client, "\x01\x0B\x04[RushRestrict]\x01 %t (%s)", "Grenades restricted during rush!", g_szGrenadesText);
							if (g_eCVarInformRepetition != InformRepetition:InformRepetition_Always)
							{
								g_bInformedGrenadesOccured = true;
								g_abInformedGrenades[client] = true;
							}
						}
						return Plugin_Changed;
					}
				}
			}
		}
		else if (buttons & IN_ATTACK2) 
		{
			if (g_bCVarScope)
			{
				new iTeam = GetClientTeam(client);
				if ( (iTeam == CS_TEAM_T && g_bRestrictT) || (iTeam == CS_TEAM_CT && g_bRestrictCT) )
				{
					decl String:sWeapon[64];
					GetClientWeapon(client, sWeapon, 64);
					if(	IsScopableWeapon(sWeapon) )
					{
						SetEntData(client, g_pFovOffset, 90, 4, true);
						SetEntData(client, g_pZoomOffset, 90, 4, true);
						buttons &= ~IN_ATTACK2;
						if (g_bCVarInformScope && (g_eCVarInformRepetition == InformRepetition:InformRepetition_Always || !g_abInformedScope[client]))
						{
							PrintToChat(client, "\x01\x0B\x04[RushRestrict]\x01 %t", "Scope restricted during rush!");
							if (g_eCVarInformRepetition != InformRepetition:InformRepetition_Always)
							{
								g_bInformedScopeOccured = true;
								g_abInformedScope[client] = true;
							}
						}
						return Plugin_Changed;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:CS_OnCSWeaponDrop(client, weapon)
{
	if (g_bCVarEnabled && g_bCVarDropBomb)
	{
		if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && IsValidEdict(weapon))
		{
			decl String:sWeapon[64];
			GetEdictClassname(weapon, sWeapon, 64);
			if (StrEqual(sWeapon, "weapon_c4"))
			{
				g_iWeaponC4 = weapon;
				CreateTimer(0.1, TimerDropBomb, client);
			}
    }
	}
	return Plugin_Continue;
}

public Action:TimerDropBomb(Handle:timer, any:client)
{
		if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && IsValidEdict(g_iWeaponC4))
		{
			AcceptEntityInput(g_iWeaponC4, "kill");
			GivePlayerItem(client, "weapon_c4");
			if (g_bCVarInformDropBomb && (g_eCVarInformRepetition == InformRepetition:InformRepetition_Always || !g_abInformedDropBomb[client]))
			{
				PrintToChat(client, "\x01\x0B\x04[RushRestrict]\x01 %t", "Drop bomb not allowed, you still have it!");
				if (g_eCVarInformRepetition != InformRepetition:InformRepetition_Always)
				{
					g_bInformedDropBombOccured = true;
					g_abInformedDropBomb[client] = true;
				}
			}
		}
}

bool:IsScopableWeapon(const String:sWeapon[])
{
	return (StrEqual(sWeapon, "weapon_ssg08") ||
					StrEqual(sWeapon, "weapon_sg556") ||
					StrEqual(sWeapon, "weapon_aug") ||
					StrEqual(sWeapon, "weapon_awp") ||
					StrEqual(sWeapon, "weapon_g3sg1") ||
					StrEqual(sWeapon, "weapon_scar20") );
}
