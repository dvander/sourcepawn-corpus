#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include <tf2>
//#include <tf2_stocks>
#include <clientprefs>

#define PLUGIN_NAME		"[TF2] Laser Beam"
#define PLUGIN_VERSION	"1.0.1"

static int g_iLaserMaterial, g_iHaloMaterial;

bool g_bLaserEnabled[MAXPLAYERS+1];
int g_bLaserColor[MAXPLAYERS+1];
static int aTeamColor[2][4] = {
{255, 64, 64, 64},
{153, 204, 255, 64}
};

ConVar lb_alpha = null;
ConVar lb_dmg = null;

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = "Pelipoika (rewritten by Grey83)",
	description = "Laser beams from the player's eyes",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2413816"
};

public void OnPluginStart()
{
	LoadTranslations("tf2_laserbeam.phrases");
	char menutitle[64];
	Format(menutitle, sizeof(menutitle), "%T", "Menu_Title", LANG_SERVER);
	AutoExecConfig(true, "tf2_laserbeam");

	CreateConVar("tf2_laserbeam_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	lb_alpha = CreateConVar("sm_laserbeam_alpha", "64", "Amount of transparency", FCVAR_NONE, true, 0.0, true, 255.0 );
	lb_dmg = CreateConVar("sm_laserbeam_damage", "2", "Default laser beam damage", FCVAR_NONE, true, 0.0);

	RegConsoleCmd("sm_laserbeam", Command_ToggleLaser, "Fire a deadly laser");
	RegConsoleCmd("sm_lb", Command_ToggleLaser, "Fire a deadly laser");

	HookEvent("player_spawn", Event_Spawn);
}

public void OnMapStart()
{
	g_iLaserMaterial = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloMaterial = PrecacheModel("materials/sprites/halo01.vmt");
}

public void OnClientPutInServer(int client)
{
	g_bLaserEnabled[client] = false;
}

public Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bLaserEnabled[client] = false;
	g_bLaserColor[client] = GetClientTeam(client) == 3 ? 1 : 0;
}

public Action Command_ToggleLaser(int client, int args)
{
	if (!client) PrintToServer("[LASER] Command is in-game only");
	else if(0 < client <= MaxClients && IsClientInGame(client))
	{
		g_bLaserEnabled[client] = !g_bLaserEnabled[client];
		PrintToChat(client, g_bLaserEnabled[client] ? "[LASER] Enabled, hold R to fire the laser" : "[LASER] Disabled");
	}
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVel[3], float fAng[3], int &iWeapon)
{
	if (IsPlayerAlive(client) && g_bLaserEnabled[client] && iButtons & IN_RELOAD)
	{
		float flPos[3], flAng[3];
		GetClientEyePosition(client, flPos);
		GetClientEyeAngles(client, flAng);
		
		flPos[2] -= 5.0;
		
		Handle TraceRay = TR_TraceRayFilterEx(flPos, flAng, (CONTENTS_SOLID|CONTENTS_WINDOW|CONTENTS_GRATE), RayType_Infinite, TraceFilterEnt, client);
		
		if(TR_DidHit(TraceRay))
		{
			float flEndPos[3];
			TR_GetEndPosition(flEndPos, TraceRay);
			int iHit = TR_GetEntityIndex(TraceRay);
			
			float flDamageForce[3];
			MakeVectorFromPoints(flPos, flEndPos, flDamageForce);
			NormalizeVector(flDamageForce, flDamageForce);
			ScaleVector(flDamageForce, 500.0);

			if(0 < iHit <= MaxClients && IsClientInGame(iHit))
			{
				SDKHooks_TakeDamage(iHit, client, client, float(GetConVarInt(lb_dmg)), DMG_ENERGYBEAM|DMG_PLASMA|DMG_DISSOLVE, _, flDamageForce);
				TeleportEntity(iHit, NULL_VECTOR, NULL_VECTOR, flDamageForce);
			}
			int color[4];
			color = aTeamColor[g_bLaserColor[client]];
			color[3] = GetConVarInt(lb_alpha);
			TE_SetupBeamPoints(flPos, flEndPos, g_iLaserMaterial, g_iHaloMaterial, 0, 0, 0.06, 1.0, 1.0, 1, 0.0, color, 0);
			TE_SendToAll();
		}
		
		delete TraceRay;
	}
}

public bool TraceFilterEnt(int entityhit, int mask, any entity)
{
	return (entityhit != entity);
}