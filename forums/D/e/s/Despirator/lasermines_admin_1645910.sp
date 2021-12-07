#pragma semicolon 1

#include <sourcemod>

#undef REQUIRE_PLUGIN
#tryinclude <lasermines>
#tryinclude <zr_lasermines>
#tryinclude <zriot_lasermines>

#define PLUGIN_VERSION	"1.0"

new Handle:h_Amount,
	Handle:h_AdminsFlag, String:s_adminsflag[12];

public Plugin:myinfo = 
{
	name = "Admin lasermines",
	author = "FrozDark (HLModders LLC)",
	description = "The number of mines for admins",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru/"
}

GetLasermineType()
{
	if (GetFeatureStatus(FeatureType_Native, "SetClientMaxLasermines") == FeatureStatus_Available)
	{
		return 1;
	}
	else if (GetFeatureStatus(FeatureType_Native, "ZR_SetClientMaxLasermines") == FeatureStatus_Available)
	{
		return 2;
	}
	else if (GetFeatureStatus(FeatureType_Native, "ZRiot_SetClientMaxLasermines") == FeatureStatus_Available)
	{
		return 3;
	}
	return 0;
}

new lm_type;
public OnPluginStart()
{
	h_Amount = CreateConVar("lasermines_admin_amount", "5", "The number of mines to set to the admins");
	h_AdminsFlag = CreateConVar("lasermines_admin_flag", "b", "An admin flag to ident for. Leave it empty for any flag");
	
	GetConVarString(h_AdminsFlag, s_adminsflag, sizeof(s_adminsflag));
	HookConVarChange(h_AdminsFlag, ConVarChanges);
	
	if ((lm_type = GetLasermineType()) == 0) SetFailState("No support");
}

public ConVarChanges(Handle:convar, const String:oldVal[], const String:newVal[])
{
	strcopy(s_adminsflag, sizeof(s_adminsflag), newVal);
}

public OnClientPostAdminCheck(client)
{
	new AdminId:adminid = GetUserAdmin(client);
	new AdminFlag:flag;
	if (adminid != INVALID_ADMIN_ID)
	{
		if (!s_adminsflag[0])
		{
			SetAmount(client, GetConVarInt(h_Amount));
		}
		
		else if (FindFlagByChar(s_adminsflag[0], flag) && GetAdminFlag(adminid, flag))
		{
			SetAmount(client, GetConVarInt(h_Amount));
		}
	}
}

SetAmount(client, amount)
{
	switch (lm_type)
	{
		case 1 : SetClientMaxLasermines(client, amount);
		case 2 : ZR_SetClientMaxLasermines(client, amount);
		case 3 : ZRiot_SetClientMaxLasermines(client, amount);
	}
}