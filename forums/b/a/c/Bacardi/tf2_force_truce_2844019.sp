
public Plugin myinfo =
{
	name = "TF2 Force Truce",
	author = "Bacardi",
	description = "Players can not harm each other",
	version = "26.04.2026",
	url = "http://www.sourcemod.net/"
};

#define HUD_NOTIFY_TRUCE_ACTIVE 26
#define HUD_NOTIFY_TRUCE_DEACTIVE 27
#include <sdktools>

public void OnPluginStart()
{
	RegServerCmd("tf_truce", tf_truce, "Players can not harm each other. 1=on, 0=off, no argument=toggle", FCVAR_NONE);
}

public Action tf_truce(int args)
{
	bool IsTruceActive = view_as<bool>(GameRules_GetProp("m_bTruceActive"));
	bool bCmdTruce = !IsTruceActive; // toggle

	if(args > 0) // cmd with argument
	{
		char buffer[4];
		GetCmdArg(1, buffer, sizeof(buffer));
		bCmdTruce = view_as<bool>(StringToInt(buffer));
		
		if(IsTruceActive == bCmdTruce) // already active/deactive
			return Plugin_Handled;
	}

	GameRules_SetProp("m_bTruceActive", bCmdTruce);

	LogMessage(" Command tf_truce %s", bCmdTruce ? "activated":"deactivated");
	PrintToChatAll(bCmdTruce ? "\x078F00FF[SM] Truce! No enemy damage allowed during the truce!":"\x078F00FF[SM] The truce has ended! Game on!");

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			BfWrite write = UserMessageToBfWrite(StartMessageOne("HudNotify", i));
			write.WriteByte(bCmdTruce ? HUD_NOTIFY_TRUCE_ACTIVE:HUD_NOTIFY_TRUCE_DEACTIVE);
			write.WriteBool(1);
			EndMessage();
		}
	}

	return Plugin_Handled;
}


