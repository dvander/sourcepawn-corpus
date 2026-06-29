#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_NOTIFY
#define PLUGIN_VERSION "1.0.0.1"

public Plugin myinfo =
{    
    name = "[L4D2] Defib Healing Plus",
    author = "Joshua Coffey + Grammernatzi",
    description = "Allows players to heal alive players with defibs to a set max health (50 by default), as well as quick revive incapacitated players with them.",
    version = "1.0.0.1",
    url = "http://www.sourcemod.net/"   
}

PluginData plugin;

enum struct PluginCvars
{
    ConVar PluginOn;
    ConVar chat;
    ConVar hint;
    ConVar health;
    ConVar maxHealth;
    ConVar incap;
    ConVar eraseTempHealthCvar;

    void Init()
    {
        CreateConVar("defib_healing_plus_version", PLUGIN_VERSION, "[L4D2] Defib Healing Plus plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
        this.PluginOn = CreateConVar("sm_defib_on", "1", "Enable/Disable the plugin");
        this.chat = CreateConVar("sm_defib_chat", "1", "Tell players when a user heals another user with a defib.");
        this.hint = CreateConVar("sm_defib_hint", "1", "Tell players that they can heal others with defibrillators when picking them up for the first time.");
        this.health = CreateConVar("sm_defib_health", "50", "The amount of health to give to player when using defibs on them.");
        this.maxHealth = CreateConVar("sm_defib_health_max", "50", "The max amount of health a player can be healed up to with a defib.");
        this.incap = CreateConVar("sm_defib_incap", "1", "Value for whether you can revive incapacitated players with a defibrillator. (1 = on, 0 = off)");
        this.eraseTempHealthCvar = CreateConVar("sm_defib_erase_temp_health", "1", "Whether to delete temp health after getting defib healed. (1 = on, 0 = off)");
        
        AutoExecConfig(true, "defibs");

        this.PluginOn.AddChangeHook(OnConVarPluginOnChange);
        this.chat.AddChangeHook(OnConVarChange);
        this.hint.AddChangeHook(OnConVarChange);
        this.health.AddChangeHook(OnConVarChange);
        this.maxHealth.AddChangeHook(OnConVarChange);
        this.incap.AddChangeHook(OnConVarChange);
        this.eraseTempHealthCvar.AddChangeHook(OnConVarChange);
    }
}

enum struct PluginData
{
	PluginCvars cvars;

	bool bHooked;
	bool bPluginOn;
	bool eraseTempHealth;
	bool chatdo;
	bool incapDo;
	bool subjectIncapacitated;
	int hintsDisplayed[MAXPLAYERS + 1];
	int healthdone;
	int subjectMaxHealth;
	int healthremainder;
	int healthtoadd;
	int subject;
	int user;
	int subjecthealth;
	int defibrillator;
	int hintDo;
	int client;
	char sTemp[20];
    char g_sSystem[16];
	GameData hGameData;
    Handle g_hSDK_CTerrorPlayer_OnRevived;

	void Init()
	{
		this.cvars.Init();
		this.hGameData = new GameData("defibs");
		StartPrepSDKCall(SDKCall_Player);
		if(PrepSDKCall_SetFromConf(this.hGameData, SDKConf_Signature, "CTerrorPlayer::OnRevived") == false)
		{
			LogError("Failed to find signature: \"CTerrorPlayer::OnRevived\" (%s)", this.g_sSystem);
		}
		else
		{
			this.g_hSDK_CTerrorPlayer_OnRevived = EndPrepSDKCall();
			if(this.g_hSDK_CTerrorPlayer_OnRevived == null)
				LogError("Failed to create SDKCall: \"CTerrorPlayer::OnRevived\" (%s)", this.g_sSystem);
		}
		delete this.hGameData;
	}

	void GetCvarValues()
	{
		this.eraseTempHealth = this.cvars.eraseTempHealthCvar.BoolValue;
		this.subjectMaxHealth = this.cvars.maxHealth.IntValue;
		this.chatdo = this.cvars.chat.BoolValue;
		this.incapDo = this.cvars.incap.BoolValue;
		this.healthremainder = this.subjectMaxHealth - this.cvars.health.IntValue;
		this.healthtoadd = this.cvars.health.IntValue;
		this.hintDo = this.cvars.hint.IntValue;
	}

	void IsAllowed()
	{
		this.bPluginOn = this.cvars.PluginOn.BoolValue;
		if(!this.bHooked && this.bPluginOn)
		{
			this.bHooked = true;
			HookEvent("defibrillator_used_fail", Events);
			HookEvent("item_pickup", Events);
		}
		else if(this.bHooked && !this.bPluginOn)
		{
			this.bHooked = false;
			UnhookEvent("defibrillator_used_fail", Events);
			UnhookEvent("item_pickup", Events);
		}
	}
}

public void OnPluginStart()
{	
	plugin.Init();
}

public void OnConfigsExecuted()
{
	plugin.IsAllowed();
	plugin.GetCvarValues();
}

void OnConVarPluginOnChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	plugin.IsAllowed();
}

void OnConVarChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	plugin.GetCvarValues();
}

public void OnClientPutInServer(int client)
{
	if(client > 0 && !IsFakeClient(client))
	{
		plugin.hintsDisplayed[client] = 0;
	}
}

Action Events(Event event, char[] name, bool dontBroadcast)
{
	if (strcmp(name, "defibrillator_used_fail") == 0)
	{
		plugin.healthdone = 0;
		plugin.subject = GetClientOfUserId(event.GetInt("subject"));
		plugin.user = GetClientOfUserId(event.GetInt("userid"));
		plugin.subjecthealth = GetClientHealth(plugin.subject);
		plugin.subjectIncapacitated = view_as<bool>(GetEntProp(plugin.subject, Prop_Send, "m_isIncapacitated", 1));
		plugin.defibrillator = GetPlayerWeaponSlot(plugin.user, 3);

		if(plugin.subjecthealth < plugin.subjectMaxHealth || (plugin.incapDo && plugin.subjectIncapacitated))
		{
			if (plugin.incapDo && plugin.subjectIncapacitated)
			{
				 SDKCall(plugin.g_hSDK_CTerrorPlayer_OnRevived, plugin.subject);
				 SetEntityHealth(plugin.subject, plugin.healthtoadd);
			}
			else if(plugin.subjecthealth > plugin.healthremainder)
			{    
				for(int i = plugin.subjecthealth; i < plugin.subjectMaxHealth; i++)
				{
					plugin.healthdone++;   
				}
				SetEntityHealth(plugin.subject, plugin.subjectMaxHealth);
			}
			else
			{
				SetEntityHealth(plugin.subject, plugin.subjecthealth + plugin.healthtoadd);
			}

			if (plugin.eraseTempHealth) SetEntPropFloat(plugin.subject, Prop_Send, "m_healthBuffer", 0.0);

			if(plugin.chatdo)
			{
				if (plugin.subjectIncapacitated && plugin.incapDo)
				{
					PrintToChatAll("%N revived %N from incapacitation with a defib.", plugin.user, plugin.subject);
				}
				else
				{
					PrintToChatAll("%N brought up %N to %i health via defib.", plugin.user, plugin.subject, GetClientHealth(plugin.subject));
				}   
			}
			RemovePlayerItem(plugin.user, plugin.defibrillator);
			RemoveEntity(plugin.defibrillator); 
		}
	}
	else if(strcmp(name, "item_pickup") == 0)
	{
		plugin.client = GetClientOfUserId(event.GetInt("userid"));
		event.GetString("item", plugin.sTemp, sizeof(plugin.sTemp));
		if(strcmp(plugin.sTemp, "defibrillator") == 0 && plugin.hintDo && plugin.hintsDisplayed[plugin.client] == 0)
		{
			if (plugin.incapDo) PrintHintText(plugin.client, "Defibs can heal live teammates up to %i health, even while they're downed.", plugin.subjectMaxHealth);
			else PrintHintText(plugin.client, "Defibs can heal live teammates up to %i health.", plugin.subjectMaxHealth);
			plugin.hintsDisplayed[plugin.client]++;
		}
	}
	return Plugin_Continue;
}
