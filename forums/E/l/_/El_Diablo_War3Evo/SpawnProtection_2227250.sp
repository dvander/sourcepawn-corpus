#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define VERSION "1.6 [CS:GO Support]"
#pragma semicolon 1

new TeamSpec;
new TeamUna;
new bool:NoTeams = false;

#define SPECTATOR_TEAM 0
#define TEAM_SPEC 	1
#define TEAM_1			2
#define TEAM_2			3

new Handle:SpawnProtectionEnabled;
new Handle:SpawnProtectionTime;
new Handle:SpawnProtectionNotify;
new Handle:SpawnProtectionColor;

new RenderOffs;

new bool:UsedRespawnMe[MAXPLAYERS + 1] = {false, ...};

enum FX
{
	FxNone = 0,
	FxPulseFast,
	FxPulseSlowWide,
	FxPulseFastWide,
	FxFadeSlow,
	FxFadeFast,
	FxSolidSlow,
	FxSolidFast,
	FxStrobeSlow,
	FxStrobeFast,
	FxStrobeFaster,
	FxFlickerSlow,
	FxFlickerFast,
	FxNoDissipation,
	FxDistort,               // Distort/scale/translate flicker
	FxHologram,              // kRenderFxDistort + distance fade
	FxExplode,               // Scale up really big!
	FxGlowShell,             // Glowing Shell
	FxClampMinScale,         // Keep this sprite from getting very small (SPRITES only!)
	FxEnvRain,               // for environmental rendermode, make rain
	FxEnvSnow,               //  "        "            "    , make snow
	FxSpotlight,
	FxRagdoll,
	FxPulseFastWider,
};

enum Render
{
	Normal = 0, 		// src
	TransColor, 		// c*a+dest*(1-a)
	TransTexture,		// src*a+dest*(1-a)
	Glow,				// src*a+dest -- No Z buffer checks -- Fixed size in screen space
	TransAlpha,			// src*srca+dest*(1-srca)
	TransAdd,			// src*a+dest
	Environmental,		// not drawn, used for environmental effects
	TransAddFrameBlend,	// use a fractional frame value to blend between animation frames
	TransAlphaAdd,		// src + dest*(1-a)
	WorldGlow,			// Same as kRenderGlow but not fixed size in screen space
	None,				// Don't render.
};

public Plugin:myinfo =
{
	name = "Spawn Protection [Added CS:GO Support]",
	author = "Fredd && Modified by El Diablo",
	description = "Adds spawn protection",
	version = "1.6",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("spawnprotection_version", VERSION, "Spawn Protection Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	SpawnProtectionEnabled		= CreateConVar("sp_on", "1");
	SpawnProtectionTime			= CreateConVar("sp_time", "10");
	SpawnProtectionNotify		= CreateConVar("sp_notify", "1");
	SpawnProtectionColor		= CreateConVar("sp_color", "0 255 0 120");

	AddCommandListener(SayCommand, "say");
	AddCommandListener(SayCommand, "say_team");

	RenderOffs					= FindSendPropOffs("CBasePlayer", "m_clrRender");

	decl String:ModName[21];
	GetGameFolderName(ModName, sizeof(ModName));

	if(StrEqual(ModName, "cstrike", false) || StrEqual(ModName, "dod", false) || StrEqual(ModName, "csgo", false) || StrEqual(ModName, "tf", false))
	{
		TeamSpec = 1;
		TeamUna = 0;
		NoTeams = false;

	} else if(StrEqual(ModName, "Insurgency", false))
	{
		TeamSpec = 3;
		TeamUna = 0;
		NoTeams = false;
	}
	else if(StrEqual(ModName, "hl2mp", false))
	{
		NoTeams = true;
	} else
	{
		SetFailState("%s is an unsupported mod", ModName);
	}
	HookEvent("player_spawn", OnPlayerSpawn);
}

public Action:SayCommand(client, const String:command[], argc)
{
	if(!GetConVarBool(SpawnProtectionEnabled))
		return Plugin_Continue;

	if (client > 0 && IsClientInGame(client))
	{
		new team = GetClientTeam(client);
		if(team == TEAM_1 || team == TEAM_2)
		{
			decl String:text[128];
			GetCmdArg(1,text,sizeof(text));
			if(StrEqual(text,"!respawnme",false) || StrEqual(text,"/respawnme",false))
			{
				if(!IsPlayerAlive(client))
				{
					UsedRespawnMe[client]=true;
					CS_RespawnPlayer(client);
				}
				else
				{
					PrintToChat(client,"You can use this command while you are alive!");
				}
				return Plugin_Handled;
			}
		}
		else
		{
			PrintToChat(client,"You must be on a team to use this command!");
		}
	}
	return Plugin_Continue;
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(SpawnProtectionEnabled) == 1)
	{
		new client 	= GetClientOfUserId(GetEventInt(event, "userid"));
		new Team 	= GetClientTeam(client);

		if(UsedRespawnMe[client])
		{
			UsedRespawnMe[client]=false;

			if(NoTeams == false)
			{
				if(Team == TeamSpec || Team == TeamUna)
					return Plugin_Continue;
			}
			if(!IsPlayerAlive(client))
				return Plugin_Continue;

			decl String:SzColor[32];
			decl String:Colors[4][4];
			new Float:Time = float(GetConVarInt(SpawnProtectionTime));

			GetConVarString(SpawnProtectionColor, SzColor, sizeof(SzColor));
			ExplodeString(SzColor, " ", Colors, 4, 4);

			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
			set_rendering(client, FX:FxDistort, StringToInt(Colors[0]),StringToInt(Colors[1]),StringToInt(Colors[2]), Render:RENDER_TRANSADD, StringToInt(Colors[3]));
			CreateTimer(Time, RemoveProtection, client);
			if(GetConVarInt(SpawnProtectionNotify) > 0)
				PrintToChat(client, "\x04[SpawnProtection] \x01you will be spawn protected for \x04%i \x01seconds", RoundToNearest(Time));
		}
	}
	return Plugin_Continue;
}
public Action:RemoveProtection(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		set_rendering(client);
		if(GetConVarInt(SpawnProtectionNotify) > 0)
			PrintToChat(client, "\x04[SpawnProtection] \x01spawn protection is now off..");
	}
}
stock set_rendering(index, FX:fx=FxNone, r=255, g=255, b=255, Render:render=Normal, amount=255)
{
	SetEntProp(index, Prop_Send, "m_nRenderFX", _:fx, 1);
	SetEntProp(index, Prop_Send, "m_nRenderMode", _:render, 1);
	SetEntData(index, RenderOffs, r, 1, true);
	SetEntData(index, RenderOffs + 1, g, 1, true);
	SetEntData(index, RenderOffs + 2, b, 1, true);
	SetEntData(index, RenderOffs + 3, amount, 1, true);
}
public OnClientPutInServer(client)
{
	UsedRespawnMe[client]=false;
}
public OnClientDisconnect(client)
{
	UsedRespawnMe[client]=false;
}
public OnMapStart()
{
	for(new i=1;i<=MaxClients;i++)
	{
		UsedRespawnMe[i]=false;
	}
}
