//
// DoDs Speed Bonus Round
// -----------------------------
// Based form <eVa>Dog's Dog Bonus Round
// http://www.dodsplugins.com
//
// For DoD:Source
// This plugin beacon the losing Team and give speed to the Winners
// Just to have a funny moment at round end
// -----------------------------

#include <sourcemod>
#include <sdktools>

#define SPEC 1
#define ALLIES 2
#define AXIS 3

#define PLUGIN_VERSION "2.3"
#define BEACON_DELAY 1.5

new g_beamSprite
new g_haloSprite
new roundwin = 0


new String:WpnMelee[4][] = { "", "", "weapon_amerknife", "weapon_spade" }

new Handle:cvar_kicknodl = INVALID_HANDLE;
new Handle:g_BeaconTimer[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "DoD Santa Bonus Round",
	author = "<eVa>Dog, vintage, modif Micmacx",
	description = "Beacon and skin the loosing Team, give speed to the Winners",
	version = PLUGIN_VERSION,
	url = "http://www.dodsplugins.com"
}

public OnPluginStart()
{
	CheckGame()
	HookEvent("dod_round_win", Hook_RoundWin, EventHookMode_Post)
	HookEvent("dod_round_start", Hook_RoundStart, EventHookMode_Post)
	cvar_kicknodl = CreateConVar("dod_santa_bonusround_kicknodl", "1", "Enabled/Disabled kicking players with DL-filter, 0 = off/1 = on", _, true, 0.0, true, 1.0)
	AutoExecConfig(true, "dod_santa_bonusround", "dod_santa_bonusround")
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/dod_santa_bonusround/christmas_libre.mp3")
	AddFileToDownloadsTable("materials/models/player/santaclaus/basic_hand.vmt")
	AddFileToDownloadsTable("materials/models/player/santaclaus/basic_hand.vtf")
	AddFileToDownloadsTable("materials/models/player/santaclaus/face.vtf")
	AddFileToDownloadsTable("materials/models/player/santaclaus/face.vmt")
	AddFileToDownloadsTable("materials/models/player/santaclaus/hat.vtf")
	AddFileToDownloadsTable("materials/models/player/santaclaus/hat.vmt")
	AddFileToDownloadsTable("materials/models/player/santaclaus/head.vtf")
	AddFileToDownloadsTable("materials/models/player/santaclaus/head.vmt")
	AddFileToDownloadsTable("materials/models/player/santaclaus/klaus_legs.vtf")
	AddFileToDownloadsTable("materials/models/player/santaclaus/klaus_legs.vmt")
	AddFileToDownloadsTable("materials/models/player/santaclaus/klaus_torso.vtf")
	AddFileToDownloadsTable("materials/models/player/santaclaus/klaus_torso.vmt")
	AddFileToDownloadsTable("materials/models/player/santaclaus/mouth_eyes.vtf")
	AddFileToDownloadsTable("materials/models/player/santaclaus/mouth_eyes.vmt")
	AddFileToDownloadsTable("models/player/santaclaus/santaclaus.dx80.vtx")
	AddFileToDownloadsTable("models/player/santaclaus/santaclaus.dx90.vtx")
	AddFileToDownloadsTable("models/player/santaclaus/santaclaus.mdl")
	AddFileToDownloadsTable("models/player/santaclaus/santaclaus.phy")
	AddFileToDownloadsTable("models/player/santaclaus/santaclaus.sw.vtx")
	AddFileToDownloadsTable("models/player/santaclaus/santaclaus.vvd")
	PrecacheModel("models/player/santaclaus/santaclaus.mdl")
	PrecacheSound("buttons/button17.wav",true)
	PrecacheSound("dod_santa_bonusround/christmas_libre.mp3", true)
	g_beamSprite = PrecacheModel("materials/sprites/laser.vmt")
	g_haloSprite = PrecacheModel("materials/sprites/halo01.vmt")
}

public OnClientAuthorized(client, const String:auth[])
{
	if(GetConVarInt(cvar_kicknodl) == 1)
	{
		QueryClientConVar(client, "cl_downloadfilter", ConVarQueryFinished:dlfilter);
	}
}

public dlfilter(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName1[], const String:cvarValue1[])
{
	if (IsClientConnected(client))
	{
		if (strcmp(cvarValue1, "none", true) == 0)
		{
			KickClient(client, "Please - Allow custom files - in Day of defeatsource-->Settings-->Multiplayer");
		}
		else if (strcmp(cvarValue1, "mapsonly", true) == 0)
		{
			KickClient(client, "Please - Allow custom files - in Day of defeatsource-->Settings-->Multiplayer");
		}
	}
}


public Action:EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_BeaconTimer[client] = INVALID_HANDLE;
}

public Hook_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundwin = 1;
	EmitSoundToAll("dod_santa_bonusround/christmas_libre.mp3")
	new winnerTeam = GetEventInt(event, "team")

	for (new x = 1; x <= MaxClients; x++)
	{
		if(!IsClientInGame(x) || !IsPlayerAlive(x))
		{
			continue
		}
		new checkclientteam = GetClientTeam(x);
		if(checkclientteam == winnerTeam)
		{
			StripWeapons(x)
			SetEntPropFloat(x, Prop_Data, "m_flLaggedMovementValue", 1.5)
			SetEntProp(x, Prop_Data, "m_takedamage", 0, 1)
			GivePlayerItem(x,WpnMelee[winnerTeam])

			continue
		}
		else if((checkclientteam == 2 || checkclientteam == 3) && checkclientteam != winnerTeam)
		{
			StripWeapons(x)		
			GivePlayerItem(x,WpnMelee[winnerTeam])
			SetEntityModel(x,"models/player/santaclaus/santaclaus.mdl")
			PrintCenterText(x, "DANGER! Run! Run! Run!")
			CreateTimer(BEACON_DELAY, BeaconTimer, x, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE)
		}
	}
}
public Hook_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundwin = 0;
}
public Action:BeaconTimer(Handle:timer, any:client)
{

	if(roundwin == 1 && IsValidClient && IsPlayerAlive(client))
	{
		BeamRing(client)
		new Float:vecPos[3]
		GetClientAbsOrigin(client, vecPos)
		EmitSoundToAll("buttons/button17.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vecPos, NULL_VECTOR, true, 0.0)
		return Plugin_Continue
	}else{
		return Plugin_Stop
	}
}

CheckGame()
{
	new String:strGame[10]
	GetGameFolderName(strGame, sizeof(strGame))

	if(StrEqual(strGame, "dod"))
	{
		PrintToServer("[dod_santa_bonusround] Version %s dod_santa_bonusround loaded.", PLUGIN_VERSION)
	}
	else
	{
		SetFailState("[dod_santa_bonusround] This plugin is made for DOD:S! Disabled.")
	}
}

BeamRing(client)
{
	new color[] = {248, 96, 244, 255}

	new Float:vec[3]
	GetClientAbsOrigin(client, vec)

	vec[2] += 5;

	TE_Start("BeamRingPoint")
	TE_WriteVector("m_vecCenter", vec)
	TE_WriteFloat("m_flStartRadius", 20.0)
	TE_WriteFloat("m_flEndRadius", 440.0)
	TE_WriteNum("m_nModelIndex", g_beamSprite)
	TE_WriteNum("m_nHaloIndex", g_haloSprite)
	TE_WriteNum("m_nStartFrame", 0)
	TE_WriteNum("m_nFrameRate", 0)
	TE_WriteFloat("m_fLife", 1.0)
	TE_WriteFloat("m_fWidth", 6.0)
	TE_WriteFloat("m_fEndWidth", 6.0)
	TE_WriteFloat("m_fAmplitude", 0.0)
	TE_WriteNum("r", color[0])
	TE_WriteNum("g", color[1])
	TE_WriteNum("b", color[2])
	TE_WriteNum("a", color[3])
	TE_WriteNum("m_nSpeed", 50)
	TE_WriteNum("m_nFlags", 0)
	TE_WriteNum("m_nFadeLength", 0)
	TE_SendToAll()
}

public Action:StripWeapons(x)
{
	for(new i = 0; i < 4; i++)
	{
		new weapon = GetPlayerWeaponSlot(x, i)
		if(weapon != -1)
		{
			RemovePlayerItem(x, weapon)
			RemoveEdict(weapon)
		}
	}
}

bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		return true;
	}
	else
	{
		return false;
	}
}
