#pragma semicolon 1

#include <sourcemod>

#undef REQUIRE_PLUGIN
#tryinclude <CA_api>

#define PLUGIN_VERSION "example"

new bool:g_bCA_api_loaded;

public Plugin:myinfo = 
{
	name = "Custom Achievements Example",
	author = "Flyflo",
	description = "Custom achievements Example",
	version = PLUGIN_VERSION,
	url = "http://www.geek-gaming.fr"
}

public OnPluginStart()
{
	RegConsoleCmd("say", SayHandler);
	RegConsoleCmd("say_team", SayHandler);
	g_bCA_api_loaded = LibraryExists("ca_api");
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "ca_api"))
	{
		g_bCA_api_loaded = false;
	}
}
 
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "ca_api"))
	{
		g_bCA_api_loaded = true;
	}
}

public Action:SayHandler(client, args)
{
	if(g_bCA_api_loaded)
	{
		if(client > 0)
		{
#if defined _c_achievements_included
			decl String:SayString[191];
			GetCmdArgString(SayString, sizeof(SayString));

			if(StrContains(SayString, "unlock", false) != -1)
			{
				CA_ProcessAchievementByName("TF_UNLOCK_TEST", client, 1, ACHIEVEMENT_DEBUG);
				// Add a 1 progress to the achievement called TF_UNLOCK_TEST and use the verbose mode.
			}
			if(StrContains(SayString, "progress", false) != -1)
			{ 
				new iProgress = CA_GetAchievementProgress(1, client);
				PrintToChatAll("%i", iProgress);
				// Get the progress of the client for the achievement 1
			}
			if(StrContains(SayString, "idtoname", false) != -1)
			{
				decl String:AchName[64];
				if(CA_IdToName(1, AchName) == 0) // If the achievement exists and have an unique name
				{
					PrintToChatAll("%s", AchName);
				}
				else // Else
				{
					PrintToChatAll("Unknown/Noname achievement");
				}
			}
			if(StrContains(SayString, "translated", false) != -1)
			{
				CA_ProcessAchievement(1, client, 1, ACHIEVEMENT_DEBUG|ACHIEVEMENT_HAS_TRANSLATION|ACHIEVEMENT_NOSOUND);
				// Add a 1 progress to the achievement 1, verbose mode, no sounds when achieved, and translated.
			}
#else
			PrintToChatAll("Custom Achievements API not included.");
#endif
		}
	}
	else
	{
		PrintToChatAll("Custom Achievements API not loaded.");
	}

	return Plugin_Continue;
}

#if defined _c_achievements_included
public AchievementProgressed(iAchievementId, String:strAchievementUniqueName[64], iClient, iProgress, iOldProgress, iMaxProgress, iSpecialFlags)
{
	PrintToChatAll("Forward: %N progressed the achievement %s, progress: %i, old value: %i, max value: %i, flags: %b", iClient, strAchievementUniqueName, iProgress, iOldProgress, iMaxProgress, iSpecialFlags);
}
#endif