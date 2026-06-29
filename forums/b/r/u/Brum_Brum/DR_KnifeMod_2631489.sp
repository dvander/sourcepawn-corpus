#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#define MOD_TAG "\x01\x0B★ \x07[Knife Mod]\x04 "
public Plugin myinfo = 
{
	name = "[DR] Knife Mod", 
	description = "Knife Mod import from cs1.6", 
	author = "spunko && Brum Brum", 
	version = "1.0", 
	url = "https://forums.alliedmods.net/showthread.php?p=378952"
};

ConVar CVAR_HIGHSPEED, CVAR_LOWSPEED, CVAR_LOWGRAV, CVAR_HEALTH_ADD, CVAR_HEALTH_MAX, CVAR_DAMAGE;

Handle g_selectedknife;

int Knife[MAXPLAYERS + 1];

bool MoreDamageLowSpeed[MAXPLAYERS + 1], NoFootSteps[MAXPLAYERS + 1], HighSpeed[MAXPLAYERS + 1], MoreLowGravity[MAXPLAYERS + 1], HealthRegeneration[MAXPLAYERS + 1];

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	g_selectedknife = RegClientCookie("sm_knifeselected", "Selected knife skills", CookieAccess_Protected);
	RegConsoleCmd("sm_knife", Display_Knife);
	
	CVAR_HIGHSPEED = CreateConVar("km_highspeed", "1.3")
	CVAR_LOWSPEED = CreateConVar("km_lowspeed", "0.7")
	CVAR_HEALTH_ADD = CreateConVar("km_addhealth", "3")
	CVAR_HEALTH_MAX = CreateConVar("km_maxhealth", "75")
	CVAR_DAMAGE = CreateConVar("km_damage", "2.0")
	CVAR_LOWGRAV = CreateConVar("km_lowgravity", "0.6")
	AutoExecConfig(true, "Knife_Mod");
	AddNormalSoundHook(Sound);
	CreateTimer(480.0, kmodmsg, _, TIMER_REPEAT);
	CreateTimer(4.0, Healing, _, TIMER_REPEAT);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	if (!IsFakeClient(client)) {
		SendConVarValue(client, FindConVar("sv_footsteps"), "0");
	}
}

public void OnClientDisconnect(int client)
{
	if (AreClientCookiesCached(client))
	{
		char value[11];
		Format(value, sizeof(value), "%d", Knife[client]);
		SetClientCookie(client, g_selectedknife, value);
	}
	Knife[client] = 0;
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientCookiesCached(int client)
{
	char value[11];
	GetClientCookie(client, g_selectedknife, value, sizeof(value));
	Knife[client] = StringToInt(value);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	float lowspeed = CVAR_LOWSPEED.FloatValue;
	float highspeed = CVAR_HIGHSPEED.FloatValue;
	float gravity = CVAR_LOWGRAV.FloatValue;
	if (MoreDamageLowSpeed[client]) {
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", lowspeed);
	}
	else if (HighSpeed[client]) {
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", highspeed);
	}
	else if (MoreLowGravity[client]) {
		SetEntityGravity(client, gravity);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	float lowspeed = CVAR_LOWSPEED.FloatValue;
	float highspeed = CVAR_HIGHSPEED.FloatValue;
	float gravity = CVAR_LOWGRAV.FloatValue;
	if (MoreDamageLowSpeed[client]) {
		if (GetClientSpeed(client) != lowspeed) {
			SetClientSpeed(client, lowspeed);
		}
	}
	else if (HighSpeed[client]) {
		if (GetClientSpeed(client) != highspeed) {
			SetClientSpeed(client, highspeed);
		}
	}
	else if (MoreLowGravity[client]) {
		if (GetEntityGravity(client) != gravity) {
			SetEntityGravity(client, gravity);
		}
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (MoreDamageLowSpeed[attacker])
	{
		char weapons[64];
		float dmg = CVAR_DAMAGE.FloatValue;
		GetClientWeapon(attacker, weapons, sizeof(weapons));
		if ((StrContains(weapons, "knife", false) != -1) || (StrContains(weapons, "bayonet", false) != -1))
		{
			damage *= dmg;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action Display_Knife(int client, int args)
{
	Menu menu = new Menu(Menu_Handler);
	menu.SetTitle("Knife Mod");
	menu.AddItem("", "Machete (More Damage/Low Speed)");
	menu.AddItem("", "Bak Knife (No Footsteps)");
	menu.AddItem("", "Pocket Knife (High Speed)");
	menu.AddItem("", "Butcher Knife (More Low Gravity)");
	menu.AddItem("", "Default Knife (Health Regeneration)");
	menu.ExitButton = false;
	menu.Display(client, 60);
}

public int Menu_Handler(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		switch (item)
		{
			case 0:SetKnife(client, 0)
			case 1:SetKnife(client, 1)
			case 2:SetKnife(client, 2)
			case 3:SetKnife(client, 3)
			case 4:SetKnife(client, 4)
		}
	}
	if (action == MenuAction_End)delete menu;
}

public SetKnife(int client, int knife) {
	switch (knife)
	{
		case 0:
		{
			RestartStats(client);
			MoreDamageLowSpeed[client] = true;
			NoFootSteps[client] = false;
			HighSpeed[client] = false;
			MoreLowGravity[client] = false;
			HealthRegeneration[client] = false;
			RestartStats(client);
			Knife[client] = 1;
		}
		case 1:
		{
			RestartStats(client);
			MoreDamageLowSpeed[client] = false;
			NoFootSteps[client] = true;
			HighSpeed[client] = false;
			MoreLowGravity[client] = false;
			HealthRegeneration[client] = false;
			Knife[client] = 2;
		}
		case 2:
		{
			RestartStats(client);
			MoreDamageLowSpeed[client] = false;
			NoFootSteps[client] = false;
			HighSpeed[client] = true;
			MoreLowGravity[client] = false;
			HealthRegeneration[client] = false;
			Knife[client] = 3;
		}
		case 3:
		{
			RestartStats(client);
			MoreDamageLowSpeed[client] = false;
			NoFootSteps[client] = false;
			HighSpeed[client] = false;
			MoreLowGravity[client] = true;
			Knife[client] = 4;
		}
		case 4:
		{
			RestartStats(client);
			MoreDamageLowSpeed[client] = false;
			NoFootSteps[client] = false;
			HighSpeed[client] = false;
			MoreLowGravity[client] = false;
			HealthRegeneration[client] = true;
			Knife[client] = 5;
		}
	}
}

public Action Healing(Handle timer)
{
	int maxhp = CVAR_HEALTH_MAX.IntValue;
	int addhp = CVAR_HEALTH_ADD.IntValue;
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (HealthRegeneration[i] && IsPlayerAlive(i))
			{
				if (GetClientHealth(i) < maxhp)
				{
					SetEntityHealth(i, GetClientHealth(i) + addhp);
				}
			}
		}
	}
}

public Action Sound(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (!IsValidClient(entity) || IsFakeClient(entity))
		return Plugin_Continue;
	
	if ((StrContains(sample, "physics") != -1 || StrContains(sample, "footsteps") != -1) && StrContains(sample, "suit") == -1)
	{
		if (!NoFootSteps[entity])
			EmitSoundToAll(sample, entity);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action kmodmsg(Handle timer) {
	PrintToChatAll("%s Type /knife to change your knife skills", MOD_TAG);
}

void RestartStats(int client)
{
	SetClientSpeed(client, 1.0);
	SetEntityGravity(client, 1.0);
}

void SetClientSpeed(int client, float speed)
{
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", speed);
}
float GetClientSpeed(int client)
{
	return GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
}

public bool IsValidClient(int client)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || !IsClientConnected(client) || IsFakeClient(client) || IsClientSourceTV(client))
		return false;
	
	return true;
} 