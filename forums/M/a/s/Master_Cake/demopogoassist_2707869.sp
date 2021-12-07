#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

#define SPRITE_BEAM	"materials/sprites/laser.vmt"
#define PLUGIN_VERSION	"1.0.3"

bool AP_ENABLED[MAXPLAYERS + 1];
bool APF_ENABLED[MAXPLAYERS + 1];
bool PL_Enabled;

Handle HudDisplay;

ConVar g_pluginEnabled;

int sprite;
int Projectile[MAXPLAYERS + 1][1];

public Plugin:myinfo =
{
	name = "Pogo Assistant for Demo",
	author = "Master Cake",
	description = "This plugin helps jumpers to track projectiles",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	CreateConVar("ap_version", PLUGIN_VERSION, "Demo Pogo Assistant Version", FCVAR_REPLICATED | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_pluginEnabled = CreateConVar("ap_enabled", "1", "Enable Demo Pogo Assistant\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	PL_Enabled = GetConVarBool(g_pluginEnabled);

	HookConVarChange(g_pluginEnabled, ConsoleVarChange);

	RegConsoleCmd("sm_ap", AP_Command, "Command to enable/disable Demo Pogo Assistant");
	RegConsoleCmd("sm_apf", APF_Command, "Command to enable/disable Demo Pogo Assistant (arrows)");

	AutoExecConfig(true, "demopogoassist");
	HudDisplay = CreateHudSynchronizer();
}

public ConsoleVarChange(Handle:CVar, const String:oldValue[], const String:newValue[])
{
	if(CVar == g_pluginEnabled)
	{
		PL_Enabled = GetConVarBool(g_pluginEnabled);
	}
}

public OnMapStart()
{
	sprite = PrecacheModel(SPRITE_BEAM);
}

public OnClientPutInServer(myClient)
{
	AP_ENABLED[myClient] = false;
	APF_ENABLED[myClient] = false;
	Projectile[myClient][0] = -1;
}

public Action:AP_Command(myClient, args)
{
	if(!PL_Enabled || !IsValidClient(myClient))
		return Plugin_Continue;

	if (!AP_ENABLED[myClient])
	{
    	AP_ENABLED[myClient] = true;
    	ReplyToCommand(myClient, "[SM] Demo Pogo Assistant Enabled!");
    	if (TF2_GetPlayerClass(myClient) != TFClass_DemoMan)
    	{
    		ClearSyncHud(myClient, HudDisplay);
    		SetHudTextParams(-1.0, -1.0, 3.0, 255, 255, 255, 255, 0, 0.1, 0.1, 0.1);
    		ShowSyncHudText(myClient, HudDisplay, "GO DEMO");
    	}
    	else
    	{
     		ClearSyncHud(myClient, HudDisplay);
    		SetHudTextParams(-1.0, -1.0, 3.0, 0, 255, 0, 255, 0, 0.1, 0.1, 0.1);
    		ShowSyncHudText(myClient, HudDisplay, "Demo Pogo Assistant Enabled!");
    	}
    	return Plugin_Continue;
    }
	if (AP_ENABLED[myClient])
    {
    	AP_ENABLED[myClient] = false;
    	ReplyToCommand(myClient, "[SM] Demo Pogo Assistant Disabled!");
    	Projectile[myClient][0] = -1;
    }

	return Plugin_Handled;
}

public Action:APF_Command(myClient, args)
{
	if(!PL_Enabled || !IsValidClient(myClient))
		return Plugin_Continue;

	if (!APF_ENABLED[myClient])
	{
    	APF_ENABLED[myClient] = true;
    	ReplyToCommand(myClient, "[SM] Demo Pogo Assistant (arrows) Enabled!");
    	if (TF2_GetPlayerClass(myClient) != TFClass_DemoMan)
    	{
    		ClearSyncHud(myClient, HudDisplay);
    		SetHudTextParams(-1.0, -1.0, 3.0, 255, 255, 255, 255, 0, 0.1, 0.1, 0.1);
    		ShowSyncHudText(myClient, HudDisplay, "GO DEMO");
    	}
    	else
    	{
     		ClearSyncHud(myClient, HudDisplay);
    		SetHudTextParams(-1.0, -1.0, 3.0, 0, 255, 0, 255, 0, 0.1, 0.1, 0.1);
    		ShowSyncHudText(myClient, HudDisplay, "Demo Pogo Assistant (arrows) Enabled!");
    	}
    	return Plugin_Continue;
    }
	if (APF_ENABLED[myClient])
    {
    	APF_ENABLED[myClient] = false;
    	ReplyToCommand(myClient, "[SM] Demo Pogo Assistant (arrows) Disabled!");
    }

	return Plugin_Handled;
}

public void OnEntityCreated(int myEntity, const char[] MyName)
{
	if (StrContains(MyName, "tf_projectile_") == 0)
	{
		if (StrEqual(MyName[14], "rocket"))
		{
			//TODO
		}
		else
		{
			SDKHook(myEntity, SDKHook_SpawnPost, ProjectileSpawn);
		}
	}
}

public Action:ProjectileSpawn(int myEntity)
{
	new myRef = EntIndexToEntRef(myEntity); //Converts an entity index into a serial encoded entity reference.
	static PrevRef = -1;

	if (PL_Enabled && PrevRef != myRef)
	{
		PrevRef = myRef; //To execute the code 1 time in this scope

		int myOwner = GetEntPropEnt(myEntity, Prop_Data, "m_hOwnerEntity");

		int CurrentWeapon = GetEntPropEnt(myOwner, Prop_Send, "m_hActiveWeapon"); //Get active weapon (entity index)
		int WeaponIndex = GetEntProp(CurrentWeapon, Prop_Send, "m_iItemDefinitionIndex"); //Get Definition Index from acrive weapon (integer value)

		if (IsValidClient(myOwner) && AP_ENABLED[myOwner] && TF2_GetPlayerClass(myOwner) == TFClass_DemoMan && IsValidEntity(myEntity) && (WeaponIndex == 20 || WeaponIndex == 207 || WeaponIndex == 661 || WeaponIndex == 797 || WeaponIndex == 806 || WeaponIndex == 886 || WeaponIndex == 895 || WeaponIndex == 904 || WeaponIndex == 913 || WeaponIndex == 962 || WeaponIndex == 971))
		{
			int color[4]; color[0] = 0; color[1] = 255; color[2] = 0; color[3] = 255;
			TE_SetupBeamFollow(myEntity, sprite, 0, 1.0, 5.0, 5.0, 1, color);
			TE_SendToClient(myOwner, 0.0);
			Projectile[myOwner][0] = myEntity;
		}
	}
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(myClient, &myButtons, &myImpulse, Float:myVel[3], Float:myAng[3], &myWeapon)
{
	if(!PL_Enabled || !IsValidClient(myClient) || !IsValidEntity(Projectile[myClient][0]) || Projectile[myClient][0] == 0 || Projectile[myClient][0] == -1)
		return Plugin_Continue;

	/*Checking for rockets*/
	char ClassName[64];
	GetEntityClassname(Projectile[myClient][0], ClassName, sizeof(ClassName));
	if (StrContains(ClassName, "tf_projectile_") == -1 || StrContains(ClassName, "tf_projectile_rocket") != -1)
		return Plugin_Continue;
	/*End*/

	if (AP_ENABLED[myClient] && myClient == GetEntPropEnt(Projectile[myClient][0], Prop_Send, "m_hThrower"))
	{
		float FL_TargetVec[3];
		float FL_PosEntityOrig[3];
		float FL_PlayerPos[3];

		GetEntPropVector(Projectile[myClient][0], Prop_Data, "m_vecAbsOrigin", FL_PosEntityOrig);
		GetClientAbsOrigin(myClient, FL_PlayerPos);

		SubtractVectors(FL_PosEntityOrig, FL_PlayerPos, FL_TargetVec); //Distance to target
		float FL_Dist = GetVectorLength(FL_TargetVec);

		char chart[32];

		ClearSyncHud(myClient, HudDisplay);
		SetHudTextParams(0.65, 0.65, 0.0001, 025, 144, 255, 255, 0, 0.1, 0.1, 0.1);
		GenerateCustomChart(chart, FL_Dist);
		ShowSyncHudText(myClient, HudDisplay, "Distance to projectile: %1.0f \n\nDistance to proj chart: %s", FL_Dist / 6.0, chart);

		if ((FL_PosEntityOrig[2] < FL_PlayerPos[2] || FL_PosEntityOrig[2] < (FL_PlayerPos[2] + 10.0)) && APF_ENABLED[myClient])
		{
			SetHudTextParams(0.475, 0.55, 0.5, 255, 0, 0, 255, 0, 0.1, 0.1, 0.1);
			ShowHudText(myClient, -1, "▼▼▼");
			return Plugin_Continue;
		}
		if ((FL_PosEntityOrig[2] > FL_PlayerPos[2]) && APF_ENABLED[myClient])
		{
			SetHudTextParams(0.475, 0.4, 0.5, 0, 255, 0, 255, 0, 0.1, 0.1, 0.1);
			ShowHudText(myClient, -1, "▲▲▲");
			return Plugin_Continue;
		}
	}

	return Plugin_Continue;
}

/////////////////////////////// <-- STOCKS --> ////////////////////////////////////////////////

/**
 * Checks client validity
 * @param myEntity        Entity index.
 * @param Replay          Logical bool parameter.
 */
stock bool:IsValidClient(myClient, bool:Replay = true)
{
  if(myClient <= 0 || myClient > MaxClients || !IsClientInGame(myClient))
    return false;
  if(Replay && (IsClientSourceTV(myClient) || IsClientReplay(myClient) || IsClientObserver(myClient)))
    return false;
  return true;
}

/**
 * Generates custom chart (THIS IS GENIUS ALGORITHM LEL)
 * @param chart        Destination string buffer.
 * @param FL_Dist      Vector's length that stores data for chart.
 */
stock void GenerateCustomChart(char chart[32], float FL_Dist)
{
	if (FL_Dist / 6.0 < 10 && FL_Dist / 6.0 > 0)
		chart = "█";

	if (FL_Dist / 6.0 < 15 && FL_Dist / 6.0 > 10)
		chart = "██";

	if (FL_Dist / 6.0 < 20 && FL_Dist / 6.0 > 15)
		chart = "███";

	if (FL_Dist / 6.0 < 25 && FL_Dist / 6.0 > 20)
		chart = "████";

	if (FL_Dist / 6.0 < 30 && FL_Dist / 6.0 > 25)
		chart = "█████";

	if (FL_Dist / 6.0 < 35 && FL_Dist / 6.0 > 30)
		chart = "██████";

	if (FL_Dist / 6.0 < 40 && FL_Dist / 6.0 > 35)
		chart = "███████";

	if (FL_Dist / 6.0 < 45 && FL_Dist / 6.0 > 40)
		chart = "████████";

	if (FL_Dist / 6.0 < 50 && FL_Dist / 6.0 > 45)
		chart = "█████████";

	if (FL_Dist / 6.0 > 50)
		chart = "TOO FAR";
}