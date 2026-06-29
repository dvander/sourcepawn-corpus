#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <colors>
#include <clientprefs>

#pragma semicolon 1

#define NO_ATTACH 0
#define ATTACH_NORMAL 1
#define ATTACH_HEAD 2

new Handle:tGlow[MAXPLAYERS+1];

new bool:pBlack[MAXPLAYERS+1];
new bool:pRed[MAXPLAYERS+1];
new bool:pBlue[MAXPLAYERS+1];
new bool:pGreen[MAXPLAYERS+1];
new bool:pYellow[MAXPLAYERS+1];
new bool:pPurple[MAXPLAYERS+1];
new bool:pCyan[MAXPLAYERS+1];
new bool:pGlow[MAXPLAYERS+1];


public Plugin:myinfo = 
{
	name = "Premium Mod",
	author = "Noodleboy347, modified by who knows",
	description = "Fuck Saigns. Their 'donator' effects are from noodleboy347's plugin",
	version = "1.0",
	url = "www.fucksaigns.com"
}


public OnPluginStart()
{
	RegConsoleCmd("playerblack", Command_Black);
	RegConsoleCmd("playerred", Command_Red);
	RegConsoleCmd("playerblue", Command_Blue);
	RegConsoleCmd("playergreen", Command_Green);
	RegConsoleCmd("playeryellow", Command_Yellow);
	RegConsoleCmd("playerpurple", Command_Purple);
	RegConsoleCmd("playercyan", Command_Cyan);
	RegConsoleCmd("glow", Command_Glow);

	HookEvent("player_changeclass", Player_Change);
}

public OnClientPostAdminCheck(client)
{
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
	{
		pGlow[client] = false;
	}
}

public Player_Change(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1 || IsValidEntity(client))
	{
		CloseAllHandles(client);
	}
}

public Action:Command_Glow(client, args)
{
	if(GetUserFlagBits(client) && ADMFLAG_CUSTOM1)
	{
		if(pGlow[client] == false)
		{
			CreateParticle("burningplayer_red", 300.0, client, ATTACH_HEAD);
			pGlow[client] = true;
			tGlow[client] = CreateTimer(300.0, Timer_Glow, client);
		}
		else
		{
			CPrintToChat(client, "You're already glowing!");
		}
		CPrintToChat(client, "You are now glowing!");
	}
	else
	{
		CPrintToChat(client, "Sorry, you don't have access to this!");
	}
	return Plugin_Handled;
}

public Action:Timer_Glow(Handle:timer, any:client)
{
	pGlow[client] = false;
}

public Action:Command_Black(client, args)
{
	if(GetUserFlagBits(client) && ADMFLAG_CUSTOM1)
	{
		if(pBlack[client] == false)
		{
			SetEntityRenderColor(client, 0, 0, 0, 255);
			pBlack[client] = true;
		}
		else
		{
			pBlack[client] = false;
		}
		CPrintToChat(client, "You are now black!");
	}
	else
	{
		CPrintToChat(client, "Sorry, you don't have access to this!");
	}
	return Plugin_Handled;
}

public Action:Command_Red(client, args)
{
	if(GetUserFlagBits(client) && ADMFLAG_CUSTOM1)
	{
		if(pRed[client] == false)
		{
			SetEntityRenderColor(client, 255, 100, 100, 255);
			pRed[client] = true;
		}
		else
		{
			pRed[client] = false;
		}
		CPrintToChat(client, "You are now red!");
	}
	else
	{
		CPrintToChat(client, "Sorry, you don't have access to this!");
	}
	return Plugin_Handled;
}

public Action:Command_Blue(client, args)
{
	if(GetUserFlagBits(client) && ADMFLAG_CUSTOM1)
	{
		if(pBlue[client] == false)
		{
			SetEntityRenderColor(client, 100, 100, 255, 255);
			pBlue[client] = true;
		}
		else
		{
			pBlue[client] = false;
		}
		CPrintToChat(client, "You are now blue!");
	}
	else
	{
		CPrintToChat(client, "Sorry, you don't have access to this!");
	}
	return Plugin_Handled;
}

public Action:Command_Green(client, args)
{
	if(GetUserFlagBits(client) && ADMFLAG_CUSTOM1)
	{
		if(pGreen[client] == false)
		{
			SetEntityRenderColor(client, 100, 255, 100, 255);
			pGreen[client] = true;
		}
		else
		{
			pGreen[client] = false;
		}
		CPrintToChat(client, "You are now green!");
	}
	else
	{
		CPrintToChat(client, "Sorry, you don't have access to this!");
	}
	return Plugin_Handled;
}

public Action:Command_Yellow(client, args)
{
	if(GetUserFlagBits(client) && ADMFLAG_CUSTOM1)
	{
		if(pYellow[client] == false)
		{
			SetEntityRenderColor(client, 255, 255, 100, 255);
			pYellow[client] = true;
		}
		else
		{
			pYellow[client] = false;
		}
		CPrintToChat(client, "You are now yellow!");
	}
	else
	{
		CPrintToChat(client, "Sorry, you don't have access to this!");
	}
	return Plugin_Handled;
}

public Action:Command_Purple(client, args)
{
	if(GetUserFlagBits(client) && ADMFLAG_CUSTOM1)
	{
		if(pPurple[client] == false)
		{
			SetEntityRenderColor(client, 255, 100, 255, 255);
			pPurple[client] = true;
		}
		else
		{
			pPurple[client] = false;
		}
		CPrintToChat(client, "You are now purple!");
	}
	else
	{
		CPrintToChat(client, "Sorry, you don't have access to this!");
	}
	return Plugin_Handled;
}

public Action:Command_Cyan(client, args)
{
	if(GetUserFlagBits(client) && ADMFLAG_CUSTOM1)
	{
		if(pCyan[client] == false)
		{
			SetEntityRenderColor(client, 100, 255, 255, 255);
			pCyan[client] = true;
		}
		else
		{
			pCyan[client] = false;
		}
		CPrintToChat(client, "You are now cyan!");
	}
	else
	{
		CPrintToChat(client, "Sorry, you don't have access to this!");
	}
	return Plugin_Handled;
}

stock Handle:CreateParticle(String:type[], Float:time, entity, attach=NO_ATTACH, Float:xOffs=0.0, Float:yOffs=0.0, Float:zOffs=0.0)
{
	new particle = CreateEntityByName("info_particle_system");
	
	if (IsValidEdict(particle))
	{
		decl Float:pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		pos[0] += xOffs;
		pos[1] += yOffs;
		pos[2] += zOffs;
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", type);

		if (attach != NO_ATTACH)
		{
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", entity, particle, 0);
		
			if (attach == ATTACH_HEAD)
			{
				SetVariantString("head");
				AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
			}
		}
		DispatchKeyValue(particle, "targetname", "present");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
		return CreateTimer(time, DeleteParticle, particle);
	}
	else
	{
		LogError("(CreateParticle): Could not create info_particle_system");
	}
	
	return INVALID_HANDLE;
}

public Action:DeleteParticle(Handle:timer, any:particle)
{
	if (IsValidEdict(particle))
	{
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		
		if (StrEqual(classname, "info_particle_system", false))
		{
			RemoveEdict(particle);
		}
	}
}

CloseAllHandles(client)
{
	tGlow[client] = INVALID_HANDLE;
}

public OnClientDisconnect(client)
{
	CloseAllHandles(client);
}