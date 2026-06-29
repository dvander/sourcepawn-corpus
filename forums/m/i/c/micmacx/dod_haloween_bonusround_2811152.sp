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
// Plugin is modified based on the plugin:Admin Sounds 1.2.2 by Cadav0r : https://forums.alliedmods.net/showthread.php?p=785989
// I used his way of handling precached sounds.
// -----------------------------

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"
#define BEACON_DELAY 1.5

new g_beamSprite
new g_haloSprite

new bool:Download_sounds[MAXPLAYERS + 1];
new bool:roundwin=false;
new String:WpnMelee[4][] = { "", "", "weapon_amerknife", "weapon_spade" }

new String:SoundFile[PLATFORM_MAX_PATH+1];

new Handle:cvar_kicknodl = INVALID_HANDLE;
new Handle:hb_CvarSoundEnable = INVALID_HANDLE;
new Handle:hb_CvarFile = INVALID_HANDLE;
new Handle:hb_PrecacheTrie = INVALID_HANDLE;
public Plugin:myinfo = 
{
	name = "DoD halloween Bonus Round",
	author = "<eVa>Dog,vintage modif Micmacx",
	description = "Beacon and skin the loosing Team, give speed to the Winners",
	version = PLUGIN_VERSION,
	url = "https://dods.neyone.fr"
}

public OnPluginStart()
{
	CheckGame()

	HookEvent("dod_round_start", Hook_RoundStart, EventHookMode_Post)
	HookEvent("dod_round_win", Hook_RoundWin, EventHookMode_Post)
	CreateConVar("dod_halloween_bonusround", PLUGIN_VERSION, "halloween Bonus Round Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvar_kicknodl = CreateConVar("dod_halloween_bonusround_kicknodl", "1", "Enabled/Disabled Kick players who do not download skins", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	hb_CvarSoundEnable = CreateConVar("dod_halloween_bonusround_sound_enable", "0", "1 : Enable / 0 : Disable Plugin", _, true, 0.0, true, 1.0);
	hb_CvarFile = CreateConVar("dod_halloween_bonusround_sound_file", "dod_halloween_bonusround/sound.mp3", "Folder and file name Name in folder sound");
	AutoExecConfig(true, "dod_halloween_bonusround", "dod_halloween_bonusround")
}

public OnMapStart()
{
	decl String:buffer[PLATFORM_MAX_PATH+1];
	if(GetConVarBool(hb_CvarSoundEnable))
	{	
		GetConVarString(hb_CvarFile, SoundFile, PLATFORM_MAX_PATH+1);
		Format(buffer, PLATFORM_MAX_PATH+1, "sound/%s", SoundFile); 
		AddFileToDownloadsTable(buffer);
	}
	AddFileToDownloadsTable("models/player/vad36freddy/kruegerr.dx80.vtx")
	AddFileToDownloadsTable("models/player/vad36freddy/kruegerr.dx90.vtx")
	AddFileToDownloadsTable("models/player/vad36freddy/kruegerr.mdl")
	AddFileToDownloadsTable("models/player/vad36freddy/kruegerr.phy")
	AddFileToDownloadsTable("models/player/vad36freddy/kruegerr.sw.vtx")
	AddFileToDownloadsTable("models/player/vad36freddy/kruegerr.vvd")
	AddFileToDownloadsTable("models/player/vad36fortnite/lollipop.dx80.vtx")
	AddFileToDownloadsTable("models/player/vad36fortnite/lollipop.dx90.vtx")
	AddFileToDownloadsTable("models/player/vad36fortnite/lollipop.mdl")
	AddFileToDownloadsTable("models/player/vad36fortnite/lollipop.phy")
	AddFileToDownloadsTable("models/player/vad36fortnite/lollipop.sw.vtx")
	AddFileToDownloadsTable("models/player/vad36fortnite/lollipop.vvd")
	AddFileToDownloadsTable("materials/models/player/vad36freddy/eye-iris-blue.vmt")
	AddFileToDownloadsTable("materials/models/player/vad36freddy/eye-iris-blue.vtf")
	AddFileToDownloadsTable("materials/models/player/vad36freddy/eye-iris-blue_n.vtf")
	AddFileToDownloadsTable("materials/models/player/vad36freddy/freddy_colour-wao.vmt")
	AddFileToDownloadsTable("materials/models/player/vad36freddy/freddy_colour-wao.vtf")
	AddFileToDownloadsTable("materials/models/player/vad36freddy/freddy_normals.vtf")
	AddFileToDownloadsTable("materials/models/player/vad36freddy/krueger.vmt")
	AddFileToDownloadsTable("materials/models/player/vad36freddy/krueger.vtf")
	AddFileToDownloadsTable("materials/models/player/vad36freddy/krueger_n.vtf")
	AddFileToDownloadsTable("materials/models/player/vad36freddy/lynch_hands.vmt")
	AddFileToDownloadsTable("materials/models/player/vad36freddy/lynch_hands.vtf")
	AddFileToDownloadsTable("materials/models/player/vad36freddy/lynch_hands_n.vtf")
	AddFileToDownloadsTable("materials/models/player/vad36freddy/mouth.vmt")
	AddFileToDownloadsTable("materials/models/player/vad36freddy/mouth.vtf")
	AddFileToDownloadsTable("materials/models/player/vad36fortnite/lollipop/t_f_med_lollipop_body_body_d.vmt")
	AddFileToDownloadsTable("materials/models/player/vad36fortnite/lollipop/t_f_med_lollipop_body_body_d.vtf")
	AddFileToDownloadsTable("materials/models/player/vad36fortnite/lollipop/t_f_med_lollipop_body_body_n.vtf")
	AddFileToDownloadsTable("materials/models/player/vad36fortnite/lollipop/t_f_med_lollipop_body_body_s.vtf")
	AddFileToDownloadsTable("materials/models/player/vad36fortnite/lollipop/t_f_med_lollipop_faceacc_d.vmt")
	AddFileToDownloadsTable("materials/models/player/vad36fortnite/lollipop/t_f_med_lollipop_faceacc_d.vtf")
	AddFileToDownloadsTable("materials/models/player/vad36fortnite/lollipop/t_f_med_lollipop_faceacc_n.vtf")
	AddFileToDownloadsTable("materials/models/player/vad36fortnite/lollipop/t_f_med_lollipop_faceacc_s.vtf")
	AddFileToDownloadsTable("materials/models/player/vad36fortnite/lollipop/t_f_med_lollipop_head_d.vmt")
	AddFileToDownloadsTable("materials/models/player/vad36fortnite/lollipop/t_f_med_lollipop_head_d.vtf")
	AddFileToDownloadsTable("materials/models/player/vad36fortnite/lollipop/t_f_med_lollipop_head_n.vtf")
	AddFileToDownloadsTable("materials/models/player/vad36fortnite/lollipop/t_f_med_lollipop_head_s.vtf")
	g_beamSprite = PrecacheModel("materials/sprites/laser.vmt")
	g_haloSprite = PrecacheModel("materials/sprites/halo01.vmt")
	PrecacheModel("models/player/vad36fortnite/lollipop.mdl")
	PrecacheModel("models/player/vad36freddy/kruegerr.mdl")
	PrecacheSound("buttons/button17.wav",true)
	if(GetConVarBool(hb_CvarSoundEnable))
	{	
		Format(buffer, PLATFORM_MAX_PATH+1, "%s", SoundFile); 
		PrecacheSound(buffer, true)
	}
	if (hb_PrecacheTrie == INVALID_HANDLE)
	{
		hb_PrecacheTrie = CreateTrie();
	}
	else
	{
		ClearTrie(hb_PrecacheTrie);
	}
}

public OnClientAuthorized(client, const String:auth[])
{

	QueryClientConVar(client, "cl_downloadfilter", ConVarQueryFinished:dlfilter);

}

public dlfilter(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName1[], const String:cvarValue1[])
{
	if(IsClientConnected(client))
	{
		if(strcmp(cvarValue1, "none", true) == 0)
		{
			if(GetConVarInt(cvar_kicknodl) == 1)
			{
				KickClient(client, "Please enable the option for skins - Allow custom files or nosounds - in Day of defeat:source-->options-->Multiplayer");
			}
		}
		if(strcmp(cvarValue1, "mapsonly", true) == 0)
		{
			if(GetConVarInt(cvar_kicknodl) == 1)
			{
				KickClient(client, "Please enable the option for skins - Allow custom files or nosounds - in Day of defeat:source-->options-->Multiplayer");
			}
		}

		if (strcmp(cvarValue1, "all", true) == 0)
		{
			Download_sounds[client] = true;
		}
		else
		{
			Download_sounds[client] = false;
		}
	}
}

public Hook_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundwin = false;
}

public Hook_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundwin = true;

	if(GetConVarBool(hb_CvarSoundEnable))
	{
		GetConVarString(hb_CvarFile, SoundFile, PLATFORM_MAX_PATH+1);
		decl String:buffer[PLATFORM_MAX_PATH+1];
		Format(buffer, PLATFORM_MAX_PATH+1, "%s", SoundFile); 
		if (hb_PrecacheTrie == INVALID_HANDLE)
		{
			hb_PrecacheTrie = CreateTrie();
		}
		else
		{
			ClearTrie(hb_PrecacheTrie);
		}
		new clientlist[MAXPLAYERS + 1];
		new clientcount = 0;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && !IsFakeClient(i))
			{
				if (Download_sounds[i])
				{
					clientlist[clientcount] = i;
					clientcount++
				}
			}
		}
		if (clientcount > 0)
		{
			if (PrepareSound(buffer))
			{
				EmitSound(clientlist, clientcount, buffer);
			}
		}
	}

	new winnerTeam = GetEventInt(event, "team")

	for (new x = 1; x <= MaxClients; x++)
	{
		if(!IsClientInGame(x) || !IsPlayerAlive(x))
		{
			continue
		}
		
		if(GetClientTeam(x) == winnerTeam)
		{
			StripWeapons(x)
			SetEntPropFloat(x, Prop_Data, "m_flLaggedMovementValue", 1.5)
			GivePlayerItem(x,WpnMelee[winnerTeam])
			SetEntityModel(x,"models/player/vad36freddy/kruegerr.mdl")

			continue
		}
		else
		{
			StripWeapons(x)		
			SetEntityModel(x,"models/player/vad36fortnite/lollipop.mdl")
			PrintCenterText(x, "DANGER! Run! Run! Run!")
			GivePlayerItem(x,WpnMelee[winnerTeam])
			CreateTimer(BEACON_DELAY, BeaconTimer, x, TIMER_REPEAT)
		}
	}
}

public Action:BeaconTimer(Handle:timer, any:client)
{
	if(!client || !IsClientInGame(client) || !IsClientConnected(client) || !IsPlayerAlive(client) || !roundwin)
	{
		return Plugin_Stop
	}
	else
	{
		BeamRing(client)
		new Float:vecPos[3]
		GetClientAbsOrigin(client, vecPos)
		EmitSoundToAll("buttons/button17.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, vecPos, NULL_VECTOR, true, 0.0)
	}
	return Plugin_Handled
}


CheckGame()
{
	new String:strGame[10]
	GetGameFolderName(strGame, sizeof(strGame))

	if(StrEqual(strGame, "dod"))
	{
		PrintToServer("[dod_halloween_bonusround] Version %s dod_halloween_bonusround loaded.", PLUGIN_VERSION)
	}
	else
	{
		SetFailState("[dod_halloween_bonusround] This plugin is made for DOD:S! Disabled.")
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

stock bool:PrepareSound(const String:sound[], bool:preload=true)
{
	if (PrecacheSound(sound, preload))
	{
		SetTrieValue(hb_PrecacheTrie, sound, true);
		return true;
	}
	else
	{
		return false;
	}
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
	if (client > 0 && client <= MaxClients && IsClientInGame(client)) {
		return true;
	} else {
		return false;
	}
}
