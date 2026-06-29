#include <sourcemod>
#include <sdktools>



#pragma newdecls			required
#pragma semicolon			1



#define PLUGIN_AUTHOR		"RaproSoft"
#define PLUGIN_VERSION		"1.0"

#define MAX_MESSAGE_CHARS	98



EngineVersion EngineVer;



public Plugin myinfo =
{
	name = "[ANY] Alert",
	author = PLUGIN_AUTHOR,
	description = "Sends alert to everyone.",
	version = PLUGIN_VERSION,
	url = "https://www.raprosoft.com/"
};



public void OnPluginStart()
{
	EngineVer = GetEngineVersion();

	RegAdminCmd("sm_alert", cmd_alert, ADMFLAG_CHAT, "Sends alert to everyone");
}



public void OnMapStart()
{
	if(EngineVer == Engine_TF2)
	{
		PrecacheSound("ui/system_message_alert.wav", true);
	}
}



public Action cmd_alert(int client, int args)
{
	char arg1[255];
	char buffer[255];

	if (args < 1)
	{
		ReplyToCommand(client, ">> Usage: sm_alert <message>");



		return Plugin_Handled;
	}

	GetCmdArg(1, arg1, sizeof(arg1));

	if (args > 0)
	{
		GetCmdArg(1, arg1, sizeof(arg1));
		for (int i = 2; i <= args; i++)
		{
			GetCmdArg(i, buffer, sizeof(buffer));
			Format(arg1, sizeof(arg1), "%s %s", arg1, buffer);
		}
	}

	if (strlen(arg1) > MAX_MESSAGE_CHARS)
	{
		ReplyToCommand(client, ">> Message cannot exceed %d chars!", MAX_MESSAGE_CHARS);



		return Plugin_Handled;
	}


	PrintHintTextToAll("[ALERT]\n>> %s <<", arg1);

	if(EngineVer == Engine_TF2)
	{
		EmitSoundToAll("ui/system_message_alert.wav");
	}

	ReplyToCommand(client, ">> Alert send.");

	LogAction(client, -1, ">> \"%L\" Sended an alert. (%s)", client, arg1);



	return Plugin_Handled;
}