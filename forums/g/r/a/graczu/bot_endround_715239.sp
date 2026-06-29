#include <sourcemod>
#include <sdktools>
#include <cstrike>


new const String:CTBOT[] = "CT MASTER";
new CtBotID;
new const String:TTBOT[] = "TT MASTER";
new TtBotID;
new Score = -100;
new CollOff;

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

new FX:g_Effect = FX:FxGlowShell;
new Render:g_Render = Render:Glow;

#define TEAM_1    2
#define TEAM_2    3
#define VERSION    "1.0"

public Plugin:myinfo = {
	name = "EndRound Blocker",
	author = "graczu_-",
	description = "Block Endround on SURF",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CollOff = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	HookEvent("player_spawn", PlayerSpawn);
}

public OnMapStart()
{
	CreateTimer(5.0, CreatBots, 0);
}

public Action:CreatBots(Handle:timer){
	CreateFakeClient(CTBOT);
	CreateFakeClient(TTBOT);
	botSwitch();
}

botSwitch(){
	new mc = GetMaxClients();
	for( new i = 1; i < mc; i++ ){
		if( IsClientInGame(i) && IsFakeClient(i)){
			decl String:target_name[50];
			GetClientName( i, target_name, sizeof(target_name) );
			if(StrEqual(target_name, CTBOT)){
				CtBotID = i;
				CS_SwitchTeam(CtBotID, TEAM_1);
				CS_RespawnPlayer(CtBotID);
				SetEntProp(i, Prop_Data, "m_iFrags", Score);
			} else if(StrEqual(target_name, TTBOT)){
				TtBotID = i;
				CS_SwitchTeam(TtBotID, TEAM_2);
				CS_RespawnPlayer(TtBotID);
				SetEntProp(i, Prop_Data, "m_iFrags", Score);
			}
		}
	}
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
//	new Team = GetClientTeam(client);
	if(client == CtBotID){
		hideBot(client);
	} else if(client == TtBotID){
		hideBot(client);
	}
}

public hideBot(any:client){
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	SetEntData(client, CollOff, 2, 4, true);
	set_rendering(client, g_Effect, 0, 0, 0, g_Render, 0);
	new Float:loc[3];
	loc[0] = 10000.0;
	loc[1] = 10000.0;
	loc[2] = 10000.0;
	TeleportEntity(client, loc, NULL_VECTOR, NULL_VECTOR); 
}

stock set_rendering(index, FX:fx=FxNone, r=255, g=255, b=255, Render:render=Normal, amount=255)
{
	SetEntProp(index, Prop_Send, "m_nRenderFX", _:fx, 1);
	SetEntProp(index, Prop_Send, "m_nRenderMode", _:render, 1);

	new offset = GetEntSendPropOffs(index, "m_clrRender");
	
	SetEntData(index, offset, r, 1, true);
	SetEntData(index, offset + 1, g, 1, true);
	SetEntData(index, offset + 2, b, 1, true);
	SetEntData(index, offset + 3, amount, 1, true);
}