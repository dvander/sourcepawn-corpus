/*ChangeLog-----------------------------------------------------------------------------------------------------------------------
Ver 1.0.0			- 09/08/2017 Initial version
------------------------------------------------------------------------------------------------------------------------------------*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION 		"1.0.0"
#define MAX_PLAYERS			MAXPLAYERS + 1	//SourceMod support max player(65)

public Plugin myinfo = 
{
	name = "Run Object",
	author = "misosiruGT",
	description = "The player can run when the player picks up the object.",
	version = PLUGIN_VERSION,
	url = "misosirugt@gmail.com"
}

static ConVar m_hCvar_Enable = null;								//plugin on/off(default:1)
static ConVar m_hCvar_ShowStamina = null;					//show stamina function (default:0)
static ConVar m_hCvar_StaminaDrainRate = null;			//Setting stamina consumption(default:10)

static float m_fStaminaDrainRate = 0.0;							//
static float m_fLastStaminaDrainTime[MAX_PLAYERS];	//

public OnPluginStart()
{
	CreateConVar("sm_run_object_version", PLUGIN_VERSION, "Run Object Version", 
							FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	m_hCvar_Enable = CreateConVar("sm_run_object_enable", "1", "Enable plugin. 1 - Enable, 2 - Disable");
	m_hCvar_ShowStamina = CreateConVar("sm_run_object_show_stamina", "0", "Show Stamina on display. 1 - Enable , 0 - Disable");
	m_hCvar_StaminaDrainRate = CreateConVar("sm_run_object_stamina_drain_rate", "10.0", "Stamina drain rate", _, true, 0.0);
	AutoExecConfig(true, "sm_run_object");
	
	m_fStaminaDrainRate = m_hCvar_StaminaDrainRate.FloatValue;
	HookConVarChange(m_hCvar_StaminaDrainRate, OnConVarChanged);
}

//フックした Console variable の内容が変更された
public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == m_hCvar_StaminaDrainRate) {
		m_fStaminaDrainRate = StringToFloat(newValue);
	}
}

public void OnGameFrame()
{
	if (!m_hCvar_Enable.BoolValue) return;

	int pickupController = -1;
	while ((pickupController = FindEntityByClassname(pickupController, "player_pickup")) != -1) {
		int client = GetEntPropEnt(pickupController, Prop_Send, "m_pPlayer");
		if (IsValidClient(client)) {
			if (view_as<bool>(GetEntProp(client, Prop_Send, "m_bSprintEnabled"))) {
				if (view_as<bool>(GetEntProp(client, Prop_Send, "m_bIsSprinting"))) {
					if ((GetGameTime() - m_fLastStaminaDrainTime[client]) >= 1.0) {
						float stamina = GetEntPropFloat(client, Prop_Send, "m_flStamina");
						float newStamina;
						if ((stamina - m_fStaminaDrainRate) >= 0.0) {
							newStamina = stamina - m_fStaminaDrainRate;
							
						} else {
							newStamina = 0.0;
						}
						SetEntPropFloat(client, Prop_Send, "m_flStamina", newStamina);
						m_fLastStaminaDrainTime[client] = GetGameTime();
					}
				}
			} else {
				SetEntProp(client, Prop_Send, "m_bSprintEnabled", 1);
				m_fLastStaminaDrainTime[client] = GetGameTime();
			}
		}
	}
	// If ShowStamina is true, show stamina on display
	if (m_hCvar_ShowStamina.BoolValue) {
		for (int client = 1; client <= MaxClients; client++) {
			if (IsValidClient(client)) {
				char text[32];
				FormatEx(text, sizeof(text), "Stamina -> %.1f", GetEntPropFloat(client, Prop_Send, "m_flStamina"));
				PrintKeyHintText(client, text);
			}
		}
	}
}

//Check client index
bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients) {
		if (IsClientInGame(client) && IsPlayerAlive(client)) {
			return true;
		}
	}
	return false;
}

//Display KeyHintText to specified client
stock void PrintKeyHintText(int client, char[] text)
{
	Handle userMsg = StartMessageOne("KeyHintText", client);
	
	if (userMsg != null) {
		BfWriteByte(userMsg, 1);
		BfWriteString(userMsg, text);
		EndMessage();
	}	
}