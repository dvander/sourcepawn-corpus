
//////////////////////////
//  thanks for code     //
//      shanapu         //
//////////////////////////

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define SOUND_HELICOPTER "vehicles/airboat/fan_blade_fullthrottle_loop1.wav"

bool g_bParachute[MAXPLAYERS+1], g_bLeft4Dead2;
int g_iVelocity = -1, g_ent[MAXPLAYERS+1];

static char g_sModels[2][] =
{
	"models/props_swamp/parachute01.mdl",
	"models/props/de_inferno/ceiling_fan_blade.mdl"
};

public Plugin myinfo = {
	name = "[L4D & L4D2] Left 4 Parachute",
	author = "Joshe Gatito",
	description = "Adds support for parachutes",
	version = "1.2",
	url = "https://steamcommunity.com/id/joshegatito/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
}

public void OnMapStart()
{
	for (int i = 0; i < 2; i++)
		PrecacheModel(g_sModels[i]);
	if( !g_bLeft4Dead2 ) PrecacheSound(SOUND_HELICOPTER);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(g_bParachute[client])
	{
		if(!(buttons & IN_USE) || !IsPlayerAlive(client))
		{
			DisableParachute(client);
			return Plugin_Continue;
		}
		
		float fVel[3];
		GetEntDataVector(client, g_iVelocity, fVel);

		if(fVel[2] >= 0.0)
		{
			DisableParachute(client);
			return Plugin_Continue;
		}

		if(GetEntityFlags(client) & FL_ONGROUND)
		{
			DisableParachute(client);
			return Plugin_Continue;
		}
		
		float fOldSpeed = fVel[2];
	
		if(fVel[2] < 100.0 * -1.0) fVel[2] = 100.0 * -1.0;
	
		if(fOldSpeed != fVel[2])
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVel);
	}
	else
	{
		if(!(buttons & IN_USE) || !IsPlayerAlive(client))
			return Plugin_Continue;
	
		if(GetEntityFlags(client) & FL_ONGROUND)
			return Plugin_Continue;

		float fVel[3];
		GetEntDataVector(client, g_iVelocity, fVel);

		if(fVel[2] >= 0.0)
			return Plugin_Continue;
	
		g_ent[client] = CreateEntityByName("prop_dynamic_override"); 			
		DispatchKeyValue(g_ent[client], "model", g_bLeft4Dead2 ? g_sModels[0] : g_sModels[1]);
		DispatchSpawn(g_ent[client]);		
		SetEntityMoveType(g_ent[client], MOVETYPE_NOCLIP);
		
		float ParachutePos[3], ParachuteAng[3];
		GetClientAbsOrigin(client, ParachutePos);
		GetClientAbsAngles(client, ParachuteAng);
		ParachutePos[2] += 60.0;
		ParachuteAng[0] = 0.0;
		
		TeleportEntity(g_ent[client], ParachutePos, ParachuteAng, NULL_VECTOR);
		
		if( g_bLeft4Dead2 )
		{		
		    SDKHook(client, SDKHook_PreThinkPost, OnRainbowParachute);
				
		    SetEntPropFloat(g_ent[client], Prop_Data, "m_flModelScale", 0.4);
			
			
		    SetEntityRenderMode(g_ent[client], RENDER_TRANSCOLOR);
		    SetEntityRenderColor(g_ent[client], 255, 255, 255, 2);
		}
		
		if( !g_bLeft4Dead2 ) CreateTimer(0.1, Timer_Parachute, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

		if( !g_bLeft4Dead2 ) EmitSoundToClient(client, SOUND_HELICOPTER, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_RAIDSIREN, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_LOW, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		
		SetVariantString("!activator");
		AcceptEntityInput(g_ent[client], "SetParent", client);

		g_bParachute[client] = true;
	}

	return Plugin_Continue;
}

public Action OnRainbowParachute(int client)
{
    if (!(0 < client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client)))
	{
		SDKUnhook(client, SDKHook_PreThinkPost, OnRainbowParachute);

		return Plugin_Continue;
	}

	int color[3];
	color[0] = RoundToNearest((Cosine((GetGameTime() * 3.0) + client + 0) * 75) + 75);
	color[1] = RoundToNearest((Cosine((GetGameTime() * 3.0) + client + 2) * 75) + 75);
	color[2] = RoundToNearest((Cosine((GetGameTime() * 3.0) + client + 4) * 75) + 75);
	
	SetEntProp(g_ent[client], Prop_Send, "m_nGlowRange", 150);
	SetEntProp(g_ent[client], Prop_Send, "m_iGlowType", 2);
    SetEntProp(g_ent[client], Prop_Send, "m_glowColorOverride", color[2] + (color[1] * 256) + (color[0] * 65536));
}

public Action Timer_Parachute( Handle timer, any client)
{
	RotateParachute(client, 100.0, 1);
	return Plugin_Continue;
}

void RotateParachute(int client, float value, int axis)
{
	float s_rotation[3];
	GetEntPropVector(g_ent[client], Prop_Data, "m_angRotation", s_rotation);
	s_rotation[axis] += value;
	TeleportEntity( g_ent[client], NULL_VECTOR, s_rotation, NULL_VECTOR);
}

void DisableParachute(int client)
{
	AcceptEntityInput(g_ent[client], "ClearParent");
	AcceptEntityInput(g_ent[client], "kill");
	
	SDKUnhook(client, SDKHook_PreThinkPost, OnRainbowParachute);

	ParachuteDrop(client);
	g_bParachute[client] = false;
}

void ParachuteDrop(int client)
{
	if (!IsClientInGame(client))
		return;
	
	if( !g_bLeft4Dead2 ) StopSound(client, SNDCHAN_STATIC, SOUND_HELICOPTER);	
}