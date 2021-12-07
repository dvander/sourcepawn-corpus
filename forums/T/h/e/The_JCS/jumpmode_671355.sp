#include <sourcemod>
#include <sdktools>
#include <nextmap>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION  "1.4.1"

public Plugin:myinfo = 
{
	name = "Jump Mode",
	author = "TheJCS",
	description = "Utilities to TF2 Jump Maps",
	version = PLUGIN_VERSION,
	url = "http://kongbr.com.br"
}
static const TFClass_MaxAmmo[TFClassType][3] =
{
  {-1, -1, -1}, {32, 36, -1},
  {25, 75, -1}, {16, 32, -1},
  {16, 24, -1}, {150, -1, -1},
  {200, 32, -1}, {200, 32, -1},
  {24, -1, -1}, {32, 200, 200}
};

static const TFClass_MaxClip[TFClassType][2] = 
{
  {-1, -1}, {6, 12}, {25, 0}, {4, 6}, {4, 8}, 
  {40, -1}, {-1, 6}, {-1, 6}, {6, -1}, {6, 12}
}; 

new Handle:g_hPluginEnabled
new Handle:g_hTeleport
new Handle:g_hAutoTeleport
new Handle:g_hAutoRespawn
new Handle:g_hAutoHeal
new Handle:g_hAutoRessuply;
new Handle:g_hRessuply;
new Handle:g_hCriticals;
new Handle:g_hTFCriticals;
new Handle:g_hTFAutoTeamBalance;
new Handle:g_hTFUnbalanceLimit;
new Handle:g_hForceTeam;
new Handle:g_hRemoveCPs;
new Handle:g_hReachedCP;
new Handle:g_hChangeLevel;
new Handle:g_hKeywords;

new bool:g_bPluginEnabled
new bool:g_bCPTouched[33][8]
new bool:g_bTimerToChange;
new bool:g_bRoundEnd;

new Float:g_fLocation[33][3];

new g_iMaxClients, g_iCPs, g_iCPsTouched[33];


public OnPluginStart()
{
	CreateConVar("jm_version", PLUGIN_VERSION, "Jump Mode plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hPluginEnabled = CreateConVar("jm_enabled", "1", "Enable the Jump Mode", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	g_hTeleport = CreateConVar("jm_teleport_enabled", "1", "Enable the Jump Mode Teleporter", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hAutoTeleport = CreateConVar("jm_autoteleport", "1", "Enable the Jump Mode Auto Teleporter", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hAutoRespawn = CreateConVar("jm_autorespawn", "1", "Enable the Jump Mode Auto Respawn", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hAutoHeal = CreateConVar("jm_autoheal", "1", "Enable the Jump Mode Auto Healer", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hAutoRessuply = CreateConVar("jm_autoressuply", "1", "Enable the Jump Mode Auto Ressuply", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hRessuply = CreateConVar("jm_ressuply_enabled", "1", "Enable the Jump Mode Ressuply", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCriticals = CreateConVar("jm_criticals", "0", "Set Jump Mode Criticals", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	g_hForceTeam = CreateConVar("jm_forceteam", "0", "Force players to join on a specific team", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	g_hRemoveCPs = CreateConVar("jm_removecps", "1", "Remove Control Points from the map", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hReachedCP = CreateConVar("jm_cpmsg", "1", "Shows a message when the player reachs CP", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hChangeLevel = CreateConVar("jm_time", "5.0", "Time to change level, starting when a player reach all CPs.", FCVAR_PLUGIN, true, 0.0);
	g_hKeywords = CreateConVar("jm_keywords", "jump,rj_,skyscraper", "Keywords to search on the map name to active the plugin, seperated by commas", FCVAR_PLUGIN);
	
	g_hTFCriticals = FindConVar("tf_weapon_criticals");
	g_hTFAutoTeamBalance = FindConVar("mp_autoteambalance");
	g_hTFUnbalanceLimit = FindConVar("mp_teams_unbalance_limit");
	
	// Commands
	RegConsoleCmd("jm_saveloc", cmdSaveLoc, "Save your current position");
	RegConsoleCmd("jm_resetloc", cmdResetLoc, "Reset your saved location");	
	RegConsoleCmd("jm_teleport", cmdTeleport, "Teleport you to the saved position");
	RegConsoleCmd("jm_ressuply", cmdRessuply, "Ressuply your ammo");
	RegConsoleCmd("jm_help", cmdHelp, "Ressuply your ammo");

	HookEvent("teamplay_round_stalemate", eventRoundEnd);
	HookEvent("teamplay_round_win", eventRoundEnd);
	HookEvent("teamplay_round_start", eventRoundStart);
	HookEvent("player_changeclass", eventPlayerChangeClass);
	HookEvent("player_team", eventChangeTeam);
	HookEvent("player_death", eventPlayerDeath);
	HookEvent("player_spawn", eventPlayerSpawn);
	HookEvent("player_hurt", eventPlayerHurt);
	HookEvent("controlpoint_starttouch", eventTouchCP);

	HookConVarChange(g_hPluginEnabled, cvarEnabledChanged);
	HookConVarChange(g_hAutoRessuply, cvarRessuplyChanged);
	HookConVarChange(g_hAutoHeal, cvarRessuplyChanged);
	HookConVarChange(g_hRemoveCPs, cvarRemoveCPsChanged);
	HookConVarChange(g_hCriticals, cvarCriticalsChanged);
	HookConVarChange(g_hForceTeam, cvarForceTeamChanged);
	
	g_iMaxClients = GetMaxClients();
}

/*****************************************************
 * OnFunctions
 ****************************************************/
 
public OnConfigsExecuted()
{
	new iEnabled = GetConVarInt(g_hPluginEnabled);
	if(iEnabled == 0)
		TurnOffPlugin();
	else if(iEnabled == 1)
	{
		if(IsMapEnabled())
			TurnOnPlugin();
		else
			TurnOffPlugin();
	}
	else
		TurnOnPlugin();
}

public OnMapStart() {
	PrecacheSound("misc/achievement_earned.wav");
	AddFileToDownloadsTable("sound/misc/achievement_earned.wav");
}

public OnClientDisconnect(client) 
{
	if(g_bPluginEnabled)
	{
		ZeroCPs(client);
		ZeroLocs(client);
	}
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
 	new criticals = GetConVarInt(g_hCriticals);
	if(g_bPluginEnabled && criticals  == 2)
	{
		result = true;	
		return Plugin_Handled;
	}
	return Plugin_Continue;	
}

/*****************************************************
 * Events
 ****************************************************/

public Action:eventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bPluginEnabled)
	{
		if(GetConVarBool(g_hRemoveCPs))
			RemoveCPs();	
		if(GetConVarBool(g_hAutoRessuply) && GetConVarBool(g_hAutoHeal))
			ToggleRessuplies(false);
		if(GetConVarInt(g_hForceTeam) == 1)
		{
			SetConVarInt(g_hTFUnbalanceLimit, 30);
			SetConVarBool(g_hTFAutoTeamBalance, false);
		}
		ZeroCPsAll();
	}
	g_bRoundEnd = false;
}

public Action:eventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bRoundEnd = true;
	ZeroLocsAll();
}

public Action:eventPlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bPluginEnabled && IsClientInGame(client) && client != 0)
	{
		ZeroLocs(client);
		PrintToChat(client, "\x04[JM]\x01 Your position has been reset");
	}
}

public Action:eventChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bPluginEnabled && IsClientInGame(client) && client != 0)
	{
		new iForceTeam = GetConVarInt(g_hForceTeam) + 1;
		if(iForceTeam != 1)
		{
			new iTeam = GetEventInt(event, "team");
			if(iTeam != iForceTeam && iTeam != 1)
				CreateTimer(0.1, timerTeam, client);
		}
		ZeroLocs(client);
		PrintToChat(client, "\x04[JM]\x01 Your position has been reset");
	}
}

public Action:eventTouchCP(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bPluginEnabled)
	{
		new client = GetEventInt(event, "player");
		new area = GetEventInt(event, "area");
		if(!g_bCPTouched[client][area])
		{
			g_iCPsTouched[client]++;
			if(GetConVarBool(g_hReachedCP))
			{
				new String:playerName[64];
				GetClientName(client, playerName, 64);
				AttachParticle(client, "achieved");
				EmitSoundToAll("misc/achievement_earned.wav");
				g_bCPTouched[client][area] = true;
				if(g_iCPsTouched[client] == g_iCPs)
					PrintToChatAll("\x04[JM]\x01 Player \x03%s \x01has reached the final Control Point!", playerName);
				else
					PrintToChatAll("\x04[JM]\x01 Player \x03%s \x01has reached a Control Point! (%i of %i)", playerName, g_iCPsTouched[client], g_iCPs);
			}
			new Float:time = GetConVarFloat(g_hChangeLevel);
			if(g_iCPsTouched[client] == g_iCPs && time > 0.0 && !g_bTimerToChange)
			{
				new String:mapName[64];
				new timeRounded = RoundToCeil(time);
				GetNextMap(mapName, 64);
				if(timeRounded == 1)
					PrintToChatAll("\x04[JM]\x01 The map will be changed to %s in 1 minute!", mapName);
				else
					PrintToChatAll("\x04[JM]\x01 The map will be changed to %s in %i minute!", mapName, timeRounded);
				CreateTimer(time * 60.0, timerChangeLevel);
				g_bTimerToChange = true;
			}
		}
	}
}
public Action:eventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bPluginEnabled && GetConVarBool(g_hAutoRespawn))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		CreateTimer(0.1, timerRespawn, client);
	}
}
public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bPluginEnabled)
	{
		if(g_fLocation[client][0] == 0.0)
			PrintToChat(client, "\x04[JM]\x01 Jump Mode is enabled! Say \x03!jm_help\x01 to see the available commands");
		else if (GetConVarBool(g_hAutoTeleport) && GetConVarBool(g_hTeleport))
		{
			TeleportEntity(client, g_fLocation[client], NULL_VECTOR, NULL_VECTOR);
			PrintToChat(client, "\x04[JM]\x01 You have been auto teleported");
		}
	}
}
public Action:eventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bPluginEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(GetConVarBool(g_hAutoHeal))
			CreateTimer(0.1, timerRegen, client);
		if(GetConVarBool(g_hAutoRessuply))
			GiveAmmo(client);
	}
}

/*****************************************************
 * Timers
 ****************************************************/
 
public Action:timerRegen(Handle:timer, any:client)
{
	new iMaxHealth = TF2_GetPlayerResourceData(client, TFResource_MaxHealth);
	SetEntityHealth(client, iMaxHealth);
}

public Action:timerRespawn(Handle:timer, any:client)
{
	TF2_RespawnPlayer(client);
}

public Action:timerTeam(Handle:timer, any:client)
{
	new iForceTeam = GetConVarInt(g_hForceTeam) + 1;
	ChangeClientTeam(client, iForceTeam);
}

public Action:timerChangeLevel(Handle:timer)
{
	new String:mapName[64];
	GetNextMap(mapName, 64);
	ForceChangeLevel(mapName, "Jump Mode auto changelevel");
}

/*****************************************************
 * CVar changes
 ****************************************************/
 
public cvarEnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iEnabled = GetConVarInt(g_hPluginEnabled);
	if(iEnabled == 0)
		TurnOffPlugin();
	else if(iEnabled == 1)
	{
		if(IsMapEnabled())
			TurnOnPlugin();
		else
			TurnOffPlugin();
	}
	else
		TurnOnPlugin();
}

public cvarRemoveCPsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StringToInt(newValue) == 0)
		ServerCommand("mp_restartgame 1"); 
	else
		RemoveCPs();
}

public cvarCriticalsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StringToInt(newValue) == 0)
		SetConVarBool(g_hTFCriticals, false);
	else
		SetConVarBool(g_hTFCriticals, true);
}

public cvarForceTeamChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StringToInt(newValue) > 0)
	{
		SetConVarInt(g_hTFUnbalanceLimit, 30);
		SetConVarBool(g_hTFAutoTeamBalance, false);
	}	
}

public cvarRessuplyChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarBool(g_hAutoRessuply) && GetConVarBool(g_hAutoHeal))
		ToggleRessuplies(false);
	else
		ToggleRessuplies(true);	
}

/*****************************************************
 * Client Commands
 ****************************************************/

public Action:cmdHelp(client, args)
{
	PrintToChat(client, "\x04[JM]\x01 See console for output");
	if(g_bPluginEnabled)
	{
		PrintToConsole(client, "[JM] Jump Mode Help");
		PrintToConsole(client, "[JM] - General");
		if(GetConVarBool(g_hAutoHeal))
			PrintToConsole(client, "[JM]   - Auto healing on player hurt");
		if(GetConVarBool(g_hAutoRessuply))
			PrintToConsole(client, "[JM]   - Auto ammo ressuply on player hurt");
		if(GetConVarInt(g_hCriticals) == 0)
			PrintToConsole(client, "[JM]   - No criticals");
		else if(GetConVarInt(g_hCriticals) == 2)
			PrintToConsole(client, "[JM]   - 100% criticals");
		if(GetConVarBool(g_hAutoTeleport) && GetConVarBool(g_hTeleport))
			PrintToConsole(client, "[JM]   - Auto teleport on respawn");
		if(GetConVarBool(g_hAutoRespawn))
			PrintToConsole(client, "[JM]   - No respawn times");
		if(GetConVarBool(g_hRemoveCPs))
			PrintToConsole(client, "[JM]   - Remove Control-Points");
		if(GetConVarBool(g_hReachedCP))
			PrintToConsole(client, "[JM]   - Displays a message when a player reach a CP");
		if(GetConVarFloat(g_hChangeLevel) > 0.0)
			PrintToConsole(client, "[JM]   - Change map when somebody reachs the final CP");
		if(GetConVarBool(g_hAutoRessuply) && GetConVarBool(g_hAutoHeal))
			PrintToConsole(client, "[JM]   - Remove Ressuplies");
		PrintToConsole(client, "[JM] - Console Commands (or \"say !\" commands)");
		if(GetConVarBool(g_hTeleport))
		{
			PrintToConsole(client, "[JM]   - jm_saveloc: Save your current position");
			PrintToConsole(client, "[JM]   - jm_resetloc: Reset your saved location");
			PrintToConsole(client, "[JM]   - jm_teleport: Teleport you to the saved position");
		}
		if(GetConVarBool(g_hRessuply))
			PrintToConsole(client, "[JM]   - jm_ressuply: Ressuply your ammo");
	}
	else
		PrintToChat(client, "[JM] Jump Mode is not enabled");
	
}

public Action:cmdResetLoc(client, args)
{
	if(!g_bPluginEnabled)
		PrintToChat(client, "\x04[JM]\x01 Jump Mode is not enabled");
	else if(!GetConVarBool(g_hTeleport))
		PrintToChat(client, "\x04[JM]\x01 Jump Mode Teleporter is not enabled");
	else
	{
		ZeroLocs(client);
		PrintToChat(client, "\x04[JM]\x01 Your location has been reset");
	}
}


public Action:cmdRessuply(client, args)
{
	if(GetConVarBool(g_hRessuply))
		GiveAmmo(client);
	else
		PrintToChat(client, "\x04[JM]\x01 Ressuply is disabled")
}

public Action:cmdSaveLoc(client, args)
{
	if(!g_bPluginEnabled)
		PrintToChat(client, "\x04[JM]\x01 Jump Mode is not enabled");
	else if(!GetConVarBool(g_hTeleport))
		PrintToChat(client, "\x04[JM]\x01 Jump Mode Teleporter is not enabled");		
	else if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[JM]\x01 You must be alive to save your location");	
	else if(!(GetEntityFlags(client) & FL_ONGROUND))
		PrintToChat(client, "\x04[JM]\x01 You can't save your location on air");
	else if(GetEntProp(client, Prop_Send, "m_bDucked") == 1)
		PrintToChat(client, "\x04[JM]\x01 You can't save your location ducked");
	else if(g_bRoundEnd)		
		PrintToChat(client, "\x04[JM]\x01 You can't save your location on humiliation");
	else
	{
		GetClientAbsOrigin(client, g_fLocation[client]);
		PrintToChat(client, "\x04[JM]\x01 Your location has been saved");
	}
}

public Action:cmdTeleport(client, args) {
	if(!g_bPluginEnabled)
		PrintToChat(client, "\x04[JM]\x01 Jump Mode is not enabled");
	else if(!GetConVarBool(g_hTeleport))
		PrintToChat(client, "\x04[JM]\x01 Jump Mode Teleporter is not enabled");		
	else if(!IsPlayerAlive(client))
		PrintToChat(client, "\x04[JM]\x01 You must be alive to teleport");
	else if(g_fLocation[client][0] == 0.0)
		PrintToChat(client, "\x04[JM]\x01 You haven't saved your position yet");
	else if(g_bRoundEnd)		
		PrintToChat(client, "\x04[JM]\x01 You can't teleport on humiliation");
	else
	{
		TeleportEntity(client, g_fLocation[client], NULL_VECTOR, NULL_VECTOR);
		PrintToChat(client, "\x04[JM]\x01 You have been teleported");
	}
}

/*****************************************************
 * Functions
 ****************************************************/

 bool:IsMapEnabled()
{
	new String:sMapName[32];
	new String:sKeywords[64];
	new String:sKeyword[16][32];
	GetCurrentMap(sMapName, 32);
	GetConVarString(g_hKeywords, sKeywords, 64);
	new iKeywords = ExplodeString(sKeywords, ",", sKeyword, 16, 32);
	for(new i = 0; i < iKeywords; i++)
	{
		if(StrContains(sMapName, sKeyword[i], false) > -1)
			return true;
	}
	return false;
}
 
TurnOnPlugin()
{
	g_bPluginEnabled = true;
	g_bRoundEnd = false;	
	g_bTimerToChange = false;
	for(new i = 0; i < g_iMaxClients; i++)
		ZeroLocs(i);
	if(GetConVarInt(g_hForceTeam) == 1)
	{
		SetConVarInt(g_hTFUnbalanceLimit, 30);
		SetConVarBool(g_hTFAutoTeamBalance, false);
	}
	if(GetConVarInt(g_hCriticals) == 0)
		SetConVarBool(g_hTFCriticals, false);
	else
		SetConVarBool(g_hTFCriticals, true);
	if(GetConVarInt(g_hForceTeam) > 0)
	{
		SetConVarInt(g_hTFUnbalanceLimit, 30);
		SetConVarBool(g_hTFAutoTeamBalance, false);
	}
	if(GetConVarBool(g_hRemoveCPs))
		RemoveCPs();	
	if(GetConVarBool(g_hAutoRessuply) && GetConVarBool(g_hAutoHeal))
		ToggleRessuplies(false);
	if(!g_bPluginEnabled)
		PrintToChatAll("\x04[JM]\x01 Jump Mode has been turned on");
}

TurnOffPlugin()
{
	if(g_bPluginEnabled)
	{
		g_bPluginEnabled = false;
		if(GetConVarBool(g_hRemoveCPs))
			ServerCommand("mp_restartgame 1"); 
		if(GetConVarBool(g_hAutoRessuply) && GetConVarBool(g_hAutoHeal))
			ToggleRessuplies(true);
		PrintToChatAll("\x04[JM]\x01 Jump Mode has been turned off");
	}
}


ZeroLocsAll()
{
	for(new i = 0; i <= g_iMaxClients; i++)
			ZeroLocs(i);
}

ZeroLocs(client)
{
	g_fLocation[client][0] = 0.0;
	g_fLocation[client][1] = 0.0;
	g_fLocation[client][2] = 0.0;
}

ZeroCPsAll()
{
	for(new i = 0; i <= g_iMaxClients; i++)
		ZeroCPs(i);
}	

ZeroCPs(client)
{
	for(new j = 0; j < 8; j++)
		g_bCPTouched[client][j] = false;
	g_iCPsTouched[client] = 0;
}	

GiveAmmo(client)
{
	new TFClassType:iClass = TF2_GetPlayerClass(client);
	for (new i = 0; i < 3; i++)
	{
		if(!(iClass == TFClass_Heavy && i == 1))
		{
			if (TFClass_MaxAmmo[iClass][i] != -1)
				SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + ((i+1)*4), TFClass_MaxAmmo[iClass][i]);
			if (i != 2 && TFClass_MaxClip[iClass][i] != -1)
				SetEntData(GetPlayerWeaponSlot(client, i), FindSendPropInfo("CTFWeaponBase", "m_iClip1"), TFClass_MaxClip[iClass][i]);
		}
	}
}

RemoveCPs()
{
	new iCP = -1;
	g_iCPs = 0;
	while ((iCP = FindEntityByClassname(iCP, "trigger_capture_area")) != -1)
	{
		SetVariantString("2 0");
		AcceptEntityInput(iCP, "SetTeamCanCap");
		SetVariantString("3 0");
		AcceptEntityInput(iCP, "SetTeamCanCap");
		g_iCPs++;
	}
}

ToggleRessuplies(bool:newStatus)
{
	new iRs = -1;
	while ((iRs = FindEntityByClassname(iRs, "func_regenerate")) != -1)
		AcceptEntityInput(iRs, (newStatus ? "Enable" : "Disable"));
}

AttachParticle(ent, String:particleType[])
{
	new particle = CreateEntityByName("info_particle_system")
	
	new String:tName[128]
	if (IsValidEdict(particle))
	{
		new Float:pos[3]
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos)
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR)
		
		Format(tName, sizeof(tName), "target%i", ent)
		DispatchKeyValue(ent, "targetname", tName)
		
		DispatchKeyValue(particle, "targetname", "tf2particle")
		DispatchKeyValue(particle, "parentname", tName)
		DispatchKeyValue(particle, "effect_name", particleType)
		DispatchSpawn(particle)
		SetVariantString(tName)
		AcceptEntityInput(particle, "SetParent", particle, particle, 0)
		SetVariantString("head")
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0)
		ActivateEntity(particle)
		AcceptEntityInput(particle, "start")
		CreateTimer(5.0, DeleteParticles, particle)
	}
}

public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
    new particle = CreateEntityByName("info_particle_system")
    if (IsValidEdict(particle))
    {
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR)
        DispatchKeyValue(particle, "effect_name", particlename)
        ActivateEntity(particle)
        AcceptEntityInput(particle, "start")
        CreateTimer(time, DeleteParticles, particle)
    }  
}


public Action:DeleteParticles(Handle:timer, any:particle)
{
    if (IsValidEntity(particle))
    {
        new String:classname[256]
        GetEdictClassname(particle, classname, sizeof(classname))
        if (StrEqual(classname, "info_particle_system", false))
        {
            RemoveEdict(particle)
        }
    }
}

