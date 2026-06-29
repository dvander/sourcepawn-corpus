#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.7"

#define TRACE_START 24.0
#define TRACE_END 64.0

#define MDL_LASER "sprites/laser.vmt"

#define SND_MINEPUT "npc/roller/blade_cut.wav"
#define SND_MINEACT "npc/roller/mine/rmine_blades_in2.wav"
#define SND_EXPLODE "weapons/c4/c4_detonate_01.wav"

#define MAX_BUTTONS 29
#define INS_USE (1 << 6)

#define TEAM_SEC 2
#define TEAM_INS 3

#define COLOR_INS "0 255 0"
#define COLOR_SEC "255 0 0"	//"0 0 255"
#define COLOR_DEF "0 255 255"

#define MAX_LINE_LEN 256
#define MAX_MESSAGE_LENGTH 250

Handle	g_hClientCookie = INVALID_HANDLE;

float	g_fActTime;

int		g_iCount = 1,
		ga_iCooldown[MAXPLAYERS + 1] = {0, ...},
		g_iNumMines,
		ga_iLastButtons[MAXPLAYERS + 1],
		g_iMyWeapons;

char	ga_sPlayerLaserColour[MAXPLAYERS + 1][12],
		g_sModel[PLATFORM_MAX_PATH];

bool	ga_bRngAlways[MAXPLAYERS + 1] = {false, ...},
		ga_bAdAboutCmd[MAXPLAYERS + 1] = {false, ...},
		g_bLateLoad;

//keep track of mines per player
ArrayList g_playerMineCount[MAXPLAYERS+1];

// convars
ConVar	g_cvNumMines = null,
		g_cvActTime = null,
		g_cvModel = null;

public Plugin myinfo = {
	name = "Tripmines 2016 Update",
	author = "404 (abrandnewday)",
	description = "That old L. Duke Tripmines plugin, updated to actually fucking work.",
	version = PLUGIN_VERSION,
	url = "http://www.unfgaming.net"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()  {
	if ((g_iMyWeapons = FindSendPropInfo("CBasePlayer", "m_hMyWeapons")) == -1) {
		SetFailState("Fatal Error: Unable to find property offset \"CBasePlayer::m_hMyWeapons\" !");
	}

	g_hClientCookie = RegClientCookie("TmRgbCookie", "trip mine rgb cookie", CookieAccess_Private);
	
	HookEvent("grenade_thrown", Event_GrenadeThrown);

	g_cvNumMines = CreateConVar("sm_tripmines_allowed", "2.0", "Max trip mines player can plant", _, true, 0.0);
	g_iNumMines = g_cvNumMines.IntValue;
	g_cvNumMines.AddChangeHook(OnConVarChanged);

	g_cvActTime = CreateConVar("sm_tripmines_activate_time", "2.0", "Time in seconds before trip mine activates", _, true, 0.0);
	g_fActTime = g_cvActTime.FloatValue;
	g_cvActTime.AddChangeHook(OnConVarChanged);

	g_cvModel = CreateConVar("sm_tripmines_model", "models/weapons/w_c4_tm.mdl", "Tip mine model path");
	GetConVarString(g_cvModel, g_sModel, sizeof(g_sModel));
	g_cvModel.AddChangeHook(OnConVarChanged);

	RegAdminCmd("sm_tripmine", Command_TripMine, ADMFLAG_KICK);
	RegAdminCmd("tmrgbrandomalways", Command_TripMineRngAlways, ADMFLAG_RESERVATION, "[toggle cmd] Randomise your trip mine laser colour every time (reserved slot access only)");

	RegConsoleCmd("tmrgb", Command_TripMineColour, "Set RGB colour of your trip mine laser");
	RegConsoleCmd("tmrgbrandom", Command_TripMineRandomRgb, "Set a random RGB colour of your trip mine laser");

	char sBuffer[PLATFORM_MAX_PATH];
	GetPluginFilename(INVALID_HANDLE, sBuffer, sizeof(sBuffer));
	ReplaceString(sBuffer, sizeof(sBuffer), ".smx", "", false);
	AutoExecConfig(true, sBuffer);

	if (g_bLateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsClientInGame(i) || IsFakeClient(i) || !AreClientCookiesCached(i)) {
				continue;
			}
			OnClientCookiesCached(i);
			if (g_playerMineCount[i] == INVALID_HANDLE) {
				g_playerMineCount[i] = CreateArray();
			}
		}
	}
}

public void OnClientCookiesCached(int client) {
	if (IsClientConnected(client) && !IsFakeClient(client)) {
		char sValue[12];
		GetClientCookie(client, g_hClientCookie, sValue, sizeof(sValue));
		if (strcmp(sValue, "vip", false) == 0) {
			ga_bRngAlways[client] = true;
		} else {
			ga_sPlayerLaserColour[client] = sValue;
		}
	}
}

public void OnMapStart() {
	// precache models
	PrecacheModel(g_sModel, true);
	PrecacheModel(MDL_LASER, true);
	
	// precache sounds
	PrecacheSound(SND_MINEPUT, true);
	PrecacheSound(SND_MINEACT, true);
	PrecacheSound(SND_EXPLODE, true);

	char sBuffer[PLATFORM_MAX_PATH];
	for (int i = 1; i <= 13; i++) {
		FormatEx(sBuffer, sizeof(sBuffer), "player/voice/responses/security/subordinate/unsuppressed/c4planted%d.ogg", i);
		PrecacheSound(sBuffer);
	}

	//Reset uniqID on map start
	g_iCount = 1;
}

public void OnClientPostAdminCheck(int client) {
	if (client && !IsFakeClient(client)) {
		if (g_playerMineCount[client] == INVALID_HANDLE) {
			g_playerMineCount[client] = CreateArray();
		} else {
			g_playerMineCount[client].Clear();
		}
	}
}

public void OnClientDisconnect(int client) {
	if (client && !IsFakeClient(client)) {
		if (ga_bRngAlways[client]) {
			SetClientCookie(client, g_hClientCookie, "vip");
			ga_bRngAlways[client] = false;
		}
		else if (strlen(ga_sPlayerLaserColour[client]) > 6) {
			SetClientCookie(client, g_hClientCookie, ga_sPlayerLaserColour[client]);
		}
		removeMines(client);
		delete g_playerMineCount[client];
		ga_sPlayerLaserColour[client] = "";
		ga_bAdAboutCmd[client] = false;
		ga_iLastButtons[client] = 0;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) {
	if (!IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client)) {
		return Plugin_Continue;
	}
	int button;
	for (int i = 0; i < MAX_BUTTONS; i++) {
		button = (1 << i);
		if (buttons & button) {
			if (!(ga_iLastButtons[client] & button)) {
				OnButtonPress(client, button);
			}
		}
	}
	ga_iLastButtons[client] = buttons;
	return Plugin_Continue;
}

void OnButtonPress(int client, int button) {
	if (button & INS_USE) {
		if (g_playerMineCount[client] == INVALID_HANDLE || !g_playerMineCount[client].Length) {
			return;
		}

		int iTarget = GetClientAimTarget(client, false);
		if (iTarget <= MaxClients || iTarget > 2048 || !IsValidEntity(iTarget)) {
			return;
		}

		char sName[64];
		if (!GetEntityClassname(iTarget, sName, sizeof(sName))) {
			return;
		}

		if (strcmp(sName, "prop_dynamic", false) == 0) {
			float	vClient[3],
					vTarget[3];

			GetClientAbsOrigin(client, vClient);
			GetEntPropVector(iTarget, Prop_Send, "m_vecOrigin", vTarget);
			if (GetVectorDistance(vClient, vTarget) > 90.0) {
				return;
			}

			char sBuffer[64];
			int laser;
			for (int i = 0; i < g_playerMineCount[client].Length; i++) {
				FormatEx(sBuffer, sizeof(sBuffer), "tmbeammdl%d", g_playerMineCount[client].Get(i));
				if (!Entity_NameMatches(iTarget, sBuffer)) {
					continue;
				}
				RemoveEntity(iTarget);

				FormatEx(sBuffer, sizeof(sBuffer), "tmbeam%d", g_playerMineCount[client].Get(i));
				laser = Entity_FindByName(sBuffer, "env_beam");
				if (laser != INVALID_ENT_REFERENCE) {
					RemoveEntity(laser);
				}
				
				g_playerMineCount[client].Erase(i);
				GiveMine(client);
				break;
			}
		}
	}
}

public Action Command_TripMine(int client, int args) {
	if (client < 1 || !IsClientInGame(client)) {
		return Plugin_Handled;
	}
	SetMine(client);
	return Plugin_Handled;
}

public Action Command_TripMineColour(int client, int args) {
	if (client < 1) {
		return Plugin_Handled;
	}

	int iTime = GetTime();
	if (iTime < ga_iCooldown[client]) {
		ga_iCooldown[client] += 2;	// Extra time just in case the client has a script
		ReplyToCommand(client, "You must wait %d seconds before using this command again!", (ga_iCooldown[client] - iTime));
		return Plugin_Handled;
	}

	if (args == 0 && strlen(ga_sPlayerLaserColour[client]) > 6) {
		ReplyToCommand(client, "Your setting: %s", ga_sPlayerLaserColour[client]);
		return Plugin_Handled;
	}

	if (ga_bRngAlways[client]) {
		ReplyToCommand(client, "Turn off the tmrgbrandomalways before using this command!");
		return Plugin_Handled;
	}

	if (args < 3) {
		ReplyToCommand(client, "Usage: tmrgb <R> <G> <B>\nGoogle: 'rgb colour picker'");
		return Plugin_Handled;
	}

	char	sBuffer[12],
			sR[4],
			sG[4],
			sB[4];

	int		iR,
			iG,
			iB,
			iLength,
			iCount = 0;

	GetCmdArgString(sBuffer, sizeof(sBuffer));

	iLength = strlen(sBuffer);

	for (int i = 0; i < iLength; i++) {
		if (!IsCharNumeric(sBuffer[i])) {
			if (IsCharSpace(sBuffer[i])) {
				if (iCount < 2) {
					iCount++;
					continue;
				} else {
					ReplyToCommand(client, "Too many spaces");
					return Plugin_Handled;
				}
			}
			ReplyToCommand(client, "Use numeric characters!\nGoogle: 'rgb colour picker'");
			return Plugin_Handled;
		}
	}
	
	GetCmdArg(1, sR, sizeof(sR));
	iR = StringToInt(sR);
	if (iR > 255) {
		ReplyToCommand(client, "RED max allowed: 255");
		return Plugin_Handled;
	}

	GetCmdArg(2, sG, sizeof(sG));
	iG = StringToInt(sG);
	if (iG > 255) {
		ReplyToCommand(client, "GREEN max allowed: 255");
		return Plugin_Handled;
	}

	GetCmdArg(3, sB, sizeof(sB));
	iB = StringToInt(sB);
	if (iB > 255) {
		ReplyToCommand(client, "BLUE max allowed: 255");
		return Plugin_Handled;
	}

	if (iR < 100 && iG < 100 && iB < 100) {
		ReplyToCommand(client, "At least one value must be above 99 (e.g., 123 0 54).");
		return Plugin_Handled;
	}

	FormatEx(sBuffer, sizeof(sBuffer), "%s %s %s", sR, sG, sB);
	ga_sPlayerLaserColour[client] = sBuffer;
	ReplyToCommand(client, "Laser RGB set to: %s", sBuffer);
	ga_iCooldown[client] = iTime + 3;

	return Plugin_Handled;
}

public Action Command_TripMineRandomRgb(int client, int args) {
	if (client < 1) {
		return Plugin_Handled;
	}

	int iTime = GetTime();
	if (iTime < ga_iCooldown[client]) {
		ga_iCooldown[client] += 2;	// Extra time just in case the client has a script
		ReplyToCommand(client, "You must wait %d seconds before using this command again!", (ga_iCooldown[client] - iTime));
		return Plugin_Handled;
	}

	if (ga_bRngAlways[client]) {
		ReplyToCommand(client, "Turn off the tmrgbrandomalways before using this command!");
		return Plugin_Handled;
	}

	ga_sPlayerLaserColour[client] = GetRandomRgb();
	ReplyToCommand(client, "Laser set to: %s", ga_sPlayerLaserColour[client]);
	ga_iCooldown[client] = iTime + 3;
	return Plugin_Handled;
}

public Action Command_TripMineRngAlways(int client, int args) {
	if (client < 1) {
		return Plugin_Handled;
	}

	if (!ga_bRngAlways[client]) {
		ga_bRngAlways[client] = true;
		ReplyToCommand(client, "tmrgbrandomalways: ON");
	} else {
		ga_bRngAlways[client] = false;
		ReplyToCommand(client, "tmrgbrandomalways: OFF");
	}
	return Plugin_Handled;
}

char GetRandomRgb() {
	int		iR,
			iG,
			iB,
			iMin;
	
	char	sBuffer[12],
			sR[4],
			sG[4],
			sB[4];


	iMin = GetRandomInt(0, 2);
	iR = GetRandomInt(iMin == 0 ? 100 : 0, 255);
	iG = GetRandomInt(iMin == 1 ? 100 : 0, 255);
	iB = GetRandomInt(iMin == 2 ? 100 : 0, 255);

	IntToString(iR, sR, sizeof(sR));
	IntToString(iG, sG, sizeof(sG));
	IntToString(iB, sB, sizeof(sB));

	FormatEx(sBuffer, sizeof(sBuffer), "%s %s %s", sR, sG, sB);

	return sBuffer;
}

public Action Event_GrenadeThrown(Event event, char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	int nade_id = event.GetInt("entityid");

	if (nade_id > 0 && client > 0 && IsPlayerAlive(client) && !IsFakeClient(client)) {
		char grenade_name[32];
		GetEntityClassname(nade_id, grenade_name, sizeof(grenade_name));
		if (strcmp(grenade_name, "grenade_c4_tripmine", false) == 0 && IsValidEntity(nade_id)) {
			RemoveEntity(nade_id);
			SetMine(client);
		}
	}

	return Plugin_Continue;
}

void removeMines(int client) {
	if (!IsClientInGame(client) || g_playerMineCount[client] == INVALID_HANDLE) {
		return;
	}

	if (g_playerMineCount[client].Length) {
		int tripmine = INVALID_ENT_REFERENCE;
		char beam[64];
		char beammdl[64];
		for (int i = 0; i < g_playerMineCount[client].Length; i++) {
			FormatEx(beam, sizeof(beam), "tmbeam%d", g_playerMineCount[client].Get(i));
			FormatEx(beammdl, sizeof(beammdl), "tmbeammdl%d", g_playerMineCount[client].Get(i));

			tripmine = Entity_FindByName(beammdl, "prop_dynamic");
			if (tripmine != INVALID_ENT_REFERENCE) {
				//PrintToChatAll("delete tripmine %s", beammdl);
				RemoveEntity(tripmine);
			}

			tripmine = INVALID_ENT_REFERENCE;

			tripmine = Entity_FindByName(beam, "env_beam");
			if (tripmine != INVALID_ENT_REFERENCE) {
				//PrintToChatAll("delete beam %s", beam);
				RemoveEntity(tripmine);
			}
		}
		g_playerMineCount[client].Clear();
	}
}

void SetMine(int client) {
	// trace client view to get position and angles for tripmine
	float start[3];
	float angle[3];
	float end[3];
	float normal[3];
	float beamend[3];
	GetClientEyePosition(client, start);
	GetClientEyeAngles(client, angle);
	GetAngleVectors(angle, end, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(end, end);

	start[0]=start[0]+end[0]*TRACE_START;
	start[1]=start[1]+end[1]*TRACE_START;
	start[2]=start[2]+end[2]*TRACE_START;
	
	end[0]=start[0]+end[0]*TRACE_END;
	end[1]=start[1]+end[1]*TRACE_END;
	end[2]=start[2]+end[2]*TRACE_END;
	
	TR_TraceRayFilter(start, end, CONTENTS_SOLID, RayType_EndPoint, FilterAll, 0);
	
	if (TR_DidHit(null)) {
		char beam[64];
		char beammdl[64];
		char tmp[128];

		/* Uho! Player has or is about to place more mines then allowed, delete oldest */
		if (g_playerMineCount[client].Length >= g_iNumMines) {
			int tripmine = INVALID_ENT_REFERENCE;

			Format(beam, sizeof(beam), "tmbeam%d", g_playerMineCount[client].Get(0));
			Format(beammdl, sizeof(beammdl), "tmbeammdl%d", g_playerMineCount[client].Get(0));

			tripmine = Entity_FindByName(beammdl, "prop_dynamic");
			if (tripmine != INVALID_ENT_REFERENCE) {
				//PrintToChatAll("delete tripmine %s", beammdl);
				RemoveEntity(tripmine);
			}

			tripmine = INVALID_ENT_REFERENCE;

			tripmine = Entity_FindByName(beam, "env_beam");
			if (tripmine != INVALID_ENT_REFERENCE) {
				//PrintToChatAll("delete beam %s", beam);
				RemoveEntity(tripmine);
			}

			g_playerMineCount[client].Erase(0);
		}

		// setup unique target names for entities to be created with
		FormatEx(beam, sizeof(beam), "tmbeam%d", g_iCount);
		FormatEx(beammdl, sizeof(beammdl), "tmbeammdl%d", g_iCount);

		g_playerMineCount[client].Push(g_iCount);
		
		g_iCount++;
		if (g_iCount > 10000) {
			g_iCount = 1;
		}
		
		// Find angles for tripmine
		TR_GetEndPosition(end, null);
		TR_GetPlaneNormal(null, normal);
		GetVectorAngles(normal, normal);
		
		// Trace laser beam
		TR_TraceRayFilter(end, normal, CONTENTS_SOLID, RayType_Infinite, FilterAll, 0);
		TR_GetEndPosition(beamend, null);
		
		// Create tripmine model
		int ent = CreateEntityByName("prop_dynamic_override");

		if (ent < 1 || !IsValidEntity(ent)) {
			return;
		}

		SetEntityModel(ent, g_sModel);
		DispatchKeyValue(ent, "StartDisabled", "false");
		DispatchSpawn(ent);
		TeleportEntity(ent, end, normal, NULL_VECTOR);
		SetEntProp(ent, Prop_Data, "m_usSolidFlags", 152);
		SetEntProp(ent, Prop_Data, "m_CollisionGroup", 1);
		SetEntityMoveType(ent, MOVETYPE_NONE);
		SetEntProp(ent, Prop_Data, "m_MoveCollide", 0);
		SetEntProp(ent, Prop_Data, "m_nSolidType", 6);
		SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
		DispatchKeyValue(ent, "targetname", beammdl);
		DispatchKeyValue(ent, "ExplodeRadius", "800");		//c4 900
		DispatchKeyValue(ent, "ExplodeDamage", "280");		//c4 280
		Format(tmp, sizeof(tmp), "%s,Break,,0,-1", beammdl);
		DispatchKeyValue(ent, "OnHealthChanged", tmp);
		Format(tmp, sizeof(tmp), "%s,Kill,,0,-1", beam);
		DispatchKeyValue(ent, "OnBreak", tmp);
		SetEntProp(ent, Prop_Data, "m_takedamage", DAMAGE_NO);
		AcceptEntityInput(ent, "Enable");

		
		// Create laser beam
		int ent2 = CreateEntityByName("env_beam");
		if (ent2 < 1 || !IsValidEntity(ent2)) {
			RemoveEntity(ent);
			return;
		}

		HookSingleEntityOutput(ent, "OnBreak", mineBreak, true);

		TeleportEntity(ent2, beamend, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(ent2, MDL_LASER);
		DispatchKeyValue(ent2, "texture", MDL_LASER);
		DispatchKeyValue(ent2, "targetname", beam);
		DispatchKeyValue(ent2, "TouchType", "4");	//    0: Not a tripwire 1: Player Only 2: NPC Only 3: Player or NPC 4: Player or NPC or Physprop
		DispatchKeyValue(ent2, "LightningStart", beam);
		DispatchKeyValue(ent2, "BoltWidth", "4.0");
		DispatchKeyValue(ent2, "life", "0");
		DispatchKeyValue(ent2, "rendercolor", "0 0 0");
		DispatchKeyValue(ent2, "renderamt", "0");
		DispatchKeyValue(ent2, "HDRColorScale", "1.0");
		DispatchKeyValue(ent2, "decalname", "Bigshot");
		DispatchKeyValue(ent2, "StrikeTime", "0");
		DispatchKeyValue(ent2, "TextureScroll", "35");
		Format(tmp, sizeof(tmp), "%s,Break,,0,-1", beammdl);
		DispatchKeyValue(ent2, "OnTouchedByEntity", tmp);	 
		SetEntPropVector(ent2, Prop_Data, "m_vecEndPos", end);
		SetEntPropFloat(ent2, Prop_Data, "m_fWidth", 4.0);
		AcceptEntityInput(ent2, "TurnOff");

		HookSingleEntityOutput(ent2, "OnTouchedByEntity", laserTouch, false);

		// Create a datapack
		DataPack hData;
		CreateDataTimer(g_fActTime, TurnBeamOn, hData);
		
		hData.WriteCell(client);
		hData.WriteCell(EntIndexToEntRef(ent));
		hData.WriteCell(EntIndexToEntRef(ent2));
		hData.WriteFloat(end[0]);
		hData.WriteFloat(end[1]);
		hData.WriteFloat(end[2]);
		
		// Play sound
		EmitSoundToAll(SND_MINEPUT, ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, ent, end, NULL_VECTOR, true, 0.0);
		
		char sBuffer[PLATFORM_MAX_PATH];
		FormatEx(sBuffer, sizeof(sBuffer), "player/voice/responses/security/subordinate/unsuppressed/c4planted%d.ogg", GetRandomInt(1, 13));
		EmitSoundToAll(sBuffer, client, SNDCHAN_VOICE, _, _, 1.0);

		if (!ga_bAdAboutCmd[client]) {
			if (CheckCommandAccess(client, "adminaccesscheck1", ADMFLAG_RESERVATION)) {
				PrintToChat(client, "\x070088ccTM COMMANDS: \x0799cc00TMRGB \x01| \x0799cc00TMRGBRANDOM \x01| \x0799cc00TMRGBRANDOMALWAYS");
			} else {
				PrintToChat(client, "\x070088ccTM COMMANDS: \x0799cc00TMRGB \x01| \x0799cc00TMRGBRANDOM");
				//if client loaded cookie from the time when he had access and now doesn't
				if (ga_bRngAlways[client]) {
					ga_bRngAlways[client] = false;
				}
			}
			ga_bAdAboutCmd[client] = true;
		}

	} else {
		PrintHintText(client, "Invalid location for the trip mine");
		GiveMine(client);
	}
}

Action TurnBeamOn(Handle timer, DataPack hData) {
	hData.Reset();
	int	client = hData.ReadCell(),
		ent = EntRefToEntIndex(hData.ReadCell()),
		ent2 = EntRefToEntIndex(hData.ReadCell());

	if (ent == INVALID_ENT_REFERENCE || !IsValidEntity(ent)) {
		if (ent2 != INVALID_ENT_REFERENCE && IsValidEntity(ent2)) {
			RemoveEntity(ent2);
		}
		return Plugin_Stop;
	}

	if (ent2 == INVALID_ENT_REFERENCE || !IsValidEntity(ent2)) {
		RemoveEntity(ent);
		return Plugin_Stop;
	}

	char color[26];

	int team = -1;
	if (IsClientInGame(client)) {
		team = GetClientTeam(client);
	}

	if (!ga_bRngAlways[client]) {
		if (team == TEAM_INS) {
			color = COLOR_INS;
		}
		else if (team == TEAM_SEC) {
			if (strlen(ga_sPlayerLaserColour[client]) < 7) {
				color = COLOR_SEC;
			} else {
				color = ga_sPlayerLaserColour[client];
			}
		} else {
			color = COLOR_DEF;
		}
	} else {
		color = GetRandomRgb();
	}

	DispatchKeyValue(ent2, "rendercolor", color);
	AcceptEntityInput(ent2, "TurnOn");

	float end[3];
	end[0] = hData.ReadFloat();
	end[1] = hData.ReadFloat();
	end[2] = hData.ReadFloat();

	EmitSoundToAll(SND_MINEACT, ent, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, ent, end, NULL_VECTOR, true, 0.0);

	return Plugin_Stop;
}

public Action laserTouch(const char[] output, int caller, int activator, float delay) {
	//PrintToChatAll("output: %s caller: %i activator: %i delay: %f", output, caller, activator, delay);
	if (activator > 0 && activator <= MaxClients && IsClientInGame(activator) && !IsFakeClient(activator)) {
		AcceptEntityInput(caller, "TurnOff");
		CreateTimer(3.0, Timer_LaserOn, EntIndexToEntRef(caller));
		return Plugin_Handled;
	}
	UnhookSingleEntityOutput(caller, "OnTouchedByEntity", laserTouch);
	return Plugin_Continue;
}

Action Timer_LaserOn(Handle timer, int entRef) {
	int iLaser = EntRefToEntIndex(entRef);
	if (iLaser != INVALID_ENT_REFERENCE && IsValidEntity(iLaser)) {
		AcceptEntityInput(iLaser, "TurnOn");
	}
}

public void mineBreak(const char[] output, int caller, int activator, float delay) {
	UnhookSingleEntityOutput(caller, "OnBreak", mineBreak);

	if (!IsValidEntity(caller)) {
		return;
	}

	char sTargetname[64];
	int index = -1;

	Entity_GetName(caller, sTargetname, sizeof(sTargetname));

	if (strlen(sTargetname)) {
		// "tmbeammdl%d", g_iCount);
		int uniqID = StringToInt(substr(sTargetname, 9));
		//PrintToChatAll("Targetname %s, uniqID %i", sTargetname, uniqID);

		for (int client = 1; client <= MaxClients; client++) {
			if (!IsClientInGame(client) || g_playerMineCount[client] == INVALID_HANDLE) {
				continue;
			}
			index = g_playerMineCount[client].FindValue(uniqID);
			if (index != -1) {
				g_playerMineCount[client].Erase(index);
			}
		}
	}

	int iParticle = CreateEntityByName("info_particle_system");
	if (IsValidEntity(iParticle)) {
		float fPos[3];
		GetEntPropVector(caller, Prop_Send, "m_vecOrigin", fPos);

		char sPos[64];
		Format(sPos, sizeof(sPos), "%f %f %f", fPos[0], fPos[1], fPos[2]);
		DispatchKeyValue(iParticle,"Origin", sPos);
		DispatchKeyValue(iParticle, "effect_name", "ins_C4_explosion");
		DispatchSpawn(iParticle);

		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "start");
		CreateTimer(3.0, Timer_KillParticle, EntIndexToEntRef(iParticle));
	}

	// Play sound
	EmitSoundToAll(SND_EXPLODE, caller, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100);
	RemoveEntity(caller);
}

Action Timer_KillParticle(Handle timer, int entRef) {
	int iParticle = EntRefToEntIndex(entRef);
	if (iParticle != INVALID_ENT_REFERENCE && IsValidEntity(iParticle)) {
		RemoveEntity(iParticle);
	}
	return Plugin_Stop;
}

public bool FilterAll(int entity, int contentsMask) {
	return false;
}

/* https://forums.alliedmods.net/showpost.php?p=2508542&postcount=10 */
stock char substr(char[] inpstr, int startpos, int len=-1) {
	char outstr[MAX_MESSAGE_LENGTH];
	if (len == -1) {
		strcopy(outstr, sizeof(outstr), inpstr[startpos]);
	} else {
		strcopy(outstr, len, inpstr[startpos]);
		outstr[len] = 0;
	}
	return outstr;
}

void GiveMine(int client) {
	int iWeapon = GivePlayerItem(client, "weapon_c4_tripmine");
	if (iWeapon > 0 && IsValidEntity(iWeapon)) {
		SetEntProp(client, Prop_Send, "m_iAmmo", 1, _, GetEntProp(iWeapon, Prop_Data, "m_iPrimaryAmmoType"));
	} else {
		char	sBuffer[32];

		int		iAmmo,
				iPrimaryAmmoType;

		for (int offset = 0; offset < 128; offset += 4) {
			iWeapon = GetEntDataEnt2(client, g_iMyWeapons + offset);
			if (iWeapon < 1) {
				continue;
			}
			if (IsValidEntity(iWeapon) && GetEdictClassname(iWeapon, sBuffer, sizeof(sBuffer)) && strcmp(sBuffer, "weapon_c4_tripmine", false) == 0) {
				iPrimaryAmmoType = GetEntProp(iWeapon, Prop_Data, "m_iPrimaryAmmoType"),
				iAmmo = GetEntProp(client, Prop_Data, "m_iAmmo", _, iPrimaryAmmoType);
				if (iAmmo >= g_iNumMines) {
					break;
				}
				SetEntProp(client, Prop_Send, "m_iAmmo", iAmmo > 0 ? iAmmo + 1 : 1, _, iPrimaryAmmoType);
				break;
			}
		}
	}
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (convar == g_cvNumMines) {
		g_iNumMines = g_cvNumMines.IntValue;
	}
	else if (convar == g_cvActTime) {
		g_fActTime = g_cvActTime.FloatValue;
	}
	else if (convar == g_cvModel) {
		GetConVarString(g_cvModel, g_sModel, sizeof(g_sModel));
	}
}