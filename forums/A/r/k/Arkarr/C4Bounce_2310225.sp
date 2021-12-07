#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_AUTHOR 	"Arkarr"
#define PLUGIN_VERSION 	"1.0"
#define MODEL_CHICKEN 	"models/chicken/chicken.mdl"

Handle timer;
Handle CVAR_MiniPowerJump;
Handle CVAR_MaxiPowerJump;
Handle CVAR_SecBetweenBounce;

bool bombCanBounce;

int g_iBeamSprite;
int g_ColorRed[] = {255, 0, 0, 200};

EngineVersion g_Game;

public Plugin myinfo = 
{
	name = "[CS:GO] Bouncing Bombs",
	author = PLUGIN_AUTHOR,
	description = "Make the C4 bounce everywhere !",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	CVAR_MiniPowerJump = CreateConVar("sm_c4bounce_mini_power", "300.0", "Set the minimal power that the bomb can bounce.");
	CVAR_MaxiPowerJump = CreateConVar("sm_c4bounce_maxi_power", "360.0", "Set the maximal power that the bomb can bounce.");
	CVAR_SecBetweenBounce = CreateConVar("sm_c4bounce_sec_between_bounces", "0.9", "Ammount of seconds before each bounce");
	
	HookEvent("bomb_dropped", EVENT_BombDropped);
	HookEvent("bomb_pickup", EVENT_BombPickUp);
	HookEvent("round_end", EVENT_BombPickUp);
}

public OnMapStart()
{
	g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	PrecacheModel(MODEL_CHICKEN);
}

public OnClientDisconnect(client)
{
	if(GetRealClientCount() == 0)
		bombCanBounce = false;
}

public Action EVENT_BombPickUp(Handle event, const char[] name, bool dontBroadcast)
{
	bombCanBounce = false;
}

public Action EVENT_BombDropped(Handle event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	int iC4 = -1; 
	
	while ((iC4 = FindEntityByClassname(iC4, "weapon_c4")) != INVALID_ENT_REFERENCE)
		if(IsValidEntity(iC4))
			break;
			
	if(iC4 != INVALID_ENT_REFERENCE)
	{	
		bombCanBounce = true;
		SetEntityModel(iC4, MODEL_CHICKEN);
		BounceC4(iC4, iClient);
    }
}

stock void BounceC4(int iC4, int iClient)
{
	/*float bombPos[3], playerPos[3], flResult[3];
	GetEntPropVector(iC4, Prop_Send, "m_vecOrigin", bombPos);
	GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", playerPos);
	
	SubtractVectors(playerPos, bombPos, flResult);
	//NegateVector(flResult);
	NormalizeVector(flResult, flResult);
	ScaleVector(flResult, 250.0);
	
	if(flResult[2] <= 250.0)
		flResult[2] = 250.0;*/	
	if(timer != INVALID_HANDLE)
		KillTimer(timer);
		
	if(!bombCanBounce)
		return;
		
	timer = CreateTimer(GetConVarFloat(CVAR_SecBetweenBounce), TMR_Bounce, iC4, TIMER_REPEAT);
}

public Action TMR_Bounce(Handle tmr, any iC4)
{
	if(iC4 != INVALID_ENT_REFERENCE && bombCanBounce)
	{
		float angles[3];
		angles[0] = GetRandomFloat(-360.0, 360.0);
		angles[1] = GetRandomFloat(-360.0, 360.0);
		angles[2] = GetRandomFloat(GetConVarFloat(CVAR_MiniPowerJump), GetConVarFloat(CVAR_MaxiPowerJump));
		TeleportEntity(iC4, NULL_VECTOR, NULL_VECTOR, angles);	
		TE_SetupBeamFollow(iC4, g_iBeamSprite, 0, 0.8, 1.0, 1.0, 1, g_ColorRed);
		TE_SendToAll();
	}
}

stock bool IsValidClient(iClient, bool bReplay = true)
{
	if (iClient <= 0 || iClient > MaxClients)
	return false;
	if (!IsClientInGame(iClient))
	return false;
	if (bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
	return false;
	return true;
}

stock GetRealClientCount(bool inGameOnly = true )
{
	int clients = 0;
	for( new i = 1; i <= GetMaxClients(); i++ )
	{
		if(((inGameOnly) ? IsClientInGame(i) : IsClientConnected(i)) && !IsFakeClient(i))
			clients++;
	}
	return clients;
}


