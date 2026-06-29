#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

static const char
	/*Plugin Info*/
	PL_NAME[]		 = "Sourcemod Detailed Plugins List",
	PL_AUTHOR[]		 = "Peter Brev",
	PL_DESCRIPTION[] = "Lists all Sourcemod plugins at once with more details",
	PL_VERSION[]	 = "1.0.1";

public Plugin myinfo =
{
	name		= PL_NAME,
	author		= PL_AUTHOR,
	description = PL_DESCRIPTION,
	version		= PL_VERSION
};

public void OnPluginStart()
{
	CreateConVar("sm_plugins_list_version", PL_VERSION, "Plugin Version");

	RegConsoleCmd("sm_plugins_list", pluginscmd, "List all available plugins at once");
}

public Action pluginscmd(int client, int args)
{
	if (!IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	if (!client)
	{
		PrintToServer("[SM] Use \"sm plugins list\" to display loaded plugins.");
		return Plugin_Handled;
	}

	char   s_pname[64], s_pauthor[64], s_pversion[16], s_pdesc[256], filename[128];
	Handle iter	  = GetPluginIterator();
	int	   iCount = 00;
	while (MorePlugins(iter))
	{
		iCount++;
		Handle p = ReadPlugin(iter);
		GetPluginInfo(p, PlInfo_Name, s_pname, sizeof(s_pname));
		GetPluginInfo(p, PlInfo_Author, s_pauthor, sizeof(s_pauthor));
		GetPluginInfo(p, PlInfo_Version, s_pversion, sizeof(s_pversion));
		GetPluginInfo(p, PlInfo_Description, s_pdesc, sizeof(s_pdesc));
		GetPluginFilename(p, filename, sizeof(filename));
			
		PrintToConsole(client, "  [%02d] %s \nAuthor(s): %s \nPlugin Description: %s \nPlugin Version: %s\nPlugin file name: %s\n\n", iCount, s_pname, s_pauthor, s_pdesc, s_pversion, filename);
	}
	return Plugin_Handled;
}