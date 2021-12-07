#include <sourcemod>

new Handle:db

public Plugin:myinfo =
{
	name = "SteamID Restrict MySQL",
	author = "Sebastian (sEbbo) Danielsson & Jaro Vanderheijden",
	description = "Kicks everyone who is not listed in the chosen MySQL-database.",
	version = "1.0",
	url = "http://www.sebastian-danielsson.com/"
}

new const String:AUTHMETHOD_RESTRICT[] = "default"

public OnPluginStart()
{
	CreateAuthMethod(AUTHMETHOD_RESTRICT)
	decl String:error[255]

	if (SQL_CheckConfig("admins"))
	{
		db = SQL_Connect("admins", true, error, sizeof(error))
	} else {
		db = SQL_Connect("default", true, error, sizeof(error))
	}

	if (db == INVALID_HANDLE)
	{
		LogError("Could not connect to database \"default\": %s", error)
		return
	}
}

public OnClientPutInServer(Client)
{
	new Handle:hQuery
	new bool:Found = false
	new String:Auth[36],String:ClientAuth[36]

	GetClientAuthString(Client,ClientAuth,sizeof(ClientAuth))

	hQuery = SQL_Query(db,"SELECT steamid FROM steamid_restrict")

	while ( SQL_FetchRow(hQuery) )
	{
		SQL_FetchString(hQuery,0,Auth,sizeof(Auth))
		if(StrEqual(Auth,ClientAuth,false))
			Found = true
	}

	if (!Found) KickClient(Client,"You don't have access to this server")

	CloseHandle(hQuery)
}