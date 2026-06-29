#include <sdktools>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Conditional DoubleJump",
	author = "sidezz",
	description	= "Allows double-jumping",
	version = "1.0",
	url	= "www.coldcommunity.com"
}

ConVar g_cvString = null;
char g_String[256] = ""; // ;)

int g_fLastButtons[MAXPLAYERS + 1];
int g_fLastFlags[MAXPLAYERS + 1];
int g_iJumps[MAXPLAYERS + 1];

bool g_DoubleJump[MAXPLAYERS + 1] = {false, ...};


	
public void OnPluginStart() 
{	
	g_cvString = CreateConVar("sm_doublejump_string", "SERVERNAME", "String required to give doublejump", FCVAR_NOTIFY);
	g_cvString.AddChangeHook(OnStringChanged);
	g_cvString.GetString(g_String, sizeof(g_String));
}

public void OnStringChanged(ConVar convar, const char[] oldVal, const char[] newVal)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			char name[MAX_NAME_LENGTH + 1];
			GetClientName(i, name, sizeof(name));
			if(StrContains(name, g_String, false) != -1)
			g_DoubleJump[i] = true;
		}
	}
}

public void OnClientAuthorized(int client)
{
	if(IsClientConnected(client))
	{
		char name[MAX_NAME_LENGTH + 1];
		GetClientName(client, name, sizeof(name));
		if(StrContains(name, g_String, false) != -1) g_DoubleJump[client] = true;
		else g_DoubleJump[client] = false;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) 
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{		
		if(g_DoubleJump[client])
		{
			DoubleJump(client);
		}
	}
}

//not sure who i got this from
void DoubleJump(int client) 
{
	int fCurFlags = GetEntityFlags(client);
	int fCurButtons	= GetClientButtons(client);	
	
	if(g_fLastFlags[client] & FL_ONGROUND)
	{
		if (!(fCurFlags & FL_ONGROUND) && !(g_fLastButtons[client] & IN_JUMP) && fCurButtons & IN_JUMP) 
		{
			OriginalJump(client);
		}
	} 
	else if (fCurFlags & FL_ONGROUND)
	{
		Landed(client);
	} 
	else if (!(g_fLastButtons[client] & IN_JUMP) && fCurButtons & IN_JUMP) 
	{
		ReJump(client);
	}
	
	g_fLastFlags[client] = fCurFlags;
	g_fLastButtons[client] = fCurButtons;
}

void OriginalJump(int client) 
{
	g_iJumps[client]++;	// increment jump count
}

void Landed(int client) 
{
	g_iJumps[client] = 0;	// reset jumps count
}

void ReJump(int client) 
{
	if (1 <= g_iJumps[client] <= 1) 
	{
		g_iJumps[client]++;
		float vVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);
		vVel[2] = 54.0;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
	}
}