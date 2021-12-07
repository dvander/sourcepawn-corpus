/*
*	Improved connect/disconnect messages
* 
*	Description: 
*		Replaces the default connect n disconnect messages with few new cool ones.
*		Adds to connect message steamid and country,city name.
*		Colors player disconnect reason depending on it's reason.
*
*	Changelog
*	   - 1.0
*		release
*	   - 1.1
*		GeoIPCity and translations support
*	   - 1.2
*		Tags support 
*		Code cleanup
*	
*
*/

#include <sourcemod>
#include <geoipcity>
#include <morecolors>

#define VERSION "1.2"

public Plugin:myinfo = 
{
	name = "Improved Connect/Disconnect messages",
	author = "Aphex",
	description = "Replace the default connect n disconnect messages with few new cool ones.",
	version = VERSION,
	url = "aph3xd@gmail.com"
}

public OnPluginStart()
{
	CreateConVar("sm_cd_messagesver", VERSION, "Improved connect/disconnect messages", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_disconnect", event_disconnect, EventHookMode_Pre);
	HookEvent("player_connect", event_connect, EventHookMode_Pre);
	LoadTranslations("cd_messages.phrases");
}

public Action:event_connect(Handle:hEvent, const String:szEventName[], bool:bDontBroadcast) { 
	SetEventBroadcast(hEvent, true); 
	return Plugin_Continue; 
}  

public OnClientAuthorized(iClient){
	decl String:szAuthID[22];
	decl String:szText[256];
	decl String:szIPAddress[18], String:szCountry[45], String:szCity[45], String:szRegion[45], String:szCC[3], String:szCC3[4], String:szName[32];

	GetClientIP(iClient, szIPAddress, sizeof(szIPAddress)-1, true);

	GetClientAuthString(iClient, szAuthID, sizeof(szAuthID)-1);
	ReplaceString(szAuthID, sizeof(szAuthID)-1, "STEAM_", "");
	
	GetClientName(iClient, szName, sizeof(szName)-1);
	CRemoveTags(szName, sizeof(szName));
	

	new CGIP = GeoipGetRecord(szIPAddress, szCity, szRegion, szCountry, szCC, szCC3);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			new flags = GetUserFlagBits(i);
			if(IsFakeClient(iClient) || !CGIP){
				if (flags & ADMFLAG_GENERIC || flags & ADMFLAG_ROOT)
					Format(szText, 256, "%T", "Connect_adm_less", i);
				else
					Format(szText, 256, "%T", "Connect_less", i);

				ReplaceString(szText, 256, "{name}", szName, false);
				ReplaceString(szText, 256, "{steam_id}", szAuthID, false);
				ReplaceString(szText, 256, "{ip}", szIPAddress, false);
			}
			else
			{
				if (flags & ADMFLAG_GENERIC || flags & ADMFLAG_ROOT)
					Format(szText, 256, "%T", "Connect_adm", i);
				else
					Format(szText, 256, "%T", "Connect", i);

				ReplaceString(szText, 256, "{name}", szName, false);
				ReplaceString(szText, 256, "{steam_id}", szAuthID, false);
				ReplaceString(szText, 256, "{ip}", szIPAddress, false);
				ReplaceString(szText, 256, "{city}", szCity, false);
				ReplaceString(szText, 256, "{country}", szCountry, false);
				ReplaceString(szText, 256, "{cc}", szCC, false);
			}
			CPrintToChat(i, szText);
	        }
	}

        if(IsFakeClient(iClient) || !CGIP){
		Format(szText, sizeof(szText), "%T", "Connect_srv_less", LANG_SERVER);
		ReplaceString(szText, sizeof(szText), "{name}", szName, false);
		ReplaceString(szText, sizeof(szText), "{steam_id}", szAuthID, false);
		ReplaceString(szText, sizeof(szText), "{ip}", szIPAddress, false);
        }else{
		Format(szText, sizeof(szText), "%T", "Connect_srv", LANG_SERVER);
		ReplaceString(szText, sizeof(szText), "{name}", szName, false);
		ReplaceString(szText, sizeof(szText), "{steam_id}", szAuthID, false);
		ReplaceString(szText, sizeof(szText), "{ip}", szIPAddress, false);
		ReplaceString(szText, sizeof(szText), "{city}", szCity, false);
		ReplaceString(szText, sizeof(szText), "{country}", szCountry, false);
		ReplaceString(szText, sizeof(szText), "{cc}", szCC, false);
        }
	PrintToServer(szText,1);
	return true;
}

public Action:event_disconnect(Handle:hEvent, const String:szEventName[], bool:bDontBroadcast)
{
	decl String:szReason[96], String:szName[32], String:szNetworkID[22], String:ReasonC[28];
	GetEventString(hEvent, "reason", szReason, sizeof(szReason)-1);
	GetEventString(hEvent, "name", szName, sizeof(szName)-1);
	GetEventString(hEvent, "networkid", szNetworkID, sizeof(szNetworkID)-1);
	
	decl String:AuthID[32];
	decl String:szText[256];
	decl String:szIPAddress[18], String:szCountry[45], String:szCity[45], String:szRegion[45], String:szCC[3], String:szCC3[4];
	
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	GetClientAuthString(client, AuthID, sizeof(AuthID));
	ReplaceString(AuthID, sizeof(AuthID)-1, "STEAM_", "");
		
		
	GetClientIP(client, szIPAddress, sizeof(szIPAddress)-1, true);
		
	
	if(StrContains(szReason, "Disconnect by user", false) != -1){
		ReasonC = "{default}";
	}
	else if(StrContains(szReason, "kick", false) != -1){
		ReasonC = "{red}";
	}
	else if(StrContains(szReason, "ban", false) != -1){
		ReasonC = "{red}";
	}
	else if(StrContains(szReason, "ping", false) != -1){
		ReasonC = "{darkorange}";
	}
	else if(StrContains(szReason, "timed out", false) != -1){
		ReasonC = "{darkorange}";
	}
	else {
		ReasonC = "{darkorange}";
	}
	
	CRemoveTags(szName, sizeof(szName));
	StrCat(ReasonC, 128, szReason);
	
	new CGIP = GeoipGetRecord(szIPAddress, szCity, szRegion, szCountry, szCC, szCC3);
		
	for (new i = 1; i <= MaxClients; i++)
	{
                if (IsClientInGame(i))
		{
			new flags = GetUserFlagBits(i);
			if(IsFakeClient(client) || !CGIP){
				if (flags & ADMFLAG_GENERIC || flags & ADMFLAG_ROOT)
					Format(szText, 256, "%T", "Disconnect_adm_less", i);
				else
					Format(szText, 256, "%T", "Disconnect_less", i);
				ReplaceString(szText, 256, "{name}", szName, false);
				ReplaceString(szText, 256, "{steam_id}", AuthID, false);
				ReplaceString(szText, 256, "{ip}", szIPAddress, false);
				ReplaceString(szText, 256, "{reason}", ReasonC, false);
			}
			else
			{
				if (flags & ADMFLAG_GENERIC || flags & ADMFLAG_ROOT)
					Format(szText, 256, "%T", "Disconnect_adm", i);
				else
					Format(szText, 256, "%T", "Disconnect", i);
				ReplaceString(szText, 256, "{name}", szName, false);
				ReplaceString(szText, 256, "{steam_id}", AuthID, false);
				ReplaceString(szText, 256, "{ip}", szIPAddress, false);
				ReplaceString(szText, 256, "{city}", szCity, false);
				ReplaceString(szText, 256, "{country}", szCountry, false);
				ReplaceString(szText, 256, "{cc}", szCC, false);
				ReplaceString(szText, 256, "{reason}", ReasonC, false);	
			}
			CPrintToChat(i, szText);
                }
        }

        if(IsFakeClient(client) || !CGIP){
		Format(szText, sizeof(szText), "%T", "Disconnect_srv_less", LANG_SERVER);
		ReplaceString(szText, sizeof(szText), "{name}", szName, false);
		ReplaceString(szText, sizeof(szText), "{steam_id}", AuthID, false);
		ReplaceString(szText, sizeof(szText), "{ip}", szIPAddress, false);
		ReplaceString(szText, sizeof(szText), "{reason}", szReason, false);
        }else{
		Format(szText, sizeof(szText), "%T", "Disconnect_srv", LANG_SERVER);
		ReplaceString(szText, sizeof(szText), "{name}", szName, false);
		ReplaceString(szText, sizeof(szText), "{steam_id}", AuthID, false);
		ReplaceString(szText, sizeof(szText), "{ip}", szIPAddress, false);
		ReplaceString(szText, sizeof(szText), "{city}", szCity, false);
		ReplaceString(szText, sizeof(szText), "{country}", szCountry, false);
		ReplaceString(szText, sizeof(szText), "{cc}", szCC, false);
		ReplaceString(szText, sizeof(szText), "{reason}", szReason, false);
        }
        PrintToServer(szText,1);

	return Plugin_Handled;
}
