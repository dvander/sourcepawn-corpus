#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

int g_iButton [MAXPLAYERS+1];

int g_iEntFiring [MAXPLAYERS];
int g_iEntRocket [MAXPLAYERS];

bool g_bRocketActive [MAXPLAYERS+1];
bool g_bFlyingClient [MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "L4D2 Rocket Launcher",
	version = "1.0",
	description = "Rocket Launcher",
	author = "alasfourom",
	url = "https://forums.alliedmods.net"
}

public void OnPluginStart()
{
	RegAdminCmd("sm_fly", Command_RocketLauncher, ADMFLAG_CHEATS, "sm_fly");
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerSpawn);
}

public void OnMapStart()
{
	PrecacheModel("models/missiles/f18_agm65maverick.mdl", true);
	
	
	for(int i = 1; i <= MaxClients; i++)
	{
		g_bRocketActive[i] = false;
		g_bFlyingClient[i] = false;
	}
}

public void OnPluginEnd()
{
	for( int i = 0; i <= MaxClients; i++ )
	{
		if(IsValidEntRef(g_iEntRocket[i]))
		{
			AcceptEntityInput(g_iEntRocket[i], "ClearParent");
			AcceptEntityInput(g_iEntRocket[i], "Kill");
		}
		if(IsValidEntRef(g_iEntFiring[i]))
		{
			AcceptEntityInput(g_iEntFiring[i], "ClearParent");
			AcceptEntityInput(g_iEntFiring[i], "Kill");
		}
	}
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client)) return;
	
	if(g_bRocketActive[client])
	{
		g_bRocketActive[client] = false;
		if(IsValidEntRef(g_iEntRocket[client]))
		{
			AcceptEntityInput(g_iEntRocket[client], "ClearParent");
			AcceptEntityInput(g_iEntRocket[client], "Kill");
		}
		if(IsValidEntRef(g_iEntFiring[client]))
		{
			AcceptEntityInput(g_iEntFiring[client], "ClearParent");
			AcceptEntityInput(g_iEntFiring[client], "Kill");
		}
	}
}

public Action Command_RocketLauncher(int client, int args)
{	
	if(GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		Toggle_RocketLaunch(client);
		Toggle_FireParticle(client);
	}
	else PrintToChat(client, "\x04[Rocket Launcher] \x01Only alive survivors can use this command.");
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *                     									Missile													   *
 *================================================================================================================ */

void Toggle_RocketLaunch(int client)
{
	int entity = g_iEntRocket[client];
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
	{
		AcceptEntityInput(entity, "Kill");
		g_bRocketActive[client] = false;
		
		AcceptEntityInput(client, "EnableLedgeHang");
		PrintToChat(client, "\x04[Rocket Launcher] \x01You have toggled rocket launcher: \x05Off");
	}
		
	else
	{
		g_iEntRocket[client] = DisplayRocketLauncher(client);
		g_iEntRocket[client] = EntIndexToEntRef(g_iEntRocket[client]);
		g_bRocketActive[client] = true;
		
		AcceptEntityInput(client, "DisableLedgeHang");
		PrintToChat(client, "\x04[Rocket Launcher] \x01You have toggled rocket launcher: \x05On");
	}
}

int DisplayRocketLauncher(int client = 0)
{
	float vPos[3], vAng[3];
	int entity = CreateEntityByName("prop_dynamic_override");
	
	if(entity != -1 && IsValidEdict(entity))
	{
		DispatchKeyValue(entity, "model", "models/missiles/f18_agm65maverick.mdl");  
		DispatchSpawn(entity);
		SetEntProp(entity, Prop_Data, "m_takedamage", 0, 1);
		SetEntityMoveType(entity, MOVETYPE_NOCLIP);
		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 2);
		SetEntPropFloat(entity, Prop_Data,"m_flModelScale",0.3);
		
		char sTemp[64];
		GetEntPropString(client, Prop_Data, "m_ModelName", sTemp, 64);
	
		if (sTemp[26] == 'c')	// coach
		{
			vAng[0] += -80;
			vPos[0] += -15;
			vPos[1] += -5;
		}
		else if (sTemp[26] == 'g')	// nick
		{
			vAng[1] += -80;
			vPos[0] += -5;
			vPos[1] += 20;
		}
		else if (sTemp[26] == 'm' && sTemp[27] == 'e')	// ellis
		{
			vAng[1] += -80;
			vPos[0] += -5;
			vPos[1] += 20;
		}
		else if (sTemp[26] == 'p')	// rochelle
		{
			vAng[1] += 110;
			vPos[0] += 15;
			vPos[1] += -20;
			vPos[2] -= 20;
		}
		else if (sTemp[26] == 'n')	// bills
		{
			vAng[1] += 180;
			vPos[0] += 25;
			vPos[1] += -5;
		}
		else if (sTemp[26] == 't')	// zoey
		{
			vAng[1] += -90;
			vPos[0] += -5;
			vPos[1] += 20;
			vPos[2] -= 0;
		}
		else if (sTemp[26] == 'b')	// francsis
		{
			vAng[0] += 20;
			vAng[1] += 215;
			vPos[0] += 30;
			vPos[1] += 0;
		}
		else	// louis
		{
			vAng[1] += -80;
			vPos[0] += -5;
			vPos[1] += 20;
		}
		
		char Buffer[16];
		Format(Buffer, sizeof(Buffer), "target%d", client);
		DispatchKeyValue(client, "targetname", Buffer);
		SetVariantString(Buffer);
		AcceptEntityInput(entity, "SetParent", entity, entity, 0);
		SetVariantString("medkit");
		AcceptEntityInput(entity, "SetParentAttachment");
		
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	 
		SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
		SetEntProp(entity, Prop_Send, "m_nGlowRange", 200);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", 249 + (155 * 256) + (84 * 65536));
		
		return entity;
	}
	return 0;
}

void AddVelocity(int client, float speed)
{
	float vecVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVelocity);
	vecVelocity[2] += speed;
	if ((vecVelocity[2]) > 200.0) vecVelocity[2] = 200.0;

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

/* =============================================================================================================== *
 *                     									Fire Particle											   *
 *================================================================================================================ */

void Toggle_FireParticle(int client)
{
	int entity = g_iEntFiring[client];
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		AcceptEntityInput(entity, "Kill");
		
	else
	{
		char sAttachment[12];
		FormatEx(sAttachment, sizeof(sAttachment), "forward");
		
		char sTemp[64];
		GetEntPropString(client, Prop_Data, "m_ModelName", sTemp, 64);
	
		if (sTemp[26] == 'c')	// Coach
			g_iEntFiring[client] = DisplayParticle("fire_small_01", view_as<float>({ 28.0, 15.0, -20.0 }), view_as<float>({ 0.0, 0.0, 0.0 }), client, sAttachment);
			
		else if (sTemp[26] == 'g')	// nick
			g_iEntFiring[client] = DisplayParticle("fire_small_01", view_as<float>({ -10.0, 0.0, -50.0 }), view_as<float>({ 0.0, 0.0, 0.0 }), client, sAttachment);
			
		else if (sTemp[26] == 'm' && sTemp[27] == 'e')	// ellis
			g_iEntFiring[client] = DisplayParticle("fire_small_01", view_as<float>({ -10.0, 0.0, -50.0 }), view_as<float>({ 0.0, 0.0, 0.0 }), client, sAttachment);
			
		else if (sTemp[26] == 'p')	// rochelle
			g_iEntFiring[client] = DisplayParticle("fire_small_01", view_as<float>({ 0.0, 0.0, 0.0 }), view_as<float>({ 0.0, 0.0, 0.0 }), client, sAttachment);
		
		else if (sTemp[26] == 'n')	// bills
			g_iEntFiring[client] = DisplayParticle("fire_small_01", view_as<float>({ -16.0, 5.0, -50.0  }), view_as<float>({ 0.0, 0.0, 0.0 }), client, sAttachment);
			
		else if (sTemp[26] == 't')	// zoey
			g_iEntFiring[client] = DisplayParticle("fire_small_01", view_as<float>({ 0.0, -25.0, -20.0 }), view_as<float>({ 0.0, 0.0, 0.0 }), client, sAttachment);
			
		else if (sTemp[26] == 'b')	// francsis
			g_iEntFiring[client] = DisplayParticle("fire_small_01", view_as<float>({ -40.0, -20.0, 0.0 }), view_as<float>({ 0.0, 0.0, 0.0 }), client, sAttachment);
			
		else g_iEntFiring[client] = DisplayParticle("fire_small_01", view_as<float>({ -16.0, 5.0, -50.0 }), view_as<float>({ 0.0, 0.0, 0.0 }), client, sAttachment); // louis

		g_iEntFiring[client] = EntIndexToEntRef(g_iEntFiring[client]);
	}
}

int DisplayParticle(char[] sParticle, float vPos[3], float fAng[3], int client = 0, const char[] sAttachment = "")
{
	int entity = CreateEntityByName("info_particle_system");

	if(entity != -1 && IsValidEdict(entity))
	{
		DispatchKeyValue(entity, "effect_name", sParticle);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "start");

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", client);
		
		if( strlen(sAttachment) != 0 )
		{
			SetVariantString(sAttachment);
			AcceptEntityInput(entity, "SetParentAttachment");
		}

		TeleportEntity(entity, vPos, fAng, NULL_VECTOR);

		return entity;
	}
	return 0;
}

bool IsValidEntRef(int iEnt)
{
	if( iEnt && EntRefToEntIndex(iEnt) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

/* =============================================================================================================== *
 *                     							Pressing "Reload" Button To Fly									   *
 *================================================================================================================ */

public void OnClientDisconnect_Post(int client)
{
    g_iButton[client] = 0;
}

public Action OnPlayerRunCmd (int client, int &buttons)
{
	if (!client || !IsClientInGame(client)) return Plugin_Handled;
	
	if(g_bRocketActive[client])
	{
		for (int i = 0; i < 25; i++)
		{
			int button = (1 << i);
			
			if ((buttons & button))
				OnButtonPress(client, button);
				
			else if ((g_iButton[client] & button))
				OnButtonRelease(client, button);
		}
		g_iButton[client] = buttons;
	}
	return Plugin_Continue;
}

void OnButtonPress(int client, int button)
{
	if(button & IN_RELOAD)
	{
		SetEntProp(client, Prop_Send, "movecollide", 1);
		SetEntProp(client, Prop_Send, "movetype", MOVETYPE_FLYGRAVITY);
		AddVelocity(client, 50.0);
	}
}

void OnButtonRelease(int client, int button)
{
	if(button & IN_RELOAD)
	{
		SetEntProp(client, Prop_Send, "movecollide", 0);
		SetEntProp(client, Prop_Send, "movetype", MOVETYPE_WALK);
	}
}