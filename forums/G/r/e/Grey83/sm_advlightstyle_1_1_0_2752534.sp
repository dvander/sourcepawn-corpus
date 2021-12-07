#pragma semicolon 1

#include <sdktools_engine>
#include <sdktools_stringtables>

#define PL_NAME	"SM advanced lightstyle"
#define PL_VER	"1.1.0"

public Plugin:myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Set lightstyle with more options",
	author		= "Franc1sco steam: franug (rewritten by Grey83)"
}

public OnPluginStart()
{
	CreateConVar("sm_advlightstyle_version", PL_VER, PL_NAME, FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public OnMapStart()
{
	new Handle:kv = CreateKeyValues("advLigheStyle");
	if(!FileToKeyValues(kv,"cfg/sourcemod/advanced_lightstyle.txt"))
		SetFailState("File cfg/sourcemod/advanced_lightstyle.txt not found");

	new String:buffer[128];
	FormatTime(buffer, sizeof(buffer), "%H", GetTime());

	new repeticion, hour_int;
	while(!KvJumpToKey(kv, buffer))
	{
		hour_int = StringToInt(buffer);
		--hour_int;
		if(hour_int < 0) hour_int = 23;

		IntToString(hour_int, buffer, sizeof(buffer));
		++repeticion;
		if(repeticion > 26)
			SetFailState("Failed to get hour");
	}

	new String:skyname[32], String:lightlevel[4];
	KvGetString(kv, "default", buffer, sizeof(buffer), "no");
	if(StrContains(buffer, "no") == -1)
	{
		CloseHandle(kv);
		return;
	}
	else
	{
		KvGetString(kv, "lightlevel", lightlevel, sizeof(lightlevel));
		KvGetString(kv, "skyname", skyname, sizeof(skyname));
	}

	KvGetString(kv, "custom", buffer, sizeof(buffer), "no");
	CloseHandle(kv);

	if(StrContains(buffer, "no") == -1)
	{
		FormatEx(buffer, sizeof(buffer), "materials/skybox/%s.vtf", skyname);
		AddFileToDownloadsTable(buffer);

		FormatEx(buffer, sizeof(buffer), "materials/skybox/%s.vmt", skyname);
		AddFileToDownloadsTable(buffer);
	}

	ServerCommand("sv_skyname %s", skyname);

	SetLightStyle(0, lightlevel);
}