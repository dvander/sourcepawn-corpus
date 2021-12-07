#include <sourcemod>

public Plugin:myinfo = {
	name = "InsultTheFreeloader",
	author = "sharkdeed",
	description = "Requested by cristi_ip. Insults the player who uses !ws or !knife commands.",
	url = ""
}

public Action OnClientSayCommand(client, const String:command[], const String:sArgs[])
{
	if(StrEqual(sArgs, "!ws") || StrEqual(sArgs, "!knife"))
	{
		PrintToChat(client, "For real skins we recommend STEAM MARKET");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}