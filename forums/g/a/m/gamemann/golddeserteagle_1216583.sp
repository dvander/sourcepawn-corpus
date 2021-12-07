#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "gold magnum",
	author = "gamemann",
	description = "",
	version = "1",
	url = ""
};

new String:Gold[] = "255 255 255";

new Handle:DesertEagle = INVALID_HANDLE;

public OnPluginStart()
{
	DesertEagle = CreateConVar("desert_eagle", Gold, "colors the magnum");
	HookEvent("player_spawn", Spawn);
	HookEvent("weapon_pickup", Weapons);
	AutoExecConfig(true, "l4d2_gold_eagle");
	LoadTranslations("common.phrases");
}

public Weapons(Handle:event, const String:name[], bool:dontbroadcast)
{

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	Paint(client);
}

public Spawn(Handle:event, const String:name[], bool:dontbroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	Paint(client);
}

stock Paint(client)
{
	if(IsClientInGame(client))
	{
		decl String:Model[150], String:Color[50];
		GetClientModel(client, Model, sizeof(Model));
		if (StrContains(Model, "v_desert_eagle", false) > -1)
			GetConVarString(DesertEagle, Color, sizeof(Color));
		else
		{
			LogMessage("Unknown Model: %s is invalid", Model); //Logs the Model for future improvements
			return;//The witch can be colored now!
		}
		SetEntityRenderColor(client,255,255,0,255)
		DispatchKeyValue(client, "rendercolor", Color);
	}
}



