#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION 		"1.0.0"

public Plugin myinfo = 
{
	name = "Display Ending Wave",
	author = "misosiruGT",
	description = "Display the ending WAVE of the survival map.",
	version = PLUGIN_VERSION,
	url = "misosirugt@gmail.com"
}

static ConVar m_hCvar_Enable = null;							//Display the ending WAVE Enable/Disable(Default:1)
static ConVar m_hCvar_CommandName = null;			//Configuration of Command name(Default:endwave)
static char m_sCommandName[64] = "";						//Command name

public OnPluginStart()
{
	LoadTranslations("sm_endingwave.phrases");
	
	CreateConVar("sm_endingwave_version", PLUGIN_VERSION, "Display Ending Wave Version", 
							FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	m_hCvar_Enable = CreateConVar("sm_endingwave_enable", "1", "Display the ending WAVE 1 - Enable , 0 - Disable");
	m_hCvar_CommandName = CreateConVar("sm_endingwave_command_name", "endwave", "Command name for trigger");
	AutoExecConfig(true, "sm_endingwave");
	
	m_hCvar_CommandName.GetString(m_sCommandName, sizeof(m_sCommandName));
	RegConsoleCmd(m_sCommandName, Command_EndingWave);
}

public Action Command_EndingWave(int client, int args)
{
	ShowEndingWave(client, false);
	
	return Plugin_Handled;
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if (strcmp(sArgs, m_sCommandName, false) == 0) {
		ShowEndingWave(client, true);
	}
}

void ShowEndingWave(int client, bool isClientSayCommand)
{
	if (!m_hCvar_Enable.BoolValue) return;
	
	char currentMapName[PLATFORM_MAX_PATH];
	
	GetCurrentMap(currentMapName, sizeof(currentMapName));
	currentMapName[4] = '\0';
	
	if (StrEqual(currentMapName, "nms_", false)) {
		int waveController = FindEntityByClassname(-1, "overlord_wave_controller");
		
		if (waveController != -1) {
			int endingWave = GetEntProp(waveController, Prop_Data, "m_iEndWave");
			if (isClientSayCommand) {
				PrintToChat(client, "[SM] %t", "SurvivalMap", endingWave);
			} else {
				ReplyToCommand(client, "[SM] %t", "SurvivalMap", endingWave);
			}
		}
	} else {
		if (isClientSayCommand) {
			PrintToChat(client, "[SM] %t", "Not SurvivalMap");
		} else {
			ReplyToCommand(client, "[SM] %t", "Not SurvivalMap");
		}
	}
}