#include <sourcemod>
#include <steamworks>
#include <multicolors>
#include <cstrike>
#include <sdktools>
char apiTimeUrl[256] , apiSecretUrl[256] , apiSecretToken[64] , g_gameId[64];
ConVar c_secretProfilLogin , c_playedTimeLogin , c_apiSecretToken , c_gameId, c_kickenable;
#pragma newdecls required

public void OnPluginStart()
{
	LoadTranslations("gizli_profil.phrases");
	c_apiSecretToken = CreateConVar("private_api_key" , "" );
	c_playedTimeLogin = CreateConVar("private_time", "300" );
	c_secretProfilLogin = CreateConVar("private_login", "1");
	c_gameId = CreateConVar("private_gameid", "730" );
	c_kickenable = CreateConVar("private_kick", "1" );
	AutoExecConfig(true, "gizli_profil", "sourcemod");
	Format( apiTimeUrl , 256 , "http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key={key}&appids_filter[0]={game}&steamid={steamid}&format=json" );
	Format( apiSecretUrl , 256 , "http://api.steampowered.com/ISteamUser/GetFriendList/v0001/?key={key}&steamid={steamid}&relationship=friend&format=json" );
	RegAdminCmd("sm_hours", CommandHours, ADMFLAG_GENERIC);
	RegAdminCmd("sm_saat", CommandHours, ADMFLAG_GENERIC);
}

public void OnClientPutInServer(int client)
{
	checkPlayerSecretProfil( client );
}

public Action CommandHours(int client, int args)
{
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] sm_hours <name or #userid>");
		return Plugin_Continue;
	}
	char target_name[MAX_TARGET_LENGTH];
	char nameadm[MAX_NAME_LENGTH];
	GetClientName(client, nameadm, sizeof(nameadm));
	int target_list[MAXPLAYERS], target_count; bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_TARGET_NONE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Continue;
	}
	
  	for (int i = 0; i < target_count; i++)
	{
		checkPlayerSecretProfil2(target_list[i]);
	}
	
	return Plugin_Handled;
}

stock void getTimeApiFormat(char[] steamid , char[] str , int len)
{
	c_apiSecretToken.GetString( apiSecretToken , 64 );
	c_gameId.GetString( g_gameId , 64 );
	Format( str , len , apiTimeUrl);
 	ReplaceString(str, len, "{key}", apiSecretToken);
 	ReplaceString(str, len, "{game}", g_gameId);
 	ReplaceString(str, len, "{steamid}", steamid);
}

stock void getSecretApiFormat(char[] steamid , char[] str , int len)
{
	c_apiSecretToken.GetString( apiSecretToken , 64 );
	Format( str , len , apiSecretUrl);
 	ReplaceString(str, len, "{key}", apiSecretToken);
 	ReplaceString(str, len, "{steamid}", steamid);
}

void checkPlayerSecretProfil( int clientID )
{
	char steamid[18];
	GetClientAuthId(clientID, AuthId_SteamID64, steamid, sizeof(steamid));
	if( c_playedTimeLogin.IntValue != 0 )
	{
		playedTimeControl( steamid , clientID );
	}
	if( c_secretProfilLogin.IntValue != 0 )
	{
		secretProfilControl( steamid , clientID );
	}
}

void checkPlayerSecretProfil2( int clientID )
{
	char steamid[18];
	GetClientAuthId(clientID, AuthId_SteamID64, steamid, sizeof(steamid));
	if( c_playedTimeLogin.IntValue != 0 )
	{
		playedTimeControl2( steamid , clientID );
	}
	if( c_secretProfilLogin.IntValue != 0 )
	{
		secretProfilControl2( steamid , clientID );
	}
} 

stock char substr(char[] inpstr, int startpos, int len=-1)
{
    char outstr[20];
    strcopy(outstr, 20 , inpstr[startpos]);
    outstr[len] = 0;
    return outstr; 
}

void secretProfilControl( char[] steamid , int clientID )
{
	char apiFormatUrl[256];
	getSecretApiFormat(steamid , apiFormatUrl , 256);
	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, apiFormatUrl);
	SteamWorks_SetHTTPRequestContextValue(request, clientID);
	SteamWorks_SetHTTPCallbacks(request, secretProfil_OnHTTPResponse);
	SteamWorks_SendHTTPRequest(request);
}

void playedTimeControl(char[] steamid , int clientID )
{
	char apiFormatUrl[256];
	getTimeApiFormat(steamid , apiFormatUrl , 256);
	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, apiFormatUrl);
	SteamWorks_SetHTTPRequestContextValue(request, clientID);
	SteamWorks_SetHTTPCallbacks(request, TimePlayed_OnHTTPResponse);
	SteamWorks_SendHTTPRequest(request);
}

void secretProfilControl2( char[] steamid , int clientID )
{
	char apiFormatUrl[256];
	getSecretApiFormat(steamid , apiFormatUrl , 256);
	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, apiFormatUrl);
	SteamWorks_SetHTTPRequestContextValue(request, clientID);
	SteamWorks_SetHTTPCallbacks(request, secretProfil_OnHTTPResponse2);
	SteamWorks_SendHTTPRequest(request);
}

void playedTimeControl2(char[] steamid , int clientID )
{
	char apiFormatUrl[256];
	getTimeApiFormat(steamid , apiFormatUrl , 256);
	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, apiFormatUrl);
	SteamWorks_SetHTTPRequestContextValue(request, clientID);
	SteamWorks_SetHTTPCallbacks(request, TimePlayed_OnHTTPResponse2);
	SteamWorks_SendHTTPRequest(request);
}

public void TimePlayed_OnHTTPResponse(Handle request, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode,int client)
{
	if ( bFailure || !bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK )
	{
		CloseHandle(request);
		return;
	}
	int iBufferSize = 0;
	SteamWorks_GetHTTPResponseBodySize(request, iBufferSize);
	char[] result = new char[iBufferSize];
	SteamWorks_GetHTTPResponseBodyData(request, result, iBufferSize);
	int playedTime = playedGetTimeUser( result );
	playedTime = playedTime / 60
	if( playedTime <= 0 )
	{
		if( c_secretProfilLogin.IntValue != 0 )
		{
			if( GetUserAdmin(client) != INVALID_ADMIN_ID )
			{
				CloseHandle(request);
				return;
			}
			if( SteamWorks_HasLicenseForApp(client, 624820) == k_EUserHasLicenseResultDoesNotHaveLicense )
			{
				CPrintToChatAll("%t", "Prime Kick Chat", client);
				KickClient( client , "%t" , "Kick Mesaj Prime");
				CloseHandle(request);
				return;
			}
			CPrintToChatAll("%t", "Profil Gizli Mesaj Chat", client);
			if (c_kickenable.IntValue == 1)
			{
				KickClient( client , "%t" , "Kick Mesaj");
			}
		}
	}
	else if( playedTime > 0 )
	{
		if( c_playedTimeLogin.IntValue > 0 && playedTime < c_playedTimeLogin.IntValue)
		{
			if( GetUserAdmin(client) != INVALID_ADMIN_ID )
			{
				CloseHandle(request);
				return;
			}
			if( SteamWorks_HasLicenseForApp(client, 624820) == k_EUserHasLicenseResultDoesNotHaveLicense )
			{
				CPrintToChatAll("%t", "Prime Kick Chat", client);
				KickClient( client , "%t" , "Kick Mesaj Prime");
				CloseHandle(request);
				return;
			}
			CPrintToChatAll("%t", "Oyun Saati Düsük Mesaj Chat", client, playedTime, c_playedTimeLogin.IntValue);
			if (c_kickenable.IntValue == 1)
			{
				KickClient( client , "%t" , "Kick Saat Mesaj" , c_playedTimeLogin.IntValue);
			}
		}
		else if(c_playedTimeLogin.IntValue > 0 && playedTime >= c_playedTimeLogin.IntValue)
		{
			if( GetUserAdmin(client) != INVALID_ADMIN_ID )
			{
				CloseHandle(request);
				return;
			}
			if( SteamWorks_HasLicenseForApp(client, 624820) == k_EUserHasLicenseResultDoesNotHaveLicense )
			{
				CPrintToChatAll("%t", "Prime Kick Chat", client);
				KickClient( client , "%t" , "Kick Mesaj Prime");
				CloseHandle(request);
				return;
			}
			CPrintToChatAll("%t", "Oyun Saati Bilgi Mesaj Chat", client, playedTime, c_playedTimeLogin.IntValue);
		}
	}
	else if( !playedTime )
	{
		if(GetUserAdmin(client) != INVALID_ADMIN_ID)
		{
			CloseHandle(request);
			return;
		}
		if( SteamWorks_HasLicenseForApp(client, 624820) == k_EUserHasLicenseResultDoesNotHaveLicense )
		{
			CPrintToChatAll("%t", "Prime Kick Chat", client);
			KickClient( client , "%t" , "Kick Mesaj Prime");
			CloseHandle(request);
			return;
		}
		if (c_kickenable.IntValue == 1)
		{
			KickClient( client , "%t" , "Kick Mesaj Veri");
		}
	}
	CloseHandle(request);
	return;
}

public void TimePlayed_OnHTTPResponse2(Handle request, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode,int client)
{
	if ( bFailure || !bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK )
	{
		CloseHandle(request);
		return;
	}
	int iBufferSize = 0;
	SteamWorks_GetHTTPResponseBodySize(request, iBufferSize);
	char[] result = new char[iBufferSize];
	SteamWorks_GetHTTPResponseBodyData(request, result, iBufferSize);
	int playedTime = playedGetTimeUser( result );
	playedTime = playedTime / 60
	if( playedTime <= 0 )
	{
		if( c_secretProfilLogin.IntValue != 0 )
		{
			if(GetUserAdmin(client) != INVALID_ADMIN_ID)
			{
				CloseHandle(request);
				return;
			}
			if( SteamWorks_HasLicenseForApp(client, 624820) == k_EUserHasLicenseResultDoesNotHaveLicense )
			{
				CPrintToChatAll("%t", "Prime Kick Chat", client);
				KickClient( client , "%t" , "Kick Mesaj Prime");
				CloseHandle(request);
				return;
			}
			PrintToConsoleAll("%t", "Profil Gizli Mesaj Konsol", client);
			if (c_kickenable.IntValue == 1)
			{
				KickClient( client , "%t" , "Kick Mesaj");
			}
		}
	}
	else if( playedTime > 0 )
	{
		if( c_playedTimeLogin.IntValue > 0 && playedTime < c_playedTimeLogin.IntValue)
		{
			if(GetUserAdmin(client) != INVALID_ADMIN_ID)
			{
				CloseHandle(request);
				return;
			}
			if( SteamWorks_HasLicenseForApp(client, 624820) == k_EUserHasLicenseResultDoesNotHaveLicense )
			{
				CPrintToChatAll("%t", "Prime Kick Chat", client);
				KickClient( client , "%t" , "Kick Mesaj Prime");
				CloseHandle(request);
				return;
			}
			PrintToConsoleAll("%t", "Oyun Saati Düsük Mesaj Konsol", client, playedTime, c_playedTimeLogin.IntValue);
			if (c_kickenable.IntValue == 1)
			{
				KickClient( client , "%t" , "Kick Saat Mesaj" , c_playedTimeLogin.IntValue);
			}
		}
		else if(c_playedTimeLogin.IntValue > 0 && playedTime >= c_playedTimeLogin.IntValue)
		{
			if( SteamWorks_HasLicenseForApp(client, 624820) == k_EUserHasLicenseResultDoesNotHaveLicense )
			{
				CPrintToChatAll("%t", "Prime Kick Chat", client);
				KickClient( client , "%t" , "Kick Mesaj Prime");
				CloseHandle(request);
				return;
			}
			PrintToConsoleAll("%t", "Oyun Saati Bilgi Mesaj Konsol", client, playedTime, c_playedTimeLogin.IntValue);
		}
	}
	else if( !playedTime )
	{
		if(GetUserAdmin(client) != INVALID_ADMIN_ID)
		{
			CloseHandle(request);
			return;
		}
		if( SteamWorks_HasLicenseForApp(client, 624820) == k_EUserHasLicenseResultDoesNotHaveLicense )
		{
			CPrintToChatAll("%t", "Prime Kick Chat", client);
			KickClient( client , "%t" , "Kick Mesaj Prime");
			CloseHandle(request);
			return;
		}
		if (c_kickenable.IntValue == 1)
		{
			KickClient( client , "%t" , "Kick Mesaj Veri");
		}
	}
	CloseHandle(request);
	return;
}

public void secretProfil_OnHTTPResponse(Handle request, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode,int client)
{
	if( eStatusCode == k_EHTTPStatusCode401Unauthorized )
	{
		if( c_secretProfilLogin.IntValue != 0)
		{
			if(GetUserAdmin(client) != INVALID_ADMIN_ID)
			{
				CloseHandle(request);
				return;
			}
			if( SteamWorks_HasLicenseForApp(client, 624820) == k_EUserHasLicenseResultDoesNotHaveLicense )
			{
				CPrintToChatAll("%t", "Prime Kick Chat", client);
				KickClient( client , "%t" , "Kick Mesaj Prime");
				CloseHandle(request);
				return;
			}
			if (c_kickenable.IntValue == 1)
			{
				KickClient( client , "%t" , "Kick Mesaj");
			}
			CloseHandle(request);
			return;
		}
	}
	else if ( bFailure || !bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK )
	{
		CloseHandle(request);
		return;
	}
	int iBufferSize = 0;
	SteamWorks_GetHTTPResponseBodySize(request, iBufferSize);
	char[] result = new char[iBufferSize];
	SteamWorks_GetHTTPResponseBodyData(request, result, iBufferSize);
	int secretProfile = secretProfileUser( result );
	if( c_secretProfilLogin.IntValue != 0 && secretProfile )
	{
		if(GetUserAdmin(client) != INVALID_ADMIN_ID)
		{
			CloseHandle(request);
			return;
		}
		if( SteamWorks_HasLicenseForApp(client, 624820) == k_EUserHasLicenseResultDoesNotHaveLicense )
		{
			CPrintToChatAll("%t", "Prime Kick Chat", client);
			KickClient( client , "%t" , "Kick Mesaj Prime");
			CloseHandle(request);
			return;
		}
		if (c_kickenable.IntValue == 1)
		{
			KickClient( client , "%t" , "Kick Mesaj");
		}
		CloseHandle(request);
		return;
	}
}

public void secretProfil_OnHTTPResponse2(Handle request, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode,int client)
{
	if( eStatusCode == k_EHTTPStatusCode401Unauthorized )
	{
		if( c_secretProfilLogin.IntValue != 0)
		{
			if(GetUserAdmin(client) != INVALID_ADMIN_ID)
			{
				CloseHandle(request);
				return;
			}
			if( SteamWorks_HasLicenseForApp(client, 624820) == k_EUserHasLicenseResultDoesNotHaveLicense )
			{
				CPrintToChatAll("%t", "Prime Kick Chat", client);
				KickClient( client , "%t" , "Kick Mesaj Prime");
				CloseHandle(request);
				return;
			}
			if (c_kickenable.IntValue == 1)
			{
				KickClient( client , "%t" , "Kick Mesaj");
			}
			CloseHandle(request);
			return;
		}
	}
	else if ( bFailure || !bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK )
	{
		CloseHandle(request);
		return;
	}
	int iBufferSize = 0;
	SteamWorks_GetHTTPResponseBodySize(request, iBufferSize);
	char[] result = new char[iBufferSize];
	SteamWorks_GetHTTPResponseBodyData(request, result, iBufferSize);
	int secretProfile = secretProfileUser( result );
	if( c_secretProfilLogin.IntValue != 0 && secretProfile )
	{
		if(GetUserAdmin(client) != INVALID_ADMIN_ID)
		{
			CloseHandle(request);
			return;
		}
		if( SteamWorks_HasLicenseForApp(client, 624820) == k_EUserHasLicenseResultDoesNotHaveLicense )
		{
			CPrintToChatAll("%t", "Prime Kick Chat", client);
			KickClient( client , "%t" , "Kick Mesaj Prime");
			CloseHandle(request);
			return;
		}
		if (c_kickenable.IntValue == 1)
		{
			KickClient( client , "%t" , "Kick Mesaj");
		}
		CloseHandle(request);
		return;
	}
}

bool secretProfileUser( char[] result )
{
	char str2[2][64];
	ExplodeString(result, "\"friendslist\"", str2, sizeof(str2), sizeof(str2[]));
	if( !StrEqual(str2[1] , "") )
		return false;
	return true;
}

int playedGetTimeUser( char[] result )
{
	char str2[2][64];
	ExplodeString(result, "\"playtime_forever\":", str2, sizeof(str2), sizeof(str2[]));
	if( !StrEqual(str2[1] , "") )
	{
		char lastString[2][64];
		ExplodeString(str2[1], "}", lastString, sizeof(lastString), sizeof(lastString[]));
		return StringToInt( lastString[0] );
	}
	return -1;
}