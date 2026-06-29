#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <geoip>
new g_CountrySize;
new bool:g_bToggledValue;
new Handle:g_hVoiceList, Handle:g_hToggle;
new String:g_sListedString[169], String:g_sCountry[24][3];

public Plugin:myinfo =
{
	name = "Voice Chat Enforcement", // http://www.youtube.com/watch?v=DGB4VDQI6XM -> Think this is the song I listened to while making this.
	author = "Kyle Sanderson",
	description = "Enforces Voice Chat to be used only by localized countries, speficied by yourself.",
	version = "1.6c",
	url = "http://sourcemod.net"
};

public OnPluginStart()
{
	g_hVoiceList = CreateConVar("sm_voicelist", "", "Whitelisted/Blacklisted Countries allowed to talk on their Microphone", FCVAR_PLUGIN); // Example would be US, CA, SE, AF, GN, UA etc.
	g_hToggle = CreateConVar("sm_voicetoggle", "0", "0 for Whitelist, 1 for Blacklist.", FCVAR_PLUGIN);
	SetConVarBounds(g_hToggle, ConVarBound_Upper, true, 1.0);
	SetConVarBounds(g_hToggle, ConVarBound_Lower, true, 0.0);
	HookConVarChange(g_hVoiceList, ChangedList);
	HookConVarChange(g_hToggle, ChangedToggle);
}

public OnPluginEnd()
{
	UnhookConVarChange(g_hVoiceList, ChangedList);
	UnhookConVarChange(g_hToggle, ChangedToggle);
}

public OnConfigsExecuted()
{
	g_bToggledValue = GetConVarBool(g_hToggle);
	Prep();
}

public ChangedList(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Prep();
}

public ChangedToggle(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bToggledValue = GetConVarBool(g_hToggle);
}

public Prep()
{
	GetConVarString(g_hVoiceList, g_sListedString, sizeof(g_sListedString));
	ReplaceString(g_sListedString, sizeof(g_sListedString), " ", "", false);
	g_CountrySize = sizeof(g_sCountry);
	ExplodeString(g_sListedString, ",", g_sCountry, g_CountrySize, sizeof(g_sCountry[]));
}

public OnClientPostAdminCheck(client)
{
	if(!CheckCommandAccess(client, "sm_voicelevel", ADMFLAG_RESERVATION))
	{
		new bool:matched;
		decl String:IPAddress[16], String:CC[3];
		GetClientIP(client, IPAddress, sizeof(IPAddress));
		GeoipCode2(IPAddress, CC);

		for(new i = 0; i < g_CountrySize; i++)
		{
			if(StrEqual(CC, g_sCountry[i]))
			{
				matched = true;
			}
		}
	
		switch (g_bToggledValue) // http://www.youtube.com/watch?v=FnD_CXnXEB8
		{
			case 0: // Whitelist
			{
				if(!matched)
				{
					SetClientListeningFlags(client, VOICE_MUTED);
				}
			}
			
			case 1: // Blacklist
			{
				if(matched)
				{
					SetClientListeningFlags(client, VOICE_MUTED);
				}
			}
		}
	}
}