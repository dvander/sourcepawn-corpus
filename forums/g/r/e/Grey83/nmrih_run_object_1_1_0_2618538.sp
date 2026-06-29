/*ChangeLog---------------------------------------------------------------------------------------------------------------
Ver 1.0.0			- 09/08/2017 Initial version
Ver 1.1.0			- 10/06/2018 Code optimized by Grey83 (plugin code has been optimized to reduce server load)
-------------------------------------------------------------------------------------------------------------------------*/
#pragma semicolon 1
#pragma newdecls required

#include <sdktools_functions>

static const char	PLUGIN_NAME[]		= "[NMRiH] Run Object",
					PLUGIN_VERSION[]	= "1.1.0";

bool bEnable,	// plugin on/off (default: 1)
	bShow;		// show stamina function (default: 0)
float fRate,	// Setting stamina consumption (default: 10)
	fTime[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name		= PLUGIN_NAME,
	author		= "misosiruGT (optimization by Grey83)",
	description	= "The player can run when the player picks up the object.",
	version		= PLUGIN_VERSION,
	url			= "misosirugt@gmail.com"
}

public void OnPluginStart()
{
	CreateConVar("sm_run_object_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ConVar cvar;
	(cvar = CreateConVar("sm_run_object_enable", "1", "1/0 - Enable/Disable plugin", _, true, _, true, 1.0)).AddChangeHook(CVarChange_Enable);
	bEnable = cvar.BoolValue;

	(cvar = CreateConVar("sm_run_object_show_stamina", "0", "1/0 - Enable/Disable show stamina", _, true, _, true, 1.0)).AddChangeHook(CVarChange_Show);
	bShow = cvar.BoolValue;

	(cvar = CreateConVar("sm_run_object_stamina_drain_rate", "10.0", "Stamina drain rate", _, true)).AddChangeHook(CVarChange_Rate);
	fRate = cvar.FloatValue;

	AutoExecConfig(true, "sm_run_object");
}

//フックした Console variable の内容が変更された
public void CVarChange_Enable(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bEnable = cvar.BoolValue;
}

public void CVarChange_Show(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bShow = cvar.BoolValue;
}

public void CVarChange_Rate(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fRate = cvar.FloatValue;
}

public void OnGameFrame()
{
	if(!bEnable) return;

	static int ent, client;
	static float stamina, time;
	ent = -1;
	time = GetGameTime();
	while((ent = FindEntityByClassname(ent, "player_pickup")) != -1)
	{
		if(IsValidClient((client = GetEntPropEnt(ent, Prop_Send, "m_pPlayer"))))
		{
			if(GetEntProp(client, Prop_Send, "m_bSprintEnabled"))
			{
				if(GetEntProp(client, Prop_Send, "m_bIsSprinting") && (time - fTime[client]) >= 1.0)
				{
					stamina = GetEntPropFloat(client, Prop_Send, "m_flStamina") - fRate;
					if(stamina < 0.0) stamina = 0.0;
					SetEntPropFloat(client, Prop_Send, "m_flStamina", stamina);
					fTime[client] = time;
				}
			}
			else
			{
				SetEntProp(client, Prop_Send, "m_bSprintEnabled", 1);
				fTime[client] = time;
			}
		}
	}
	// If ShowStamina is true, show stamina on display
	if(bShow) for(int i = 1; i <= MaxClients; i++) PrintKeyHintText(i);
}

//Display KeyHintText to specified client
stock void PrintKeyHintText(int client)
{
	if(!IsValidClient(client))
		return;

	static Handle msg;
	if((msg = StartMessageOne("KeyHintText", client)) == null)
		return;

	static char text[32];
	BfWriteByte(msg, 1);
	FormatEx(text, sizeof(text), "Stamina -> %.1f", GetEntPropFloat(client, Prop_Send, "m_flStamina"));
	BfWriteString(msg, text);
	EndMessage();
}

//Check client index
stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client);
}